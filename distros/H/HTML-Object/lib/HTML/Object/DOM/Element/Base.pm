##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Base.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/26
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Base;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :base );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'base' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property href inherited

# Note: property target inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Base - HTML Object

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Base;
    my $base = HTML::Object::DOM::Element::Base->new || 
        die( HTML::Object::DOM::Element::Base->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface contains the base URI for a document. This object inherits all of the properties and methods as described in the L<HTML::Object::Element> interface.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Base |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +----------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 href

Is a string that reflects the href HTML attribute, containing a base URL for relative URLs in the document.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLBaseElement/href>

=head2 target

Is a string that reflects the target HTML attribute, containing a default target browsing context or frame for elements that do not have a target reference specified.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLBaseElement/target>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLBaseElement>, L<Mozilla documentation on base element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/base>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
