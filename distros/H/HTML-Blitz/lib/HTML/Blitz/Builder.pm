package HTML::Blitz::Builder;
use HTML::Blitz::pragma;
use Exporter qw(import);
use Carp qw(croak);

our $VERSION = '0.09';

our @EXPORT_OK = qw(
    mk_doctype
    mk_comment
    mk_elem
    to_html
    fuse_fragment
);

{
    package HTML::Blitz::Builder::_Fragment;

    method new($class: @parts) {
        bless {
            parts => \@parts,
        }, $class
    }

    method unwrapped() {
        @{$self->{parts}}
    }
}

fun to_html(@parts) {
    join '',
        map ref($_) eq __PACKAGE__ ? $$_ : s{(?![\n\t])([[:cntrl:]&<])}{ $1 eq '<' ? '&lt;' : $1 eq '&' ? '&amp;' : '&#' . ord($1) . ';' }egr,
        map ref($_) eq __PACKAGE__ . '::_Fragment' ? $_->unwrapped : $_,
        @parts
}

fun fuse_fragment(@parts) {
    return $parts[0]
        if @parts == 1 && (ref($parts[0]) eq __PACKAGE__ || ref($parts[0]) eq __PACKAGE__ . '::_Fragment');
    HTML::Blitz::Builder::_Fragment->new(@parts)
}

fun mk_doctype() {
    my $code = '<!DOCTYPE html>';
    bless \$code, __PACKAGE__
}

fun mk_comment($content) {
    $content =~ /\A(-?>)/
        and croak "HTML comment cannot start with '$1': '$content'";
    $content =~ /(<!--|--!?>)/
        and croak "HTML comment cannot contain '$1': '$content'";
    my $code = "<!--$content-->";
    bless \$code, __PACKAGE__
}

fun _mk_attr($name, $value) {
    $name =~ m{\A[^\s/>="'<[:cntrl:]]+\z}
        or croak "Invalid attribute name '$name'";
    my $code = " $name";
    if ($value ne '') {
        $code .= '=';
        if ($value !~ m{[\s"'=<>`]}) {
            $code .= $value =~ s{([[:cntrl:]&])}{ $1 eq '&' ? '&amp;' : '&#' . ord($1) . ';' }egr;
        } else {
            $code .= '"' . $value =~ s{(?![\n\t])([[:cntrl:]&"])}{ $1 eq '"' ? '&quot;' : $1 eq '&' ? '&amp;' : '&#' . ord($1) . ';' }egr . '"';
        }
    }
    $code
}

my %is_void = map +($_ => 1), qw(
    area
    base basefont bgsound br
    col
    embed
    frame
    hr
    img input
    keygen
    link
    meta
    param
    source
    track
    wbr
);

my %is_childless = map +($_ => 1), qw(
    title
    textarea
    script
    style
);

fun mk_elem($name, @args) {
    my $attrs = @args && ref($args[0]) eq 'HASH'
        ? shift @args
        : {};
    $name =~ m{\A[A-Za-z][^\s/>[:cntrl:]]*\z}
        or croak "Invalid tag name '$name'";
    (my $lc_name = $name) =~ tr/A-Z/a-z/;
    @args = map ref($_) eq __PACKAGE__ . '::_Fragment' ? $_->unwrapped : $_, @args;
    my $attr_str = join '', map _mk_attr($_, $attrs->{$_}), sort keys %$attrs;
    my $html = "<$name$attr_str>";
    if ($is_void{$lc_name}) {
        croak "<$name> tag cannot have contents" if @args;
    } else {
        croak "<$name> tag cannot have child elements" if $is_childless{$lc_name} && grep ref($_) eq __PACKAGE__, @args;
        my $contents;
        if ($lc_name eq 'style') {
            $contents = join '', @args;
            $contents =~ m{(</style[\s/>])}aai
                and croak "<$name> tag cannot contain '$1'";
        } elsif ($lc_name eq 'script') {
            $contents = join '', @args;
            SCRIPT_DATA: {
                $contents =~ m{ ( <!-- (?! -?> ) ) | ( </script [ \t\r\n\f/>] ) }xaaigc
                    or last SCRIPT_DATA;
                $1 or croak "<$name> tag cannot contain '$2'";
                SCRIPT_DATA_ESCAPED: {
                    $contents =~ m{ (-->) | ( < (/?) script [ \t\r\n\f/>] ) }xaaigc
                        or last SCRIPT_DATA;
                    $1 and redo SCRIPT_DATA;
                    $3 and croak "<$name> tag cannot contain '$2'";

                    $contents =~ m{ (-->) | </script [ \t\r\n\f/>] }xaaigc
                        or croak "<$name> tag cannot contain '<!-- ... <script>' without a following '-->' or '</script>'";
                    $1 and redo SCRIPT_DATA;
                    redo SCRIPT_DATA_ESCAPED;
                }
            }
        } else {
            $contents = to_html @args;
        }
        $html .= "$contents</$name>";
    }
    bless \$html, __PACKAGE__
}

1
__END__

=head1 NAME

HTML::Blitz::Builder - create HTML code dynamically and safely

=head1 SYNOPSIS

    use HTML::Blitz::Builder qw(
        mk_doctype
        mk_comment
        mk_elem
        to_html
        fuse_fragment
    );

=head1 DESCRIPTION

This module is useful for creating snippets of HTML code (or entire documents)
programmatically. It takes care of automatically escaping any strings you pass
to it, which prevents the injection of HTML and script code (XSS).

To use it, call the C<mk_elem>, C<mk_comment>, and C<mk_doctype> constructor
functions as needed to create the document structure you want. At the very end,
pass everything to C<to_html> to obtain the corresponding HTML code.

The basic data structure used by this module is the document fragment, which in
Perl is represented as a list of (zero or more) node values. A node value is
one of the following:

=over

=item *

A text node, represented by a plain string.

=item *

An element node, represented by an object returned from C<mk_elem>.

=item *

A comment node, represented by an object returned from C<mk_comment>.

=item *

A C<DOCTYPE> declaration, represented by an object returned from C<mk_doctype>.

=back

See below for the list of public functions provided by this module, which are
exportable on request.

=head1 FUNCTIONS

=head2 to_html(@nodes)

Takes a list of node values (as described above) and returns the corresponding HTML code.

The list of elements can be empty: C<to_html()> (which is the same as
C<to_html(())>) simply returns the empty string. More generally,
C<to_html> is a homomorphism from lists to strings in that it preserves
concatenation:

    to_html(@A, @B) eq (to_html(@A) . to_html(@B))

=head2 mk_elem($name, [\%attributes, ] @nodes)

Creates an element with the specified name, attributes, and child nodes.

The only required argument is the element name. The optional second argument is
a reference to a hash of attribute name/value pairs; omitting it is equivalent
to passing C<{}> (an empty hashref), meaning no attributes. All remaining
arguments are taken to be child nodes.

For example:

    to_html( mk_elem("div") )
    # => '<div></div>'

    to_html( mk_elem("div", "I <3 U") )
    # => '<div>I &lt;3 U</div>'

C<mk_elem> is aware of "void" (i.e. content-free) elements and will not
generate closing tags for them:

    to_html( mk_elem("br") )
    # => '<br>'

If you attempt to create a void element with child nodes, an exception will be
thrown:

    to_html( mk_elem("br", "Hello!") )
    # error!

The same is true for elements that cannot contain nested child elements
(C<title>, C<textarea>, C<style>, C<script>):

    to_html( mk_elem("title", "Hello!") )
    # => '<title>Hello!</title>'

    to_html( mk_elem("title", mk_elem("span", "Hello!")) )
    # error!

Because the contents of C<style> and C<script> elements do not follow the usual
HTML parsing rules, not all values can be represented:

    to_html( mk_elem("p", "</p>") )
    # => '<p>&lt;/p></p>'

    to_html( mk_elem("style", "</style>") )
    # error!

    to_html( mk_elem("script", "</script>") )
    # error!

All attributes and text nodes are properly HTML escaped:

    to_html( mk_elem("a", { href => "/q?a=1&b=2&c=3" }, "things, stuff, &c.") )
    # => '<a href="/q?a=1&amp;b=2&amp;c=3">things, stuff, &amp;c.</a>'

The result of C<to_html> is deterministic; in particular, attributes are always
generated in the same order (despite being passed in the form of a hash).

=head2 mk_comment($comment)

Creates a comment with the specified contents.

    to_html( mk_comment("a b c") )
    # => '<!--a b c-->'

Certain strings (most notably C<< --> >>) cannot appear in an HTML comment, so
the following will throw an exception:

    to_html( mk_comment("A --> B") )
    # error!

=head2 mk_doctype()

Creates a DOCTYPE declaration. It takes no arguments and always produces an
C<html> doctype:

    to_html( mk_doctype() )
    # => '<!DOCTYPE html>'

=head2 fuse_fragment(@nodes)

Sometimes you want to store a document fragment (a list of nodes) in a single
Perl value without wrapping an extra element around it. This is what
C<fuse_fragment> does: It takes a list of node values and returns a single
object representing that list.

C<fuse_fragment> is idempotent:

    fuse_fragment(fuse_fragment(@nodes))
    # is equivalent to
    fuse_fragment(@nodes)

Another way of looking at it is that as far as fragment consumers (i.e.
C<to_html>, C<mk_elem>, and C<fuse_fragment> itself) are concerned,
C<fuse_fragment> is transparent:

    to_html( fuse_fragment(@values) )
    # is the same as
    to_html( @values )

    mk_elem($name, $attrs, fuse_fragment(@values))
    # is the same as
    mk_elem($name, $attrs, @values)

=head1 EXAMPLE

    my @fragment =
        mk_elem('form', { method => 'POST', action => '/login' },
            mk_elem('label',
                'Username: ',
                mk_elem('input', { name => 'user' }),
            ),
            mk_elem('label',
                'Password: ',
                mk_elem('input', { name => 'password', type => 'password' }),
            ),
        );

    my @document = (
        mk_doctype,
        mk_elem('title', 'Log in'),
        mk_comment('hello, world'),
        @fragment,
    );

    my $html = to_html @document;
    # Equivalent to:
    # $html =
    #     '<!DOCTYPE html>'
    #     . '<title>Log in</title>'
    #     . '<!--hello, world-->'
    #     . '<form method="POST" action="/login">'
    #     .    '<label>Username: <input name="user"></label>'
    #     .    '<label>Password: <input name="password" type="password"></label>'
    #     . '</form>';

=head1 AUTHOR

Lukas Mai, C<< <lmai at web.de> >>

=head1 COPYRIGHT & LICENSE

Copyright 2022 Lukas Mai.

This module is free software: you can redistribute it and/or modify it under
the terms of the L<GNU General Public License|https://www.gnu.org/licenses/gpl-3.0.html>
as published by the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.

=head1 SEE ALSO

L<HTML::Blitz>
