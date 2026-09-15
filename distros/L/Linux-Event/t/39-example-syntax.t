use v5.36;
use strict;
use warnings;

use Config;
use FindBin qw($Bin);
use Test::More;

my @example = sort glob "$Bin/../examples/*.pl";
ok(@example, 'distribution contains examples');

for my $path (@example) {
    my $name = $path =~ s{.*/}{}r;

    SKIP: {
        skip "$name requires ithreads", 1
            if $name eq 'wakeup-thread.pl' && !$Config{useithreads};

        my $status = system(
            $^X, "-I$Bin/../blib/lib", "-I$Bin/../blib/arch", '-c', $path,
        );
        is($status >> 8, 0, "$name compiles");
    }
}

done_testing;
