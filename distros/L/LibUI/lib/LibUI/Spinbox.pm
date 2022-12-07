package LibUI::Spinbox 0.01 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'LibUI::Control';
    #
    affix(
        LibUI::lib(), 'uiNewSpinbox', [ Void, Int, Int ] => InstanceOf ['LibUI::Spinbox'],
        'new'
    );
    affix(
        LibUI::lib(),
        'uiSpinboxOnChanged',
        [   InstanceOf ['LibUI::Spinbox'],
            CodeRef [ [ InstanceOf ['LibUI::Spinbox'], Any ] => Void ], Any
        ] => Void,
        'onChanged'
    );
    affix(
        LibUI::lib(), 'uiSpinboxSetValue', [ InstanceOf ['LibUI::Spinbox'], Int ] => Void,
        'setValue'
    );
    affix( LibUI::lib(), 'uiSpinboxValue', [ InstanceOf ['LibUI::Spinbox'] ] => Int, 'value' );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Spinbox - Control to Display and Modify Integer Values via a Text Field
or +/- Buttons

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::VBox;
    use LibUI::Window;
    use LibUI::Spinbox;
    Init( { Size => 1024 } ) && die;
    my $window = LibUI::Window->new( 'Hi', 320, 100, 0 );
    my $box    = LibUI::VBox->new();
    my $count  = LibUI::Spinbox->new( 1, 100 );
    $box->append( $count, 0 );
    $count->onChanged( sub { warn shift->value }, undef );
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

A LibUI::Spinbox object represents a control to display and modify integer
values via a text field or +/- buttons.

This is a convenient control for having the user enter integer values. Values
are guaranteed to be within the specified range.

The C<+> button increases the held value by 1.

The C<-> button decreased the held value by 1.

Entering a value out of range will clamp to the nearest value in range.

=head1 Functions

Not a lot here but... well, it's just a text box with some little buttons.

=head2 C<new( ... )>

    my $count = LibUI::Spinbox->new( 1, 100 );

Creates a new spinbox.

Expected parameters include:

=over

=item C<$min> - minimum value

=item C<$max> - maximum value

=back

The initial spinbox value equals the C<$min>imum value.

In the current upstream implementation, C<$min> and C<$max> are swapped if
C<$min> is greater than C<$max>. This may change in the future though.

=head2 C<onChanged( ... )>

    $count->onChanged(
    sub {
        my ($ctrl, $data) = @_;
        warn $ctrl->value;
    }, undef);

Registers a callback for when the spinbox value is changed by the user.

Expected parameters include:

=over

=item C<$callback> - CodeRef that should expect the following:

=over

=item C<$count> - backreference to the instance that initiated the callback

=item C<$data> - user data registered with the sender instance

=back

=item C<$data> - user data to be passed to the callback

=back

Note: The callback is not triggered when calling C<setValue( ... )>.

=head2 C<setValue( ... )>

    $count->setValue( 50 );

Sets the spinbox value.

=head2 C<value( ... )>

    warn $count->value( );

Returns the spinbox value.

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=for stopwords spinbox imum

=cut

