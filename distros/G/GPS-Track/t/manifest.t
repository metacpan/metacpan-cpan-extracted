use Test::More;
use ExtUtils::Manifest qw/manicheck/;

my @missingFiles = manicheck();

is(scalar(@missingFiles), 0, "there are no file missing from the manifest");

done_testing();
