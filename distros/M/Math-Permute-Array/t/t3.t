# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Math::Permute::Array.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print STDERR, ';

use strict;
use warnings;

use Test::More tests => 1;
BEGIN { use_ok('Math::Permute::Array') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $p = new Math::Permute::Array(undef);
exit(-1) if defined $p;

my @array = (1..8);
$p = new Math::Permute::Array(\@array);
my $err;

$err = $p->permutation(undef);
exit(-1) if(defined $err);

$err = Math::Permute::Array::Apply_on_perms(undef,\@array);
exit(-2) if(defined $err);

$err = Math::Permute::Array::Apply_on_perms { } undef;
exit(-3) if(defined $err);

$err = Math::Permute::Array::Apply_on_perms(undef,undef);
exit(-4) if(defined $err);

$err = Math::Permute::Array::Permute(undef,undef);
exit(-5) if(defined $err);

$err = Math::Permute::Array::Permute(0,undef);
exit(-5) if(defined $err);

$err = Math::Permute::Array::Permute(undef,\@array);
exit(-6) if(defined $err);
