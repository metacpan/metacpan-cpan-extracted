#!/usr/bin/perl

use DB_File;
use IO::Zlib;

my %wordlist;

my $dir = './blib/lib/Lingua/EN/NamedEntity';

print  "\n";
print  "I'm going to write some wordlists as DB_Files into a subdirectory\n";
print  "in your home directory, to decrease start-up time.\n";

#my $dir = ((getpwuid $<)[7]). "/.namedentity";
#if (-d $dir) {
#  print  "Except I see you'd already got some. Carry on, then!\n";
#  return 1;
#}

unless (-d $dir) {
  mkdir $dir or die "Well, I can't seem to create $dir - $!\n";
}

tie %wordlist, "DB_File", "$dir/wordlist"
  or die "Something went wrong with DB_File [$!]\n";

print  "Opening wordlist...\n";
$dict = new IO::Zlib;

$dict->open("data/dictionary.gz", "rb") or die("Can not open wordlist dictionary.gz");
my $count = 0;
while (<$dict>) {
    chomp;
    next if /[A-Z]/;
    $wordlist{$_}=1;

    if ($count % 10000 == 0) {print "$count words done\n"; }
    $count++;
}
print  "\n";

print  "Converting the forename list\n";
my %forename;
tie %forename, "DB_File", "$dir/forename"
  or die "Something went wrong with DB_File";
open IN, "data/givennames-ol" or die "Couldn't open data file: $!";
my $size = -s "data/givennames-ol";
my %said;
while (<IN>) {
    chomp;
    s/[^a-zA-Z ]//g;
    $forename{lc $_}=1;
    my $percent = int(100*(tell(IN)/$size));
    print  $percent, "% " unless $percent %10 or $said{$percent}++;
}
print  "\n";


