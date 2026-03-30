##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/FencedFrame.pm
## Version v0.1.0
## Copyright(c) 2025 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2025/10/25
## Modified 2025/10/25
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::FencedFrame;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'HTML::Object' );
    use parent qw( HTML::Object::DOM::Element );
    use HTML::Object::DOM::Element::Shared qw( :fencedframe );
    our $VERSION = 'v0.1.0';
};

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'fencedframe' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property allow
sub allow : lvalue { return( shift->_set_get_property( 'allow', @_ ) ); }

# Note: property config
sub config : lvalue { return( shift->_set_get_property( 'config', @_ ) ); }

# Note: property height is inherited

# Note: property width is inherited

1;
# NOTE POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::FencedFrame - HTML Object DOM FencedFrame Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::FencedFrame;
    my $fencedframe = HTML::Object::DOM::Element::FencedFrame->new || 
        die( HTML::Object::DOM::Element::FencedFrame->error );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This interface represents a &lt;fencedframe&gt; element in JavaScript and provides configuration properties.

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 allow

Gets and sets the value of the corresponding C<fencedframe> allow attribute, which represents a Permissions Policy applied to the content when it is first embedded.

Example:

    my $frame = $doc->createElement("fencedframe");
    say($frame->allow);

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFencedFrameElement/allow>

=head2 config

a C<FencedFrameConfig> object, which represents the navigation of a C<fencedframe>, i.e., what content will be displayed in it. A C<FencedFrameConfig> is returned from a source such as the Protected Audience API.

Example:

    my $frameConfig = await navigator->runAdAuction({
        # … auction configuration
        resolveToConfig: true,
    });

    my $frame = $doc->createElement("fencedframe");
    $frame->config = $frameConfig;

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFencedFrameElement/config>

=head2 height

Gets and sets the value of the corresponding C<fencedframe> height attribute, which specifies the height of the element.

Example:

    my $frame = $doc->createElement("fencedframe");
    $frame->height = "320";

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFencedFrameElement/height>

=head2 width

Gets and sets the value of the corresponding C<fencedframe> width attribute, which specifies the width of the element.

Example:

    my $frame = $doc->createElement("fencedframe");
    $frame->width = "480";

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFencedFrameElement/width>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozila documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLFencedFrameElement>, L<Mozilla documentation on fencedframe element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/fencedframe>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2025 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

