#!perl

use strict;
use warnings;
use Test::More;

use FIDO::Raw;

my $a = FIDO::Raw::Assert->new;
isa_ok $a, 'FIDO::Raw::Assert';

is $a->rp ('localhost'), "localhost";
my $id = $a->rp;
is $id, "localhost";

$a = FIDO::Raw::Assert->new;
$a->allow_cred ('a');
$a->allow_cred ('b');
$a->count (1);
$a->hmac_salt ('12345678901234561234567890123456');

is $a->authdata(), undef;
is $a->clientdata_hash(), undef;
is $a->sig(), undef;
is $a->rp(), undef;
is $a->hmac_secret (0), undef;

$a->clientdata_hash ('abc');

ok (!eval {$a->allow_cred (undef)});
ok (!eval {$a->clientdata_hash (undef)});
ok (!eval {$a->rp (undef)});
ok (!eval {$a->authdata (0, undef)});
ok (!eval {$a->authdata ('abc', undef)});
ok (!eval {$a->authdata_raw (undef, 0)});
ok (!eval {$a->authdata_raw (undef, 'abc')});
ok (!eval {$a->authdata_raw ('abc', 'abc')});
ok (!eval {$a->authdata_raw ('abc', 0)});
ok (!eval {$a->sigcount (undef)});
ok (!eval {$a->sigcount (-1)});
ok (!eval {$a->sig ('abc')});
ok (!eval {$a->sig (0, undef)});
ok (!eval {$a->user (undef)});
ok (!eval {$a->flags (undef)});
ok (!eval {$a->flags ('abc')});
ok (!eval {$a->id (undef)});
ok (!eval {$a->id (-1)});
ok (!eval {$a->id ('abc')});
ok (!eval {$a->hmac_salt (undef)});
ok (!eval {$a->count (-1)});
ok (!eval {$a->count ('abc')});
ok (!eval {$a->sig ('abc')});
ok (!eval {$a->flags (-1)});

ok (!eval {$a->verify (0, 0, undef)});
ok (!eval {$a->verify (0, 0, '')});

done_testing;

