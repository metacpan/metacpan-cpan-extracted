#!perl
###########################################################################
#
#   tag_string.t
#
#   Copyright (C) 1999 Raphael Manfredi.
#   Copyright (C) 2002-2015 Mark Rogaski, mrogaski@cpan.org;
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
##########################################################################

print "1..2\n";

require 't/code.pl';
sub ok;

use Log::Agent;
require Log::Agent::Driver::File;
require Log::Agent::Tag::String;

unlink 't/file.out', 't/file.err';

my $driver = Log::Agent::Driver::File->make(
	-prefix => 'me',
	-channels => {
		'error' => 't/file.err',
		'output' => 't/file.out'
	},
);
my $t1 = Log::Agent::Tag::String->make(-value => "<tag #1>");
my $t2 = Log::Agent::Tag::String->make(-value => "<tag #2>", -postfix => 1);

logconfig(
	-driver		=> $driver,
	-tags		=> [$t1],
);

logerr "error string";

use Log::Agent qw(logtags);
my $tags = logtags;
$tags->append($t2);

logwarn "warn string";

ok 1, contains("t/file.err", '<tag #1> error string$');
ok 2, contains("t/file.err", '<tag #1> warn string <tag #2>$');

unlink 't/file.out', 't/file.err';
