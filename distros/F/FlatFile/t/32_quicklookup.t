use Test::More tests => 7;
use FlatFile;
ok(1); # If we made it this far, we're ok.

my @TO_REMOVE = my $tmp = "/tmp/FlatFile.$$";
END { unlink @TO_REMOVE }

open F, ">", $tmp or die "$tmp: $!";
print F <DATA>;
close F;

package PW;
use vars ('@ISA', '$FILE', '@FIELDS', '$FIELDSEP', '$RECCLASS');
@ISA = qw(FlatFile);
$FILE = $tmp;
$FIELDS = ['fruit', 'color'];

package main;

my @redfruit = PW->lookup(color => 'red');
is(scalar(@redfruit), 2);
is($redfruit[0]->fruit, "apple");
is($redfruit[1]->fruit, "cherry");

my @afruit = PW->c_lookup(sub {$_{fruit} =~ /a/});
is(scalar(@afruit), 2);
is($afruit[0]->fruit, "apple");
is($afruit[1]->fruit, "banana");

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

__DATA__
apple  red
banana green
cherry red
kiwi brown
