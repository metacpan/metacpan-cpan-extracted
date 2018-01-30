#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use File::Find::Rex;

my $source = './t';
my %options = (
  ignore_dirs => 1
);
my $rex = new File::Find::Rex(\%options);
my $regexp = qr/^0/;
my @files = $rex->query($source, $regexp);

ok (scalar(@files) == 2); # 6 files including the dirs
done_testing();
