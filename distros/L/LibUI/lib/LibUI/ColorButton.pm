package LibUI::ColorButton 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'LibUI::Control';
    #
    sub color ($) {
        my $s = shift;
        CORE::state $affix //= wrap(
            LibUI::lib(),
            'uiColorButtonColor',
            [   InstanceOf ['LibUI::ColorButton'],
                Pointer [Double],
                Pointer [Double],
                Pointer [Double],
                Pointer [Double]
            ] => Void
        );
        my ( $r, $g, $b, $a ) = ( 0, 0, 0, 0 );
        $affix->( $s, $r, $g, $b, $a );
        ( $r, $g, $b, $a );
    }
    affix(
        LibUI::lib(),
        [ 'uiColorButtonSetColor', 'setColor' ],
        [ InstanceOf ['LibUI::ColorButton'], Double, Double, Double, Double ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiColorButtonOnChanged', 'onChanged' ],
        [   InstanceOf ['LibUI::ColorButton'],
            CodeRef [ [ InstanceOf ['LibUI::ColorButton'], Any ] => Void ], Any
        ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiNewColorButton', 'new' ],
        [Void] => InstanceOf ['LibUI::ColorButton']
    );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::ColorButton - Color Picker

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::Window;
    use LibUI::ColorButton;
    Init && die;
    my $window = LibUI::Window->new( 'Hi', 320, 100, 0 );
    $window->setMargined( 1 );
    my $cbtn   = LibUI::ColorButton->new();
    $cbtn->onChanged(
        sub {
            warn sprintf 'RGBA: #%02X%02X%02X%02X', map { $_ * 255 } $cbtn->color();
        },
        undef
    );
    $window->setChild($cbtn);
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

A LibUI::ColorButton object represents control with a color indicator that
opens a color chooser when clicked.

The control visually represents a button with a color field representing the
selected color.

Clicking on the button opens up a color chooser in form of a color palette.

=head1 Functions

Not a lot here but... well, it's just a button with managed utility.

=head3 C<color( )>

    my ($r, $g, $b, $a) = $cbtn->color( );

Returns the color button color where each is a double in range of C<0.0 ...
1.0>.

=head3 C<setColor( ... )>

    $cbtn->setColor( $r, $g, $b, $a );

Sets the color button color.

Expected parameters include:

=over

=item C<$r> - Red

=item C<$g> - Green

=item C<$b> - Blue

=item C<$a> - Alpha

=back

All parameters are doubles in the range of C<0.0 ... 1.0>.

=head3 C<onChanged( ... )>

    $cbtn->onChanged(sub { ... }, undef);

Registers a callback for when the color is changed.

Expected parameters include:

=over

=item C<$callback> - CodeRef which should expect the following when triggered:

=over

=item C<$sender> - Colorbutton that triggered callback

=item C<$userdata> - Userdata as defined by... you

=back

=item C<$userdata> - Arbitrary data, if defined

=back

Only one callback can be registered at a time. The callback is not triggered
when calling C<setColor( ... )>.

=head3 C<new( ... )>

    my $cbtn = LibUI::ColorButton->new( );

Creates a new LibUI::ColorButton.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

