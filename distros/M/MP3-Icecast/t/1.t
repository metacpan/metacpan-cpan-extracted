# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('MP3::Icecast') };

use constant DEBUG => 0;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use strict;

my $icy = MP3::Icecast->new();
ok(1);

$icy->recursive(1);

$icy->add_directory('./mp3');
ok(2);

$icy->alias('mp3'=>'http://localhost/mp3');

warn $icy->m3u if DEBUG;
warn $icy->pls if DEBUG;
