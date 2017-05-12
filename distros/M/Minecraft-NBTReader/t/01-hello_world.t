# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Minecraft-NBTReader.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More;
BEGIN { use_ok('Minecraft::NBTReader') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $sixtyfourbit = 0;
eval {
    my $foo = pack('q', 1);
    $sixtyfourbit = 1;
};

ok($sixtyfourbit, "pack() does not support 64bit quads!");
if(!$sixtyfourbit) {
    done_testing();
    exit;
}

ok(-f 't/hello_world.nbt', 'Found hello_world.nbt');
if(!-f 't/hello_world.nbt') {
    done_testing();
    exit(0);
}

my $reader = Minecraft::NBTReader->new();
ok(defined($reader), "new()");

my $evalok = 0;
my %data;
eval {
    %data = $reader->readFile('t/hello_world.nbt');
    $evalok = 1;
};

ok($evalok, 'Load file without crashing');
exit(0) unless($evalok);
ok(defined($data{'hello world'}->{'name'}), 'Test string loaded');
ok($data{'hello world'}->{'name'} eq 'Bananrama', 'Correct string');

done_testing();
