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
$c->rp ($rp_id, $rp_name);
$c->authdata ($authdata);
$c->rk (FIDO::Raw->OPT_FALSE);
$c->uv (FIDO::Raw->OPT_FALSE);
$c->x509 ($x509);
$c->sig ($sig);
$c->fmt ("packed");
is $c->verify(), FIDO::Raw->ERR_SUCCESS;

my $k = $c->pubkey();
is length ($k), length ($pubkey);

my $i = $c->id();
is length ($i), length ($id);

my $g = $c->aaguid();
is length ($g), length ($aaguid);

is $k, $pubkey, "dump: ".unpackit ($k);
is $i, $id, "dump: ".unpackit ($i);
is $g, $aaguid, "dump: ".unpackit ($g);

done_testing;

