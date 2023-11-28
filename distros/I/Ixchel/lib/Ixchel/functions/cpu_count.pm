package Ixchel::functions::cpu_count;

use 5.006;
use strict;
use warnings;
use File::Slurp;
use Exporter 'import';
our @EXPORT = qw(cpu_count);

=head1 NAME

Ixchel::functions::cpu_count - Gets a count of processors

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Ixchel::functions::cpu_count;

    print 'CPU count: '.cpu_count."\n";

=head1 Functions

=head2 cpu_count

Returns CPU count starting from 1.

Supported OSes...

    FreeBSD
    Linux

=cut

sub cpu_count {
	my $count;

	if ( $^O eq 'freebsd' ) {
		my $output=`/sbin/sysctl -n kern.smp.cpus`;
		chomp($output);
		$count=$output;
	} elsif ( $^O eq 'linux' ) {
		eval{
			my $proc_info=read_file('/proc/cpuinfo');
			my @proc_split=split(/\n/, $proc_info);
			my @procs=grep(/^processor.*\:.*\d/, @proc_split);
			$count=$#procs;

			# arrays index from zero, so add one to it
			$count++;
		};
	}else {
		die('"'.$^O.'" is not a supported OS as of currently');
	}

	return $count;
}

1;    # End of Ixchel::functions::cpu_count
