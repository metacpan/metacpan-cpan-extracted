package LibUI::RadioButtons 0.01 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'LibUI::Control';
    #
    affix( LibUI::lib(), 'uiNewRadioButtons', [Void] => InstanceOf ['LibUI::RadioButtons'], 'new' );
    affix(
        LibUI::lib(), 'uiRadioButtonsAppend', [ InstanceOf ['LibUI::RadioButtons'], Str ] => Void,
        'append'
    );
    affix(
        LibUI::lib(),
        'uiRadioButtonsOnSelected',
        [   InstanceOf ['LibUI::RadioButtons'],
            CodeRef [ [ InstanceOf ['LibUI::RadioButtons'], Any ] => Void ], Any
        ] => Void,
        'onSelected'
    );
    affix(
        LibUI::lib(), 'uiRadioButtonsSelected', [ InstanceOf ['LibUI::RadioButtons'] ] => Int,
        'selected'
    );
    affix(
        LibUI::lib(), 'uiRadioButtonsSetSelected',
        [ InstanceOf ['LibUI::RadioButtons'], Int ] => Void,
        'setSelected'
    );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::RadioButtons - Multiple Choice Array of Check Buttons

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::VBox;
    use LibUI::Window;
    use LibUI::RadioButtons;
    Init( { Size => 1024 } ) && die;
    my $window = LibUI::Window->new( 'Age range', 320, 100, 0 );
    my $box    = LibUI::VBox->new();
    my $radio  = LibUI::RadioButtons->new();
    my @range  = qw[0-5 6-12 13-18 19-25 26-35 36-45 46-60 60+];
    $radio->append($_) for @range;
    $box->append( $radio, 0 );
    $radio->onSelected( sub { warn 'Aged: ' . $range[ shift->selected ] }, undef );
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

A LibUI::RadioButtons object represents a multiple choice control of check
buttons from which only one can be selected at a time.

=head1 Functions

Not a lot here but... well, it's just a simple widget.

=head2 C<new( )>

    my $lst = LibUI::RadioButtons->new( );

Creates a new radio buttons instance.

=head2 C<append( )>

   $lst->append( 'English' );

Appends a radio button.

=head2 C<onSelected( ... )>

    $lst->onSelected(
    sub {
        my ($ctrl, $data) = @_;
        warn $ctrl->selected;
    }, undef);

Registers a callback for when radio button is selected.

Expected parameters include:

=over

=item C<$callback> - CodeRef that should expect the following:

=over

=item C<$lst> - backreference to the instance that initiated the callback

=item C<$data> - user data registered with the sender instance

=back

=item C<$data> - user data to be passed to the callback

=back

Note: The callback is not triggered when calling C<setSelected( ... )>.

=head2 C<selected( ... )>

    if( $lst->selected == 3 ) {
        ...;
    }

Returns the index of the item selected or C<-1> if there is no selected
element.

=head2 C<setSelected( ... )>

    $lst->setSelected( 3 );

Sets the item selected. Pass C<-1> to clear selection.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

