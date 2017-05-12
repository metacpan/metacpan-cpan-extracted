#!perl
###########################################################################
#
#   tag_callback.t
#
#   Copyright (C) 1999 Raphael Manfredi.
#   Copyright (C) 2002-2015 Mark Rogaski, mrogaski@cpan.org;
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
##########################################################################

require 't/code.pl';
sub ok;

eval "require Callback";
if ($@) {
	print "1..0\n";
	exit 0;
}
print "1..2\n";

use Log::Agent;
require Log::Agent::Driver::File;
require Log::Agent::Tag::Callback;

unlink 't/file.out', 't/file.err';

sub build_tag {
	return "<" . join(':', @_) . ">";
}

my $driver = Log::Agent::Driver::File->make(
	-prefix => 'me',
	-channels => {
		'error' => 't/file.err',
		'output' => 't/file.out'
	},
);

my $c1 = Callback->new(\&build_tag, qw(a b c));
my $c2 = Callback->new(\&build_tag, qw(d e f));
my $t1 = Log::Agent::Tag::Callback->make(-callback => $c1);
my $t2 = Log::Agent::Tag::Callback->make(-callback => $c2, -postfix => 1);

logconfig(
	-driver		=> $driver,
	-tags		=> [$t1],
);

logerr "error string";

use Log::Agent qw(logtags);
my $tags = logtags;
$tags->prepend($t2);

logwarn "warn string";

ok 1, contains("t/file.err", '<a:b:c> error string$');
ok 2, contains("t/file.err", '<a:b:c> warn string <d:e:f>$');

unlink 't/file.out', 't/file.err';
