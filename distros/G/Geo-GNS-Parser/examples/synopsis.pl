#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use Geo::GNS::Parser 'parse_file';
my $in_file = 'ja.txt';
my %lines;
my $n_entries;
my $n_places;
binmode STDOUT, ":encoding(utf8)";
parse_file (file => $in_file, callback => \& callback);
print "$n_entries / $n_places\n";
exit;

sub callback
{
    my (undef, $line) = @_;
    $n_entries++;
    my @parts = split /\t/, $_;
    my $ufi = $line->{UFI};
    if (my $e = $lines{$ufi}) {
        print "Duplicate $ufi for $line->{FULL_NAME_RO} $e->{FULL_NAME_RO}\n";
    }
    else {
        $lines{$ufi} = $line;
        $n_places++;
    }
}
