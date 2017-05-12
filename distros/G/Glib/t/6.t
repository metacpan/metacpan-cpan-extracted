#!perl

#
# more derivation testing, ensuring that signals are inherited properly.
#

use strict;
use warnings;
use Glib;
use vars qw/@one_base_ok @one_inst_ok @two_base_ok @two_inst_ok
	    @three_base_ok @three_inst_ok @four_base_ok @four_inst_ok
	    @member_ok @signal_ok/;

# this looks a little hairy because i want to make sure that we test the
# order of operations.  the begin block at the top defines a few named
# arrays of sequence numbers.  the ok() function takes a string with the
# the name of the array (minus the _ok) from which to shift the next
# sequence number.  this way we can change the order rather simply as we
# modify the test, and allow each callback to be run more than once.
BEGIN {
	print "1..31\n";

	@one_base_ok = (1,3,5);
	@one_inst_ok = (8,11,12,14);

	@two_base_ok = (2,6);
	@two_inst_ok = (9,13);

	@three_base_ok = (4);
	@three_inst_ok = (15);

	@four_base_ok = (7);
	@four_inst_ok = (10);

	@member_ok = (16..23);

	@signal_ok = (24..31);
}

sub ok {
	no strict 'refs';
	my $condition = shift;
	my $ary = \@{"$_[0]\_ok"};
	my $seq = $ary->[0];
	shift @$ary;
	print "".($condition ? "ok" : "not ok")." $seq - $_[0]\n";
}

sub readwrite { [qw/readable writable/] }
sub makeparam {
	my $name = shift;
	Glib::ParamSpec->string ($name, $name, $name, '', [qw/readable writable/]);
}

#
# define several classes that form a hierarchy, deriving from one another.
#
package One;

  use Glib::Object::Subclass
        Glib::Object::,
        signals => { one => {} },
        properties => [ ::makeparam('one'), ],
        ;

  sub INIT_BASE { ::ok(1, 'one_base'); } 
  sub INIT_INSTANCE { $_[0]{one} = 'one'; ::ok(1, 'one_inst'); } 
  sub one { shift->signal_emit ('one', @_); }

package Two;

  sub INIT_BASE { ::ok(1, 'two_base'); } 
  use Glib::Object::Subclass
        One::,
        signals => { two => {} },
        properties => [ ::makeparam ('two'), ],
        ;

  sub INIT_INSTANCE { $_[0]{two} = 'two'; ::ok(1, 'two_inst'); }
  sub two { shift->signal_emit ('two', @_); }

package Three;

  sub INIT_BASE { ::ok(1, 'three_base'); } 
  use Glib::Object::Subclass
        One::,
        signals => { three => {} },
        properties => [ ::makeparam ('three'), ],
        ;

  sub INIT_INSTANCE { $_[0]{three} = 'three'; ::ok(1, 'three_inst'); }
  sub three { shift->signal_emit ('three', @_); }

package Four;

  sub INIT_BASE { ::ok(1, 'four_base'); } 
  use Glib::Object::Subclass
        Two::,
        signals => { four => {} },
        properties => [ ::makeparam ('four'), ],
        ;

  sub INIT_INSTANCE { $_[0]{four} = 'four'; ::ok(1, 'four_inst'); }
  sub four { shift->signal_emit ('four', @_); }

package main;

my $four = Four->new;
my $one = One->new;
my $two = Two->new;
my $three = Three->new;

#
# the INIT_INSTANCE for each class should've run appropriately.  let's
# verify that by testing that each instance variable contains what we
# think it should contain.
#
ok( $one->{one}   eq 'one', 'member' );
ok( $two->{one}   eq 'one', 'member' );
ok( $three->{one} eq 'one', 'member' );
ok( $four->{one}  eq 'one', 'member' );

ok( $two->{two}  eq 'two', 'member' );
ok( $four->{two} eq 'two', 'member' );

ok( $three->{three} eq 'three', 'member' );

ok( $four->{four} eq 'four', 'member' );

#
# we'll get complaints from GLib if we try to connect to non-existent
# signals.  this verifies that signals we create for one type are
# still valid for derivatives of that type.
#

sub do_ok { ok (1, 'signal'); }

$one->signal_connect (one => \&do_ok);
$two->signal_connect (one => \&do_ok);
$three->signal_connect (one => \&do_ok);
$four->signal_connect (one => \&do_ok);

$two->signal_connect (two => \&do_ok);
$four->signal_connect (two => \&do_ok);

$three->signal_connect (three => \&do_ok);

$four->signal_connect (four => \&do_ok);

$one->one;
$two->one;
$three->one;
$four->one;

$two->two;
$four->two;

$three->three;

$four->four;
