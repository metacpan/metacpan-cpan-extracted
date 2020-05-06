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
$c->authdata ($authdata);
$c->rk (FIDO::Raw->OPT_FALSE);
$c->uv (FIDO::Raw->OPT_FALSE);
$c->x509 ('0' x length ($x509));
$c->sig ($sig);
$c->fmt ("packed");
is $c->verify(), FIDO::Raw->ERR_INVALID_SIG;

my $k = $c->pubkey();
is length ($k), length ($pubkey);

my $i = $c->id();
is length ($i), length ($id);

is $k, $pubkey, "dump: ".unpackit ($k);
is $i, $id, "dump: ".unpackit ($i);

done_testing;

