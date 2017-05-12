package Frost::TestSystem;

use strict;
use warnings;

package main;

use strict;
use warnings;

my ( $INFO, @INFO, $CPU_NAME, $CPU_SPEED, $RAM_SIZE, $PERL_VERSION );

{
	no warnings;

	$INFO	= `/bin/cat /proc/cpuinfo`;
	@INFO	= split /\n/, $INFO;

	for ( @INFO )
	{
		if ( m/^model name\s+:\s+(.+)$/i )
		{
			$CPU_NAME	= $1;
		}

		if ( m/^cpu MHz\s+:\s+(.+)$/i )
		{
			$CPU_SPEED	= $1;
			$CPU_SPEED	= sprintf ( '%4.1f', $CPU_SPEED / 1000 );		#	GHz
		}
	}

	$INFO	= `/bin/cat /proc/meminfo`;
	@INFO	= split /\n/, $INFO;

	for ( @INFO )
	{
		if ( m/^MemTotal:\s+(\d+)/i )
		{
			$RAM_SIZE	= $1;
			$RAM_SIZE	= sprintf ( '%5d', $RAM_SIZE / 1024 );		#	MB
		}
	}

	$PERL_VERSION	= sprintf "v%vd", $^V;
	$PERL_VERSION	= sprintf "%-8s", $PERL_VERSION;

	$CPU_NAME		||= 'undef';
	$CPU_SPEED		||= 'undef';
	$RAM_SIZE		||= 0;
	$PERL_VERSION	||= 'undef';
}

sub TF_CPU_NAME	()	{ $CPU_NAME		}
sub TF_CPU_SPEED	()	{ $CPU_SPEED	}
sub TF_RAM_SIZE	()	{ $RAM_SIZE		}

sub TF_RAM_FREE	()
{
	no warnings;

	$INFO	= `/bin/cat /proc/meminfo`;
	@INFO	= split /\n/, $INFO;

	my $free;

	for ( @INFO )
	{
		if ( m/^MemFree:\s+(\d+)/i )
		{
			$free	= $1;
			$free	= sprintf ( '%5d', $free / 1024 );		#	MB
		}
	}

	defined $free		or return - TF_RAM_SIZE;

	$free;
}

sub TF_RAM_USED	()
{
	TF_RAM_SIZE - TF_RAM_FREE;
}

sub TF_PERL_VERSION	()	{ $PERL_VERSION }

sub TF_DISK_SPEED	()
{
	my $size			= 256;			#	MB
	my $filename	= '/tmp/frost_test_speed';

	my $chunk		= ( 'X' x 1023 ) . "\n";

	my $max_chunk	= $size * 1024;

	my ( $success, $t0, $t1, $t2, $td, $mb_sec );

	unlink $filename		if -e $filename;

	$success	= open SPEED_TEST, ">$filename";

	if ( $success )
	{
		my $oldfh = select(SPEED_TEST); $| = 1; select($oldfh);	#	unbuffer

		$t0		= Time::HiRes::gettimeofday();

		for ( my $i = 0; $i < $max_chunk; $i++ )
		{
			last		unless $success;

			$success	= print SPEED_TEST $chunk;
		}

		$success	= close SPEED_TEST			if $success;
	}

	if ( $success )
	{
		$t1		= Time::HiRes::gettimeofday() - $t0;

#		print STDERR "\n-----> WRITE $size MB $t1\n";
	}

	$success	= open SPEED_TEST, "<$filename";

	if ( $success )
	{
		my $oldfh = select(SPEED_TEST); $| = 1; select($oldfh);	#	unbuffer

		for ( my $i = 0; $i < $max_chunk; $i++ )
		{
			last		unless $success;

			$success	= <SPEED_TEST>;
		}

		$success	= close SPEED_TEST			if $success;
	}

	if ( $success )
	{
		$t2		= Time::HiRes::gettimeofday() - $t0 - $t1;

#		print STDERR "-----> READ  $size MB $t2\n";
	}

	if ( $success )
	{
		my $write_mb_sec	= $t1 > 0 ? int ( $size / $t1 ) : -1;
		my $read_mb_sec	= $t2 > 0 ? int ( $size / $t2 ) : -1;

#		print STDERR "-----> WRITE $write_mb_sec MB\n";
#		print STDERR "-----> READ  $read_mb_sec MB\n";

		$mb_sec	= int ( ( $write_mb_sec + $read_mb_sec ) / 2 );

#		print STDERR "-----> I/O   $mb_sec MB\n";
	}
	else
	{
		$mb_sec	= -2;
	}

	unlink $filename		if -e $filename;

	return $mb_sec;
}

1;

__END__

