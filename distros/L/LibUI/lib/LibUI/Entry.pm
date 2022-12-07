package LibUI::Entry 0.01 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'LibUI::Control';
    #
    affix(
        LibUI::lib(),
        'uiEntryOnChanged',
        [   InstanceOf ['LibUI::Entry'],
            CodeRef [ [ InstanceOf ['LibUI::Entry'], Any ] => Void ], Any
        ] => Void,
        'onChanged'
    );
    affix( LibUI::lib(), 'uiEntryReadOnly', [ InstanceOf ['LibUI::Entry'] ] => Int, 'readonly' );
    affix(
        LibUI::lib(), 'uiEntrySetReadOnly', [ InstanceOf ['LibUI::Entry'], Int ] => Void,
        'setReadonly'
    );
    affix(
        LibUI::lib(), 'uiEntrySetText', [ InstanceOf ['LibUI::Entry'], Str ] => Void,
        'setText'
    );
    affix( LibUI::lib(), 'uiEntryText', [ InstanceOf ['LibUI::Entry'] ] => Str, 'text' );
    affix( LibUI::lib(), 'uiNewEntry',  [Void] => InstanceOf ['LibUI::Entry'],  'new' );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Entry - Single Line Text Entry Field

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::VBox;
    use LibUI::Window;
    use LibUI::Entry;
    Init( { Size => 1024 } ) && die;
    my $window = LibUI::Window->new( 'Hi', 320, 100, 0 );
    my $box    = LibUI::VBox->new();
    my $entry  = LibUI::Entry->new;
    $box->append( $entry, 0 );
    $entry->onChanged( sub { warn shift->text }, undef );
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

A LibUI::Entry object represents a control with a single line text entry field.

=head1 Functions

Not a lot here but... well, it's just a text box.

=head2 C<new( ... )>

    my $txt = LibUI::Entry->new( );

Creates a new entry.

=head2 C<onChanged( ... )>

    $txt->onChanged(
    sub {
        my ($ctrl, $data) = @_;
        warn $ctrl->text;
    }, undef);

Registers a callback for when the user changes the entry's text.

Expected parameters include:

=over

=item C<$callback> - CodeRef that should expect the following:

=over

=item C<$txt> - backreference to the instance that initiated the callback

=item C<$data> - user data registered with the sender instance

=back

=item C<$data> - user data to be passed to the callback

=back

Note: The callback is not triggered when calling C<setText( ... )>.

=head2 C<readonly( ... )>

    if( $txt->readonly( ) ) {
        ...;
    }

Returns whether or not the entry's text can be changed.

=head2 C<setReadonly( ... )>

    $txt->setReadonly( 1 );

Sets whether or not the entry's text is read only.

=head2 C<setText( ... )>

    $txt->setText( 'Updated' );

Sets the entry's text.

=head2 C<text( ... )>

    warn $txt->text( );

Returns the entry's text.

=head1 See Also

L<LibUI::PasswordEntry>, L<LibUI::SearchEntry>.

L<LibUI::MultilineEntry> - Multi-line text file that does not wrap

L<LibUI::NonWrappingMultilineEntry> - Multi-line text file that does not wrap

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

