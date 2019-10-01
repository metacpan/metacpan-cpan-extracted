#!perl

use strict;
use warnings;

use Capture::Tiny qw( capture_stdout );
use Test::More;

## no critic (InputOutput::RequireCheckedSyscalls)
{
    my $stdout = capture_stdout {
        system('perl script/gh-open -e');
    };
    chomp $stdout;

    like( $stdout, qr{https://github.com/\w+/git-helpers}, '-e' );
}

{
    my $stdout = capture_stdout {
        system('perl script/gh-open -b -e');
    };
    chomp $stdout;

    like( $stdout, qr{https://github.com/\w+/git-helpers/tree/\w+}, '-b -e' );
}

done_testing();
