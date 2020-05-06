#!perl

use strict;
use warnings;
use lib './t';
use Test::More;
use AssertHelper;
use FIDO::Raw;

my $pk = FIDO::Raw::PublicKey::ES256->new ($es256_pk);
isa_ok $pk, 'FIDO::Raw::PublicKey::ES256';

my $a = FIDO::Raw::Assert->new;
$a->clientdata_hash ($cdh);
$a->rp ("localhost");
$a->count (1);
$a->authdata (0, $authdata);
$a->sig (0, $sig);

$a->up (FIDO::Raw->OPT_TRUE);
$a->uv (FIDO::Raw->OPT_FALSE);
is $a->verify (0, FIDO::Raw->COSE_ES256, $pk), FIDO::Raw->ERR_INVALID_PARAM;

$a->up (FIDO::Raw->OPT_FALSE);
$a->uv (FIDO::Raw->OPT_TRUE);
is $a->verify (0, FIDO::Raw->COSE_ES256, $pk), FIDO::Raw->ERR_INVALID_PARAM;

$a->up (FIDO::Raw->OPT_TRUE);
$a->uv (FIDO::Raw->OPT_TRUE);
is $a->verify (0, FIDO::Raw->COSE_ES256, $pk), FIDO::Raw->ERR_INVALID_PARAM;

$a->up (FIDO::Raw->OPT_FALSE);
$a->uv (FIDO::Raw->OPT_FALSE);
is $a->verify (0, FIDO::Raw->COSE_ES256, $pk), FIDO::Raw->OK;

done_testing;

