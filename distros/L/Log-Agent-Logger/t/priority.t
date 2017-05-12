#!./perl
###########################################################################
#
#   priority.t
#
#   Copyright (C) 1999-2000 Raphael Manfredi.
#   Copyright (C) 2015 Mark Rogaski, mrogaski@cpan.org;
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
##########################################################################

print "1..6\n";

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
	-channel  => $channel,
	-max_prio => 'info',
	-priority => [ -display => '<$priority/$level>', -prefix => 1 ],
);

$log->error("error string");
$log->notice("notice string");
$log->info("info string");

$log->set_priority_info(-display => '<$priority>');
$log->info("info2 string");

$log->set_priority_info();
$log->info("info3 string");

$log->close;

ok 1, contains($file, "<error/3> error string");
ok 2, contains($file, "<notice/6> notice string");
ok 3, contains($file, "<info/8> info string");
ok 4, contains($file, "<info> info2 string");
ok 5, contains($file, "info3 string");
ok 6, !contains($file, "> info3 string");

cleanlog;
