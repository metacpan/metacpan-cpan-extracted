#!/usr/bin/perl
use strict; use warnings;
use Games::AssaultCube::Log::Line;
use Term::ProgressBar;

# the log directory
my $logdir = 'ac_logs';

# autoflush stdout
$|++;

# get the log files in the directory
opendir( MYDIR, $logdir ) or die "Unable to opendir: $!";
my @entries = readdir( MYDIR );
closedir( MYDIR ) or die "Unable to closedir: $!";

# filter the . and ..
@entries = grep { substr( $_, 0, 1 ) ne '.' } @entries;

# generate statistics on event types
my %event_types;

# start the progress bar!
print "Parsing " . scalar @entries . " logfiles...\n";
my $progress_bar = Term::ProgressBar->new({ name => 'progress', count => scalar @entries, remove => 1, ETA => 'linear', fh => \*STDOUT });
my $current_progress = 1;

# open the logfiles!
foreach my $file ( @entries ) {
	open( my $fh, "<", $logdir . '/' . $file ) or die "Unable to open logfile: $!";
	while ( my $line = <$fh> ) {
		$line =~ s/(?:\n|\r)+//;

		# parse the line!
		my $log = Games::AssaultCube::Log::Line->new( $line );

		# log some events "deeper"
		if ( $log->event eq 'CallVote' ) {
			$event_types{ $log->event . '-' . $log->type }++;
		} else {
			$event_types{ $log->event }++;
		}
	}
	close( $fh ) or die "Unable to close logfile: $!";

	$progress_bar->update( $current_progress++ );
}

# print the most-seen events
print "The events in descending order:\n";
my @biggest = sort { $event_types{$b} <=> $event_types{$a} } keys %event_types;
foreach my $k ( @biggest ) {
	print "\t[$k] -> $event_types{$k}\n";
}
