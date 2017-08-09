#!/usr/bin/perl

use v5.18;
use warnings FATAL => 'all';
use Test2::V0;

use FormValidator::Tiny qw( limit_character_set );

like dies {
        my $foo = limit_character_set('abc');
    }, qr/invalid character set/,
    'invalid character sets cause error';

like dies {
        my $foo = limit_character_set('z-a');
    }, qr/invalid character set/,
    'invalid character sets cause error';

like dies {
        my $foo = limit_character_set(['abc'], ['a-z']);
    }, qr/invalid character set/,
    'invalid character sets cause error';

like dies {
        my $foo = limit_character_set(['a-c'], ['abc']);
    }, qr/invalid character set/,
    'invalid character sets cause error';

my $limit_az = limit_character_set('a-z');
my ($v, $e) = $limit_az->('abc');
ok $v, "valid string is valid";
($v, $e) = $limit_az->('ABC');
ok !$v, "invalid string is invalid";
like $e, qr/Only permits/, "got the expected error";
like $e, qr/: "a" through "z"$/, "got the expected error details";

my $limit_az_AZ = limit_character_set('a-z', 'A-Z');
($v, $e) = $limit_az_AZ->('Abc');
ok $v, 'valid string is valid';
($v, $e) = $limit_az_AZ->('Abc123');
ok !$v, 'invalid string is invalid';
like $e, qr/Only permits/, 'got the expected error';
like $e, qr/: "a" through "z" and "A" through "Z"$/, 'got the expected error details';

my $limit_az_AZ_09 = limit_character_set('a-z', 'A-Z', '0-9');
($v, $e) = $limit_az_AZ_09->('Abc123');
ok $v, 'valid string is valid';
($v, $e) = $limit_az_AZ_09->('Abc123:');
ok !$v, 'invalid string is invalid';
like $e, qr/Only permits/, 'got the expected error';
like $e, qr/: "a" through "z", "A" through "Z", and "0" through "9"$/, 'got the expected error details';

my $limit_alpha = limit_character_set('[Lowercase_Letter]');
($v, $e) = $limit_alpha->('abc');
ok $v, 'valid string is valid';
($v, $e) = $limit_alpha->('ABC');
ok !$v, 'invalid string is invalid';
like $e, qr/Only permits/, 'got the expected error';
like $e, qr/: lowercase letter characters$/, 'got the expected error details';

my $limit_az_dash = limit_character_set('a-z', '-');
($v, $e) = $limit_az_dash->('ab-cd');
ok $v, "valid string is valid";
($v, $e) = $limit_az_dash->('ab_cd');
ok !$v, "invalid string is invalid";
like $e, qr/Only permits/, "got the expected error";
like $e, qr/: "a" through "z" and "-"$/, "got the expected error details";

my $limit_AZ_limit_az = limit_character_set(['A-Z'], ['a-z']);
($v, $e) = $limit_AZ_limit_az->('Abc');
ok $v, "valid string is valid";
($v, $e) = $limit_AZ_limit_az->('ABC');
ok !$v, "invalid string is invalid";
like $e, qr/Remaining only permits/, "got the expected error";
like $e, qr/: "a" through "z"$/, "got the expected error details";
($v, $e) = $limit_AZ_limit_az->('abc');
ok !$v, "invalid string is invalid";
like $e, qr/First character only permits/, "got the expected error";
like $e, qr/: "A" through "Z"/, "got the expected error details";

done_testing;
