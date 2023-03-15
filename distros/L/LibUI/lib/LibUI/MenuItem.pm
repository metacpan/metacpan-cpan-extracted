package LibUI::MenuItem 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    #
    affix(
        LibUI::lib(),
        [ 'uiMenuItemChecked', 'checked' ],
        [ InstanceOf ['LibUI::MenuItem'] ] => Int
    );
    affix(
        LibUI::lib(),
        [ 'uiMenuItemDisable', 'disable' ],
        [ InstanceOf ['LibUI::MenuItem'] ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiMenuItemEnable', 'enable' ],
        [ InstanceOf ['LibUI::MenuItem'] ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiMenuItemOnClicked', 'onClicked' ],
        [   InstanceOf ['LibUI::MenuItem'],
            CodeRef [
                [ InstanceOf ['LibUI::MenuItem'], InstanceOf ['LibUI::Window'], Any ] => Void
            ],
            Any
        ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiMenuItemSetChecked',         'setChecked' ],
        [ InstanceOf ['LibUI::MenuItem'], Int ] => Void
    );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::MenuItem - Menu Item Use in Conjunction with LibUI::Menu

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::Window;
    use LibUI::Menu;
    Init && die;
    my $mnuTest  = LibUI::Menu->new('Test');
    my $mnuCheck = $mnuTest->appendCheckItem('Target');
    $mnuTest->appendSeparator;
    $mnuTest->appendItem('Enable')->onClicked( sub { $mnuCheck->enable }, undef );
    $mnuTest->appendItem('Disable')->onClicked( sub { $mnuCheck->disable }, undef );
    $mnuTest->appendItem('Check')->onClicked( sub { $mnuCheck->setChecked(1) }, undef );
    $mnuTest->appendItem('Uncheck')->onClicked( sub { $mnuCheck->setChecked(0) }, undef );
    my $window = LibUI::Window->new( 'Hi', 320, 100, 1 );
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

A LibUI::MenuItem object represents a menu item used in conjunction with
L<LibUI::Menu>.

=head1 Functions

Not a lot here but... well, it's just a menu item.

=head2 C<checked( )>

    if( $mnu_i->checked ) {
        ...;
    }

Returns whether or not the menu item's checkbox is checked.

=head2 C<disable( )>

    $mnu_i->disable;

Disables the menu item.

Menu item is grayed out and user interaction is not possible.

=head2 C<enable( )>

    $mnu_i->enable;

Enables the menu item.

=head2 C<onClicked( ... )>

    $chk->onClicked(
    sub {
        my ($ctrl, $win, $data) = @_;
        warn $ctrl->text;
    }, undef);

Registers a callback for when the checkbox is toggled by the user.

Expected parameters include:

=over

=item C<$callback> - CodeRef that should expect the following:

=over

=item C<$chk> - backreference to the instance that initiated the callback

=item C<$win> - reference to the window from which the callback got triggered

=item C<$data> - user data registered with the sender instance

=back

=item C<$data> - user data to be passed to the callback

=back

=head2 C<setChecked( ... )>

    $chk->setChecked( 1 );

Sets whether or not the menu item's checkbox is checked.

To be used only with items created via C<appendCheckItem( ... )>.

=head1 See Also

L<LibUI::Menu>

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords checkbox backreference

=cut

