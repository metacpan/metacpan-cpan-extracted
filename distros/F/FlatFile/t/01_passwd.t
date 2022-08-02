use strict; use warnings;

my @TO_REMOVE = my $FILE = "/tmp/FlatFile.$$";
END { unlink @TO_REMOVE }
use File::Copy ();
use Tie::File ();
File::Copy::copy("/etc/passwd", $FILE);
{
	tie my @line, 'Tie::File', $FILE or die "Couldn't Tie::File $FILE: $!\n";
	@line = grep !/^[\x09\x20]*(?:#|$)/, @line; # avoid encountering comment/empty lines
}

use Test::More;
use FlatFile;
plan skip_all => 'Missing or empty /etc/passwd' if ! -s '/etc/passwd';
plan tests => 5;
ok(1); # If we made it this far, we're ok.

my $pw = FlatFile->new(FILE => $FILE,
                                   FIELDS => [qw(uname passwd uid gid gecos home shell)],
                                   FIELDSEP => ":",
                                  );
ok($pw);

my ($root) = my @rec = $pw->lookup(uname => "root");
is(scalar(@rec), 1, "one record for root");

is($root->uid, 0, "root uid is 0 (method call)");
is($root->get_uid, 0, "root uid is 0 (get method call)");
