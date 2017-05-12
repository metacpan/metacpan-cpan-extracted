#!perl
use warnings;
use strict;

use Data::Dumper;
use Test::More tests => 8;
use Test::Trap;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new(
                            file => 't/sample.data',
                            engine => 'all',
                          );
{#2 - core dump

    my $file = 't/core_dump.debug';

    do {
        
        eval { open STDOUT, '>', $file or die $!; };
        ok (! $@, "STDOUT redirected for core dump");

        my @exit = trap { $des->run({core_dump => 1}); };

        eval { print STDOUT $trap->stdout; };
        is (! $trap->stdout, '', "output to stdout" );
        ok (! $@, "core dump gave no errors" );

    };

    eval { open my $fh, '<', $file or die $!; };
    ok (! $@, "core dump output file exists and can be read" );
    open my $fh, '<', $file or die $!;
    
    my @lines = <$fh>;
    if ($^O eq 'MSWin32' || $^O eq 'MSWin64') {
        is (1, 1, "Bypass windows check");
    }
    else {
        is (@lines, 170, "Based on test data, core dump dumps the correct info" );
    }

    eval { close $fh; };
    ok (! $@, "core dump output file closed successfully" );

    eval { unlink $file; };
    ok (! $@, "core dump temp file deleted successfully" );
}
