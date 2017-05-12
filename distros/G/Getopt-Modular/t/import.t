#!perl

use Test::More qw(no_plan); # tests => 1;
use Test::Exception;

use_ok( 'Getopt::Modular', -namespace => 'GM', '-getOpt');

use Data::Dumper;

my @default_arr = qw(12 22 32);

GM->acceptParam(
                 's' => {
                     spec => ':s',
                     validate => sub { /^(?:[[:alpha:]]\d+|)?$/ },
                 },
                 i => {
                     spec => ':i',
                     default => 3,
                 },
                 iarr => {
                     spec => ':i@',
                     default => sub {
                         @default_arr;
                     },
                 },
                 sarr => {
                     spec => ':s@',
                     default => sub {
                         [qw(foo bar baz)]
                     },
                     validate => sub {
                         ### $_
                         for (@$_) {
                             ### $_
                             return 0 if /blah/;
                         }
                         1;
                     },
                 },
                 bool => {
                     spec => '!',
                 },
                 f => {
                     spec => '=f',
                 },
                 h => {
                     spec => '=f%',
                 },
                );

# Integer tests
is(getOpt('i'), 3, 'Check default');
dies_ok { GM->setOpt('i', 'z'); } 'validation: setting something that should be a number to a string';

# String tests
lives_ok { GM->setOpt('s', ''); } 'validation: setting to blank should be ok'
    or diag($@);

lives_ok { GM->setOpt('s', 'b0'); } 'validation: setting to b0 should be ok'
    or diag($@);

throws_ok { GM->setOpt('s', 'xyz'); } 'Getopt::Modular::Exception',
    'validation: setting to xyz should not be ok';

# Integer list tests
# ensure it's dynamic by changing it from what's above.
@default_arr = qw(8 9 99);
is_deeply([getOpt('iarr')], \@default_arr, 'validation: default array');

lives_ok { GM->setOpt('iarr', 1, 2, 3); } 'validation: setting a list of numbers';
is_deeply([getOpt('iarr')], [1,2,3], 'Ensure we get back our list of numbers') or diag(Dumper(getOpt('arr')));

# boolean tests
ok(!getOpt('bool'), 'default for boolean is false');
lives_ok { GM->setOpt('bool', 1) } 'set boolean to true';
ok(getOpt('bool'), 'retrieve set boolean value');
dies_ok { GM->setOpt('bool', [123]) } 'silly boolean value';

# String list tests
is_deeply([getOpt('sarr')], [qw(foo bar baz)], 'validation: default array via ref');
lives_ok { GM->setOpt('sarr', qw(abra ca dabra)) } 'setting string list';
dies_ok { GM->setOpt('sarr', qw(foo blah fooz)) } 'not-allowed value';

# hash tests
my %t = ( x => 1, z => 3 );
lives_ok { GM->setOpt('h', %t) } 'setting hash';
is(getOpt('h')->{x}, 1, 'retrieving hash');
dies_ok { GM->setOpt('h', x => 'z') } 'not setting hash';

# float tests
lives_ok { GM->setOpt('f', '3.141529') } 'setting float';
dies_ok { GM->setOpt('f', '3.1.4.1') } 'setting float badly';

lives_ok { my $x = getOpt('not-there') } 'get non-existant entry';
dies_ok { GM->setMode('invalid-mode') } 'set invalid mode';
lives_ok { GM->setMode('strict') } 'set valid mode';
dies_ok { getOpt('not-there') } 'get non-eixstant entry: strict mode';
