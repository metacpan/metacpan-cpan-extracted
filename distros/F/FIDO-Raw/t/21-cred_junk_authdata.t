#!perl

use strict;
use warnings;
use lib './t';
use Test::More;
use CredHelper;
use FIDO::Raw;

my $c = FIDO::Raw::Cred->new;

$c->type (FIDO::Raw->COSE_ES256);
$c->clientdata_hash ($cdh);
$c->rp ($rp_id, 'potato');
ok (!eval {$c->authdata ('0' x length ($authdata))});

is $c->authdata(), undef;
is $c->flags(), 0;
is $c->fmt(), undef;
is $c->id(), undef;
is $c->pubkey(), undef;
# TODO: rp
is $c->sig(), undef;
is $c->x509(), undef;

is $c->verify(), FIDO::Raw->ERR_INVALID_ARGUMENT;

done_testing;

