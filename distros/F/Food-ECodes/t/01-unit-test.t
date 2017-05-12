#!perl

use strict;use warnings;
use Test::More tests => 3;
use Food::ECodes;

eval { Food::ECodes->new('x') };
like($@, qr/ERROR: No parameters required for constructor/);

my $ecode = Food::ECodes->new;
eval { $ecode->search; };
like($@, qr/ERROR: Missing parameter 'ecode'/);

eval { $ecode->search('x'); };
like($@, qr/ERROR: Invalid ecode 'x' received/);
