package LibUI::Slider 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'LibUI::Control';
    #
    affix(
        LibUI::lib(),
        [ 'uiNewSlider', 'new' ],
        [ Void, Int, Int ] => InstanceOf ['LibUI::Slider']
    );
    affix(
        LibUI::lib(),
        [ 'uiSliderHasToolTip', 'hasToolTip' ],
        [ InstanceOf ['LibUI::Slider'] ] => Int
    );
    affix(
        LibUI::lib(),
        [ 'uiSliderOnChanged', 'onChanged' ],
        [   InstanceOf ['LibUI::Slider'],
            CodeRef [ [ InstanceOf ['LibUI::Slider'], Any ] => Void ], Any
        ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiSliderOnReleased', 'onReleased' ],
        [   InstanceOf ['LibUI::Slider'],
            CodeRef [ [ InstanceOf ['LibUI::Slider'], Any ] => Void ], Any
        ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiSliderSetHasToolTip',      'setHasToolTip' ],
        [ InstanceOf ['LibUI::Slider'], Int ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiSliderSetRange', 'setRange' ],
        [ InstanceOf ['LibUI::Slider'], Int, Int ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiSliderSetValue',           'setValue' ],
        [ InstanceOf ['LibUI::Slider'], Int ] => Void
    );
    affix( LibUI::lib(), [ 'uiSliderValue', 'value' ], [ InstanceOf ['LibUI::Slider'] ] => Int );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Slider - Control to Display and Modify Integer Values via a Draggable
Slider

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::VBox;
    use LibUI::Window;
    use LibUI::Slider;
    Init && die;
    my $window = LibUI::Window->new( 'Hi', 320, 100, 0 );
    $window->setMargined( 1 );
    my $box    = LibUI::VBox->new();
    my $slider = LibUI::Slider->new( 1, 100 );
    $box->append( $slider, 0 );
    $slider->onChanged( sub { warn 'Sliding to ' . shift->value }, undef );
    $slider->onReleased( sub { warn 'Stopped at ' . shift->value }, undef );
    $window->setChild($box);
    $window->onClosing(
        sub {
            Quit();
            return 1;
        },
        undef
    );
    $window->show;
    Main();

=head1 DESCRIPTION

A LibUI::Slider object represents a control to display and modify integer
values via a draggable slider.

Values are guaranteed to be within the specified range.

Sliders by default display a tool tip showing the current value when being
dragged.

Sliders are horizontal only.

=head1 Functions

Not a lot here but... well, it's just a simple widget.

=head2 C<new( ... )>

    my $sld = LibUI::Slider->new( 1, 100 );

Creates a new slider.

Expected parameters include:

=over

=item C<$min> - minimum value

=item C<$max> - maximum value

=back

The initial slider value equals the C<$min>imum value.

In the current upstream implementation, C<$min> and C<$max> are swapped if
C<$min> is greater than C<$max>. This may change in the future though.

=head2 C<hasToolTip( )>

    if( $sld->hasToolTip ) {
        ...;
    }

Returns whether or not the slider has a tool tip.

=head2 C<setHasToolTip( ... )>

    $sld->setHasToolTip( 0 );

Sets whether or not the slider has a tool tip.

=head2 C<onChanged( ... )>

    $sld->onChanged(
    sub {
        my ($ctrl, $data) = @_;
        warn $ctrl->value;
    }, undef);

Registers a callback for when the slider value is changed by the user.

Expected parameters include:

=over

=item C<$callback> - CodeRef that should expect the following:

=over

=item C<$sld> - backreference to the instance that initiated the callback

=item C<$data> - user data registered with the sender instance

=back

=item C<$data> - user data to be passed to the callback

=back

Note: The callback is not triggered when calling C<setValue( ... )>.

=head2 C<onReleased( ... )>

    $sld->onReleased(
    sub {
        my ($ctrl, $data) = @_;
        warn $ctrl->value;
    }, undef);

Registers a callback for when the slider is released from dragging.

Expected parameters include:

=over

=item C<$callback> - CodeRef that should expect the following:

=over

=item C<$sld> - backreference to the instance that initiated the callback

=item C<$data> - user data registered with the sender instance

=back

=item C<$data> - user data to be passed to the callback

=back

=head2 C<setRange( ... )>

    $sld->setRange( 10, 20 );

Sets the slider range.

Expected parameters include:

=over

=item C<$min> - minimum value

=item C<$max> - maximum value

=back

=head2 C<setValue( ... )>

    $sld->setValue( 50 );

Sets the slider value.

=head2 C<value( ... )>

    warn $sld->value( );

Returns the slider value.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords imum draggable

=cut

