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
$a->up (FIDO::Raw->OPT_FALSE);
$a->uv (FIDO::Raw->OPT_FALSE);
$a->extensions (0);
$a->sig (0, $sig);

is $a->sigcount (0), 3;
is $a->hmac_secret (0), undef;
is $a->verify (0, FIDO::Raw->COSE_ES256, $pk), FIDO::Raw->OK;

my $user = $a->user (0);
isa_ok $user, 'HASH';

done_testing;

