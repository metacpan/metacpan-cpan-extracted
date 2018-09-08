use 5.006;
use strict;
use warnings;
use feature 'say';
use File::Find::Rex;

my $rex = new File::Find::Rex;
$rex->set_option('recursive', 1);
my @files = $rex->query('../xt');

foreach (@files) { say $_; }
