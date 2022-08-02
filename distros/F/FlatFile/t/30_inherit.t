use strict; use warnings;

use Test::More;
use FlatFile;
plan skip_all => 'Missing or empty /etc/passwd' if ! -s '/etc/passwd';
plan tests => 5;
ok(1); # If we made it this far, we're ok.

package PW;
use File::Copy ();
use Tie::File ();
our (@ISA, $FILE, $FIELDS, $FIELDSEP);
@ISA = qw(FlatFile);
my @TO_REMOVE = $FILE = "/tmp/FlatFile.$$";
END { unlink @TO_REMOVE }
File::Copy::copy("/etc/passwd", $FILE);
{
	tie my @line, 'Tie::File', $FILE or die "Couldn't Tie::File $FILE: $!\n";
	@line = grep !/^[\x09\x20]*(?:#|$)/, @line; # avoid encountering comment/empty lines
}
$FIELDS = [qw(uname passwd uid gid gecos home shell)];
$FIELDSEP = ":";


package main;

my $pw = PW->new;
ok($pw);

my ($root) = my @rec = $pw->lookup(uname => "root");
is(scalar(@rec), 1, "one record for root");
is($root->uid, 0, "root uid is 0");
is($root->get_uid, 0, "root uid is 0");
