use strict;
use warnings;
use Test::More tests => 4;

use Email::MIME::Kit 2.002;

my $kit = Email::MIME::Kit->new({ source => 't/mkits/basic.mkit' });

my $email = $kit->assemble;

my ($one, $two, $tre, $qua) = $email->subparts;

like($one->body, qr{This will be the first part}, "relative path found");
like($two->body, qr{This will be the second part}, "absolute kit path found");
like($tre->body, qr{This is a sample shared file}, "sharedir path found");
like($qua->body, qr{This will be the fourth part}, "fs path found");

