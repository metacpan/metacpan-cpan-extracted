# -*- perl -*-

use Test::More;
use Mail::GnuPG;
use strict;

require('t/import_keys.pl');
my $gpghome=import_keys('t/test-key.pgp');
unless (defined($gpghome)){
  plan skip_all => "failed to import GPG keys for testing";
  goto end;
}

plan tests => 3;

my $mg = new Mail::GnuPG( keydir => $gpghome );
isa_ok($mg, 'Mail::GnuPG');

is($mg->has_public_key('mail@gnupg.dom'), 1, 'public key exists');
is($mg->has_public_key('bogus@email.example.com'), 0, "bogus key doesn't exist");

end:
