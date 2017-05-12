# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Mail-OpenDKIM-PrivateKey.t'

#########################

use Test::More tests => 3;
BEGIN { use_ok('Mail::OpenDKIM::PrivateKey') };

#########################

eval {
  ok(!defined(Mail::OpenDKIM::PrivateKey->load(File => 'ffff')));
};

my $pk = Mail::OpenDKIM::PrivateKey->load(File => 't/example.key');

ok(defined($pk));

isa_ok($pk, 'Mail::OpenDKIM::PrivateKey');
