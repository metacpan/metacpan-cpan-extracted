use strict;
use warnings;

use Digest;
use Digest::Bcrypt;
use Scalar::Util qw(refaddr);
use Test::More;
use Try::Tiny qw(try catch);

my $secret = "Super Secret Squirrel";
my $salt   = "   known salt   ";
my $cost   = 1;

{ # direct object
    my $direct = Digest::Bcrypt->new;
    isa_ok($direct, 'Digest::Bcrypt', 'new: direct instance');

    try {
        $direct->add($secret);
        $direct->salt($salt);
        $direct->cost($cost);
    } catch { fail("direct instance: $_"); };
    is($direct->salt, $salt, "direct: salt correct");
    is($direct->cost, "0$cost", "direct: cost correct");


    my $direct_clone = $direct->clone;
    isa_ok($direct_clone, 'Digest::Bcrypt', 'clone: direct instance');
    isnt( refaddr $direct, refaddr $direct_clone, "clone: not the same object" );

    try {
        $direct_clone->salt('  unknown salt  ');
        $direct_clone->cost(2);
    } catch { fail("direct clone: $_"); };
    isnt($direct->salt, $direct_clone->salt, "clone: salt differs from orig");
    isnt($direct->cost, $direct_clone->cost, "clone: cost differs from orig");
    isnt($direct->hexdigest, $direct_clone->hexdigest, "clone: different hash");
}

{ # indirect object
    my $indirect = Digest->new('Bcrypt');
    isa_ok($indirect, 'Digest::Bcrypt', 'new: indirect instance');

    try {
        $indirect->add($secret);
        $indirect->salt($salt);
        $indirect->cost($cost);
    } catch { fail("indirect instance: $_"); };
    is($indirect->salt, $salt, "indirect: salt correct");
    is($indirect->cost, "0$cost", "indirect: cost correct");

    my $indirect_clone = $indirect->clone;
    isa_ok($indirect_clone, 'Digest::Bcrypt', 'clone: indirect instance');
    isnt( refaddr $indirect, refaddr $indirect_clone, "clone: not the same object" );

    try {
        $indirect_clone->salt('  unknown salt  ');
        $indirect_clone->cost(2);
    } catch { fail("indirect clone: $_"); };
    isnt($indirect->salt, $indirect_clone->salt, "clone: salt differs from orig");
    isnt($indirect->cost, $indirect_clone->cost, "clone: cost differs from orig");
    isnt($indirect->hexdigest, $indirect_clone->hexdigest, "clone: different hash");
}

done_testing();
