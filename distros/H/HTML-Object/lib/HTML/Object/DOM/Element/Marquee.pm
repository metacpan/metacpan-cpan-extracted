##----------------------------------------------------------------------------
## HTML Object - ~/lib/HTML/Object/DOM/Element/Marquee.pm
## Version v0.2.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/01/06
## Modified 2022/09/18
## All rights reserved
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTML::Object::DOM::Element::Marquee;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( HTML::Object::DOM::Element );
    use vars qw( $VERSION );
    use HTML::Object::DOM::Element::Shared qw( :marquee );
    our $VERSION = 'v0.2.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->{tag} = 'marquee' if( !CORE::length( "$self->{tag}" ) );
    return( $self );
}

# Note: property behavior
sub behavior : lvalue { return( shift->_set_get_property( 'behavior', @_ ) ); }

# Note: property bgColor
sub bgColor : lvalue { return( shift->_set_get_property( 'bgcolor', @_ ) ); }

# Note: property direction
sub direction : lvalue { return( shift->_set_get_property( 'direction', @_ ) ); }

# Note: property height is inherited

# Note: property hspace
sub hspace : lvalue { return( shift->_set_get_property( 'hspace', @_ ) ); }

# Note: property loop
sub loop : lvalue { return( shift->_set_get_property( 'loop', @_ ) ); }

sub onbounce : lvalue { return( shift->on( 'bounce', @_ ) ); }

sub onfinish : lvalue { return( shift->on( 'finish', @_ ) ); }

sub onstart : lvalue { return( shift->on( 'start', @_ ) ); }

# Note: property scrollAmount
sub scrollAmount : lvalue { return( shift->_set_get_property( 'scrollamount', @_ ) ); }

# Note: property scrollDelay
sub scrollDelay : lvalue { return( shift->_set_get_property( 'scrolldelay', @_ ) ); }

sub start { return; }

sub stop { return; }

# Note: property trueSpeed
sub trueSpeed : lvalue { return( shift->_set_get_property({ attribute => 'truespeed', is_boolean => 1 }, @_ ) ); }

# Note: property vspace
sub vspace : lvalue { return( shift->_set_get_property( 'vspace', @_ ) ); }

# Note: property width is inherited

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTML::Object::DOM::Element::Marquee - HTML Object DOM Marquee Class

=head1 SYNOPSIS

    use HTML::Object::DOM::Element::Marquee;
    my $marquee = HTML::Object::DOM::Element::Marquee->new ||
        die( HTML::Object::DOM::Element::Marquee->error, "\n" );

=head1 VERSION

    v0.2.0

=head1 DESCRIPTION

Deprecated: This feature is no longer recommended. Though some browsers might still support it, it may have already been removed from the relevant web standards, may be in the process of being dropped, or may only be kept for compatibility purposes. Avoid using it, and update existing code if possible; see the compatibility table at the bottom of this page to guide your decision. Be aware that this feature may cease to work at any time.

=head1 INHERITANCE

    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-------------------------------------+
    | HTML::Object::Element | --> | HTML::Object::EventTarget | --> | HTML::Object::DOM::Node | --> | HTML::Object::DOM::Element | --> | HTML::Object::DOM::Element::Marquee |
    +-----------------------+     +---------------------------+     +-------------------------+     +----------------------------+     +-------------------------------------+

=head1 PROPERTIES

Inherits properties from its parent L<HTML::Object::DOM::Element>

=head2 behavior

This is the HTML attribute that reflects how the text is scrolled within the marquee. Possible values are C<scroll>, C<slide> and C<alternate>. If no value is specified, the default value is C<scroll>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMarqueeElement/behavior>

=head2 bgColor

This is the HTML attribute that reflects the background color through color name or hexadecimal value.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMarqueeElement/bgColor>

=head2 direction

This is the HTML attribute that reflects the direction of the scrolling within the marquee. Possible values are C<left>, C<right>, C<up> and C<down>. If no value is specified, the default value is C<left>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMarqueeElement/direction>

=head2 height

This is the HTML attribute that reflects the height in pixels or percentage value.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMarqueeElement/height>

=head2 hspace

This is the HTML attribute that reflects the horizontal margin.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMarqueeElement/hspace>

=head2 loop

This is the HTML attribute that reflects the number of times the marquee will scroll. If no value is specified, the default value is C<undef> (C<−1> under JavaScript), which means the marquee will scroll continuously.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMarqueeElement/loop>

=head2 scrollAmount

This is the HTML attribute that reflects the amount of scrolling at each interval in pixels. The default value is C<6>.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMarqueeElement/scrollAmount>

=head2 scrollDelay

Sets the interval between each scroll movement in milliseconds. The default value is 85. Note that any value smaller than 60 is ignored and the value 60 is used instead, unless trueSpeed is true.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMarqueeElement/scrollDelay>

=head2 trueSpeed

This is the HTML attribute that reflects whether to ignore scrollDelay small value. By default, scrollDelay values lower than 60 are ignored. If trueSpeed is true, then those values are not ignored.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMarqueeElement/trueSpeed>

=head2 vspace

This is the HTML attribute that reflects the vertical margin.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMarqueeElement/vspace>

=head2 width

This is the HTML attribute that reflects the width in pixels or percentage value.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMarqueeElement/width>

=head1 METHODS

Inherits methods from its parent L<HTML::Object::DOM::Element>

=head2 start

Under perl, this does nothing and always returns C<undef> obviously.

Under JavaScript, this starts scrolling of the marquee.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMarqueeElement/start>

=head2 stop

Under perl, this does nothing and always returns C<undef> obviously.

Under JavaScript, this stops scrolling of the marquee.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMarqueeElement/stop>

=head1 EVENT HANDLERS

None of the following events are fired automatically under perl, obviously, but you can trigger them yourself.

=head2 onbounce

Fires when the marquee has reached the end of its scroll position. It can only fire when the behavior attribute is set to alternate.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMarqueeElement/onbounce>

=head2 onfinish

Fires when the marquee has finished the amount of scrolling that is set by the loop attribute. It can only fire when the loop attribute is set to some number that is greater than 0.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMarqueeElement/onfinish>

=head2 onstart

Fires when the marquee starts scrolling.

See also L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMarqueeElement/onstart>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/API/HTMLMarqueeElement>, L<Mozilla documentation on marquee element|https://developer.mozilla.org/en-US/docs/Web/HTML/Element/marquee>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
