#!perl
use strict;
use warnings;

use Test::More;

plan skip_all => "Version check not requested" unless
	$ENV{EXTENDED_TESTING} || $ENV{RELEASE_TESTING}
	|| $ENV{AUTHOR_TESTING} || $ENV{AUTOMATED_TESTING};
plan tests => 1;

use Alien::proj;
use File::Spec;


my $bin = File::Spec->catdir(Alien::proj->dist_dir, 'bin', 'cs2cs');
$bin = 'cs2cs' if Alien::proj->install_type eq 'system';

my $out = `$bin 2>&1` // '';
my ($version) = $out =~ m/\b(\d+\.\d+(?:\.\d\w*)?)\b/;

diag sprintf "Alien::proj %s with %s PROJ %s",
	Alien::proj->VERSION, Alien::proj->install_type, $version // "";

# need to run at least one test
pass;

done_testing;
