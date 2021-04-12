#!./perl
###########################################################################
#
#   caller.t
#
#   Copyright (C) 1999-2000 Raphael Manfredi.
#   Copyright (C) 2015 Mark Rogaski, mrogaski@cpan.org;
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
##########################################################################

print "1..5\n";

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
	-caller   => [ -format => "<%s,%.4d>", -info => "sub line", -postfix => 1 ],
);

my $show_error = __LINE__ + 2;
sub show_error {
	$_[0]->error("error string");
}

sub notice_string { "notice string" }

my $show_notice = __LINE__ + 2;
sub show_notice {
	$_[0]->notice(\&notice_string);
}

show_error($log);
show_notice($log);

$log->set_caller_info(-display => "<nothing>");
$log->error("error2 string");

$log->set_caller_info();
$log->error("error3 string");

$log->close;

my $error_str = sprintf("%.4d", $show_error);
my $notice_str = sprintf("%.4d", $show_notice);

ok 1, contains($file, "error string <main::show_error,$error_str>");
ok 2, contains($file, "notice string <main::show_notice,$notice_str>");
ok 3, contains($file, '<nothing> error2 string');
ok 4, contains($file, 'error3 string');
ok 5, !contains($file, '> error3 string');

cleanlog;
