package LibUI::DateTimePicker 0.01 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'LibUI::Control';
    use LibUI::Time;
    #
    affix(
        LibUI::lib(), 'uiNewDateTimePicker', [Void] => InstanceOf ['LibUI::DateTimePicker'],
        'new'
    );
    affix(
        LibUI::lib(),
        'uiDateTimePickerOnChanged',
        [   InstanceOf ['LibUI::DateTimePicker'],
            CodeRef [ [ InstanceOf ['LibUI::DateTimePicker'], Any ] => Void ], Any
        ] => Void,
        'onChanged'
    );

    sub setTime ($$) {
        my ( $s, $time ) = @_;
        CORE::state $affix //= wrap( LibUI::lib(), 'uiDateTimePickerSetTime',
            [ InstanceOf ['LibUI::DateTimePicker'], Pointer [LibUI::Time] ] => Void );
        $time = LibUI::Time::to_hash($time) unless ref $time eq 'HASH';
        $affix->( $s, $time );
    }

    sub time {
        CORE::state $affix //= wrap( LibUI::lib(), 'uiDateTimePickerTime',
            [ InstanceOf ['LibUI::DateTimePicker'], Pointer [LibUI::Time] ] => Void );
        my $ret;
        $affix->( shift, $ret );
        LibUI::Time::to_obj($ret);
    }
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::DateTimePicker - Control to Enter a Date and Time

=head1 SYNOPSIS

    use LibUI ':all';
    use LibUI::VBox;
    use LibUI::Window;
    use LibUI::DateTimePicker;
    use Time::Piece;
    Init( { Size => 1024 } ) && die;
    my $window = LibUI::Window->new( 'Schedule an Event', 320, 100, 0 );
    my $box    = LibUI::VBox->new();
    my $date   = LibUI::DateTimePicker->new();
    $box->append( $date, 0 );
    $date->setTime( localtime->add_months(3) );
    $date->onChanged(
        sub {
            my $picker = shift;
            my $t      = $picker->time;
            warn sprintf 'Setting an appointment for %s at %s', $t->time, $t->date;
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

A LibUI::DateTimePicker object represents a control used to enter a date and
time.

All functions operate on C<struct tm> as defined in <time.h> which is wrapped
by C<LibUI::Time>.

All functions assume local time and do NOT perform any time zone conversions.

=head1 Functions

Not a lot here but... well, it's just a simple widget.

=head2 C<new( )>

    my $dt = LibUI::DateTimePicker->new( );

Creates a new date and time picker.

=head2 C<onChanged( ... )>

    $date->onChanged(
    sub {
        my ($ctrl, $data) = @_;
        warn $ctrl->time;
    }, undef);

Registers a callback for when the date time picker value is changed by the
user.

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

Returns date and time stored in the date time picker.

By default, this returns a L<Time::Piece> object.

=head2 C<setTime( ... )>

    $date->setTime( localtime );

Sets date and time of the data time picker.

You may pass a L<Time::Piece> object or a LibUI::Time structure.

=head1 See Also

L<LibUI::TimePicker> - Select a time of day

L<LibUI::DatePicker> - Select a calendar date

L<LibUI::Time> - Wraps the date/time structure

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

