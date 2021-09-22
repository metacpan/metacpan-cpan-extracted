# -*- mode: perl; -*-

use strict;
use warnings;

use Test::More tests => 3;

use IO::File;
use IO::Dir;
#use Sort::Versions qw< versioncmp >;

my @found;      # all changelog files found

my $dh = IO::Dir -> new('.')
  or die "can't open the current directory for reading: $!";
for my $filename ($dh -> read()) {
    next unless $filename =~ /change(s|.*log)/i && -f $filename;
    my @info = stat(_);
    my ($dev, $ino, $size) = @info[0,1,7];
    push @found, [ $filename, $size ];
}
$dh -> close()
  or die "can't close directory after reading: $!";

my $changes_filename = $found[0][0];
my $changes_filesize = $found[0][1];

if (!cmp_ok(scalar(@found), '==', 1,
            qq|found one changelog file: "$changes_filename"|))
{
    if (@found) {
        diag(qq|  Found the following changelog files:\n\n|,
             map("    " . $_->[0] . "\n", @found), "\n");
    } else {
        diag(qq|  Found no changelog files.|);
    }
}

cmp_ok($changes_filesize, '>', 0, 'changelog file is non-empty')
  or diag("  Change log file is empty");

my @versions = ();
my $fh = IO::File -> new($changes_filename)
  or die "$changes_filename: can't open file for reading: $!\n";
while (defined(my $line = <$fh>)) {
    if ($line =~ /^(\d\S+)/) {
        push @versions, [ $1, $. ];
    }
}
$fh -> close()
  or die "$changes_filename: can't close file after reading: $!\n";

subtest "Version number order" => sub {
    plan tests => $#versions;

    for (my $i = 1 ; $i <= $#versions ; $i++) {
        my $vb = $versions[$i - 1][0];
        my $lb = $versions[$i - 1][1];
        my $va = $versions[$i][0];
        my $la = $versions[$i][1];
        my $test = "version number $vb on line $lb follows "
                 . "version number $va on line $la";
        #if (versioncmp($vb, $va) > 0) {
        if ($vb > $va) {
            pass($test);
        } else {
            fail($test);
        }
    }
};
