package HTML::Scrubber;

# ABSTRACT: Perl extension for scrubbing/sanitizing HTML


use 5.008;    # enforce minimum perl version of 5.8
use strict;
use warnings;
use HTML::Parser 3.47 ();
use HTML::Entities;
use Scalar::Util ('weaken');
use List::Util qw(any);

our ( @_scrub, @_scrub_fh );

our $VERSION = '0.17'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

# my my my my, these here to prevent foolishness like
# http://perlmonks.org/index.pl?node_id=251127#Stealing+Lexicals
(@_scrub)    = ( \&_scrub,    "self, event, tagname, attr, attrseq, text" );
(@_scrub_fh) = ( \&_scrub_fh, "self, event, tagname, attr, attrseq, text" );


sub new {
    my $package = shift;
    my $p       = HTML::Parser->new(
        api_version             => 3,
        default_h               => \@_scrub,
        marked_sections         => 0,
        strict_comment          => 0,
        unbroken_text           => 1,
        case_sensitive          => 0,
        boolean_attribute_value => undef,
        empty_element_tags      => 1,
    );

    my $self = {
        _p        => $p,
        _rules    => { '*' => 0, },
        _comment  => 0,
        _process  => 0,
        _r        => "",
        _optimize => 1,
        _script   => 0,
        _style    => 0,
    };

    $p->{"\0_s"} = bless $self, $package;
    weaken( $p->{"\0_s"} );

    return $self unless @_;

    my (%args) = @_;

    for my $f (qw[ default allow deny rules process comment ]) {
        next unless exists $args{$f};
        if ( ref $args{$f} ) {
            $self->$f( @{ $args{$f} } );
        }
        else {
            $self->$f( $args{$f} );
        }
    }

    return $self;
}


sub comment {
    return $_[0]->{_comment}
        if @_ == 1;
    $_[0]->{_comment} = $_[1];
    return;
}


sub process {
    return $_[0]->{_process}
        if @_ == 1;
    $_[0]->{_process} = $_[1];
    return;
}


sub script {
    return $_[0]->{_script}
        if @_ == 1;
    $_[0]->{_script} = $_[1];
    return;
}


sub style {
    return $_[0]->{_style}
        if @_ == 1;
    $_[0]->{_style} = $_[1];
    return;
}


sub allow {
    my $self = shift;
    for my $k (@_) {
        $self->{_rules}{ lc $k } = 1;
    }
    $self->{_optimize} = 1;    # each time a rule changes, reoptimize when parse

    return;
}


sub deny {
    my $self = shift;

    for my $k (@_) {
        $self->{_rules}{ lc $k } = 0;
    }

    $self->{_optimize} = 1;    # each time a rule changes, reoptimize when parse

    return;
}


sub rules {
    my $self = shift;
    my (%rules) = @_;
    for my $k ( keys %rules ) {
        $self->{_rules}{ lc $k } = $rules{$k};
    }

    $self->{_optimize} = 1;    # each time a rule changes, reoptimize when parse

    return;
}


sub default {
    return $_[0]->{_rules}{'*'}
        if @_ == 1;

    $_[0]->{_rules}{'*'} = $_[1] if defined $_[1];
    $_[0]->{_rules}{'_'} = $_[2] if defined $_[2] and ref $_[2];
    $_[0]->{_optimize} = 1;    # each time a rule changes, reoptimize when parse

    return;
}


sub scrub_file {
    if ( @_ > 2 ) {
        return unless defined $_[0]->_out( $_[2] );
    }
    else {
        $_[0]->{_p}->handler( default => @_scrub );
    }

    $_[0]->_optimize();    #if $_[0]->{_optimize};

    $_[0]->{_p}->parse_file( $_[1] );

    return delete $_[0]->{_r} unless exists $_[0]->{_out};
    print { $_[0]->{_out} } $_[0]->{_r} if length $_[0]->{_r};
    delete $_[0]->{_out};
    return 1;
}


sub scrub {
    if ( @_ > 2 ) {
        return unless defined $_[0]->_out( $_[2] );
    }
    else {
        $_[0]->{_p}->handler( default => @_scrub );
    }

    $_[0]->_optimize();    # if $_[0]->{_optimize};

    $_[0]->{_p}->parse( $_[1] ) if defined( $_[1] );
    $_[0]->{_p}->eof();

    return delete $_[0]->{_r} unless exists $_[0]->{_out};
    delete $_[0]->{_out};
    return 1;
}


sub _out {
    my ( $self, $o ) = @_;

    unless ( ref $o and ref \$o ne 'GLOB' ) {
        open my $F, '>', $o or return;
        binmode $F;
        $self->{_out} = $F;
    }
    else {
        $self->{_out} = $o;
    }

    $self->{_p}->handler( default => @_scrub_fh );

    return 1;
}


sub _validate {
    my ( $s, $t, $r, $a, $as ) = @_;
    return "<$t>" unless %$a;

    $r = $s->{_rules}->{$r};
    my %f;

    for my $k ( keys %$a ) {
        my $check = exists $r->{$k} ? $r->{$k} : exists $r->{'*'} ? $r->{'*'} : next;

        if ( ref $check eq 'CODE' ) {
            my @v = $check->( $s, $t, $k, $a->{$k}, $a, \%f );
            next unless @v;
            $f{$k} = shift @v;
        }
        elsif ( ref $check || length($check) > 1 ) {
            $f{$k} = $a->{$k} if $a->{$k} =~ m{$check};
        }
        elsif ($check) {
            $f{$k} = $a->{$k};
        }
    }

    if (%f) {
        my %seen;
        return "<$t $r>"
            if $r = join ' ', map {
            defined $f{$_}
                ? qq[$_="] . encode_entities( $f{$_} ) . q["]
                : $_;    # boolean attribute (TODO?)
            } grep { exists $f{$_} and !$seen{$_}++; } @$as;
    }

    return "<$t>";
}


sub _scrub_str {
    my ( $p, $e, $t, $a, $as, $text ) = @_;

    my $s      = $p->{"\0_s"};
    my $outstr = '';

    if ( $e eq 'start' ) {
        if ( exists $s->{_rules}->{$t} )    # is there a specific rule
        {
            if ( ref $s->{_rules}->{$t} )    # is it complicated?(not simple;)
            {
                $outstr .= $s->_validate( $t, $t, $a, $as );
            }
            elsif ( $s->{_rules}->{$t} )     # validate using default attribute rule
            {
                $outstr .= $s->_validate( $t, '_', $a, $as );
            }
        }
        elsif ( $s->{_rules}->{'*'} )        # default allow tags
        {
            $outstr .= $s->_validate( $t, '_', $a, $as );
        }
    }
    elsif ( $e eq 'end' ) {

        # empty tags list taken from
        # https://developer.mozilla.org/en/docs/Glossary/empty_element
        my @empty_tags = qw(area base br col embed hr img input link meta param source track wbr);
        return "" if $text ne '' && any { $t eq $_ } @empty_tags;    # skip false closing empty tags

        my $place = 0;
        if ( exists $s->{_rules}->{$t} ) {
            $place = 1 if $s->{_rules}->{$t};
        }
        elsif ( $s->{_rules}->{'*'} ) {
            $place = 1;
        }
        if ($place) {
            if ( length $text ) {
                $outstr .= "</$t>";
            }
            else {
                substr $s->{_r}, -1, 0, ' /';
            }
        }
    }
    elsif ( $e eq 'comment' ) {
        if ( $s->{_comment} ) {

            # only copy comments through if they are well formed...
            $outstr .= $text if ( $text =~ m|^<!--.*-->$|ms );
        }
    }
    elsif ( $e eq 'process' ) {
        $outstr .= $text if $s->{_process};
    }
    elsif ( $e eq 'text' or $e eq 'default' ) {
        $text =~ s/</&lt;/g;    #https://rt.cpan.org/Public/Ticket/Attachment/83958/10332/scrubber.patch
        $text =~ s/>/&gt;/g;

        $outstr .= $text;
    }
    elsif ( $e eq 'start_document' ) {
        $outstr = "";
    }

    return $outstr;
}


sub _scrub_fh {
    my $self = $_[0]->{"\0_s"};
    print { $self->{_out} } $self->{'_r'} if length $self->{_r};
    $self->{'_r'} = _scrub_str(@_);
}


sub _scrub {

    $_[0]->{"\0_s"}->{_r} .= _scrub_str(@_);
}

sub _optimize {
    my ($self) = @_;

    my (@ignore_elements) = grep { not $self->{"_$_"} } qw(script style);
    $self->{_p}->ignore_elements(@ignore_elements);    # if @ is empty, we reset ;)

    return unless $self->{_optimize};

    #sub allow
    #    return unless $self->{_optimize}; # till I figure it out (huh)

    if ( $self->{_rules}{'*'} ) {    # default allow
        $self->{_p}->report_tags();    # so clear it
    }
    else {

        my (@reports) =
            grep {                     # report only tags we want
            $self->{_rules}{$_}
            } keys %{ $self->{_rules} };

        $self->{_p}->report_tags(      # default deny, so optimize
            @reports
        ) if @reports;
    }

    # sub deny
    #    return unless $self->{_optimize}; # till I figure it out (huh)
    my (@ignores) =
        grep { not $self->{_rules}{$_} } grep { $_ ne '*' } keys %{ $self->{_rules} };

    $self->{_p}->ignore_tags(    # always ignore stuff we don't want
        @ignores
    ) if @ignores;

    $self->{_optimize} = 0;
    return;
}

1;

#print sprintf q[ '%-12s => %s,], "$_'", $h{$_} for sort keys %h;# perl!
#perl -ne"chomp;print $_;print qq'\t\t# test ', ++$a if /ok\(/;print $/" test.pl >test2.pl
#perl -ne"chomp;print $_;if( /ok\(/ ){s/\#test \d+$//;print qq'\t\t# test ', ++$a }print $/" test.pl >test2.pl
#perl -ne"chomp;if(/ok\(/){s/# test .*$//;print$_,qq'\t\t# test ',++$a}else{print$_}print$/" test.pl >test2.pl

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Scrubber - Perl extension for scrubbing/sanitizing HTML

=head1 VERSION

version 0.17

=for stopwords html cpan callback homepage Perlbrew perltidy repository

=head1 SYNOPSIS

    use HTML::Scrubber;

    my $scrubber = HTML::Scrubber->new( allow => [ qw[ p b i u hr br ] ] );
    print $scrubber->scrub('<p><b>bold</b> <em>missing</em></p>');
    # output is: <p><b>bold</b> </p>

    # more complex input
    my $html = q[
    <style type="text/css"> BAD { background: #666; color: #666;} </style>
    <script language="javascript"> alert("Hello, I am EVIL!");    </script>
    <HR>
        a   => <a href=1>link </a>
        br  => <br>
        b   => <B> bold </B>
        u   => <U> UNDERLINE </U>
    ];

    print $scrubber->scrub($html);

    $scrubber->deny( qw[ p b i u hr br ] );

    print $scrubber->scrub($html);

=head1 DESCRIPTION

If you want to "scrub" or "sanitize" html input in a reliable and flexible
fashion, then this module is for you.

I wasn't satisfied with L<HTML::Sanitizer> because it is based on
L<HTML::TreeBuilder>, so I thought I'd write something similar that works
directly with L<HTML::Parser>.

=head1 METHODS

First a note on documentation: just study the L<EXAMPLE|"EXAMPLE"> below. It's
all the documentation you could need.

Also, be sure to read all the comments as well as L<How does it work?|"How does
it work?">.

If you're new to perl, good luck to you.

=head2 new

    my $scrubber = HTML::Scrubber->new( allow => [ qw[ p b i u hr br ] ] );

Build a new L<HTML::Scrubber>.  The arguments are the initial values for the
following directives:-

=over 4

=item * default

=item * allow

=item * deny

=item * rules

=item * process

=item * comment

=back

=head2 comment

    warn "comments are  ", $p->comment ? 'allowed' : 'not allowed';
    $p->comment(0);  # off by default

=head2 process

    warn "process instructions are  ", $p->process ? 'allowed' : 'not allowed';
    $p->process(0);  # off by default

=head2 script

    warn "script tags (and everything in between) are supressed"
        if $p->script;      # off by default
    $p->script( 0 || 1 );

B<**> Please note that this is implemented using L<HTML::Parser>'s
C<ignore_elements> function, so if C<script> is set to true, all script tags
encountered will be validated like all other tags.

=head2 style

    warn "style tags (and everything in between) are supressed"
        if $p->style;       # off by default
    $p->style( 0 || 1 );

B<**> Please note that this is implemented using L<HTML::Parser>'s
C<ignore_elements> function, so if C<style> is set to true, all style tags
encountered will be validated like all other tags.

=head2 allow

    $p->allow(qw[ t a g s ]);

=head2 deny

    $p->deny(qw[ t a g s ]);

=head2 rules

    $p->rules(
        img => {
            src => qr{^(?!http://)}i, # only relative image links allowed
            alt => 1,                 # alt attribute allowed
            '*' => 0,                 # deny all other attributes
        },
        a => {
            href => sub { ... },      # check or adjust with a callback
        },
        b => 1,
        ...
    );

Updates a set of attribute rules. Each rule can be 1/0, a regular expression or
a callback. Values longer than 1 char are treated as regexps. The callback is
called with the following arguments: the current object, tag name, attribute
name, and attribute value; the callback should return an empty list to drop the
attribute, C<undef> to keep it without a value, or a new scalar value.

=head2 default

    print "default is ", $p->default();
    $p->default(1);      # allow tags by default
    $p->default(
        undef,           # don't change
        {                # default attribute rules
            '*' => 1,    # allow attributes by default
        }
    );

=head2 scrub_file

    $html = $scrubber->scrub_file('foo.html');   ## returns giant string
    die "Eeek $!" unless defined $html;  ## opening foo.html may have failed
    $scrubber->scrub_file('foo.html', 'new.html') or die "Eeek $!";
    $scrubber->scrub_file('foo.html', *STDOUT)
        or die "Eeek $!"
            if fileno STDOUT;

=head2 scrub

    print $scrubber->scrub($html);  ## returns giant string
    $scrubber->scrub($html, 'new.html') or die "Eeek $!";
    $scrubber->scrub($html', *STDOUT)
        or die "Eeek $!"
            if fileno STDOUT;

=for comment _out
    $scrubber->_out(*STDOUT) if fileno STDOUT;
    $scrubber->_out('foo.html') or die "eeek $!";

=for comment _validate
Uses $self->{_rules} to do attribute validation.
Takes tag, rule('_' || $tag), attrref.

=for comment _scrub_str

I<default> handler, used by both C<_scrub> and C<_scrub_fh>. Moved all the
common code (basically all of it) into a single routine for ease of
maintenance.

=for comment _scrub_fh

I<default> handler, does the scrubbing if we're scrubbing out to a file. Now
calls C<_scrub_str> and pushes that out to a file.

=for comment _scrub

I<default> handler, does the scrubbing if we're returning a giant string. Now
calls C<_scrub_str> and appends that to the output string.

=head1 How does it work?

When a tag is encountered, L<HTML::Scrubber> allows/denies the tag using the
explicit rule if one exists.

If no explicit rule exists, Scrubber applies the default rule.

If an explicit rule exists, but it's a simple rule(1), then the default
attribute rule is applied.

=head2 EXAMPLE

=for example begin

    #!/usr/bin/perl -w
    use HTML::Scrubber;
    use strict;

    my @allow = qw[ br hr b a ];

    my @rules = (
        script => 0,
        img    => {
            src => qr{^(?!http://)}i,    # only relative image links allowed
            alt => 1,                    # alt attribute allowed
            '*' => 0,                    # deny all other attributes
        },
    );

    my @default = (
        0 =>                             # default rule, deny all tags
            {
            '*'    => 1,                             # default rule, allow all attributes
            'href' => qr{^(?:http|https|ftp)://}i,
            'src'  => qr{^(?:http|https|ftp)://}i,

            #   If your perl doesn't have qr
            #   just use a string with length greater than 1
            'cite'        => '(?i-xsm:^(?:http|https|ftp):)',
            'language'    => 0,
            'name'        => 1,                                 # could be sneaky, but hey ;)
            'onblur'      => 0,
            'onchange'    => 0,
            'onclick'     => 0,
            'ondblclick'  => 0,
            'onerror'     => 0,
            'onfocus'     => 0,
            'onkeydown'   => 0,
            'onkeypress'  => 0,
            'onkeyup'     => 0,
            'onload'      => 0,
            'onmousedown' => 0,
            'onmousemove' => 0,
            'onmouseout'  => 0,
            'onmouseover' => 0,
            'onmouseup'   => 0,
            'onreset'     => 0,
            'onselect'    => 0,
            'onsubmit'    => 0,
            'onunload'    => 0,
            'src'         => 0,
            'type'        => 0,
            }
    );

    my $scrubber = HTML::Scrubber->new();
    $scrubber->allow(@allow);
    $scrubber->rules(@rules);    # key/value pairs
    $scrubber->default(@default);
    $scrubber->comment(1);       # 1 allow, 0 deny

    ## preferred way to create the same object
    $scrubber = HTML::Scrubber->new(
        allow   => \@allow,
        rules   => \@rules,
        default => \@default,
        comment => 1,
        process => 0,
    );

    require Data::Dumper, die Data::Dumper::Dumper($scrubber) if @ARGV;

    my $it = q[
        <?php   echo(" EVIL EVIL EVIL "); ?>    <!-- asdf -->
        <hr>
        <I FAKE="attribute" > IN ITALICS WITH FAKE="attribute" </I><br>
        <B> IN BOLD </B><br>
        <A NAME="evil">
            <A HREF="javascript:alert('die die die');">HREF=JAVA &lt;!&gt;</A>
            <br>
            <A HREF="image/bigone.jpg" ONMOUSEOVER="alert('die die die');">
                <IMG SRC="image/smallone.jpg" ALT="ONMOUSEOVER JAVASCRIPT">
            </A>
        </A> <br>
    ];

    print "#original text", $/, $it, $/;
    print
        "#scrubbed text (default ", $scrubber->default(),    # no arguments returns the current value
        " comment ", $scrubber->comment(), " process ", $scrubber->process(), " )", $/, $scrubber->scrub($it), $/;

    $scrubber->default(1);                                   # allow all tags by default
    $scrubber->comment(0);                                   # deny comments

    print
        "#scrubbed text (default ",
        $scrubber->default(),
        " comment ",
        $scrubber->comment(),
        " process ",
        $scrubber->process(),
        " )", $/,
        $scrubber->scrub($it),
        $/;

    $scrubber->process(1);    # allow process instructions (dangerous)
    $default[0] = 1;          # allow all tags by default
    $default[1]->{'*'} = 0;   # deny all attributes by default
    $scrubber->default(@default);    # set the default again

    print
        "#scrubbed text (default ",
        $scrubber->default(),
        " comment ",
        $scrubber->comment(),
        " process ",
        $scrubber->process(),
        " )", $/,
        $scrubber->scrub($it),
        $/;

=for example end

=head2 FUN

If you have L<Test::Inline> (and you've installed L<HTML::Scrubber>), try

    pod2test Scrubber.pm >scrubber.t
    perl scrubber.t

=head1 SEE ALSO

L<HTML::Parser>, L<Test::Inline>.

The L<HTML::Sanitizer> module is no longer available on CPAN.

=head1 VERSION REQUIREMENTS

As of version 0.14 I have added a perl minimum version requirement of 5.8. This
is basically due to failures on the smokers perl 5.6 installations - which
appears to be down to installation mechanisms and requirements.

Since I don't want to spend the time supporting a version that is so old (and
may not work for reasons on UTF support etc), I have added a C<use 5.008;> to
the main module.

If this is problematic I am very willing to accept patches to fix this up,
although I do not personally see a good reason to support a release that has
been obsolete for 13 years.

=head1 CONTRIBUTING

If you want to contribute to the development of this module, the code is on
L<GitHub|http://github.com/nigelm/html-scrubber>. You'll need a perl
environment with L<Dist::Zilla>, and if you're just getting started, there's
some documentation on using Vagrant and Perlbrew
L<here|http://mrcaron.github.io/2015/03/06/Perl-CPAN-Pull-Request.html>.

There is now a C<.perltidyrc> and a C<.tidyallrc> file within the repository
for the standard perltidy settings used - I will apply these before new
releases.  Please do not let formatting prevent you from sending in patches etc
- this can be sorted out as part of the release process.  Info on C<tidyall>
can be found at
L<https://metacpan.org/pod/distribution/Code-TidyAll/bin/tidyall>.

=head1 AUTHORS

=over 4

=item *

Ruslan Zakirov <Ruslan.Zakirov@gmail.com>

=item *

Nigel Metheringham <nigelm@cpan.org>

=item *

D. H. <podmaster@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Ruslan Zakirov, Nigel Metheringham, 2003-2004 D. H.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc HTML::Scrubber

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/HTML-Scrubber>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/HTML-Scrubber>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Scrubber>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/HTML-Scrubber>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/HTML-Scrubber>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/HTML-Scrubber>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/HTML-Scrubber>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/H/HTML-Scrubber>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=HTML-Scrubber>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=HTML::Scrubber>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-html-scrubber at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=HTML-Scrubber>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/nigelm/html-scrubber>

  git clone https://github.com/nigelm/html-scrubber.git

=head1 CONTRIBUTORS

=for stopwords Andrei Vereha Lee Johnson Michael Caron Nigel Metheringham Paul Cochrane Ruslan Zakirov Sergey Romanov vagrant

=over 4

=item *

Andrei Vereha <avereha@gmail.com>

=item *

Lee Johnson <lee@givengain.ch>

=item *

Michael Caron <michael.r.caron@gmail.com>

=item *

Michael Caron <mrcaron@users.noreply.github.com>

=item *

Nigel Metheringham <nm9762github@muesli.org.uk>

=item *

Paul Cochrane <paul@liekut.de>

=item *

Ruslan Zakirov <ruz@bestpractical.com>

=item *

Sergey Romanov <complefor@rambler.ru>

=item *

vagrant <vagrant@precise64.(none)>

=back

=cut
