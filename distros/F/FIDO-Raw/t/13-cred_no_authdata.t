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
$c->rk (FIDO::Raw->OPT_FALSE);
$c->uv (FIDO::Raw->OPT_FALSE);
$c->x509 ($x509);
$c->sig ($sig);
$c->fmt ("packed");
is $c->verify(), FIDO::Raw->ERR_INVALID_ARGUMENT;

my $k = $c->pubkey();
is $k, undef;

my $i = $c->id();
is $i, undef;

done_testing;

