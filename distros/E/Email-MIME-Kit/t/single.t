use strict;
use warnings;

use Test::More tests => 3;
use lib 't/lib';

use Email::MIME::Kit;

my $kit = Email::MIME::Kit->new({ source => 't/kits/single.mkit' });

my $manifest = $kit->manifest;
ok($manifest, 'got a manifest');

my $email = $kit->assemble;

my @parts = $email->subparts;
is(@parts, 0, "no subparts on single-part email");
like($email->body, qr{never been harder}, "the body is right there!");


