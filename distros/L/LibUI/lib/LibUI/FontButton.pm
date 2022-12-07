package LibUI::FontButton 0.01 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'LibUI::Control';
    use LibUI::FontDescriptor;
    #
    affix( LibUI::lib(), 'uiNewFontButton', [Void] => InstanceOf ['LibUI::FontButton'], 'new' );

    sub font($) {
        CORE::state $affix //= wrap( LibUI::lib(), 'uiFontButtonFont',
            [ InstanceOf ['LibUI::FontButton'], Pointer [LibUI::FontDescriptor] ] => Void, );
        my $desc;
        $affix->( shift, $desc );
        return $desc;
    }
    affix(
        LibUI::lib(),
        'uiFontButtonOnChanged',
        [   InstanceOf ['LibUI::FontButton'],
            CodeRef [ [ InstanceOf ['LibUI::FontButton'], Any ] => Void ], Any
        ] => Void,
        'onChanged'
    );
    affix(
        LibUI::lib(), 'uiFreeFontButtonFont', [ Pointer [LibUI::FontDescriptor] ] => Void,
        'freeFont'
    );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::FontButton - Button-like Control that Opens a Font Chooser when Clicked

=head1 SYNOPSIS


    use LibUI ':all';
    use LibUI::VBox;
    use LibUI::Window;
    use LibUI::FontButton;
    Init( { Size => 1024 } ) && die;
    my $window = LibUI::Window->new( 'Font Picker', 320, 100, 0 );
    my $box    = LibUI::VBox->new();
    my $text   = LibUI::FontButton->new();
    $box->append( $text, 1 );
    $text->onChanged(
        sub {
            my $f = shift->font;

            # Some enum values don't have a 1:1 equiv with CSS but...
            printf <<'', $f->{weight}, $f->{italic}, $f->{size}, $f->{family};
                html {
                    font: %s %s %spt "%s";
                }

        },
        undef
    );
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

A control with a button-like control that opens a font chooser when clicked.

=head1 Functions

Not a lot here but... well, it's just a simple widget.

=head2 C<new( )>

    my $font = LibUI::FontButton->new( );

Creates a new font button.

The default font is determined by the OS defaults.

=head2 C<font( ... )>

    my $desc = $font->font;

Returns the selected font.

Note: Make sure to call C<freeFont()> to free all allocated resources within
the returned font.

=head2 C<onChanged( ... )>

    sub new_font {
        my ($ctrl, $data) = @_;
        my $font = $ctrl->font;
        ...;
    }
    $font->onChanged( \&new_font, undef );

Registers a callback for when the font is changed.

Expected parameters include:

=over

=item C<$callback> - CodeRef that should expect the following:

=over

=item C<$font> - backreference to the instance that initiated the callback

=item C<$data> - user data registered with the sender instance

=back

=item C<$data> - user data to be passed to the callback

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
