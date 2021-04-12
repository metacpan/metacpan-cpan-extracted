#!./perl
###########################################################################
#
#   basic.t
#
#   Copyright (C) 1999-2000 Raphael Manfredi.
#   Copyright (C) 2015 Mark Rogaski, mrogaski@cpan.org;
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
##########################################################################

print "1..13\n";

require 't/code.pl';
sub ok;

sub cleanlog() {
	unlink <t/logfile*>;
}

require Log::Agent::Channel::File;
require Log::Agent::Logger;

cleanlog;
my $file = "t/logfile";
my $channel = Log::Agent::Channel::File->make(
	-prefix     => "foo",
	-stampfmt   => "own",
	-showpid    => 1,
    -filename   => $file,
    -share      => 1,
);

my $log = Log::Agent::Logger->make(
	-channel    => $channel,
	-max_prio	=> 'info',
);

$log->info("this is an %s message", "informational");
$log->debug("this message (debug) will NOT show");
$log->emerg("emergency message");
$log->warn("warning message");
$log->alert("alert message");
$log->critical("critical message");
$log->error("error message");
$log->notice("notice message");

ok 1, 1 == contains($file, "this is an informational message");
ok 2, 0 == contains($file, "will NOT show");
ok 3, 1 == contains($file, "emergency");
ok 4, 1 == contains($file, "warning");
ok 5, 1 == contains($file, "alert");
ok 6, 1 == contains($file, "critical");
ok 7, 1 == contains($file, "error");
ok 8, 1 == contains($file, "notice");

#
# 00/11/06 13:36:33 foo[12138]: warning message
#
ok 9, 7 == contains($file,
	'^\d{2}\/\d{2}\/\d{2} \d{2}:\d{2}:\d{2} foo\[\d+\]: ');

sub genmsg {
	my ($arg) = @_;
	return "message #$arg";
}

$log->notice(\&genmsg, 1);
$log->notice(\&genmsg, 2);
$log->notice(sub { join ' ', @_ }, "message", "#3");

ok 10, 1 == contains($file, "message #1");
ok 11, 1 == contains($file, "message #2");
ok 12, 1 == contains($file, "message #3");

$log->close;
$log->notice("will NOT show at all");

ok 13, !contains($file, "will NOT show");

cleanlog;
