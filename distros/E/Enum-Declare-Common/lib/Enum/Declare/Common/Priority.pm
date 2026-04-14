package Enum::Declare::Common::Priority;

use 5.014;
use strict;
use warnings;

use Enum::Declare;

enum Level :Type :Export {
	Lowest  = 1,
	Low     = 2,
	Medium  = 3,
	High    = 4,
	Highest = 5
};

enum Severity :Str :Type :Export {
	Debug    = "debug",
	Info     = "info",
	Warning  = "warning",
	Error    = "error",
	Critical = "critical"
};

1;

=head1 NAME

Enum::Declare::Common::Priority - Priority levels and severity strings

=head1 SYNOPSIS

    use Enum::Declare::Common::Priority;

    say Medium;    # 3
    say Highest;   # 5
    say Critical;  # "critical"
    say Debug;     # "debug"

    # Compare levels numerically
    if ($priority >= High) { ... }

=head1 ENUMS

=head2 Level :Export

Lowest=1, Low=2, Medium=3, High=4, Highest=5.

=head2 Severity :Str :Export

Debug="debug", Info="info", Warning="warning", Error="error",
Critical="critical".

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 LNATION. Artistic License 2.0.

=cut
