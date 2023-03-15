package LibUI::MultilineEntry 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'LibUI::Control';
    #
    affix(
        LibUI::lib(),
        [ 'uiNewMultilineEntry', 'new' ],
        [Void] => InstanceOf ['LibUI::MultilineEntry']
    );
    affix(
        LibUI::lib(),
        [ 'uiMultilineEntryAppend',             'append' ],
        [ InstanceOf ['LibUI::MultilineEntry'], Str ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiMultilineEntryOnChanged', 'onChanged' ],
        [   InstanceOf ['LibUI::MultilineEntry'],
            CodeRef [ [ InstanceOf ['LibUI::MultilineEntry'], Any ] => Void ], Any
        ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiMultilineEntryReadOnly', 'readonly' ],
        [ InstanceOf ['LibUI::MultilineEntry'] ] => Int
    );
    affix(
        LibUI::lib(),
        [ 'uiMultilineEntrySetReadOnly',        'setReadonly' ],
        [ InstanceOf ['LibUI::MultilineEntry'], Int ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiMultilineEntrySetText',            'setText' ],
        [ InstanceOf ['LibUI::MultilineEntry'], Str ] => Void
    );
    affix(
        LibUI::lib(),
        [ 'uiMultilineEntryText', 'text' ],
        [ InstanceOf ['LibUI::MultilineEntry'] ] => Str
    );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::MultilineEntry - Multiline Text Entry Field

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::VBox;
    use LibUI::Window;
    use LibUI::MultilineEntry;
    Init && die;
    my $window = LibUI::Window->new( 'Notepadish', 320, 100, 0 );
    $window->setMargined( 1 );
    my $box    = LibUI::VBox->new();
    my $text   = LibUI::MultilineEntry->new();
    $box->append( $text, 1 );
    $text->onChanged( sub { warn sprintf '%d chars', length shift->text; }, undef );
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

A control with a multi line text entry field.

=head1 Functions

Not a lot here but... well, it's just a simple widget.

=head2 C<new( )>

    my $text = LibUI::MultilineEntry->new( );

Creates a new multi line entry that visually wraps text when lines overflow.

=head2 C<append( ... )>

    $text->append(qq[-- \nJohn Smith\nsmithj\@work.email]);

Appends text to the multi line entry's text.

=head2 C<onChanged( ... )>

    $date->onChanged(
    sub {
        my ($ctrl, $data) = @_;
        warn $ctrl->text;
    }, undef);

Registers a callback for when the user changes the multi line entry's text.

Expected parameters include:

=over

=item C<$callback> - CodeRef that should expect the following:

=over

=item C<$date> - backreference to the instance that initiated the callback

=item C<$data> - user data registered with the sender instance

=back

=item C<$data> - user data to be passed to the callback

=back

Note: The callback is not triggered when calling C<setText( ... )> or C<append(
... )>.

=head2 C<readonly( )>

    if( $text->readonly ) {
        ...;
    }

Returns whether or not the multi line entry's text can be changed.

=head2 C<setReadonly( ... )>

    $text->setReadonly( 1 );

Sets whether or not the multi line entry's text is read only.

=head2 C<text( )>

    warn $date->text;

Returns the multi line entry's text.

=head2 C<setTime( ... )>

    $date->setTime( 'We need to get to work.' );

Sets the multi line entry's text.

=head1 See Also

L<LibUI::Entry> - Single line text field

L<LibUI::NonWrappingMultilineEntry> - Multi-line text file that does not wrap

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
