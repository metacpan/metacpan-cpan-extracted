
package Log::Parallel::Misc;

use strict;
use warnings;
use Time::JulianDay;
require Exporter;
use Carp qw(confess);

our @ISA = qw(Exporter);
our @EXPORT = qw(jd_data);
our @EXPORT_OK = (@EXPORT, qw(monitor_free_space));

my $min_jd = julian_day(1970,1,1);

sub monitor_free_space
{
	my ($min) = @_;
	my $free = `free`;
	$free =~ m{buffers/cache:\s+\d+\s+(\d+)}s;
	my $mem = $1;
	$free =~ m{Swap:\s+\d+\s+\d+\s+(\d+)}s;
	my $swap = $1;
	if ($mem + $swap < $min) {
		print STDERR "DIE DIE DIE DIE: runnin out of memory:\n$free\n";
		exit 1;
	}
	return $mem + $swap;
}

sub jd_data
{
	my ($jd) = @_;
	my ($y, $m, $d) = inverse_julian_day($jd);
	confess "date too early: $y-$m-$d ($jd)" unless $jd >= $min_jd;
	return (
		YYYY	=> $y,
		MM	=> $m,
		DD	=> $d,
	);
}

1;

__END__

=head1 DESCRIPTION

These are support routines for L<Log::Parallel>.

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

