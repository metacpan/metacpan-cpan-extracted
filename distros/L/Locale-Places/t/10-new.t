#!perl -wT

use warnings;
use strict;

use Test::Most tests => 15;

use_ok('Locale::Places');
isa_ok(Locale::Places->new(), 'Locale::Places', 'Creating Locale::Places object');
isa_ok(Locale::Places->new()->new(), 'Locale::Places', 'Cloning Locale::Places object');
isa_ok(Locale::Places::new(), 'Locale::Places', 'Creating Locale::Places object');
# ok(!defined(Locale::Places::new()));

# Test 1: Default instantiation
my $obj = Locale::Places->new();
isa_ok($obj, 'Locale::Places', 'Object created successfully');
ok($obj->{'directory'}, 'Directory initialized');

# Test 2: Instantiate with a hash
$obj = Locale::Places->new(cache_duration => '2 weeks', some_arg => 'test');
is($obj->{cache_duration}, '2 weeks', 'cache_duration initialized correctly');
is($obj->{some_arg}, 'test', 'Additional argument stored correctly');

# Test 3: Instantiate with a hash reference
$obj = Locale::Places->new({ cache_duration => '3 weeks', another_arg => 'example' });
is($obj->{cache_duration}, '3 weeks', 'cache_duration initialized correctly with hashref');
is($obj->{another_arg}, 'example', 'Additional argument stored correctly from hashref');

# Test 4: Cloning an existing object with new arguments
my $cloned_obj = $obj->new(new_arg => 'new_value');
isa_ok($cloned_obj, 'Locale::Places', 'Cloned object created successfully');
is($cloned_obj->{another_arg}, 'example', 'Cloned object retains old arguments');
is($cloned_obj->{new_arg}, 'new_value', 'New arguments added to cloned object');

# Test 5: Check if directory and cache are correctly set
ok(defined($obj->{'directory'}), 'Directory path is set');

if(defined($ENV{'GITHUB_ACTION'}) ||
   defined($ENV{'CIRCLECI'}) ||
   defined($ENV{'TRAVIS_PERL_VERSION'}) ||
   defined($ENV{'APPVEYOR'}) ||
   defined($ENV{'AUTOMATED_TESTING'}) ||
   defined($ENV{'NO_NETWORK_TESTING'})) {
	ok((!-d $obj->{'directory'}), $obj->{'directory'} . ': No data directory in automated testers');
} else {
	ok(-d $obj->{'directory'}, $obj->{'directory'} . ': Directory path exists or created');
}
