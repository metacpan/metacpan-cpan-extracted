#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

use Digest::MD5;
use XML::Parser;
use bytes;
use YAML;

autoflush(\*STDOUT);
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $testdir = shift(@ARGV);
my $datadir = shift(@ARGV);
my $iterations = shift(@ARGV);
my $output = shift(@ARGV);

if (! defined($output)) {
	$output = 'results.data';
}

my $log = 'results.log';
my @all_iterations;

if (! defined($datadir)) {
	print STDERR "Usage: $0 <directory full of tests> <directory full of test data> [number of iterations]\n";
	exit(1);
}

if (! defined($iterations)) {
	$iterations = 1;
}

my ($datafh, $logfh);
die "could not open $output: $!" unless open($datafh, "> $output");
die "could not open log: $!" unless open($logfh, "> $log");
autoflush($logfh);

while($iterations--) {
	print "Iterations remaining: ", $iterations + 1, "\n";
	
	foreach my $data (get_contents($datadir)) {
		my $data_path = $data;
		my %report;
		my $md5;
		my $len;
		
		print "Benchmarking $data\n";
		
		$report{tests} = [];
		
		$report{filename} = $data;
		$report{size} = filesize($data_path);
		
		print "Generating md5sum: ";
		($len, $md5) = get_md5sum($data_path);
		
		$report{markup_density} = 	1 - ($len / $report{size});
		$report{md5sum} = $md5;
		
		print "$md5\n";
		
		print "Markup density: ", $report{markup_density}, "\n";
		
		foreach my $test (get_contents($testdir)) {
			my $command = "$test $data_path";
			my $start_time = time;
			
			print "running $command: ";
			my %results = bench($command);
			print time - $start_time, " seconds ";
			
			if (! defined($results{fail_reason}) && (! defined($md5) || $results{md5sum} ne $md5)) {
				$results{failed} = 1;
				$results{fail_reason} = "md5sum mismatch";
			}
			
			if ($results{failed}) {
				print "FAILED ";
			}
			
			print "\n";
			
			push(@{$report{tests}}, { name => $test, %results });		
		}
	
		my @rankings = make_rankings(%report);
		
		$report{tests} = \@rankings;
		
		print $logfh Dump(\%report);
		push(@all_iterations, \%report);
		
	}
}

print $datafh Dump(\@all_iterations) or die "could not save results to $output: $!";

sub bench {
	my ($command) = @_;	
	my ($read, $write);
	my ($child, $result);
	my ($cuser, $csys, $md5);
	my %results;
	
	pipe($read, $write);
#	autoflush($write);

	$child = fork();
	
	if ($child == 0) {
		bench_child($command, $write);
		die "child should exit";
	}

	$result = <$read>;
	
	waitpid($child, 0) or die "could not waitpid($child, 0)";

	($cuser, $csys, $md5) = parse_result($result);

	if (defined($cuser)) {
		$results{runtimes}->{system} = $csys;
		$results{runtimes}->{user} = $cuser;
		$results{runtimes}->{total} = $csys + $cuser;
		$results{md5sum} = $md5;
	} else {
		$results{failed} = 1;
		$results{fail_reason} = "benchmark execution error";
	}
	
	return %results;
}

sub bench_child {
	my ($command, $write) = @_;
	my $md5 = Digest::MD5->new;
	my ($child_user, $child_sys);
	my $fh;
	
	open($fh, "$command |") or die "could not execute $command for reading";
	
	while(<$fh>) {
		$md5->add($_);
	}
	
	if (! close($fh)) {
		print STDERR "FAILED ";
		print $write "FAILED\n";
		exit(1);
	} 

	if ($? >> 8) {
		print STDERR "FAILED ";
		print $write "FAILED\n";
		exit(1);
	}

	(undef, undef, $child_user, $child_sys) = times;

	print $write "$child_user $child_sys ", $md5->hexdigest, "\n" or die "could not write to pipe: $!";

	exit(0);
}

sub autoflush {
	my ($fh) = @_;
	my $old = select($fh);
	
	$| = 1;
	print '';
	
	select($old);
	
	return;
}

sub parse_result {
	my ($text) = @_;
	
	if ($text !~ m/^([0-9.]+) ([0-9.]+) (.+)/) {
		return();
	}
	
	return ($1, $2, $3);
}

sub filesize {
	my ($file) = @_;
	my @stat = stat($file);
	
	return $stat[7];
}

sub get_contents {
	my ($dir) = @_;
	my @contents;
	
	if (-f $dir) {
		return ($dir);
	}
	
	die "could not open $dir: $!" unless opendir(DIR, $dir);

	foreach (sort(readdir(DIR))) {
		next if m/^\./;
		#next unless m/\.t$/;
		push(@contents, $dir . '/' . $_);
	}

	closedir(DIR);
	
	return @contents;
}

sub get_md5sum {
	my ($file) = @_;
	my $command;
	my $md5 = Digest::MD5->new;
	my $fh;
	my $prog;
	my $len;
	
	if (-x "bin/libxml") {
		$prog = 'test_cases/libxml.t';
	} else {
		$prog = 'test_cases/XML-CompactTree-XS.t';
	}

	
	$command = "$prog $file";
	
	open($fh, "$command |") or die "could not execute $command for reading";
	
	while(<$fh>) {
		$md5->add($_);
		$len += bytes::length($_);
	}
	
	close($fh) or die "could not close $command";

	if ($? >> 8) {
		die "could not generate md5sum";
	}	
	
	return ($len, $md5->hexdigest);
}


sub make_rankings {
	my (%data) = @_;
	my @tests = sort_tests($data{tests});	
	my $fastest = $tests[0]->{runtimes}->{total};
	my $size = $data{size};
	
	if (! defined($fastest) || $fastest == 0) {
		die "no successful tests were run";
	}
	
	foreach (@tests) {
		my $total = $_->{runtimes}->{total};
		
		next unless defined $total;
		
		$_->{'MiB/sec'} = $size / $total / 1024 / 1024;
		$_->{percentage} = int($total / $fastest * 100);
	}	

	return @tests;
}

sub sort_tests {
	return sort({ 
		if ($a->{failed}) {
			return 1;
		} elsif ($b->{failed}) {
			return -1;
		}
		
		$a->{runtimes}->{total} <=> $b->{runtimes}->{total} } @{$_[0]}
	);
}
