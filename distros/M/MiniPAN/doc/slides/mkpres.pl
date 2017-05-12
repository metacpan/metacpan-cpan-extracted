#!/usr/bin/perl
#
# This script generates a linked set of HTML slide files from the contents of
# talk.xml.  Use './mkpres.pl --help' for more info.
#
# Copyright (c) 2004-2007 Grant McLean <grantm@cpan.org>
#
# This library is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.
#

use strict;
use warnings;

use XML::LibXML  qw();
use FindBin      qw();
use Pod::Usage   qw(pod2usage);
use Getopt::Long qw(GetOptions);
use Storable     qw(dclone);

my $file = 'talk.xml';

my %template = (
  index => Template::MasonLite->new_from_file('./_index.html'),
  toc   => Template::MasonLite->new_from_file('./_toc.html'),
  slide => Template::MasonLite->new_from_file('./_slide.html'),
);

my(%opt, $have_vim_highlight);
if(!GetOptions(\%opt, 'help|?', 'devmode|d')) {
    pod2usage(-exitval => 1,  -verbose => 0);
}
pod2usage(-exitstatus => 0, -verbose => 2) if($opt{'help'});

chdir($FindBin::Bin) or die "chdir($FindBin::Bin): $!";

my $pres = read_presentation_data($file);
generate_presentation_pages($pres);

exit;


sub read_presentation_data {
    my($filename) = @_;
    my $parser = XML::LibXML->new;
    my $doc    = $parser->parse_file($file);

    my $pres = {
        metadata => {
            title     => $doc->findvalue('/presentation/title')    || '',
            subtitle  => $doc->findvalue('/presentation/subtitle') || '',
            author    => $doc->findvalue('/presentation/author')   || '',
            email     => $doc->findvalue('/presentation/email')    || '',
            event     => $doc->findvalue('/presentation/event')    || '',
            date      => $doc->findvalue('/presentation/date')     || '',
        },
    };
    add_slide_data($pres, $doc);

    return $pres;
}


sub add_slide_data {
    my($pres, $doc) = @_;

    my @slides;
    foreach my $slide ( $doc->findnodes('/presentation/slide') ) {
        push @slides, parse_slide($slide);
    }

    my $i    = 1;
    my $prev = 1;
    my $last_slide;
    my @toc;
    foreach my $slide (@slides) {
        $slide->{filename} = slide_filename($i);
        if(! $slide->{id}) {
            ($slide->{id}) = $slide->{filename} =~ m/^(.*)\.html$/;
        }
        $slide->{next}     = ($i - 1 == $#slides)
                             ? 'index.html'
                             : slide_filename($i + 1);
        $slide->{previous} = ($i == 1) 
                             ? 'toc.html'
                             : slide_filename($prev);
        $prev = $i if not $slide->{continuation};

        if(defined $last_slide and not $opt{devmode}) {
            add_prefetch_links($last_slide, $slide)
        }

        my $cont = $slide->{continuation} 
                   || ($last_slide && $last_slide->{title} eq $slide->{title});
        if(not $cont) {
            push @toc, { 
                filename => $slide->{filename}, 
                title    => $slide->{title},
            };
        }
        $last_slide = $slide;
        $i++;
    }
    $pres->{slides} = \@slides;
    $pres->{toc}    = \@toc;
}


sub slide_filename {
    return sprintf("slide%03u.html", $_[0]);
}


sub add_prefetch_links {
    my($last_slide, $slide) = @_;

    my @links;
    push @links, "images/$slide->{image}" if $slide->{image};
    push @links, map {
                     $_->[0] eq 'screenshot' ? "images/$_->[1]" : () 
                 } @{$slide->{content}};
    $last_slide->{prefetch} = \@links if @links;
}


sub parse_slide {
    my($slide) = @_;

    my @partials;
    my $data = {
        title   => $slide->findvalue('./title') || '',
        id      => $slide->findvalue('./@id')   || '',
        content => [],
    };
    my $content = $data->{content};

    my $item_expr = './bullet|./pause|./screenshot|./code|./image';
    foreach my $node ($slide->findnodes($item_expr)) {
        my $type = $node->nodeName;
        if($type eq 'bullet') {
            if(!@$content or $content->[-1][0] ne 'bullets') {
                push @$content, [ bullets => [] ]
            }
            my $blist = $content->[-1][1];
            push @$blist, join '', map { $_->toString } $node->childNodes;
        }
        elsif($type eq 'pause') {
            push @partials, dclone($data);
            $data->{continuation} = 1;
        }
        elsif($type eq 'screenshot') {
            push @$content, [ screenshot => image_path($node->to_literal) ];
        }
        elsif($type eq 'code') {
            my $code = outdent($node->to_literal);
            my $language = $node->findvalue('./@syntax') || '';
            $code = syntax_highlight($code, $language) if $language;
            push @$content, [ code => $code ];
        }
        elsif($type eq 'image') {
            $data->{image} = image_path($node->to_literal);
        }
    }
    return @partials, $data;
}


sub image_path {
    my($path) = @_;
    die "File not found: html/images/$path" unless -r "html/images/$path";
    return $path;
}


sub generate_presentation_pages {
    my($pres) = @_;

    generate_title_page($pres);
    generate_contents_page($pres);
    generate_slide_pages($pres);
}

sub generate_title_page {
    my($pres) = @_;

    my $data = {
        %{ $pres->{metadata} },
        next     => slide_filename(1),
        previous => '',
    };
    save_file($template{index}, 'index.html', $data);
}


sub generate_contents_page {
    my($pres) = @_;

    my $data = {
        title    => 'Contents',
        metadata => $pres->{metadata},
        toc      => $pres->{toc},
        next     => slide_filename(1),
        previous => 'index.html',
    };
    save_file($template{toc}, 'toc.html', $data);
}


sub generate_slide_pages {
    my($pres) = @_;

    unlink grep m{/slide\d+\.html}, glob "html/*.html";

    foreach my $slide ( @{ $pres->{slides} } ) {
        my $data = {
          %$slide,
          metadata => $pres->{metadata},
        };
        save_file($template{slide}, $slide->{filename}, $data);
    }
}

sub outdent {
    local($_) = @_;
    s/\s+$//s;
    s/^\s*?\n//s;
    my($prefix, @prefs) = m/^(\s*)/mg;
    foreach (@prefs) {
        $prefix = $_ if length($_) < length($prefix);
    }
    s/^$prefix//mg;
    return $_;
}


sub syntax_highlight {
    my($code, $language) = @_;

    if(!defined $have_vim_highlight) {
        eval 'require Text::VimColor';
        if($@) {
            warn "Warning: Text::VimColor is required for syntax highlighting\n";
            $have_vim_highlight = 0;
        }
        else {
            $have_vim_highlight = 1;
        }
    }
    return $code unless $have_vim_highlight;

    return Text::VimColor->new(
        string   => $code,
        filetype => $language,
    )->html;
}


sub save_file {
    my($tmpl, $file, $data) = @_;

    if($opt{devmode}) {
        my $time = time();
        $data->{next}     .= '?' . $time;
        $data->{previous} .= '?' . $time;
    }
    open my $out, '>:utf8', "./html/$file" or die "open(./html/$file): $!";
    print $out $tmpl->apply(%$data);
}



package Template::MasonLite;

use strict;
use warnings;
use Carp;

our $VERSION = '0.9';

my(
    $nl, $init_sect, $perl_sect, $perl_line, $comp_def, $comp_call, 
    $expression, $literal
);

BEGIN {
    $nl         = qr{(?:[ \r]*\n)};
    $init_sect  = qr{<%init>(.*?)</%init>$nl?}s;
    $perl_sect  = qr{<%perl>(.*?)</%perl>$nl?}s;
    $perl_line  = qr{(?:(?<=\n)|^)%(.*?)(\n|\Z)}s;
    $comp_def   = qr{<%def\s+([.\w+]+)>$nl(.*?)</%def>$nl?}s;
    $comp_call  = qr{<&\s*([\w._-]+)(?:\s*,)?(.*?)&>}s;
    $expression = qr{<%\s*(.*?)%>}s;
    $literal    = qr{(.*?(\n|(?=<%|<&|\Z)))};
}

sub new           { return bless $_[0]->_parse($_[1]),      $_[0]; }
sub new_from_file { return bless $_[0]->_parse_file($_[1]), $_[0]; }

sub apply         { my $self = shift; return $self->(@_) };

sub _parse_file {
    my($class, $template) = @_;

    open my $fh, '<', $template or croak "$!: $template";
    sysread $fh, $_, -s $template;
    return $class->_parse($_);
}

sub _parse {
    my($class, $template) = @_;

    die "No template!\n" unless defined($template);
    $_ = $template;

    my(@head, @body, %comp);
    while(!/\G\Z/sgc) {
        if   (/\G$init_sect/sgc ) { push @head, $1;        }
        elsif(/\G$perl_sect/sgc ) { push @body, $1;        }
        elsif(/\G$perl_line/sgc ) { push @body, $1;        }
        elsif(/\G$comp_def/sgc  ) { $comp{$1} = $2;        }
        elsif(/\G$comp_call/sgc ) { push @body,
                                      [ 0, "\$comp{'$1'}->apply($2)" ]; 
                                  }
        elsif(/\G$expression/sgc) { push @body, [ 0, $1 ]; }
        elsif(/\G$literal/sgc   ) { push @body, [ 1, $1 ]; }
        else {/(.*)/sgc && croak "could not parse: '$1'";  }
    };
    while(my($name, $source) = each %comp) {
        $comp{$name} = $class->new($source);
    }

    unshift @head, 'my @r; my %ARGS; %ARGS = @_ unless(@_ % 2);';
    push    @body, 'return join "", @r';

    my $code = join("\n", map {
        ref($_)
        ? ( $_->[0] ? _literal($_->[1]) : _expr($_->[1]) )
        : $_;
    } @head, @body);

    $_ = '';
    my $sub = eval "sub { $code }";
    croak $@ if $@;
    return $sub;
}

sub _expr    { "push \@r, $_[0];"; }
sub _literal { $_ = shift; s/'/\\'/g; s/\\\n//s; _expr("'$_'"); }

# End of Template::MasonLite

sub h {
    $_ = shift;
    s/&/&amp;/g;
    s/</&lt;/g;
    s/>/&gt;/g;
    $_;
}

__END__


=head1 NAME

mkpres - generate HTML slide files from talk.xml

=head1 SYNOPSIS

  mkpres [options]

  Options:

   -d     enable 'dev' mode - links will be timestamped
   -?     detailed help message

=head1 DESCRIPTION

Generates a linked set of HTML slide files from the contents of F<talk.xml>.

=head1 OPTIONS

=over 4

=item B<-d>

Enables 'dev' mode.  When this mode is enabled, the 'next' and 'previous'
links between slides will be made unique through the addition of a numeric 
query-string.  This is handy for working around browser caching issues while
the presentation is under development.

You almost certainly don't want this option enabled when generating the final
version of a presentation for publication on the web.

=item B<-?>

Display this documentation.

=back

=head1 OUTPUTS

Generates the following files in the F<html> directory:

=over 4

=item *

a series of slide files called F<slide001.html> ... F<slideNNN.html>

=item *

a main cover page called F<index.html>

=item *

a table of contents page called F<toc.html>

=back

These files are generated from the F<_slide.html>, F<_index.html> and
F<_toc.html> template files respectively.

=head1 XML SCHEMA

This script expects to read a file called F<talk.xml> in the current directory.
That file should be in XML format with:

=over 4

=item *

a top-level element called C<< <presentation> >>

=item *

some metadata elements

=item *

a series of C<< <slide> >> elements

=back

You are encouraged to introduce extra elements that you need.  You'll need to
do a bit of code and template hacking to make them work.


=head2 Metadata Elements

The metadata elements primarily affect the index page however they are 
available to all slides and can be used in headers, footers etc, with
appropriate tweaks to templates and stylesheets.

=over 4

=item C<< <title> >>

The name of the presentation.

=item C<< <subtitle> >>

An optional subtitle for the presentation.

=item C<< <author> >>

The name of the presenter.

=item C<< <email> >>

Presenter's email address (optional).

=item C<< <event> >>

Not generally used.  Some themes display this in the footer.  By convention it
is the name of the event where the talk is presented but you can put whatever
you like in it.

=item C<< <date> >>

Like the 'event' element above, this is not generally used but will be
displayed in the footer by some themes.  Use it for whatever you like.

=back

=head2 Slide Elements

Each C<< <slide> >> element can have an optional C<id> attribute.  The value
will be used as the C<id> of the C<< <body> >> tag in the generated HTML. 
This can be useful for having certain CSS styling apply only to specific 
slides.

Each C<< <slide> >> should also have a C<< <title> >>.

A C<< <slide> >> can include an optional image tag.  The referenced image
would typically be displayed on the righthand side of the slide as decoration.
The text content of this tag is used as the filename.  The file must exist in
the F<html/images> directory.

Following the title and optional image, a slide can contain any number of
C<< <bullet> >>, C<< <pause> >>, C<< <code> >> and C<< <screenshot> >>
'content' elements:

=over 4

=item C<< <bullet> >>

Text for a bullet point.  This text can contain HTML markup, which is typically
used to make hyperlinks or to emphasise words or phrases.

  <bullet>Here is <a href="http://example.com">a link</a></bullet>

=item C<< <pause /> >>

You can insert a 'pause' between bullet points or other content items.  Items
following the pause will not be displayed until the presenter advances the 
slide - typically by pressing the spacebar.  Audiences generally hate this 
effect so you should use it sparingly (eg: to avoid prematurely revealing a 
punchline).

If a slide includes multiple C<< <image> >> elements, only the 'last' one 
before the pause will be used.

=item C<< <code> >> 

The code tag is used for displaying sample snippets of source code.  The
line-wrapping and indentation will be preserved.  The code can optionally be 
syntax highlighted if you have the Text::VimColor module installed.  To enable
syntax highlighting, include a 'syntax' attribute which specifies the language.

Entering programming code into an XML document can be tedious due to special
characters like <, > and &.  For this reason, you would typically use a CDATA
section within the code tags:

    <code syntax="perl"><![CDATA[
      if( $dow > 0 && $dow < 6) {
          print "Wake up - it's a work day!\n";
      }
    ]]></code>

=item C<< <screenshot> >>

The screenshot element is used for any image that should be displayed 'inline'
as part of the presentation (unlike the C<< <image> >> elements which are 
usually visual fluff).

  <screenshot>flowchart.png</screenshot>

=back

=head1 COPYRIGHT

Copyright (c) 2004-2007 Grant McLean <grantm@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

