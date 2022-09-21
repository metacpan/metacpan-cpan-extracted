##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Script.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/23
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Script;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :script );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'script' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property async
sub async : lvalue { return( shift->_set_get_property({ attribute => 'async', is_boolean => 1 }, @_ ) ); }

# Note: property charset
sub charset : lvalue { return( shift->_set_get_property( 'charset', @_ ) ); }

# Note: property crossOrigin inherited

# Note: property defer
sub defer : lvalue { return( shift->_set_get_property({ attribute => 'defer', is_boolean => 1 }, @_ ) ); }

# Note: property event
sub event : lvalue { return( shift->_set_get_property( 'event', @_ ) ); }

# Note: property noModule
sub noModule : lvalue { return( shift->_set_get_property({ attribute => 'nomodule', is_boolean => 1 }, @_ ) ); }

# Note: property referrerPolicy inherited

# Note: property src inherited

# Note: property text
sub text : lvalue { return( shift->textContent( @_ ) ); }

# Note: property type inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Script - HTML Object DOM Script Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Script;
    my $script = HTML::Object::DOM::Element::Script->new || 
        die( HTML::Object::DOM::Element::Script->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This implements the interface for C<<script>> elements, which provides special properties and methods for manipulating the behavior and execution of C<<script>> elements (beyond the inherited L<HTML::Object::Element> interface).

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Script |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 async

The async and defer attributes are boolean attributes that control how the script should be executed. The C<defer> and C<async> attributes must not be specified if the src attribute is absent.

There are three possible execution modes:

=over 4

=item 1. If the async attribute is present, then the script will be executed asynchronously as soon as it downloads.

=item 2. If the async attribute is absent but the defer attribute is present, then the script is executed when the page has finished parsing.

=item 3. If neither attribute is present, then the script is fetched and executed immediately, blocking further parsing of the page.

=back

The C<defer> attribute may be specified with the C<async> attribute, so legacy browsers that only support defer (and not async) fall back to the defer behavior instead of the default blocking behavior.

Note: The exact processing details for these attributes are complex, involving many different aspects of HTML, and therefore are scattered throughout the specification. These algorithms describe the core ideas, but they rely on the parsing rules for C<<script>> start and end tags in HTML, in foreign content, and in XML; the rules for the C<document.write()> method; the handling of scripting; and so on.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLScriptElement/async>

=head2 charset

Is a string representing the character encoding of an external script. It reflects the charset attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLScriptElement/charset>

=head2 crossOrigin

Is a string reflecting the CORS setting for the script element. For scripts from other origins, this controls if error information will be exposed.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLScriptElement/crossOrigin>

=head2 defer

The C<defer> attribute may be specified even if the C<async> attribute is specified, to cause legacy web browsers that only support defer (and not async) to fall back to the defer behavior instead of the blocking behavior that is the default.

=head2 event

Is a string; an obsolete way of registering event handlers on elements in an HTML document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLScriptElement/event>

=head2 noModule

Is a boolean value that if true, stops the script's execution in browsers that support ES2015 modules — used to run fallback scripts in older browsers that do not support C<JavaScript> modules.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLScriptElement/noModule>

=head2 referrerPolicy

Is a string that reflects the referrerpolicy HTML attribute indicating which referrer to use when fetching the script, and fetches done by that script.

Example:

    my $scriptElem = $doc->createElement( 'script' );
    $scriptElem->src = '/';
    $scriptElem->referrerPolicy = 'unsafe-url';
    $doc->body->appendChild( $scriptElem );

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLScriptElement/referrerPolicy>

=head2 src

Is a string representing the URL of an external script. It reflects the src HTML attribute. You can get and set an L<URI> object.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLScriptElement/src>

=head2 text

Is a string that joins and returns the contents of all Text nodes inside the C<<script>> element (ignoring other nodes like comments) in tree order. On setting, it acts the same way as the L<textContent|HTML::Object::DOM::Node/textContent> IDL attribute.

Note: When inserted using the document.write() method, <script> elements execute (typically synchronously), but when inserted using innerHTML or outerHTML, they do not execute at all.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLScriptElement/text>

=head2 type

Is a string representing the MIME type of the script. It reflects the type HTML attribute.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLScriptElement/type>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLScriptElement>, L<Mozilla documentation on script element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/script>, L<W3C specifications|https://html.spec.whatwg.org/multipage/scripting.html#htmlscriptelement>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
