package LibUI::EditableCombobox 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'LibUI::Control';
    #
    affix(
        LibUI::lib(),
        [ 'uiEditableComboboxAppend',             'append' ],
        [ InstanceOf ['LibUI::EditableCombobox'], Str ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiEditableComboboxOnChanged', 'onChanged' ],
        [   InstanceOf ['LibUI::EditableCombobox'],
            CodeRef [ [ InstanceOf ['LibUI::EditableCombobox'], Any ] => Void ], Any
        ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiEditableComboboxSetText',            'setText' ],
        [ InstanceOf ['LibUI::EditableCombobox'], Str ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiEditableComboboxText', 'text' ],
        [ InstanceOf ['LibUI::EditableCombobox'] ] => Str
    );
    affix(
        LibUI::lib(),
        [ 'uiNewEditableCombobox', 'new' ],
        [Void] => InstanceOf ['LibUI::EditableCombobox']
    );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::EditableCombobox - Single-Selection Control with a Drop Down Menu of
Predefined Options or Enter Your Own

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::VBox;
    use LibUI::Window;
    use LibUI::EditableCombobox;
    Init && die;
    my $window = LibUI::Window->new( 'Hi', 320, 100, 0 );
    $window->setMargined( 1 );
    my $box    = LibUI::VBox->new();
    my $combo  = LibUI::EditableCombobox->new();
    my @langs  = ( qw[English French Klingon German Japanese], 'Ubbi dubbi' );
    $combo->append($_) for @langs;
    $box->append( $combo, 0 );
    $combo->onChanged( sub { warn 'Language: ' . shift->text }, undef );
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

A LibUI::EditableCombobox object represents a control to select one item from a
predefined list of items or enter ones own.

A customary item can be entered by the user via an editable text field.

=head1 Functions

Not a lot here but... well, it's just a simple widget.

=head2 C<new( )>

    my $lst = LibUI::EditableCombobox->new( );

Creates a new combo box.

=head2 C<append( )>

   $lst->append( 'English' );

Appends an item to the editable combo box.

=head2 C<onChanged( ... )>

    $lst->onChanged(
    sub {
        my ($ctrl, $data) = @_;
        warn $ctrl->text;
    }, undef);

Registers a callback for when an editable combo box item is selected or user
text changed.

Expected parameters include:

=over

=item C<$callback> - CodeRef that should expect the following:

=over

=item C<$lst> - backreference to the instance that initiated the callback

=item C<$data> - user data registered with the sender instance

=back

=item C<$data> - user data to be passed to the callback

=back

Note: The callback is not triggered when calling C<setText( ... )>.

=head2 C<setText( ... )>

    $lst->setText( 'Icelandic' );

Sets the editable combo box text.

=head2 C<text( )>

    if($lst->selected eq 'English') {
        ...;
    }

Returns the text of the editable combo box.

This text is either the text of one of the predefined list items or the text
manually entered by the user.

=head1 See Also

L<LibUI::Combobox>

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

