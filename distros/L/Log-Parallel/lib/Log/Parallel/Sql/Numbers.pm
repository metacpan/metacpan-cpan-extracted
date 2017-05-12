
package Log::Parallel::Sql::Numbers;

use strict;
use warnings;
require Exporter;

our @ISA = qw(Exporter);
our @EXPORT = qw(integer float);

sub integer
{
	my ($n, $default) = @_;
	unless (defined($n) && $n ne 'nan' && $n ne '') {
		return (defined($default) ? $default : -1);
	}
	return int($n);
}

sub float
{
	my ($n, $default) = @_;
	unless (defined($n) && $n ne 'nan' && $n ne '') {
		return (defined($default) ? $default : -9999);
	}
	return 0.0+$n;
}

1;

__END__


=head1 NAME

Log::Parallel::Sql::Numbers - force values to be numbers

=head1 SYNOPSIS

 use Log::Parallel::Sql::Numbers;

 $integer = integer($scalar, $default)

 $float = float($scalar, $default)

=head1 DESCRIPTION

These simple functions make sure that a scalar is in fact a number.
Non-numbers, including C<nan> will be turned into the default.

This is useful if you want to hand an unknown value to a database.

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

