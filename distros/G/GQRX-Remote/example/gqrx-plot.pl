#!/usr/bin/env perl

use GQRX::Remote;
use Time::HiRes qw( usleep );
use List::Util qw( max );

use strict;
use warnings;


my %OPTIONS = (
    output_file => 'output_data.csv', # CSV output file
    start_frequency => 24000,         # Start scan frequency in kHz
    end_frequency => 1766000,         # End scan frequency in kHz
    demodulator => 'WFM',             # The demodulator to use (step size must matchc)
    step_size => 160,                 # Step size in kHz
    num_samples => 10,                # Number of samples to take per step
    sample_delay => 100               # Delay between taking samples in microseconds
    );


sub get_percentile {
    my ($data, $percentile) = @_;
    my $index = max($percentile * ($#{ $data } + 1) - 1, 0);
    my $rounded_index = int (sprintf("%d", $index + .5));
    my @sorted_data = sort({$a <=> $b} @$data);

    if ($index == $rounded_index) {
        if ($index == $#{ $data }) { # If this is the last item, return that
            return ($sorted_data[$index]);
        }
        else { # Return the average of the index and the item that follows
            return ($sorted_data[$index] + $sorted_data[$index + 1]) / 2;
        }
    }
    else {
	return ($sorted_data[$rounded_index]);
    }
}


sub print_results_row {
    my ($fd, $current_frequency, $results) = @_;
    my ($p75, $p50, $p25) = (get_percentile($results, .75),
                             get_percentile($results, .50),
                             get_percentile($results, .25));

    # Write formatted output to STDOUT
    printf("%-10d 75th=%-2.2f, 50th=%-2.2f, 25th=%-2.2f\n", int($current_frequency / 1000),
           $p75, $p50, $p25);

    # CSV output to the file
    print $fd join(',', int($current_frequency / 1000),
                   $p75, $p50, $p25) . "\n";
}


sub main {
    my $remote = GQRX::Remote->new(exit_on_error => 1);
    my $current_frequency;
    my $fd;

    # Store the frequency options scaled from kHz to Hz
    my $start_frequency = $OPTIONS{start_frequency} * 1000;
    my $end_frequency = $OPTIONS{end_frequency} * 1000;
    my $step_size = $OPTIONS{step_size} * 1000;

    $remote->connect();

    if (! open ($fd, '>', $OPTIONS{output_file})) {
	die "ERROR: Failed to open file '$OPTIONS{output_file}' for writing\n";
    }

    $fd->autoflush(1); # Immediately write to the file
    print $fd join(',', 'Frequency (kHz)', '75th Percentile', 'Median', '25th Percentile') . "\n";

    $remote->set_demodulator_mode($OPTIONS{demodulator});
    $remote->set_frequency($start_frequency);

    # For each frequency in the scan, collect the number of samples and write the results to the CSV
    while (($current_frequency = $remote->get_frequency()) < $end_frequency) {
	my @results = ();
	my $x;

	for ($x = 0; $x < $OPTIONS{num_samples}; $x++) {
	    my $strength = $remote->get_signal_strength();

	    push (@results, $strength);

	    usleep($OPTIONS{sample_delay} * 1000);
	}

        print_results_row($fd, $current_frequency, \@results);

	$remote->set_frequency($current_frequency + $step_size);
    }

    close ($fd);
}


main();
