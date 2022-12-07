package LibUI::VBox 0.01 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'LibUI::HBox';
    #
    affix( LibUI::lib(), 'uiNewVerticalBox', [Void] => InstanceOf ['LibUI::VBox'], 'new' );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::VBox - Vertically Oriented Boxlike Container that Holds a Group of
Controls

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::VBox;
    use LibUI::Window;
    use LibUI::ColorButton;
    use LibUI::Label;
    Init( { Size => 1024 } ) && die;
    my $window = LibUI::Window->new( 'Hi', 320, 100, 0 );
    my $box    = LibUI::VBox->new;
    my $lbl    = LibUI::Label->new('Pick a color');
    my $cbtn   = LibUI::ColorButton->new();
    $cbtn->onChanged(
        sub {
            my @rgba = $cbtn->color();
            $lbl->setText(
                sprintf "#%02X%02X%02X%02X\nrgba(%d, %d, %d, %.2f)",
                ( map { $_ * 255 } @rgba ),
                ( map { $_ * 255 } @rgba[ 0 .. 2 ] ),
                $rgba[-1]
            );
        },
        undef
    );
    $box->setPadded(1);
    $box->append( $cbtn, 1 );
    $box->append( $lbl,  1 );
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

A LibUI::VBox object represents a boxlike container that holds a group of
controls.

The contained controls are arranged to be displayed vertically on top of each
other.

=head1 Functions

Not a lot here but... well, it's just a box.

=head2 C<new( ... )>

    my $box = LibUI::VBox->new( );

Creates a new LibUI::VBox.

=head2 C<append( ... )>

    $box->append( $lbl, 1 );

Appends a control to the box.

Expected parameters include:

=over

=item C<$child> - LibUI::Control instance to append

=item C<$stretchy> - true to stretch control, otherwise false

=back

Stretchy items expand to use the remaining space within the box. In the case of
multiple stretchy items the space is shared equally.

=head2 C<delete( ... )>

    $box->delete( $index );

Removes the control at C<$index> from the box.

Note: The control is neither destroyed nor freed.

=head2 C<numChildren( )>

    my $tally = $box->numChildren( );

Returns the number of controls contained within the box.

=head2 C<padded( )>

    if( $box->padded ) {
        ...;
    }

Returns whether or not controls within the box are padded.

Padding is defined as space between individual controls.

=head2 C<setPadded( ... )>

    $box->setPadded( 1 );

Sets whether or not controls within the box are padded.

Padding is defined as space between individual controls. The padding size is
determined by the OS defaults.

=head1 See Also

L<LibUI::HBox> for a horizontally oriented box.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

