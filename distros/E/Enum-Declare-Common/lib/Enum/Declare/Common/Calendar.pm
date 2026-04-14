package Enum::Declare::Common::Calendar;

use 5.014;
use strict;
use warnings;

use Enum::Declare;

# ── Weekday (ISO 8601: Monday=1 .. Sunday=7) ──

enum Weekday :Type :Export {
	Monday    = 1,
	Tuesday   = 2,
	Wednesday = 3,
	Thursday  = 4,
	Friday    = 5,
	Saturday  = 6,
	Sunday    = 7
};

# ── WeekdayFlag (bitmask for scheduling) ──

enum WeekdayFlag :Flags :Type :Export {
	Mon,
	Tue,
	Wed,
	Thu,
	Fri,
	Sat,
	Sun
};

# ── Month (January=1 .. December=12) ──

enum Month :Type :Export {
	January   = 1,
	February  = 2,
	March     = 3,
	April     = 4,
	May       = 5,
	June      = 6,
	July      = 7,
	August    = 8,
	September = 9,
	October   = 10,
	November  = 11,
	December  = 12
};

1;

=head1 NAME

Enum::Declare::Common::Calendar - Weekday, weekday flags, and month enums

=head1 SYNOPSIS

    use Enum::Declare::Common::Calendar;

    say Monday;    # 1
    say January;   # 1
    say December;  # 12

    # Bitmask scheduling
    my $weekdays = Mon | Tue | Wed | Thu | Fri;  # 31
    ok($weekdays & Mon);  # true

=head1 ENUMS

=head2 Weekday :Export

ISO 8601 weekdays: Monday=1 through Sunday=7.

=head2 WeekdayFlag :Flags :Export

Bitmask flags: Mon=1, Tue=2, Wed=4, Thu=8, Fri=16, Sat=32, Sun=64.

=head2 Month :Export

Months: January=1 through December=12.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 LNATION. Artistic License 2.0.

=cut
