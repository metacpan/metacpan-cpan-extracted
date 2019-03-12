use strict;
use 5.006;

package HTML::Restrict;

use version;
our $VERSION = 'v3.0.0';

use Carp qw( croak );
use Data::Dump qw( dump );
use HTML::Parser ();
use HTML::Entities qw( encode_entities );
use Types::Standard 1.000001 qw[ Bool HashRef ArrayRef CodeRef ];
use List::Util 1.33 qw( any none );
use Scalar::Util qw( reftype weaken );
use Sub::Quote 'quote_sub';
use URI ();

use Moo 1.002000;
use namespace::clean;

has allow_comments => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

has allow_declaration => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

has debug => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

has parser => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_parser',
);

has rules => (
    is       => 'rw',
    isa      => HashRef,
    required => 0,
    default  => quote_sub(q{ {} }),
    trigger  => \&_build_parser,
    reader   => 'get_rules',
    writer   => 'set_rules',
);

has strip_enclosed_content => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [ 'script', 'style' ] },
);

has replace_img => (
    is      => 'rw',
    isa     => Bool | CodeRef,
    default => 0,
);

has trim => (
    is      => 'rw',
    isa     => Bool,
    default => 1,
);

has uri_schemes => (
    is       => 'rw',
    isa      => ArrayRef,
    required => 0,
    default  => sub { [ undef, 'http', 'https' ] },
    reader   => 'get_uri_schemes',
    writer   => 'set_uri_schemes',
);

has _processed => (
    is  => 'rw',
    isa => quote_sub(
        q{
        die "$_[0] is not false or a string!"
            unless !defined($_[0]) || $_[0] eq "" || "$_[0]" eq '0' || ref(\$_[0]) eq 'SCALAR'
    }
    ),
    clearer => '_clear_processed',
);

has _stripper_stack => (
    is      => 'rw',
    isa     => ArrayRef,
    default => sub { [] },
);

sub _build_parser {
    my $self  = shift;
    my $rules = shift;

    # don't allow any upper case tag or attribute names
    # these rules would otherwise silently be ignored
    if ($rules) {
        foreach my $tag_name ( keys %{$rules} ) {
            if ( lc $tag_name ne $tag_name ) {
                croak "All tag names must be lower cased";
            }
            if ( reftype $rules->{$tag_name} eq 'ARRAY' ) {
                my @attr_names;
                foreach my $attr_item ( @{ $rules->{$tag_name} } ) {
                    ref $attr_item eq 'HASH'
                        ? push( @attr_names, keys(%$attr_item) )
                        : push( @attr_names, $attr_item );
                }
                for (@attr_names) {
                    croak "All attribute names must be lower cased"
                        if lc $_ ne $_;
                }
            }
        }
    }

    weaken($self);
    return HTML::Parser->new(
        empty_element_tags => 1,

        start_h => [
            sub {
                my ( $p, $tagname, $attr, $text ) = @_;
                print "starting tag:  $tagname", "\n" if $self->debug;
                my $more = q{};

                if ( any { $_ eq $tagname } keys %{ $self->get_rules } ) {
                    print dump $attr if $self->debug;

                    foreach my $source_type ( 'href', 'src', 'cite' ) {

                        my $link = $attr->{$source_type};

                        # Remove unprintable ASCII control characters, which
                        # are 0..31. These characters are not valid in URLs,
                        # but they can prevent the URI parser from recognizing
                        # the scheme when they are used as leading characters.
                        # Browsers will helpfully ignore some of them, meaning
                        # that some of these characters (particularly 1..8 and
                        # 14..31) can be used to defeat HTML::Restrict when
                        # used as leading characters in a link.  In our case we
                        # will strip them all regardless of where they are in
                        # the URL. See
                        # https://github.com/oalders/html-restrict/issues/30
                        # https://url.spec.whatwg.org/
                        # https://infra.spec.whatwg.org/#c0-control

                        if ($link) {

                            # C0 control chars (decimal 0..31)
                            # sort of like $link =~ s/[[:^print:]]//g
                            $link =~ s/[\00-\037]|&#x?0+;/ /g;

                            my $url = URI->new($link);
                            if ( defined $url->scheme ) {
                                delete $attr->{$source_type}
                                    if none { $_ eq $url->scheme }
                                grep { defined } @{ $self->get_uri_schemes };
                            }
                            else {    # relative URL
                                delete $attr->{$source_type}
                                    unless grep { !defined }
                                    @{ $self->get_uri_schemes };
                            }
                        }
                    }

                    foreach
                        my $attr_item ( @{ $self->get_rules->{$tagname} } ) {
                        if ( ref $attr_item eq 'HASH' ) {

                            # validate or munge with regex or coderef contraints
                            #
                            for my $attr_name (
                                sort grep exists $attr->{$_},
                                keys %$attr_item
                            ) {
                                my $rule  = $attr_item->{$attr_name};
                                my $value = $attr->{$attr_name};
                                if ( ref $rule eq 'CODE' ) {
                                    $value = $rule->($value);
                                    next
                                        if !defined $value;
                                }
                                elsif ( $value =~ $rule ) {

                                    # ok
                                }
                                else {
                                    next;
                                }
                                $more .= qq[ $attr_name="]
                                    . encode_entities($value) . q["];
                            }
                        }
                        else {
                            my $attr_name = $attr_item;
                            if ( exists $attr->{$attr_name} ) {
                                my $value
                                    = encode_entities( $attr->{$attr_name} );
                                $more .= qq[ $attr_name="$value" ]
                                    unless $attr_name eq q{/};
                            }
                        }
                    }

                    # closing slash should (naturally) close the tag
                    if ( exists $attr->{q{/}} && $attr->{q{/}} eq q{/} ) {
                        $more .= ' /';
                    }

                    my $elem = "<$tagname $more>";
                    $elem =~ s{\s*>}{>}gxms;
                    $elem =~ s{\s+}{ }gxms;

                    $self->_processed( ( $self->_processed || q{} ) . $elem );
                }
                elsif ( $tagname eq 'img' && $self->replace_img ) {
                    my $alt;
                    if ( ref $self->replace_img ) {
                        $alt = $self->replace_img->( $tagname, $attr, $text );
                    }
                    else {
                        $alt
                            = defined( $attr->{alt} ) ? ": $attr->{alt}" : "";
                        $alt = "[IMAGE$alt]";
                    }
                    $self->_processed( ( $self->_processed || q{} ) . $alt );
                }
                elsif (
                    any { $_ eq $tagname }
                    @{ $self->strip_enclosed_content }
                ) {
                    print "adding $tagname to strippers" if $self->debug;
                    push @{ $self->_stripper_stack }, $tagname;
                }

            },
            "self,tagname,attr,text"
        ],

        end_h => [
            sub {
                my ( $p, $tagname, $attr, $text ) = @_;
                print "end: $text\n" if $self->debug;
                if ( any { $_ eq $tagname } keys %{ $self->get_rules } ) {
                    $self->_processed( ( $self->_processed || q{} ) . $text );
                }
                elsif ( any { $_ eq $tagname } @{ $self->_stripper_stack } ) {
                    $self->_delete_tag_from_stack($tagname);
                }

            },
            "self,tagname,attr,text"
        ],

        text_h => [
            sub {
                my ( $p, $text ) = @_;
                print "text: $text\n" if $self->debug;
                $text = _fix_text_encoding($text);
                if ( !@{ $self->_stripper_stack } ) {
                    $self->_processed( ( $self->_processed || q{} ) . $text );
                }
            },
            "self,text"
        ],

        comment_h => [
            sub {
                my ( $p, $text ) = @_;
                print "comment: $text\n" if $self->debug;
                if ( $self->allow_comments ) {
                    $self->_processed( ( $self->_processed || q{} ) . $text );
                }
            },
            "self,text"
        ],

        declaration_h => [
            sub {
                my ( $p, $text ) = @_;
                print "declaration: $text\n" if $self->debug;
                if ( $self->allow_declaration ) {
                    $self->_processed( ( $self->_processed || q{} ) . $text );
                }
            },
            "self,text"
        ],

    );
}

sub process {
    my $self = shift;

    # returns undef if no value was passed
    return if !@_;
    return $_[0] if !$_[0];

    my ($content) = @_;
    die 'content must be a string!'
        unless ref( \$content ) eq 'SCALAR';
    $self->_clear_processed;

    my $parser = $self->parser;
    $parser->parse($content);
    $parser->eof;

    my $text = $self->_processed;

    if ( $self->trim && $text ) {
        $text =~ s{\A\s*}{}gxms;
        $text =~ s{\s*\z}{}gxms;
    }
    $self->_processed($text);

    # ensure stripper stack is reset in case of broken html
    $self->_stripper_stack( [] );

    return $self->_processed;
}

# strip_enclosed_content tags could be nested in the source HTML, so we
# maintain a stack of these tags.

sub _delete_tag_from_stack {
    my $self        = shift;
    my $closing_tag = shift;

    my $found    = 0;
    my @tag_list = ();

    foreach my $tag ( reverse @{ $self->_stripper_stack } ) {
        if ( $tag eq $closing_tag && $found == 0 ) {
            $found = 1;
            next;
        }
        push @tag_list, $tag;
    }

    $self->_stripper_stack( [ reverse @tag_list ] );

    return;
}

# regex for entities that don't require a terminating semicolon
my ($short_entity_re)
    = map qr/$_/i,
    join '|',
    '#x[0-9a-f]+',
    '#[0-9]+',
    grep !/;\z/,
    sort keys %HTML::Entities::entity2char;

# semicolon required
my ($complete_entity_re)
    = map qr/$_/i,
    join '|',
    grep /;\z/,
    sort keys %HTML::Entities::entity2char;

sub _fix_text_encoding {
    my $text = shift;
    $text =~ s{
        &
        (?:
          ($short_entity_re);?
        |
          ($complete_entity_re)
        )?
    }{
          defined $1  ? "&$1;"
        : defined $2  ? "&$2"
                      : "&amp;"
    }xgie;
    return encode_entities( $text, '<>' );
}

1;    # End of HTML::Restrict

# ABSTRACT: Strip unwanted HTML tags and attributes

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Restrict - Strip unwanted HTML tags and attributes

=head1 VERSION

version v3.0.0

=head1 SYNOPSIS

    use HTML::Restrict;

    my $hr = HTML::Restrict->new();

    # use default rules to start with (strip away all HTML)
    my $processed = $hr->process('  <b>i am bold</b>  ');

    # $processed now equals: 'i am bold'

    # Now, a less restrictive example:
    $hr = HTML::Restrict->new(
        rules => {
            b   => [],
            img => [qw( src alt / )]
        }
    );

    my $html = q[<body><b>hello</b> <img src="pic.jpg" alt="me" id="test" /></body>];
    $processed = $hr->process( $html );

    # $processed now equals: <b>hello</b> <img src="pic.jpg" alt="me" />

=head1 DESCRIPTION

This module uses L<HTML::Parser> to strip HTML from text in a restrictive
manner.  By default all HTML is restricted.  You may alter the default
behaviour by supplying your own tag rules.

=head1 CONSTRUCTOR AND STARTUP

=head2 new()

Creates and returns a new HTML::Restrict object.

    my $hr = HTML::Restrict->new()

HTML::Restrict doesn't require any params to be passed to new.  If your goal is
to remove all HTML from text, then no further setup is required.  Just pass
your text to the process() method and you're done:

    my $plain_text = $hr->process( $html );

If you need to set up specific rules, have a look at the params which
HTML::Restrict recognizes:

=over 4

=item * C<< rules => \%rules >>

Sets the rules which will be used to process your data.  By default all HTML
tags are off limits.  Use this argument to define the HTML elements and
corresponding attributes you'd like to use.  Essentially, consider the default
behaviour to be:

    rules => {}

Rules should be passed as a HASHREF of allowed tags.  Each hash value should
represent the allowed attributes for the listed tag.  For example, if you want
to allow a fair amount of HTML, you can try something like this:

    my %rules = (
        a       => [qw( href target )],
        b       => [],
        caption => [],
        center  => [],
        em      => [],
        i       => [],
        img     => [qw( alt border height width src style )],
        li      => [],
        ol      => [],
        p       => [qw(style)],
        span    => [qw(style)],
        strong  => [],
        sub     => [],
        sup     => [],
        table   => [qw( style border cellspacing cellpadding align )],
        tbody   => [],
        td      => [],
        tr      => [],
        u       => [],
        ul      => [],
    );

    my $hr = HTML::Restrict->new( rules => \%rules )

Or, to allow only bolded text:

    my $hr = HTML::Restrict->new( rules => { b => [] } );

Allow bolded text, images and some (but not all) image attributes:

    my %rules = (
        b   => [ ],
        img => [qw( src alt width height border / )
    );
    my $hr = HTML::Restrict->new( rules => \%rules );

Since L<HTML::Parser> treats a closing slash as an attribute, you'll need to
add "/" to your list of allowed attributes if you'd like your tags to retain
closing slashes.  For example:

    my $hr = HTML::Restrict->new( rules =>{ hr => [] } );
    $hr->process( "<hr />"); # returns: <hr>

    my $hr = HTML::Restrict->new( rules =>{ hr => [qw( / )] } );
    $hr->process( "<hr />"); # returns: <hr />

HTML::Restrict strips away any tags and attributes which are not explicitly
allowed. It also rebuilds your explicitly allowed tags and places their
attributes in the order in which they appear in your rules.

So, if you define the following rules:

    my %rules = (
        ...
        img => [qw( src alt title width height id / )]
        ...
    );

then your image tags will all be built like this:

    <img src=".." alt="..." title="..." width="..." height="..." id=".." />

This gives you greater consistency in your tag layout.  If you don't care about
element order you don't need to pay any attention to this, but you should be
aware that your elements are being reconstructed rather than just stripped
down.

As of 2.1.0, you can also specify a regex to be tested against the attribute
value. This feature should be considered experimental for the time being:

    my $hr = HTML::Restrict->new(
        rules => {
            iframe => [
                qw( width height allowfullscreen ),
                {   src         => qr{^http://www\.youtube\.com},
                    frameborder => qr{^(0|1)$},
                }
            ],
            img => [ qw( alt ), { src => qr{^/my/images/} }, ],
        },
    );

    my $html = '<img src="http://www.example.com/image.jpg" alt="Alt Text">';
    my $processed = $hr->process( $html );

    # $processed now equals: <img alt="Alt Text">

As of 2.3.0, the value to be tested against can also be a code reference.  The
code reference will be passed the value of the attribute, and should return
either a string to use for the attribute value, or undef to remove the attribute.

    my $hr = HTML::Restrict->new(
        rules => {
            span => [
                { style     => sub {
                    my $value = shift;
                    # all colors are orange
                    $value =~ s/\bcolor\s*:\s*[^;]+/color: orange/g;
                    return $value;
                } }
            ],
        },
    );

    my $html = '<span style="color: #0000ff;">This is blue</span>';
    my $processed = $hr->process( $html );

    # $processed now equals: <span style="color: orange;">

=item * C<< trim => [0|1] >>

By default all leading and trailing spaces will be removed when text is
processed.  Set this value to 0 in order to disable this behaviour.

=item * C<< uri_schemes => [undef, 'http', 'https', 'irc', ... ] >>

As of version 1.0.3, URI scheme checking is performed on all href and src tag
attributes. The following schemes are allowed out of the box.  No action is
required on your part:

    [ undef, 'http', 'https' ]

(undef represents relative URIs). These restrictions have been put in place to
prevent XSS in the form of:

    <a href="javascript:alert(document.cookie)">click for cookie!</a>

See L<URI> for more detailed info on scheme parsing.  If, for example, you
wanted to filter out every scheme barring SSL, you would do it like this:

    uri_schemes => ['https']

This feature is new in 1.0.3.  Previous to this, there was no schema checking
at all.  Moving forward, you'll need to whitelist explicitly all URI schemas
which are not supported by default.  This is in keeping with the whitelisting
behaviour of this module and is also the safest possible approach.  Keep in
mind that changes to uri_schemes are not additive, so you'll need to include
the defaults in any changes you make, should you wish to keep them:

    # defaults + irc + mailto
    uri_schemes => [ 'undef', 'http', 'https', 'irc', 'mailto' ]

=item * allow_declaration => [0|1]

Set this value to true if you'd like to allow/preserve DOCTYPE declarations in
your content.  Useful when cleaning up your own static files or templates. This
feature is off by default.

    my $html = q[<!doctype html><body>foo</body>];

    my $hr = HTML::Restrict->new( allow_declaration => 1 );
    $html = $hr->process( $html );
    # $html is now: "<!doctype html>foo"

=item * allow_comments => [0|1]

Set this value to true if you'd like to allow/preserve HTML comments in your
content.  Useful when cleaning up your own static files or templates. This
feature is off by default.

    my $html = q[<body><!-- comments! -->foo</body>];

    my $hr = HTML::Restrict->new( allow_comments => 1 );
    $html = $hr->process( $html );
    # $html is now: "<!-- comments! -->foo"

=item * replace_img => [0|1|CodeRef]

Set the value to true if you'd like to have img tags replaced with
C<[IMAGE: ...]> containing the alt attribute text.  If you set it to a
code reference, you can provide your own replacement (which may
even contain HTML).

    sub replacer {
        my ($tagname, $attr, $text) = @_; # from HTML::Parser
        return qq{<a href="$attr->{src}">IMAGE: $attr->{alt}</a>};
    }

    my $hr = HTML::Restrict->new( replace_img => \&replacer );

This attribute will only take effect if the img tag is not included
in the allowed HTML.

=item * strip_enclosed_content => [0|1]

The default behaviour up to 1.0.4 was to preserve the content between script
and style tags, even when the tags themselves were being deleted.  So, you'd be
left with a bunch of JavaScript or CSS, just with the enclosing tags missing.
This is almost never what you want, so starting at 1.0.5 the default will be to
remove any script or style info which is enclosed in these tags, unless they
have specifically been whitelisted in the rules.  This will be a sane default
when cleaning up content submitted via a web form.  However, if you're using
HTML::Restrict to purge your own HTML you can be more restrictive.

    # strip the head section, in addition to JS and CSS
    my $html = '<html><head>...</head><body>...<script>JS here</script>foo';

    my $hr = HTML::Restrict->new(
        strip_enclosed_content => [ 'script', 'style', 'head' ]
    );

    $html = $hr->process( $html );
    # $html is now '<html><body>...foo';

The caveat here is that HTML::Restrict will not try to fix broken HTML. In the
above example, if you have any opening script, style or head tags which don't
also include matching closing tags, all following content will be stripped
away, regardless of any parent tags.

Keep in mind that changes to strip_enclosed_content are not additive, so if you
are adding additional tags you'll need to include the entire list of tags whose
enclosed content you'd like to remove.  This feature strips script and style
tags by default.

=back

=head1 SUBROUTINES/METHODS

=head2 process( $html )

This is the method which does the real work.  It parses your data, removes any
tags and attributes which are not specifically allowed and returns the
resulting text.  Requires and returns a SCALAR.

=head2 get_rules

Accessor which returns a hash ref of the current rule set.

=head2 get_uri_schemes

Accessor which returns an array ref of the current valid uri schemes.

=head1 CAVEATS

Please note that all tag and attribute names passed via the rules param must be
supplied in lower case.

    # correct
    my $hr = HTML::Restrict->new( rules => { body => ['onload'] } );

    # throws a fatal error
    my $hr = HTML::Restrict->new( rules => { Body => ['onLoad'] } );

=head1 MOTIVATION

There are already several modules on the CPAN which accomplish much of the same
thing, but after doing a lot of poking around, I was unable to find a solution
with a simple setup which I was happy with.

The most common use case might be stripping HTML from user submitted data
completely or allowing just a few tags and attributes to be displayed.  With
the exception of URI scheme checking, this module doesn't do any validation on
the actual content of the tags or attributes.  If this is a requirement, you
can either mess with the parser object, post-process the text yourself or have
a look at one of the more feature-rich modules in the SEE ALSO section below.

My aim here is to keep things easy and, hopefully, cover a lot of the less
complex use cases with just a few lines of code and some brief documentation.
The idea is to be up and running quickly.

=head1 SEE ALSO

L<HTML::TagFilter>, L<HTML::Defang>, L<MojoMojo::Declaw>, L<HTML::StripScripts>,
L<HTML::Detoxifier>, HTML::Sanitizer, L<HTML::Scrubber>

=head1 ACKNOWLEDGEMENTS

Thanks to Raybec Communications L<http://www.raybec.com> for funding my
work on this module and for releasing it to the world.

Thanks also to the following for patches, bug reports and assistance:

Mark Jubenville (ioncache)

Duncan Forsyth

Rick Moore

Arthur Axel 'fREW' Schmidt

perlpong

David Golden

Graham TerMarsch

Dagfinn Ilmari Mannsåker

Graham Knop

Carwyn Ellis

=head1 AUTHOR

Olaf Alders <olaf@wundercounter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013-2017 by Olaf Alders.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
