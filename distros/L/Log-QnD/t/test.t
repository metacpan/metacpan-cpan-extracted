#!/usr/bin/perl -w
use strict;
use lib '../../';
# BEGIN {unless($ENV{'clear_done'}){system '/usr/bin/clear'}} # NODIST
use Log::QnD;
use Test;
use FileHandle;
use Carp 'croak';
use String::Util ':all';

# debugging
# use Debug::ShowStuff ':all';
# use Debug::ShowStuff::ShowVar;

# plan tests
BEGIN { plan tests => 45 };

# path to log file
my $log_path =  './qnd.log';


#------------------------------------------------------------------------------
## cannot get log object w/o path param
#
if (1) { ##i
	my ($log, $success);
	
	# get log object w/o path param
	eval {
		$log = Log::QnD::LogFile->new();
		$success = 1;
	};
	
	# should not have been successful in getting log object
	ok(! $success);
	ok(! $log);
}
#
# cannot get log object w/o path param
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
## log object
#
if (1) { ##i
	my ($log, @vals_org, $raw_log, @vals_logged);
	
	# delete log file if it exists
	delete_log_file();
	
	# generate random values
	foreach (1..3) {
		$vals_org[@vals_org] = randword(5);
	}
	
	# get log object
	$log = Log::QnD::LogFile->new($log_path);
	
	## should have been successful in getting log object
	ok($log);
	ok($log->{'path'} eq $log_path);
	
	## write to log file
	foreach my $val (@vals_org) {
		$log->write_entry($val);
	}
	
	# get contents of log
	$raw_log = slurp($log_path);
	
	# split into entries
	@vals_logged = split(m|\s+|, $raw_log);
	
	## compare values
	for (my $idx = 0; $idx < @vals_org; $idx++) {
		ok($vals_logged[$idx] eq $vals_org[$idx]);
	}
}
#
# log object
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
## log entry must have path
#
if (1) { ##i
	my ($qnd, $success);
	
	# get log entry object w/o path param
	eval {
		$qnd = Log::QnD->new();
		$success = 1;
	};
	
	# should not have been successful in getting log object
	ok(! $success);
	ok(! $qnd);
}
#
# log entry must have path
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
## log entry
#
if (1) { ##i
	my ($qnd, $private);
	
	# delete log file if it exists
	delete_log_file();
	
	# get log object
	$qnd = Log::QnD->new($log_path);
	ok($qnd);
	
	# get private hash
	$private = $qnd->private;
	ok($private);
	
	# should have path
	ok($private->{'path'} eq $log_path);
	
	# autosave should be true
	ok($private->{'autosave'});
}
#
# log entry
#------------------------------------------------------------------------------



#------------------------------------------------------------------------------
## $qnd->save
#
if (1) { ##i
	my ($qnd, $private, $log, $from_log);
	
	# delete log file if it exists
	delete_log_file();
	
	# get log object
	$qnd = Log::QnD->new($log_path);
	
	# add entry with newline
	$qnd->{'rand'} = randword(3) . "\n" . randword(3);
	
	# save
	$qnd->save();
	
	# get log object
	$log = Log::QnD::LogFile->new($log_path);
	
	# get log entry
	$from_log = $log->read_backward();
	ok($from_log);
	
	# compare
	compare_entries($qnd, $from_log);
}
#
# $qnd->save
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
## auto_save
#
if (1) { ##i
	my ($qnd, $org, $private, $log, $from_log);
	
	# delete log file if it exists
	delete_log_file();
	
	# get log object
	$qnd = Log::QnD->new($log_path);
	$org = {};
	
	# add entry with newline
	$qnd->{'rand'} = randword(3) . "\n" . randword(3);
	
	# hold on to values in $qnd
	foreach my $key (keys %$qnd) {
		$org->{$key} = $qnd->{$key};
	}
	
	# undef log entry
	undef($qnd);
	
	# get log object
	$log = Log::QnD::LogFile->new($log_path);
	
	# get log entry
	$from_log = $log->read_backward();
	ok($from_log);
	
	# compare
	compare_entries($org, $from_log);
}
#
# auto_save
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
## cancel
#
if (1) { ##i
	my ($qnd, $org, $private, $log, $from_log);
	
	# delete log file if it exists
	delete_log_file();
	
	# get log object
	$qnd = Log::QnD->new($log_path);
	$org = {};
	
	# add entry with newline
	$qnd->{'rand'} = randword(3) . "\n" . randword(3);
	
	# hold on to values in $qnd
	foreach my $key (keys %$qnd) {
		$org->{$key} = $qnd->{$key};
	}
	
	# cancel save
	$qnd->cancel();
	
	# undef log entry
	undef($qnd);
	
	# get log object
	$log = Log::QnD::LogFile->new($log_path);
	
	# get log entry
	$from_log = $log->read_backward();
	
	# should not get entry
	ok(! $from_log);
}
#
# cancel
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
## uncancel
#
if (1) { ##i
	my ($qnd, $org, $private, $log, $from_log);
	
	# delete log file if it exists
	delete_log_file();
	
	# get log object
	$qnd = Log::QnD->new($log_path);
	$org = {};
	
	# add entry with newline
	$qnd->{'rand'} = randword(3) . "\n" . randword(3);
	
	# hold on to values in $qnd
	foreach my $key (keys %$qnd) {
		$org->{$key} = $qnd->{$key};
	}
	
	# cancel
	$qnd->cancel();
	
	# uncancel
	$qnd->uncancel();
	
	# undef log entry
	undef($qnd);
	
	# get log object
	$log = Log::QnD::LogFile->new($log_path);
	
	# get log entry
	$from_log = $log->read_backward();
	ok($from_log);
	
	# compare
	compare_entries($org, $from_log);
}
#
# uncancel
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
## read_backward()
#
if (1) { ##i
	my ($log, @ids);
	
	# delete log file if it exists
	delete_log_file();
	
	# create several log entries, holding on to the first id
	for (1..5) {
		my $qnd = Log::QnD->new($log_path);
		push @ids, $qnd->{'entry_id'};
	}
	
	# reverse entries so latest is first
	@ids = reverse(@ids);
	
	# get log object
	$log = Log::QnD::LogFile->new($log_path);
	
	# read backward
	do {
		foreach my $id (@ids) {
			my $entry = $log->read_backward();
			ok($entry->{'entry_id'} eq $id);
		}
	};
}
#
# read_backward()
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
## read_backward(entry_id=>$id)
#
if (1) { ##i
	my ($entry_id, $log, $entry);
	
	# delete log file if it exists
	delete_log_file();
	
	# create several log entries, holding on to the first id
	for (1..5) {
		my $qnd = Log::QnD->new($log_path);
		
		if (! $entry_id)
			{ $entry_id = $qnd->{'entry_id'} }
	}
	
	# get log object
	$log = Log::QnD::LogFile->new($log_path);
	
	# get entry by id
	$entry = $log->read_backward(entry_id=>$entry_id);
	ok($entry_id eq $entry->{'entry_id'});
	ok(! $log->{'read'});
	
	# attempt to get non-existent log entry
	$entry = $log->read_backward(entry_id=>'sdfsadf');
	ok(! $entry);
	ok(! $log->{'read'});
}
#
# read_backward(entry_id=>$id)
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
## read_forward()
#
if (1) { ##i
	my ($log, @ids);
	
	# delete log file if it exists
	delete_log_file();
	
	# create several log entries, holding on to the first id
	for (1..5) {
		my $qnd = Log::QnD->new($log_path);
		push @ids, $qnd->{'entry_id'};
	}
	
	# get log object
	$log = Log::QnD::LogFile->new($log_path);
	
	# read backward
	do {
		foreach my $id (@ids) {
			my $entry = $log->read_forward();
			ok($entry->{'entry_id'} eq $id);
		}
	};
}
#
# read_forward()
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
## read_forward(count=>$c)
#
if (1) {
	my ($counts, $log, @ids);
	
	# configure
	$counts = {};
	$counts->{'should'} = 100;
	
	# delete log file if it exists
	delete_log_file();
	
	# generate entries
	foreach (1..$counts->{'should'}) {
		my $qnd = Log::QnD->new($log_path);
		$ids[@ids] = $qnd->{'entry_id'};
	}
	
	# get log object
	$log = Log::QnD::LogFile->new($log_path);
	
	# get count of log entries
	$counts->{'is'} = $log->entry_count();
	
	# read in batches of 5
	LOG_LOOP: {
		while (my @entries = $log->read_forward(count=>5)) {
			while (my $entry = shift(@entries)) {
				my $id = shift(@ids);
				unless ($id and ($entry->{'entry_id'} eq $id)) {
					ok(0);
					last LOG_LOOP;
				}
			}
		}
		
		# should be no more @ids
		if (@ids)
			{ ok(0) }
		
		# else ok
		else
			{ ok(1) }
	}
}
#
# read_forward(count=>$c)
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
## read_backward(count=>$c)
#
if (1) {
	my ($log, @ids);
	
	# delete log file if it exists
	delete_log_file();
	
	# generate entries
	foreach (1..30) {
		my $qnd = Log::QnD->new($log_path);
		$ids[@ids] = $qnd->{'entry_id'};
	}
	
	# reverse ids because we're reading the log file backward
	@ids = reverse(@ids);
	
	# get log object
	$log = Log::QnD::LogFile->new($log_path);
	
	# read in batches of 5
	LOG_LOOP: {
		while (my @entries = $log->read_backward(count=>5)) {
			while (my $entry = shift(@entries)) {
				my $id = shift(@ids);
				unless ($id and ($entry->{'entry_id'} eq $id)) {
					ok(0);
					last LOG_LOOP;
				}
			}
		}
		
		# should be no more @ids
		if (@ids)
			{ ok(0) }
		
		# else ok
		else
			{ ok(1) }
	}
}
#
# read_backward(count=>$c)
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
## catch_stderr
#
if (1) {
	my ($qnd, $rnd, $log, $entry);
	
	# generate random value
	$rnd = rand();
	
	# delete log file if it exists
	delete_log_file();
	
	# get log object
	$qnd = Log::QnD->new($log_path);
	
	# hold on to stderr
	$qnd->catch_stderr();
	
	# output to stderr
	print STDERR $rnd;
	
	# undef log entry object
	undef $qnd;
	
	# get log object
	$log = Log::QnD::LogFile->new($log_path);
	
	# get log entry
	$entry = $log->read_backward();
	
	# compare random value to log entry
	ok($rnd eq $entry->{'stderr'});
}
#
# catch_stderr
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
## entry_count returns undef for non-existent log file
#
if (1) {
	my ($log);
	
	# delete log file if it exists
	delete_log_file();
	
	# get log object
	$log = Log::QnD::LogFile->new($log_path);
	
	# compare counts
	ok(! defined $log->entry_count());
}
#
# entry_count returns undef for non-existent log file
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
## entry_count
#
if (1) {
	my ($counts, $log);
	
	# configure
	$counts = {};
	$counts->{'should'} = 100;
	
	# delete log file if it exists
	delete_log_file();
	
	# generate entries
	foreach (1..$counts->{'should'}) {
		my $qnd = Log::QnD->new($log_path);
	}
	
	# get log object
	$log = Log::QnD::LogFile->new($log_path);
	
	# get count of log entries
	$counts->{'is'} = $log->entry_count();
	
	# compare counts
	ok($counts->{'is'} == $counts->{'should'});
}
#
# entry_count
#------------------------------------------------------------------------------


# clean up
delete_log_file();


### utility functions #########################################################



#------------------------------------------------------------------------------
# delete_log_file
#
sub delete_log_file {
	if (-e $log_path)
		{ unlink($log_path) or die $! }
}
#
# delete_log_file
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# compare_entries
#
sub compare_entries {
	my ($a, $b) = @_;
	
	ok($a->{'entry_id'} eq $b->{'entry_id'});
	ok($a->{'time'} eq $b->{'time'});
	ok($a->{'rand'} eq $b->{'rand'});
}
#
# compare_entries
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
# slurp
#
sub slurp {
	my ($path, %opts)=@_;
	my ($chunk, $fh, @rv, $max, $stdout, $stderr, $out, $total);
	$total = 0;
	
	# don't slurp in more than this amount
	# default is 100K
	if (defined $opts{'max'})
		{ $max = $opts{'max'} }
	else
		{ $max = 102400 }
	
	# attempt to open
	unless ($fh = FileHandle->new($path)){
		$opts{'quiet'} and return undef;
		croak "slurp: could not open file [$path] for reading: $!";
	}
	
	$fh->binmode($fh) if $opts{'bin'};
	
	# slurp in everything
	CHUNKLOOP:
	while (read $fh, $chunk, 1024) {
		push @rv, $chunk;
		$total += length($chunk);
		
		# output to stdout and|or stderr
		if ($stdout)
			{ print STDOUT $chunk }
		if ($stderr)
			{ print STDERR $chunk }
		
		if ( $max && ($total > $max) ) {
			if ($out)
				{ return 1 }
			
			# we're done reading in
			last CHUNKLOOP;
		}
	}
	
	# return
	return join('', @rv);
}
#
# slurp
#------------------------------------------------------------------------------


# done
# println 'done?'; # NODIST

