package Enum::Declare::Common::LogLevel;

use 5.014;
use strict;
use warnings;

use Enum::Declare;

enum Level :Type :Export {
	Trace = 0,
	Debug = 1,
	Info  = 2,
	Warn  = 3,
	Error = 4,
	Fatal = 5
};

1;

=head1 NAME

Enum::Declare::Common::LogLevel - Numeric log levels for comparison

=head1 SYNOPSIS

    use Enum::Declare::Common::LogLevel;

    say Trace;  # 0
    say Fatal;  # 5

    # Filter by level
    log($msg) if $level >= Warn;

=head1 ENUMS

=head2 Level :Export

Trace=0, Debug=1, Info=2, Warn=3, Error=4, Fatal=5.
Integer values support numeric comparison.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2026 LNATION. Artistic License 2.0.

=cut
