use strict;
use warnings;

use Test::More tests => 4;
use Test::Deep;
use lib 't/lib';

use Email::MIME::Kit;

my $kit = Email::MIME::Kit->new({ source => 't/kits/test.mkit' });

my $manifest = $kit->manifest;
ok($manifest, 'got a manifest');

isa_ok(
  $kit->validator,
  'Email::MIME::Kit::Validator::Simplest',
  "kit's validator",
);

cmp_deeply(
  $manifest->{alternatives}[0],
  superhashof({
    attributes => { content_type => "text/plain" },
    body       => "We don't support tests.",
  }),
  "we have desugared the first alternative's c-t",
);

cmp_deeply(
  $manifest->{alternatives}[2]{attachments}[0],
  superhashof({
    attributes => { content_type => "image/jpeg" },
    path       => "logo.jpg",
  }),
  "the desugaring propagated down into an alt's attachment",
);
