package LibUI::Checkbox 0.01 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'LibUI::Control';
    #
    affix(
        LibUI::lib(), 'uiCheckboxChecked', [ InstanceOf ['LibUI::Checkbox'] ] => Int,
        'checked'
    );
    affix(
        LibUI::lib(),
        'uiCheckboxOnToggled',
        [   InstanceOf ['LibUI::Checkbox'],
            CodeRef [ [ InstanceOf ['LibUI::Checkbox'], Any ] => Void ], Any
        ] => Void,
        'onToggled'
    );
    affix(
        LibUI::lib(), 'uiCheckboxSetChecked', [ InstanceOf ['LibUI::Checkbox'], Int ] => Void,
        'setChecked'
    );
    affix(
        LibUI::lib(), 'uiCheckboxSetText', [ InstanceOf ['LibUI::Checkbox'], Str ] => Void,
        'setText'
    );
    affix( LibUI::lib(), 'uiCheckboxText', [ InstanceOf ['LibUI::Checkbox'] ] => Str, 'text' );
    affix( LibUI::lib(), 'uiNewCheckbox',  [ Void, Str ] => InstanceOf ['LibUI::Checkbox'], 'new' );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Checkbox - User Checkable Box

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::VBox;
    use LibUI::Window;
    use LibUI::Checkbox;
    Init( { Size => 1024 } ) && die;
    my $window = LibUI::Window->new( 'Hi', 320, 100, 0 );
    my $box    = LibUI::VBox->new();

    sub checked {
        my ( $ctrl, $data ) = @_;
        printf "%s is %schecked\n", $ctrl->text, $ctrl->checked ? '' : 'un';
    }
    for my $lang (qw[Perl Rust Java C C++ Python Go COBOL]) {
        my $chk = LibUI::Checkbox->new($lang);
        $chk->onToggled( \&checked, undef );
        $box->append( $chk, 0 );
    }
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

A LibUI::Checkbox object represents a user checkable box accompanied by a text
label.

=head1 Functions

Not a lot here but... well, it's just a checkbox.

=head2 C<new( ... )>

    my $chk = LibUI::Checkbox->new( 'Perl' );

Creates a new checkbox.

=head2 C<checked( ... )>

    if( $chk->checked ) {
        ...;
    }

Returns whether or the checkbox is checked.

=head2 C<onToggled( ... )>

    $chk->onToggled(
    sub {
        my ($ctrl, $data) = @_;
        warn $ctrl->text;
    }, undef);

Registers a callback for when the checkbox is toggled by the user.

Expected parameters include:

=over

=item C<$callback> - CodeRef that should expect the following:

=over

=item C<$chk> - backreference to the instance that initiated the callback

=item C<$data> - user data registered with the sender instance

=back

=item C<$data> - user data to be passed to the callback

=back

Note: The callback is not triggered when calling C<setChecked( ... )>.

=head2 C<setChecked( ... )>

    $chk->setChecked( 1 );

Sets whether or not the checkbox is checked.

=head2 C<setText( ... )>

    $chk->setText( 'Updated' );

Sets the checkbox label text.

=head2 C<text( ... )>

    my $label = $chk->text( );

Returns the checkbox label text.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords checkbox backreference

=cut

