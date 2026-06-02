use strict;
use warnings;
use Test::More;
use Pod::Checker;

use lib './lib'; # actually use the module, not other versions installed

my @files = ('lib/Geo/Coder/OpenCage.pm');

for my $file (@files) {
    # Capture Pod::Checker's diagnostic output so test output stays clean,
    # and we can diag() it on failure.
    my $output = '';
    open my $fh, '>', \$output or die "open scalar: $!";

    my $checker = Pod::Checker->new();
    $checker->parse_from_file($file, $fh);
    close $fh;

    is($checker->num_errors, 0, "$file: POD has no errors")
        or diag($output);
}

done_testing();
