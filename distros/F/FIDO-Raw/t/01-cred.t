#!perl

use strict;
use warnings;
use Test::More;

use FIDO::Raw;

my $cred = FIDO::Raw::Cred->new;
isa_ok $cred, 'FIDO::Raw::Cred';

is $cred->fmt, undef;
is $cred->fmt ("packed"), "packed";
is $cred->fmt, "packed";
is $cred->fmt ("fido-u2f"), "fido-u2f";
is $cred->fmt, "fido-u2f";
ok (!eval {$cred->fmt ("invalid")});
is $cred->fmt, undef;

is $cred->prot, 0;
is $cred->prot (FIDO::Raw->CRED_PROT_UV_OPTIONAL), FIDO::Raw->CRED_PROT_UV_OPTIONAL;
is $cred->prot, FIDO::Raw->CRED_PROT_UV_OPTIONAL;
is $cred->prot (FIDO::Raw->CRED_PROT_UV_OPTIONAL_WITH_ID), FIDO::Raw->CRED_PROT_UV_OPTIONAL_WITH_ID;
is $cred->prot, FIDO::Raw->CRED_PROT_UV_OPTIONAL_WITH_ID;
is $cred->prot (FIDO::Raw->CRED_PROT_UV_REQUIRED), FIDO::Raw->CRED_PROT_UV_REQUIRED;
is $cred->prot, FIDO::Raw->CRED_PROT_UV_REQUIRED;
is $cred->prot (0), 0;
is $cred->prot, 0;

$cred->extensions (FIDO::Raw->EXT_HMAC_SECRET);
$cred->extensions (FIDO::Raw->EXT_CRED_PROTECT);
$cred->extensions (0);
ok (!eval {$cred->extensions (-1)});

$cred->rp ('id', 'name');
$cred->rp (undef, 'name');
ok (!eval {$cred->rp ('id', undef)});

my $rp = $cred->rp ('id', 'name');
isa_ok $rp, 'HASH';
is $rp->{id}, "id";
is $rp->{name}, "name";

$cred->user ("user_id");
$cred->user ("user_id", "name");
$cred->user ("user_id", "name", "display_name");
$cred->user ("user_id", "name", "display_name", "icon");

my $user = $cred->user;
isa_ok $user, 'HASH';
is $user->{id}, "user_id";
is $user->{name}, "name";
is $user->{display_name}, "display_name";

$cred = FIDO::Raw::Cred->new;
$cred->type (FIDO::Raw->COSE_ES256);
is $cred->type(), FIDO::Raw->COSE_ES256;

$cred = FIDO::Raw::Cred->new;
$cred->type (FIDO::Raw->COSE_RS256);
is $cred->type(), FIDO::Raw->COSE_RS256;

$cred = FIDO::Raw::Cred->new;
$cred->type (FIDO::Raw->COSE_EDDSA);
is $cred->type(), FIDO::Raw->COSE_EDDSA;

$cred = FIDO::Raw::Cred->new;
ok (!eval {$cred->type (-1)});
ok (!eval {$cred->type ('abc')});

$cred = FIDO::Raw::Cred->new;

$cred->rk();
$cred->rk (FIDO::Raw->OPT_OMIT);
$cred->rk (FIDO::Raw->OPT_FALSE);
$cred->rk (FIDO::Raw->OPT_TRUE);

$cred->uv();
$cred->uv (FIDO::Raw->OPT_OMIT);
$cred->uv (FIDO::Raw->OPT_FALSE);
$cred->uv (FIDO::Raw->OPT_TRUE);

$cred->exclude ('a');
$cred->exclude ('b');
ok (!eval {$cred->exclude (undef)});

$cred = FIDO::Raw::Cred->new;
is $cred->clientdata_hash(), undef;
$cred->clientdata_hash ('abcd');
ok (!eval {$cred->clientdata_hash (undef)});

$cred->sig ('abcd');
ok (!eval {$cred->sig (undef)});

$cred->x509 ('abcd');
ok (!eval {$cred->x509 (undef)});

$cred = FIDO::Raw::Cred->new;
ok (!eval {$cred->authdata (undef)});

$cred = FIDO::Raw::Cred->new;
ok (!eval {$cred->authdata_raw (undef)});
ok (!eval {$cred->authdata_raw ('bad')});

done_testing;

