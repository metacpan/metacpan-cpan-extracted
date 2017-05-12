use strict;
use warnings;
use Test;
BEGIN { plan  tests => 14 }

use Getopt::Easy;

@ARGV = qw/ -x -f filename -gfilename -dabc one two /;
get_options "l-list x-extra f-fname= g-gname= h-hname= d-debug=abcDEF";
ok($O{extra} == 1);
ok($O{list} == 0);
ok($O{fname} eq "filename");
ok($O{gname} eq "filename");
ok($O{hname} eq "");
ok("@ARGV" eq "one two");
ok($O{debug} eq "abc");

#
# stopping at --
#
@ARGV = qw/ -x -f filename -- -l hello/;
get_options "x-extra f-fname=";

ok("@ARGV" eq "-l hello");

#
# now for testing failures of various kinds
#
sub do_test {
	my ($argv, $errmsg) = @_;
	@ARGV = split /\s+/, $argv;
	eval {
		get_options "l-list f-fname= d-debug=abc";
	};
	ok($@ =~ /$errmsg/);
}
do_test("-A", , "unknown option: -A");
do_test("-f", "missing");
do_test("-f -x", "begins with a dash");
do_test(
	"-d abXY",
	#'illegal values for debug option d: XY, legal ones are: abc',
	'for -d: illegal options: XY, valid ones are: abc',
);

#
# errors with the parameters to get_options
#
eval {
get_options "li-list";
};
my $err = 'li-list: syntax error - must be like this: l-length\n';
ok($@ =~ /$err/);

#
# failure with a usage message
#
@ARGV = "-A";
eval {
get_options "l-list",
	        "usage: prog -l";
};
ok($@ =~ /usage: prog -l/);
