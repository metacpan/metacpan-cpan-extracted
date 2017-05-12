use strict;
use warnings;

use Test::More tests => 2;
use lib 't/lib';

use Email::MIME::Kit;

my $kit = Email::MIME::Kit->new({ source => 't/kits/borg.mkit' });

my $manifest = $kit->manifest;
ok($manifest, 'got a manifest');

my $email = $kit->assemble;

like(
  $email->body,
  qr{We are borg.  You will be assimilated.  We will add your stash to our},
  "the custom assembler was used, replacing anything the manifest said",
);

