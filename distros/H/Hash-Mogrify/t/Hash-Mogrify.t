# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Hash-Mogrify.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 16;
BEGIN { use_ok('Hash::Mogrify') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use Hash::Mogrify qw(:all :nowarning);

my %testhash = (
    quux  =>  'quuz',
    foo   =>  'bar',
    death => 'freedom',
    baz   => 'borked',
);

my $href = kmap { $_ =~ s/o/a/g } %testhash;
is($href->{death}, 'freedom', 'value of death has not been changed');
is($href->{faa}, 'bar', 'foo has been renamed to faa');
isnt($href->{foo}, 'value foo no longer exists');

my %hash = vmap { $_ =~ s/e/i/g } %testhash;
is($hash{death}, 'friidom', 'death becomes friidom');

is($testhash{quux},  'quuz',    'original hash value quux still intact');
is($testhash{foo},   'bar',     'original hash value foo still intact');
is($testhash{death}, 'freedom', 'original hash value death still intact');

hmap { $_[0] =~ s/e/a/g; $_[1] =~ s/a/o/g; } \%testhash;
is($testhash{daath}, 'freedom', 'key death changed into daath');
is($testhash{foo},   'bor', 'value of foo changed into bor');

kmap { $_ =~ s/foo/quux/ } \%testhash;
is($testhash{foo},   'bor', 'value of foo is still bor');

kmap { $_ =~ s/baz/foo/ } \%testhash;
is($testhash{foo},   'bor', 'value of foo is still bor');

my %new = ktrans { foo => 'fool', daath => 'dood' }, %testhash;
is($new{dood},    'freedom', 'key death changed into dood');
isnt($new{daath}, 'key daath no longer exists');
is($new{fool},    'bor', 'key foo changed into fool');
isnt($new{foo},   'key foo no longer exists');
