#!/usr/bin/perl 

package Log::Parallel::test_log_configs;

use strict;
use warnings;
use Test::More qw(no_plan);
use Log::Parallel::Task;
use Log::Parallel::Task qw(%user_code_defaults %compile_fields);
use Getopt::Long;
use File::Basename;
use Config::YAMLMacros qw(get_config listify);
use Log::Parallel::ConfigCheck;
use YAML::Syck;
use Config::YAMLMacros::YAML;
use Log::Parallel::Parsers;

my $finished = 0;

END { ok($finished, 'finished') }

sub run 
{

	my %opts;
	exit unless GetOptions(
		'config_file|config-file|c=s'		=> \$opts{config_file},
		'test=s'				=> \$opts{test},
		'yaml'					=> \$opts{yaml},
		'job=s'					=> \$opts{job},
	);

	BAIL_OUT("--config_file required") unless $opts{config_file};

	my $config;
	eval { $config = get_config($opts{config_file}) };

	ok(defined $config);
	is("$@", "", "we have a config");

	eval { validate_config($config); };
	is("$@", "", "the config is valid");

	my $cdir = dirname($opts{config_file});

	my %output_readers = (
		tsv		=> sub {
			my ($file, $job, $test, $timeinfo, $opts) = @_;
			open my $fh, "<", $file || die "open $file: $!";
			my $header = <$fh>;
			chomp($header);
			my @cols = split("\t", $header);
			return sub {
				my $line = <$fh>;
				chomp($line);
				my %ret;
				@ret{@cols} = split("\t", $line, -1);
				return \%ret;
			};
		},
		yml		=> sub {
			my ($file, $job, $test, $timeinfo, $opts) = @_;
			my @r = LoadFile($file);
			if (@r == 1 && ref($r[0]) eq 'ARRAY') {
				@r = @{$r[0]};
			}
			@r = reverse(@r);
			return sub {
				pop @r;
			};
		},
	);


	JOB:
	for my $job (@{$config->{jobs}}) {
		next if $job->{DISABLED};
		next unless $job->{tests};
		next unless @{$job->{tests}};
		next if $opts{job} && $opts{job} ne $job->{name};
		for my $test (@{$job->{tests}}) {
			next if $opts{test} && $test ne $opts{test};

			my $timeinfo = {
				YYYY	=> 2000,
				MM	=> '01',
				DD	=> '01',
			};

			my $opts = {};

			my $input_stream;
			eval { 
				$input_stream = get_input($job, $test, $timeinfo, $opts);
			};
			is($@, "", "we have inputs for $test for $job->{name}");
			next if $@;

			my $output_stream;
			eval { 
				$output_stream = get_output($job, $test, $timeinfo, $opts);
			};
			is($@, "", "we have expected outputs for $test for $job->{name}");
			next if $@;

			my %code;
			undef $@;
			for my $field (keys %Log::Parallel::Task::compile_fields) {
				my ($s, $eval) = compile_user_code($job, $timeinfo, $field, {}, '', {}, mode => 'test');
				my $e;
				$e = "$@:\nEVAL:\n$eval" if $@;
				is($@, "", "compile $field for $job->{name}");
				next JOB if $@;
				$code{$field} = $s;
			}

			$code{grouper} = grouper_wrap($code{grouper}) if $job->{grouper};

			my $c = 0;
			my $d = 0;
			while (my $input = $input_stream->()) {
				eval {
					if (defined $input) {
						return unless $code{filter}->($input);
					}
					for my $output ($code{transform}->($code{grouper}->($input))) {
						my $reference = $output_stream->();
						diag Dump($output) if $opts{yaml};
						is_deeply($output, $reference, "result $c from $job->{name} $test");
						my $bucket_data;
						$bucket_data = $code{bucketizer}->($output) if defined $output;
						$c++;
					}
				};
				is($@, "", "process input $d for $job->{name} $test");
				$d++;
			}
			eval {
				for my $output ($code{transform}->($code{grouper}->(undef))) {
					my $reference = $output_stream->();
					diag Dump($output) if $opts{yaml};
					is_deeply($output, $reference, "result $c (final) from $job->{name} $test");
					my $bucket_data;
					$bucket_data = $code{bucketizer}->($output) if defined $output;
					$c++;
				}
			};
			is($@, "", "process eof for $job->{name} $test");
			my $o = $output_stream->();
			is(undef, $o, "remaining reference outputs for $job->{name} $test");
		}
	}

	$finished = 1;

	sub get_input
	{
		my ($job, $test, $timeinfo, $opts) = @_;
		$test =~ m/\.([^\.]+)$/ or die "need a suffix for $test";
		my $suffix = $1;
		open my $fh, "<", "$cdir/$test" 
			or die "open $cdir/$test: $!";
		my $p;
		if ($suffix eq 'tsv') {
			my $header = <$fh>;
			chomp($header);
			my @cols = split("\t", $header);
			return sub {
				my $line = <$fh>;
				return undef unless $line;
				chomp($line);
				my %ret;
				@ret{@cols} = split("\t", $line, -1);
				return \%ret;
			};
		} else {
			my $header;
			$header = LoadFile("$cdir/$test.header") if -e "$cdir/$test.header";
			$header ||= {};
			eval { $p = get_parser($suffix, $fh, sorted_by => $header->{sort_by} || [], filename => "$cdir/$test", header => $header) }; 
			if ($@) {
				if ($@ ne "no such parser '$suffix'\n") {
					die "Error when trying to get parser for $suffix: $@";
				}
			} elsif ($p) {
				return $p;
			}
			die "don't know how to handle the .$suffix suffix";
		}
	}

	sub get_output
	{
		my ($job, $test, $timeinfo, $opts) = @_;
		$test =~ m/(.*)\.[^\.]+$/ or die "need a suffix for $test";
		my $base = $1;

		for my $suffix (keys %output_readers) {
			next unless -e "$cdir/$base.expected.$suffix";
			return $output_readers{$suffix}->("$cdir/$base.expected.$suffix", $job, $test, $timeinfo, $opts);
		}
		die "Could not find reference output";
	}
}

__END__

=head1 NAME

test_log_config - run regression tests against log processing steps

=head1 OPTIONS

 test_log_config [Options] -c config_file

 --config_file -c	Specifies the log configuration file
 --test TESTNAME	Specifies a particular test input file to process
 --job STEPNAME		Specifies a particular log processing step to test
 --yaml			Show the generated data in YAML format

=head1 DESCRIPTION

This program provides a way to write regression tests for your log processing
configurations.   It's part of the L<Log::Parallel> framework.
The output from C<test_log_config> is in Test Anything Protocol (TAP).

To write a I<test> for a log processing step, you just need to provide
an example input data file and a reference output data file.

Inputs can either be in one of the formats supported by the log processing
system, or they can be in a regular Tab Separated Values (TSV) file.  The
file suffix will determine the parser used to read the input.   Use
C<.tsv> for TSV files and C<.ParserName> for files that should be read by
I<ParserName>.

The reference output must be in either YAML or TSV.  

Tests are specified by having a C<tests> array in the log job configuration.
The elements of the array are the input files for the test.  Relative paths
start with the same directory as the configuration file.   

Expected output files are named by adding C<.execpected.yml> or C<.expected.tsv>
to the input file name.

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

