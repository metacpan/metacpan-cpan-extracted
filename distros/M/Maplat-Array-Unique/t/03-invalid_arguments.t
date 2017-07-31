#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 6;
BEGIN { use_ok('Maplat::Array::Unique') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @testarray = qw[one two three four five six seven eight nine ten];
my $somestring = '';
my %somehash = (hello => 'world', hallo => 'welt');


eval {
    unique(\@testarray);
};
ok($@ eq '', 'arrayref');

eval {
    unique();
};
ok($@ =~ /array\ reference\ is\ not\ defined\ in\ unique/, 'undefined');

eval {
    unique(@testarray);
};
ok($@ =~ /dataset\ is\ not\ an\ array\ reference\ in\ unique/, 'array');

eval {
    unique($somestring);
};
ok($@ =~ /dataset\ is\ not\ an\ array\ reference\ in\ unique/, 'string');

eval {
    unique(\%somehash);
};
ok($@ =~ /dataset\ is\ not\ an\ array\ reference\ in\ unique/, 'hash');

