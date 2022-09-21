##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/VTTRegion.pm
## Version v0.2.0
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2021/12/27
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::VTTRegion;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic );
    use vars qw( $VERSION );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    return( $self );
}

# Note: property
sub id : lvalue { return( shift->_set_get_scalar_as_object( 'id', @_ ) ); }

# Note: property
sub lines : lvalue { return( shift->_set_get_number( 'lines', @_ ) ); }

# Note: property
sub regionAnchorX : lvalue { return( shift->_set_get_number( 'regionanchorx', @_ ) ); }

# Note: property
sub regionAnchorY : lvalue { return( shift->_set_get_number( 'regionanchory', @_ ) ); }

# Note: property
sub scroll : lvalue { return( shift->_set_get_scalar_as_object( 'scroll', @_ ) ); }

# Note: property
sub viewportAnchorX : lvalue { return( shift->_set_get_number( 'viewportanchorx', @_ ) ); }

# Note: property
sub viewportAnchorY : lvalue { return( shift->_set_get_number( 'viewportanchory', @_ ) ); }

# Note: property
sub width : lvalue { return( shift->_set_get_number( 'width', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::VTTRegion - HTML Object DOM VTTRegion Class

=head1 SYNOPSIS

    use HTML::Object::DOM::VTTRegion;
    my $region = HTML::Object::DOM::VTTRegion->new || 
        die( HTML::Object::DOM::VTTRegion->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

The C<VTTRegion> interface—part of the API for handling C<WebVTT> (text tracks on media presentations)—describes a portion of the video to render a L<HTML::Object::DOM::VTTCue> onto.

=head1 PROPERTIES

=head2 id

Sets or gets a string that identifies the region, as a L<scalar object|Module::Generic::Scalar>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VTTRegion/id>

=head2 lines

Sets or gets a L<double|Module::Generic::Number> representing the height of the region, in number of lines.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VTTRegion/lines>

=head2 regionAnchorX

Sets or gets a L<double|Module::Generic::Number> representing the region anchor X offset, as a percentage of the region.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VTTRegion/regionAnchorX>

=head2 regionAnchorY

Sets or gets a L<double|Module::Generic::Number> representing the region anchor Y offset, as a percentage of the region.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VTTRegion/regionAnchorY>

=head2 scroll

Sets or gets an enum representing how adding new cues will move existing cues, as a L<scalar object|Module::Generic::Scalar>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VTTRegion/scroll>

=head2 viewportAnchorX

Sets or gets a L<double|Module::Generic::Number> representing the viewport anchor X offset, as a percentage of the video.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VTTRegion/viewportAnchorX>

=head2 viewportAnchorY

Sets or gets a L<double|Module::Generic::Number> representing the viewport anchor Y offset, as a percentage of the video.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VTTRegion/viewportAnchorY>

=head2 width

Sets or gets a L<double|Module::Generic::Number> representing the width of the region, as a percentage of the video.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VTTRegion/width>

=head1 METHODS

There are no method.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/VTTRegion>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2021 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
