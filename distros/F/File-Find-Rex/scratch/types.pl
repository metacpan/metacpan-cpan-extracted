use 5.006;
use strict;
use warnings;
use feature 'say';

my $str = 'ff';
my @arr = ();
my %hsh = ();

my $regex = '^a';
$regex = qr/$regex/i;

say ref \&callback;

sub callback {

}
