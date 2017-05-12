#!perl

use strict;
use warnings;

my $sendgrid;

use Test::More 0.88 tests => 3;
BEGIN { use_ok( 'Mail::SendGrid' ); }

eval { $sendgrid = Mail::SendGrid->new(); };
ok($@);

eval { $sendgrid = Mail::SendGrid->new(api_user => 'fred', api_key => 'bloggs'); };
ok(not $@);

