use strict;
use warnings;
use DB_File;

my %hash;
tie %hash, 'DB_File', glob('cmudict.db'), O_RDWR|O_CREAT, 0644, $DB_File::DB_HASH or die "Can't tie: $!";

open CMUDICT, "<cmudict.0.7a" or die "Can't open source: $!";
while (<CMUDICT>) {
  chomp;
  next unless $_;
  next if /^;/; # ignore comments
  my ($latin, $pronunciation) = split /  /, $_, 2;

  $hash{$latin} = $pronunciation;
}

close CMUDICT or die "Can't close source: $!";
untie %hash or die "Can't untie: $!";

