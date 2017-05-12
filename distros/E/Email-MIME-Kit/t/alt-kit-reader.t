use strict;
use warnings;

use Test::More tests => 4;
use lib 't/lib';

use Email::MIME::Kit;

my $kit = Email::MIME::Kit->new({ source => 't/kits/alt-kit-reader.mkit' });

my $manifest = $kit->manifest;
ok($manifest, 'got a manifest');

my $email = $kit->assemble;

my @parts = $email->subparts;
is(@parts, 2, "we got two alternatives");

like($parts[0]->body, qr{first/text/alternative},  'path used as content');
like($parts[1]->body, qr{second/text/alternative}, 'path used as content');

