package HTML::ExtractText;

use strict;
use warnings;

our $VERSION = '1.002004'; # VERSION

use Try::Tiny;
use Scalar::Util qw/blessed/;
use Carp qw/croak/;
use Devel::TakeHashArgs;
use Mojo::DOM;
use overload q|""|  => sub { shift->error        },
             q|%{}| => sub { shift->last_results };

sub new {
    my $self = bless [], shift;
    get_args_as_hash( \@_, \ my %args,
        {   # these are optional with defaults
            separator        => "\n",
            ignore_not_found => 1,
        },
        [ ], # these are mandatory (none, ATM)
        [ qw/separator ignore_not_found/ ], # only these args are valid ones
    ) or croak $@;

    $self->$_( $args{$_} ) for keys %args;

    return $self;
}

sub extract {
    my ( $self, $what, $html, $obj ) = @_;

    $self->error( undef );
    $self->last_results( undef );

    ref $what eq 'HASH'
        or return $self->_set_error('First argument to '
                . 'extract_text() must be a hashref');

    defined $html
        or return $self->_set_error('Second argument to extract_text() is '
                    . 'an undef, expected HTML');

    if ( defined $obj ) {
        blessed $obj
           or return $self->_set_error('Third argument must be an object');

        for ( keys %$what ) {
            $obj->can($_)
                or return $self->_set_error(
                    'The object your provided does not implement the ->'
                    . $_ . '() method that you requested in the first'
                    . ' argument',
                );
        }
    }


    my $dom = Mojo::DOM->new( $html );

    my $did_have_error = 0;
    for my $selector ( sort keys %$what ) {
        my $result;

        try {
            my @results = $self->_extract( $dom, $selector, $what, );
            die "NOT FOUND\n"
                if not @results and not $self->ignore_not_found;

            if ( defined (my $sep = $self->separator) ) {
                $result = join $sep, @results;
            }
            else {
                $result = [ @results ];
            }

        } catch {
            chomp($_);
            $self->error("ERROR: [$selector]: $_");
            $result = "ERROR: $_";
            $did_have_error = 1;
        };

        $what->{ $selector } = $result;
    }

    if ( defined $obj ) {
        for ( keys %$what ) {
            $obj->$_( $what->{ $_ } );
        }
    }

    $self->last_results( $what );

    if ( $did_have_error ) {
        return;
    }
    else {
        return $what;
    }
}

sub separator {
    my $self = shift;
    if ( @_ ) { $self->[0]->{SEPARATOR} = shift; }
    return $self->[0]->{SEPARATOR};
}

sub ignore_not_found {
    my $self = shift;
    if ( @_ ) { $self->[0]->{IGNORE_NOT_FOUND} = shift; }
    return $self->[0]->{IGNORE_NOT_FOUND};
}

sub last_results {
    my $self = shift;
    if ( @_ ) { $self->[0]->{LAST_RESULTS} = shift; }
    return $self->[0]->{LAST_RESULTS};
}

sub error {
    my $self = shift;
    if ( @_ ) { $self->[0]->{ERROR} = shift; }
    return $self->[0]->{ERROR};
}

sub _set_error {
    my ( $self, $error ) = @_;
    $self->error( $error );
    return;
}

sub _process {
    my $tag = $_->tag;
    return _all_text($_) unless $tag =~ /input|img/;

    return $_->attr('alt')//''
        if $tag eq 'img' or
        ($tag eq 'input' and ($_->attr('type')//'') eq 'image');

    return $_->attr('value')//'';
}

sub _extract {
    my ( $self, $dom, $selector, $what ) = @_;
    return $dom->find( $what->{ $selector } )
        ->map( sub { $self->_process( @_ ) } )->each;
}

# The _all_text & _text functions copied from Mojo::DOM 6.66.
sub _all_text {
    my ( $dom ) = @_;
    my $trim = 1;

    # Detect "pre" tag
    my $tree = $dom->tree;
    map { $_->[1] eq 'pre' and $trim = 0 } Mojo::DOM::_ancestors( $dom ), $tree
        if $trim && $tree->[0] ne 'root';

    return _text( [Mojo::DOM::_nodes($tree)], $trim );
}

sub _text {
    my ( $nodes, $trim ) = @_;

    # Merge successive text nodes.
    my $i = 0;
    while ( my $next = $nodes->[$i + 1] ) {
       ++$i and next unless $nodes->[$i][0] eq 'text' && $next->[0] eq 'text';
       splice @$nodes, $i, 2, ['text', $nodes->[$i][1] . $next->[1]];
    }

    my $text = '';
    for my $node ( @$nodes ) {
        my $type = $node->[0];
        my $chunk = '';

        # Text.
        if ( $type eq 'text' ) {
            $chunk = $node->[1];
            if ( $trim ) {
                $chunk =~ s/^\s+//;
                $chunk =~ s/\s+$//;
                $chunk =~ s/\s+/ /g;
            }
        }
        # CDATA or raw text.
        elsif ( $type eq 'cdata' || $type eq 'raw' ) {
            $chunk = $node->[1];
        }
        # Nested tag.
        elsif ( $type eq 'tag' ) {
           no warnings 'recursion';
           $chunk = _text( [Mojo::DOM::_nodes($node)], 1, $node->[1] eq 'pre' ? 0 : $trim );
        }

        # Add leading whitespace if punctuation allows it.
        $chunk = " $chunk" if $text =~ /\S\z/ && $chunk =~ /^[^.!?,;:\s]+/;

        # Trim whitespace blocks.
        $text .= $chunk if $chunk =~ /\S+/ || !$trim;
    }

    return $text;
}


q|
Programming is 10% science, 20% ingenuity,
and 70% getting the ingenuity to work with the science.
|;

__END__

=encoding utf8

=for stopwords Znet Zoffix errored  html

=head1 NAME

HTML::ExtractText - extract multiple text strings from HTML content, using CSS selectors

=head1 SYNOPSIS

=for test_synopsis no strict qw/vars/; no warnings;

At its simplest; use CSS selectors:

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

    use HTML::ExtractText;
    my $ext = HTML::ExtractText->new;
    $ext->extract({ page_title => 'title' }, $html) or die "Error: $ext";
    print "Page title is $ext->{page_title}\n";

=for html  </div></div>

We can go fancy pants with selectors as well as
extract more than one bit of text:

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

    use HTML::ExtractText;
    my $ext = HTML::ExtractText->new;
    $ext->extract(
        {
            article   => 'article#main_content',
            irc_links => 'article#main_content a[href^="irc://"]',
        },
        $html,
    ) or die "Error: $ext";

    print "IRC links:\n$ext->{irc_links}\n";
    print "Full text:\n$ext->{article}\n";

=for html  </div></div>

We can also pass in an object and let the extractor call
setter methods on it when it extracts text:

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-code.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

    use HTML::ExtractText;
    my $ext = HTML::ExtractText->new;
    $ext->extract({ title => 'title' }, $html_code, $some_object )
        or die "Error: $ext";

    print "Our object's ->title method is now set to:",
        $some_object->title, "\n";

=for html  </div></div>

=head1 DESCRIPTION

The module allows to extract [multiple] text strings from HTML documents,
using CSS selectors to declare what text needs extracting. The module
can either return the results as a hashref or automatically call
setter methods on a provided object.

If you're looking for extra automatic post-processing and laxer
definition of what constitutes "text", see L<HTML::ExtractText::Extra>.

=head1 OVERLOADED METHODS

    $extractor->extract(
        { stuff => 'title', },
        '<title>My html code!</title>',
        bless {}, 'Foo',
    ) or die "Extraction error: $extractor";

    print "Title is: $extractor->{stuff}\n\n";

The module incorporates two overloaded methods C<< ->error() >>, which
is overloaded for interpolation (C<< use overload q|""| ... >>),
and C<< ->last_result() >>,
which is overloaded for hash dereferencing
(C<< use overload q|%{}| ... >>).

What this means is that you can interpolate the object in a string
to retrieve the error message and you can use the object as a hashref
to access the hashref returned by C<< ->last_results() >>.

=head1 METHODS

=head2 C<< ->new() >>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-key-value.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-object.png">

    my $extractor = HTML::ExtractText->new;

    my $extractor = HTML::ExtractText->new(
        separator        => "\n",
        ignore_not_found => 1,
    ); # default values for arguments are shown

Creates and returns new C<HTML::ExtractText> object. Takes optional
arguments as key/value pairs:

=head3 C<separator>

    my $extractor = HTML::ExtractText->new(
        separator => "\n", # default value
    );

    my $extractor = HTML::ExtractText->new(
        separator => undef,
    );

B<Optional>. B<Default:> C<\n> (new line).
Takes C<undef> or a string as a value.
Specifies what to do when CSS selector matches multiple
elements. If set to a string value, text from all the matching
elements will be joined using that string. If set to C<undef>,
no joining will happen and results will be returned as arrayrefs
instead of strings (even if selector matches a single element).

=head3 C<ignore_not_found>

    my $extractor = HTML::ExtractText->new(
        ignore_not_found => 1,  # default value
    );

    my $extractor = HTML::ExtractText->new(
        ignore_not_found => 0,
    );

B<Optional>. B<Default:> C<1> (true). Takes true or false values
as a value. Specifies whether to consider it an error when any
of the given selectors match nothing. If set to a true value,
any non-matching selectors will have empty strings as values and no
errors will be reported. If set to a false value, all selectors must
match at least one element or the module will error out.

=head2 C<< ->extract() >>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">

    my $results = $extractor->extract(
        { stuff => 'title', },
        '<title>My html code!</title>',
        $some_object, # optional
    ) or die "Extraction error: $extractor";

    print "Title is: $extractor->{stuff}\n\n";
    # $extractor->{stuff} is the same as $results->{stuff}

Takes B<two mandatory> and B<one optional> arguments. Extracts text from
given HTML code and returns a hashref with results (
    see C<< ->last_results() >> method
). On error, returns
C<undef> or empty list and the error will be available via
C<< ->error() >> method. Even if errors occurred, anything that
was successfully extracted will still be available through
C<< ->last_results() >> method.

=head3 first argument

    $extractor->extract(
        { stuff => 'title', },
        ... ,
        ... ,
    ) or die "Extraction error: $extractor";

Must be a hashref. The keys can be whatever you want; you will use them
to refer to the extracted text. The values must be CSS selectors that
match the elements you want to extract text from.
All the selectors listed on
L<https://metacpan.org/pod/Mojo::DOM::CSS#SELECTORS> are supported.

Note: the values will be modified in place in the original
hashref you provided, so you can use that
to your advantage, if needed.

=head3 second argument

    $extractor->extract(
        ... ,
        '<title>My html code!</title>',
        ... ,
    ) or die "Extraction error: $extractor";

Takes a string that is HTML code you're trying to extract text from.

=head3 third argument

    $extractor->extract(
        { stuff => 'title', },
        '<title>My html code!</title>',
        $some_object,
    ) or die "Extraction error: $extractor";

    # this is what is being done automatically, during extraction,
    # for each key in the first argument of ->extract():
    # $some_object->stuff( $extractor->{stuff} );

B<Optional>. No defaults. For convenience, you can supply an object and
C<HTML::ExtractText> will call methods on it. The called methods
will be the keys of the first argument given to C<< ->extract() >> and
the extracted text will be given to those methods as the first argument.

=for html <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>

=head1 ACCESSORS

=head2 C<< ->error() >>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">

    $extractor->extract(
        { stuff => 'title', },
        '<title>My html code!</title>',
    ) or die "Extraction error: " . $extractor->error;

    $extractor->extract(
        { stuff => 'title', },
        '<title>My html code!</title>',
    ) or die "Extraction error: $extractor";

Takes no arguments. Returns the error message as a string, if any occurred
during the last call to C<< ->extract() >>. Note that
C<< ->error() >> will only return one of the error messages, even
if more than one selector failed. Examine the hashref returned
by C<< ->last_results() >> to find all the errors;
for any selector that errored out, the value will begin with
C<< "ERROR: " >> and the error message will be there.

=head2 C<< ->last_results() >>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">

    $extractor->extract(
        { stuff => 'title', },
        '<title>My html code!</title>',
    ) or die "Extraction error: $extractor";

    print "Stuff is " . $extractor->last_results->{stuff} . "\n";

    # or

    print "Stuff is $extractor->{stuff}\n";

Takes no arguments. Returns the same hashref
the last call to C<< ->extract >> did. If C<< ->extract >>
failed, you can still use C<< ->last_results() >> to get
anything that didn't error out (the error messages will be in the values
of failed keys).

The hashref will contain the same keys as the first argument
to C<< ->extract() >> had and the values will be replaced with
whatever the selectors matched.

If C<< separator >> (see C<< ->new() >>) is set to C<undef>, the values
will be arrayrefs, with each item in those arrayrefs corresponding
to one matched element in HTML.

The module will attempt to DWIM (Do What I Mean) when selector matches
form controls or images, and use C<value=""> or C<alt=""> attributes
as text sources.

=head2 C<< ->separator() >>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">

    $extractor->separator("\n");
    $extractor->separator(undef);

Accessor to C<separator> option (see C<< ->new() >>).
Takes one optional argument, which if provided, will become the
new separator.

=head2 C<< ->ignore_not_found() >>

=for html  <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/in-scalar-optional.png"> <img alt="" src="http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/out-scalar.png">

    $extractor->ignore_not_found(1);
    $extractor->ignore_not_found(0);

Accessor to C<ignore_not_found> option (see C<< ->new() >>).
Takes one optional argument, which if provided, will become the
new value of C<ignore_not_found> option.

=head1 SUBCLASSING

    sub _extract {
        my ( $self, $dom, $selector, $what ) = @_;
        return $dom->find( $what->{ $selector } )
            ->map( sub { $self->_process( @_ ) } )->each;
    }

You can subclass this module by overriding either or both
C<_extract> and C<_process> methods. Their names and purpose
are guaranteed to remain unchanged. See source code for their default
implementation.

=head1 NOTES AND CAVEATS

=head2 Encoding

This module does not automatically encode extracted text, so the
examples in this documentation should really include something akin to:

    use Encode;

    my $title = encode 'utf8', $ext->{page_title};
    print "$title\n";

=head1 SEE ALSO

L<HTML::ExtractText::Extra> - a subclass that offers extra features

L<Mojo::DOM>, L<Text::Balanced>, L<HTML::Extract>

=for html <div style="background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/hr.png);height: 18px;"></div>

=head1 REPOSITORY

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-github.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

Fork this module on GitHub:
L<https://github.com/zoffixznet/HTML-ExtractText>

=for html  </div></div>

=head1 BUGS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-bugs.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

To report bugs or request features, please use
L<https://github.com/zoffixznet/HTML-ExtractText/issues>

If you can't access GitHub, you can email your request
to C<bug-html-extracttext at rt.cpan.org>

=for html  </div></div>

=head1 AUTHOR

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-author.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=for html   <span style="display: inline-block; text-align: center;"> <a href="http://metacpan.org/author/ZOFFIX"> <img src="http://www.gravatar.com/avatar/328e658ab6b08dfb5c106266a4a5d065?d=http%3A%2F%2Fwww.gravatar.com%2Favatar%2F627d83ef9879f31bdabf448e666a32d5" alt="ZOFFIX" style="display: block; margin: 0 3px 5px 0!important; border: 1px solid #666; border-radius: 3px; "> <span style="color: #333; font-weight: bold;">ZOFFIX</span> </a> </span>

=for text Zoffix Znet <zoffix at cpan.org>

=for html  </div></div>

=head1 CONTRIBUTORS

=for html  <div style="display: table; height: 91px; background: url(http://zoffix.com/CPAN/Dist-Zilla-Plugin-Pod-Spiffy/icons/section-contributors.png) no-repeat left; padding-left: 120px;" ><div style="display: table-cell; vertical-align: middle;">

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut
