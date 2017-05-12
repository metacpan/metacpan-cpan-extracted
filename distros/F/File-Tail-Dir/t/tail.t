#! /usr/bin/perl

use strict;
use warnings;

use Test::More tests => 17;
use File::Temp qw/tempdir/;
use Digest::MD5 qw/md5_hex/;

use_ok("File::Tail::Dir");

my $parallel = 5;
my $debug = 0;
my @pids;

for (qw/INT KILL TERM QUIT/) {
    $SIG{$_} = \&death_handler;
}

END {
    death_handler();
}

my $dir = tempdir( CLEANUP => ($debug ? 0: 1));
diag("Using temporary directory $dir\n") if $debug;
chdir($dir);
my $written_t;
my $autostate_delay = 2;

# Add some symlinks, including a circular reference
eval {
    symlink("input1.txt", "input-symlink");
# File::ChangeNotify does not handle circular references
#    symlink("..", "top");
#    symlink("input-circular1", "input-circular2");
#    symlink("input-circular2", "input-circular1");
};

# Do several runs; 
# second run tests state persistence and moving files, 
# third tests no state on existing dir; output.txt is removed and whole contents should be resent 
# fourth tests no_init; nothing should be sent
# In each case line count and checksums of output.txt should match sum of input files
for my $phase (qw/initial subsequent no_state no_init autostate/) {
# start watcher
    unlink(".filetaildirstate") if ($phase eq 'no_state');
    unlink("output.txt") if ($phase eq 'no_state');
    my $lw_pid = background(
	sub {
	    File::Tail::Dir->install_signal_handlers();
	    open my $fh, '>>', 'output.txt' or die "Failed to open output.txt: $!";
	    my $lw = File::Tail::Dir->new(  filter => qr/^input/,
					    processor => sub { my ($name, $lines) = @_; print $fh join("", @$lines); },
					    follow_symlinks => 1,
					    no_init => ($phase eq 'no_init'),
                                            autostate => ($phase eq 'autostate'),
                                            autostate_delay => $autostate_delay,
		) or die "Failed to create File::Tail::Dir instance";
	    $lw->watch_files();
	});

    sleep(2);

    if ($phase eq 'initial' || $phase eq 'subsequent') {
# start set of writers, except on no_init phase where we just need initial contents
	my @src_pids;
	for my $i (1 .. $parallel) {
	    rand();		# ensures different seed for each subprocess
	    push(@src_pids, background(
		     sub {
			 my $fname = "input$i.txt";
			 my $curname = $fname;
			 open my $fh, '>>', $fname or die "Failed to open $fname: $!";
			 select($fh);
			 $| = 1;
			 my @chartable = ( 'A' .. 'Z' );
			 # random number of writes, up to 10
			 my @lines;
			 for my $iter (0 .. int(rand(10))) {
			     # random block of lines up to 50 at a time
			     my $line_count = int(rand(50)) + 1;
			     # random lines up to 1000 chars in length
			     for (1 .. $line_count) {
				 push(@lines, join('', map { $chartable[int(rand(scalar @chartable))] } ( 0 .. int(rand(1000)) )));
			     }
			     if ($phase eq 'subsequent') {
				 my $nextname = $fname . ".$iter";
				 rename $curname, $nextname;
				 $curname = $nextname;
			     }
			     # prefix lines with checksum to verify integrity later
			     print $fh join('', map { md5_hex($_) . " " . $_ . "\n" } @lines);
			 }
			 close($fh);
		     }
		 ));
	}
# wait for writers to finish
	waitpids(30, @src_pids);
    }
    elsif ($phase eq 'autostate') {
        # write to one file to make the state dirty.
        my $fname = 'input1.txt';
        open my $fh, '>>', $fname or die "Failed to open $fname: $!";
        print $fh join('', map { md5_hex($_) . " " . $_ . "\n" } ( 'blah' ));
        close($fh);
        $written_t = time();
        sleep($autostate_delay + 1);
        my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime) = stat('.filetaildirstate');
        ok($mtime > $written_t, "state file automatically updated");
    }

# stop watcher
    sleep(2);
    kill 1, $lw_pid;
    waitpids(30, $lw_pid);

# evaluate content
# check that each line matches its checksum, and that total number of bytes/lines tally
    my $char_count = 0;
    my $line_count = 0;
    for my $i (1 .. $parallel) {
	my ($chars, $lines) = count_file("input$i.txt*");
	$char_count += $chars;
	$line_count += $lines;
    }

    my ($lw_chars, $lw_lines) = count_file("output.txt");

    is($lw_chars, $char_count, "character count, $phase run");
    is($lw_lines, $line_count, "line_count, $phase run");

    my ($test_count, $fail_count) = checksum_file("output.txt");
    diag("Checksummed $test_count lines, $fail_count failures");
    ok($fail_count == 0, "checksums, $phase run");
}


sub count_file {
    my $fname_glob = shift;
    my $line_count = 0;
    my $char_count = 0;
    for my $fname (glob $fname_glob) {
	open my $fh, '<', $fname or die "Failed to open $fname for reading: $!";
	while (<$fh>) {
	    $line_count++;
	    $char_count += length($_);
	}
	close($fh);
    }
    return ($char_count, $line_count);
}

sub checksum_file {
    my $fname = shift;

    my $test_count = 0;
    my $fail_count = 0;
    open my $fh, '<', $fname or die "Failed to open $fname for reading: $!";
    while (my $line = <$fh>) {
	my ($cs, $text) = split(/\s+/, $line);
	my $md5 = md5_hex($text);
	$test_count++;
	$fail_count++ unless $md5 eq $cs;
	if ($debug && $md5 ne $cs) {
	    diag("Bad checksum $md5: $line\n");
	}
    }
    close($fh);
    return ($test_count, $fail_count);
}
    

sub death_handler {
    chdir("..");
    kill 1, @pids;
    exit();
}

sub background {
    my $sub = shift;

    my $pid = fork();
    die "Fork failed: $!" unless defined $pid;

    if ($pid == 0) {
	@pids = ();
	exit($sub->());
    }
    push(@pids, $pid);
    return $pid;
}

sub waitpids {
    my ($timeout, @src_pids) = @_;

    eval {
	local $SIG{ALRM} = sub { die "alarm\n" };
	alarm($timeout);
	for my $pid (@src_pids) {
	    waitpid($pid,0);
	}
	alarm(0);
    };
    if ($@) {
	if ($@ eq "alarm\n") {
	    die "Test timed out";
	}
	else {
	    die;
	}
    }
}

