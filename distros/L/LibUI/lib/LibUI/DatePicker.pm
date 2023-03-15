package LibUI::DatePicker 0.02 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'LibUI::DateTimePicker';
    use LibUI::Time;
    #
    affix( LibUI::lib(), [ 'uiNewDatePicker', 'new' ], [Void] => InstanceOf ['LibUI::DatePicker'] );
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::DatePicker - Control to Enter a Date

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::VBox;
    use LibUI::Window;
    use LibUI::DatePicker;
    use Time::Piece;
    Init && die;
    my $window = LibUI::Window->new( 'Schedule an Event', 320, 100, 0 );
    $window->setMargined( 1 );
    my $box    = LibUI::VBox->new();
    my $date   = LibUI::DatePicker->new();
    $box->append( $date, 0 );
    $date->setTime( Time::Piece->new->add_months(60) );    # Five years from now
    $date->onChanged(
        sub {
            my $picker = shift;
            my $t      = $picker->time;
            warn sprintf 'Setting an appointment for %s', $t->date;
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

A LibUI::DatePicker object represents a control used to enter a date.

All functions operate on C<struct tm> as defined in <time.h> which is wrapped
by C<LibUI::Time>.

All functions assume local time and do NOT perform any time zone conversions.

=head1 Functions

Not a lot here but... well, it's just a simple widget.

=head2 C<new( )>

    my $dt = LibUI::DatePicker->new( );

Creates a new date picker.

=head2 C<onChanged( ... )>

    $date->onChanged(
    sub {
        my ($ctrl, $data) = @_;
        warn $ctrl->time;
    }, undef);

Registers a callback for when the date picker value is changed by the user.

Expected parameters include:

=over

=item C<$callback> - CodeRef that should expect the following:

=over

=item C<$date> - backreference to the instance that initiated the callback

=item C<$data> - user data registered with the sender instance

=back

=item C<$data> - user data to be passed to the callback

=back

Note: The callback is not triggered when calling C<setTime( ... )>.

=head2 C<time( ... )>

    warn scalar $date->time;

Returns date stored in the date picker.

By default, this returns a L<Time::Piece> object.

=head2 C<setTime( ... )>

    $date->setTime( localtime );

Sets date of the date picker.

You may pass a L<Time::Piece> object or a LibUI::Time structure.

=head1 See Also

L<LibUI::TimePicker> - Select a time of day

L<LibUI::DateTimePickerPicker> - Select a calendar date and time

L<LibUI::Time> - Wraps the date/time structure

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

