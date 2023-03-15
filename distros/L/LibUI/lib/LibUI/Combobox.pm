package LibUI::Combobox 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'LibUI::Control';
    #
    affix(
        LibUI::lib(),
        [ 'uiComboboxAppend',             'append' ],
        [ InstanceOf ['LibUI::Combobox'], Str ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiComboboxClear', 'clear' ],
        [ InstanceOf ['LibUI::Combobox'] ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiComboboxDelete',             'delete' ],
        [ InstanceOf ['LibUI::Combobox'], Int ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiComboboxInsertAt', 'insertAt' ],
        [ InstanceOf ['LibUI::Combobox'], Int, Str ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiComboboxNumItems', 'numItems' ],
        [ InstanceOf ['LibUI::Combobox'], ] => Int
    );
    affix(
        LibUI::lib(),
        [ 'uiComboboxOnSelected', 'onSelected' ],
        [   InstanceOf ['LibUI::Combobox'],
            CodeRef [ [ InstanceOf ['LibUI::Combobox'], Any ] => Void ], Any
        ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiComboboxSelected', 'selected' ],
        [ InstanceOf ['LibUI::Combobox'] ] => Int
    );
    affix(
        LibUI::lib(),
        [ 'uiComboboxSetSelected',        'setSelected' ],
        [ InstanceOf ['LibUI::Combobox'], Int ] => Void
    );
    affix( LibUI::lib(), [ 'uiNewCombobox', 'new' ], [Void] => InstanceOf ['LibUI::Combobox'] );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Combobox - Single-Selection Control with a Drop Down Menu of Predefined
Options

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::VBox;
    use LibUI::Window;
    use LibUI::Combobox;
    Init && die;
    my $window = LibUI::Window->new( 'Hi', 320, 100, 0 );
    $window->setMargined( 1 );
    my $box    = LibUI::VBox->new();
    my $combo  = LibUI::Combobox->new();
    my @langs  = ( qw[English French Klingon German Japanese], 'Ubbi dubbi' );
    $combo->append($_) for @langs;
    $box->append( $combo, 0 );
    $combo->onSelected( sub { warn 'Language: ' . $langs[ shift->selected ] }, undef );
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

A LibUI::Combobox object represents a control to select one item from a
predefined list of items via a drop down menu.

=head1 Functions

Not a lot here but... well, it's just a simple widget.

=head2 C<new( )>

    my $lst = LibUI::Combobox->new( );

Creates a new combo box.

=head2 C<append( )>

   $lst->append( 'English' );

Appends an item to the combo box.

=head2 C<clear( )>

    $lst->clear( );

Deletes all items from the combo box.

=head2 C<delete( ... )>

    $lst->delete( 4 );

Deletes an item at C<$index> from the combo box.

=head2 C<insertAt( ... )>

    $lst->insertAt( 10, 'Klingon' );

Inserts an item at L<$index> to the combo box.

=head2 C<numItems( )>

    my $count = $lst->numItems;

Returns the number of items contained within the combo box.

=head2 C<onSelected( ... )>

    $lst->onSelected(
    sub {
        my ($ctrl, $data) = @_;
        warn $ctrl->value;
    }, undef);

Registers a callback for when a combo box item is selected.

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

=head2 C<selected( )>

    if($lst->selected == 5) {
        ...;
    }

Returns the index of the item selected. C<-1> is returned on empty selection.

=head2 C<setSelected( ... )>

    $lst->setSelected( 50 );

Sets the item selected.

=head1 See Also

L<LibUI::EditableCombobox>

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

