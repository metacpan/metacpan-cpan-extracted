#!perl
use warnings;
use strict;

use Test::More tests => 8;
use Test::Trap;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new(
                            file => 't/sample.data',
                            engine => 'all',
                          );
{#2 - engine dump

    my $file = 't/engine_dump.debug';

    do {
        
        eval { open STDOUT, '>', $file or die $!; };
        ok (! $@, "STDOUT redirected for engine dump");

        my @exit = trap { $des->run({engine_dump => 1}); };

        eval { print STDOUT $trap->stdout; };
        is (! $trap->stdout, '', "output to stdout" );
        ok (! $@, "engine dump gave no errors" );

    };

    eval { open my $fh, '<', $file or die $!; };
    ok (! $@, "engine dump output file exists and can be read" );
    open my $fh, '<', $file or die $!;
    
    my @lines = <$fh>;
    is (@lines, 13, "Based on test data, engine dump dumps the correct info" );

    eval { close $fh; };
    ok (! $@, "engine dump output file closed successfully" );

    eval { unlink $file; };
    ok (! $@, "engine dump temp file deleted successfully" );
}
