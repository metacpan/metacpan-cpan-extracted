#!./perl
###########################################################################
#
#   tags.t
#
#   Copyright (C) 1999-2000 Raphael Manfredi.
#   Copyright (C) 2015 Mark Rogaski, mrogaski@cpan.org;
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
##########################################################################

print "1..2\n";

require 't/code.pl';
sub ok;

sub cleanlog() {
	unlink <t/logfile*>;
}

require Log::Agent::Channel::File;
require Log::Agent::Logger;
require Log::Agent::Tag::String;

cleanlog;
my $file = "t/logfile";
my $channel = Log::Agent::Channel::File->make(
	-prefix     => "foo",
	-stampfmt   => "own",
	-showpid    => 1,
    -filename   => $file,
    -share      => 1,
);

my $t1 = Log::Agent::Tag::String->make(-value => "<tag #1>");
my $t2 = Log::Agent::Tag::String->make(-value => "<tag #2>", -postfix => 1);

my $log = Log::Agent::Logger->make(
	-channel  => $channel,
	-max_prio => 'info',
	-tags     => [$t1],
);

$log->err("error string");
$log->tags->append($t2);
$log->warn("warn string");

ok 1, contains($file, '<tag #1> error string');
ok 2, contains($file, '<tag #1> warn string <tag #2>');

cleanlog;
