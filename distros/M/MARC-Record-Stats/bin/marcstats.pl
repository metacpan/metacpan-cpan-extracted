#!/usr/bin/env perl
use warnings;
use strict;

use MARC::Record::Stats;
use MARC::File::USMARC;

use Getopt::Euclid;

my $stats = MARC::Record::Stats->new();

foreach my $fn ( @{ $ARGV{'<file>'} } ) {
	my $batch = MARC::File::USMARC->in( $fn )
		or warn "Can't read the file $fn\n";
	next unless $batch;
	
	while ( my $record = $batch->next() ) {
		$stats->add_record_to_stats($record);
	}
	
	$batch->close();
	undef $batch;
}

my $out;
if ( my $fn = $ARGV{'-o'} ) {
	open $out, ">", "$fn";
}
else {
	$out = *STDOUT
}

my $config = { };
$config->{dots} = $ARGV{'--dots'};
$stats->report($out, $config);

if ( $ARGV{'-o'} ) { close $out; }

__END__
=head1 NAME

marcstats.pl - report statistics on MARC records in batch files

=head1 USAGE

Calculate the frequency rate and the repeatability of tags and subtags
in a number of MARC batch files. 

	marcstats.pl [options] <file>,...

=head1 VERSION

This documentation is for marcstats.pl version 0.0.1

=head1 REQUIRED ARGUMENTS

=over

=item <file>

Name(s) of the MARC batch file(s). Several file names may be given:

	marcstat.pl -o statistics.txt batch1.iso batch2.iso --dots

=for Euclid:
	repeatable

=back

=head1 OPTIONS

=over

=item --dots

Replace spaces with dots in the output

=item -o <outfile>

Send output to outfile. By default output is sent to console (STDOUT)

=back

=cut