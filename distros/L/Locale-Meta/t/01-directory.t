#!perl -T

use strict;
use warnings;
use utf8;

use Test::More tests => 6;
use Locale::Meta;

my $lm = Locale::Meta->new('t/i18n');
ok($lm, 'Got a proper Meta structure');

is($lm->loc('key', 'en'), 'key', 'en -> en scope1');

is($lm->loc('key', 'es'), 'llave', 'en -> es scope2');

is($lm->loc('keyes', 'en'), 'keyes', 'key not defined');

is($lm->loc(undef, 'en'), undef, 'undef string returns undef');

is($lm->{locales}->{key}->{meta}->{localization},"/home"," meta attributes loaded successfully.");

done_testing();
