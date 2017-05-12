#!perl -T

use Test::More tests => 3;

use Locale::Country::Multilingual qw(en fr es de);

my $lcm = Locale::Country::Multilingual->new;

can_ok($lcm, 'languages');

my $languages = eval { $lcm->languages };	# program must not die

isa_ok($languages, 'HASH', '$object->languages is a HASH reference');

$languages ||= {};	# make sure tests fail rather than program dies

is_deeply([sort keys %$languages], [qw(de en es fr)], 'languages preloaded successfully');
