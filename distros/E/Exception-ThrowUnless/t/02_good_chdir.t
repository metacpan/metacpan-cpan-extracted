use strict;
use lib "lib";
use Test::More;
require "./t/setup.pl";
require "./t/must_die.pl";
plan tests => 13;
eval q{ use Croak; confess; };
use Exception::ThrowUnless qw(:all);
sub file_id($){
	@_ = stat(shift);
	join(":", shift, shift);
};
sub t_schdir # ($)
{
	my $psc = "/proc/self/cwd";
	my $pwd = readlink($psc);
	is(file_id("$psc/."),my $dot=file_id("."), 'dot matches /proc');
	is(file_id("$psc/."),file_id($pwd), 'dot matches /proc');
	ok(schdir("/"),"changed to root");
	isnt(file_id("."), $dot, "not the same dir");
	is(file_id("/"),file_id("."), "is the root dir");
	ok(schdir($pwd), "there and back again");
	isnt(file_id("/"),file_id("."),"no longer root");
	is(file_id("$psc/."),$dot, 'I like to be home when I can.');
	ok(schdir("tmp"),"changed to tmp");
	ok(schdir(".."), "changed back");
	must_die(sub { schdir($0) }, qr(^chdir:), "cd $0");
	ok(schdir("tmp"),"changed to tmp");
	ok(schdir(".."), "changed back");
}
t_schdir;
