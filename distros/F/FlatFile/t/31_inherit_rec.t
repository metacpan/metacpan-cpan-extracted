use strict; use warnings;

use Test::More;
use FlatFile;
plan skip_all => 'Missing or empty /etc/passwd' if ! -s '/etc/passwd';
plan tests => 8;
ok(1); # If we made it this far, we're ok.

package PW;
use File::Copy ();
use Tie::File ();
our (@ISA, $FILE, $FIELDS, $FIELDSEP, $RECCLASS);
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
$RECCLASS = "PW::Rec";

package PW::Rec;
our @ISA = qw(FlatFile::Rec);
sub bingle { $main::OK = 1 }
sub nextuid { my $self = shift; $self->uid + 1; }

package main;

my $pw = PW->new;
ok($pw);

my ($root) = my @rec = $pw->lookup(uname => "root");
is(scalar(@rec), 1, "one record for root");
is($root->uid, 0, "root uid is 0");
is($root->get_uid, 0, "root uid is 0");
eval { $root->bingle };
is($@, "", "bingle didn't fail");
is(our $OK, 1, "bingled");
is($root->nextuid, 1, "nextuid worked");
