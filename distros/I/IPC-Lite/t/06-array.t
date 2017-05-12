use strict;
use warnings;
use Test::Simple tests=>22;
use Data::Dumper;

# not terribly thorough test of array operators

BEGIN {
	(-d 'tmp') || mkdir('tmp') || die;
}

# set default path (set for this package only)
use IPC::Lite Path=>'tmp/test.db';

# bind style 1 (shared table, implicit use vars)
use IPC::Lite qw(@a);

# bind style 2 (own table, normal var, tie it up)
our @b;
tie @b, 'IPC::Lite', Table=>'b';

no strict 'refs';
no warnings 'uninitialized';

# clear other tests
@a = ();
@b = ();

our @x;
# for each style
for (qw(b a)) {
*x = \@$_;
die unless tied(@x);

ok(@x == 0, "$_ siz 0: " . @x);

$x[0] = 'hello';

ok(@x == 1, "$_ siz 1: " . @x);

push @x, 'goodbye';

ok(@x == 2, "$_ siz 2: " . @x);

unshift @x, 'begin';

ok($x[1] eq 'hello', "$_ 1:" . $x[1]);

ok(@x == 3, "$_ siz 3: " . @x);

ok($x[0] eq 'begin', "$_ 0:" . $x[0]);
ok($x[1] eq 'hello', "$_ 1:" . $x[1]);
ok($x[2] eq 'goodbye', "$_ 2:" . $x[2]);

my $v = pop @x;

ok($v eq 'goodbye', "$_ pop 1: " . $v);

my $ret = shift @x;
ok (@x == 1 && $x[0] eq "hello", "shift");
ok ($ret eq "begin", "shift ret");

}


