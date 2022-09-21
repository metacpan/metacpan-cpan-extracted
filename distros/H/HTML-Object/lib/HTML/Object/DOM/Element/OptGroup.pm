##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/OptGroup.pm
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
package HTML::Object::DOM::Element::OptGroup;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :optgroup );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'optgroup' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property disabled inherited

# Note: property label
sub label : lvalue { return( shift->_set_get_property( 'label', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::OptGroup - HTML Object DOM OptGroup Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::OptGroup;
    my $group = HTML::Object::DOM::Element::OptGroup->new || 
        die( HTML::Object::DOM::Element::OptGroup->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

This interface provides special properties and methods (beyond the regular L<HTML::Object::Element> object interface they also have available to them by inheritance) for manipulating the layout and presentation of C<<optgroup>> elements.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +--------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::OptGroup |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +--------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 disabled

Is a boolean value representing whether or not the whole list of children C<<option>> is disabled (true) or not (false).

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOptGroupElement/disabled>

=head2 label

Is a string representing the label for the group.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOptGroupElement/label>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLOptGroupElement>, L<Mozilla documentation on optgroup element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/optgroup>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
