#! /usr/bin/perl

package Scribe::Thrift::ResultCode;
use constant OK => 0;
use constant TRY_LATER => 1;

package main;
use strict;
use warnings;

use Test::MockObject;
use Test::More tests => 2;
use File::Temp qw/tempdir/;

my $debug = 0;
my @pids;

for (qw/INT KILL TERM QUIT/) {
    $SIG{$_} = \&death_handler;
}

END {
    death_handler();
}

require_ok( 'File::Tail::Scribe' );


my $dir = tempdir( CLEANUP => ($debug ? 0: 1));
diag("Using temporary directory $dir\n") if $debug;
chdir($dir);

our $transport_ok = 1;
my $child_fh;

BEGIN {
    my $std_new = sub { 
	my $class = shift;
	my %opts = ref($_[0]) ? %{$_[0]} : ( @_ );
	return bless \%opts, ref($class) || $class;
    };

    my %subs = (
	'Thrift::FramedTransport' => {
	    new => $std_new,
	    open => sub {},
	    close => sub {},
	    isOpen => sub { return $transport_ok },
	},
	'Scribe::Thrift::scribeClient' => {
	    new => $std_new,
	    Log => sub { 
		die Thrift::TException->new(message => "Transport disconnected") unless $transport_ok;
		my $self = shift;
		my $args = shift;
		print $child_fh $_->{message} for @$args;
		return 0; 
	    },
	},
	'Thrift::Socket' => {
	    new => $std_new,
	},
	'Thrift::BinaryProtocol' => {
	    new => $std_new,
	},
	'Scribe::Thrift::LogEntry' => {
	    new => $std_new,
	},
	'Scribe::Thrift::scribe' => {
	    new => $std_new,
	},
	'Thrift::TException' => {
	    new => $std_new,
	},
	);
    for my $mod (keys %subs) {
	Test::MockObject->fake_module( $mod, %{$subs{$mod}} );
    }
    require Log::Dispatch::Scribe;
}

my $random_lines = make_random_content(1000);

# start scribe; scribe output will be sent to a file
my $scribe_pid = background(
    sub {
	open $child_fh, '>', 'output.txt' or die "Failed to open output.txt for writing: $!";
	select $child_fh;
	$| = 1;
	my $scribe = File::Tail::Scribe->new( 
	    directories => '.',
	    filter => qr/input/,
	    scribe_options => {
		name       => 'scribe',
		min_level  => 'info',
		host       => 'localhost',
		port       => 1463,
		default_category => 'test',
		retry_plan_a => 'buffer',
		retry_buffer_size => 1,
		retry_plan_b => 'die',
		retry_delay => 1,
		retry_count => 2,
	    },
	    );
	$scribe->watch_files();
    });

# start process to write data to file being tailed
waitpid(10, background(
	    sub {
		my $fname = "input.txt";
		open my $fh, '>>', $fname or die "Failed to open $fname: $!";
		select($fh);
		$| = 1;
		print $fh "$_\n" for @$random_lines;
		close($fh);
	    }));

# stop watcher
sleep(2);
kill 1, $scribe_pid;
waitpids(30, $scribe_pid);

my $line_count = 0;
my $failure_count = 0;
open(my $result, '<', 'output.txt') or die "Failed to open output.txt for reading: $!";
while (my $line = <$result>) {
    chomp $line;
    $failure_count++ unless $line eq $random_lines->[$line_count++];
}
close($result);
diag("Tested $line_count lines, $failure_count failures");
ok($failure_count == 0);


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

sub make_random_content {
    my $line_count = shift;
    my @chartable = ( 'A' .. 'Z' );
    # random number of writes, up to 10
    my @lines;
    for (1 .. $line_count) {
	push(@lines, join('', map { $chartable[int(rand(scalar @chartable))] } ( 0 .. int(rand(1000)) )));
    }
    return \@lines;
}




