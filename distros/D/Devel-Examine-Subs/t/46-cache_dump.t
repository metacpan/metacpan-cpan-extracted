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
                            cache => 1,
                          );
{#2 - cache dump

    my $file = 't/cache_dump.debug';
    $des->has(include => [qw(one)]);
    $des->has(include => [qw(one)]);

    do {
        
        eval { open STDOUT, '>', $file or die $!; };
        ok (! $@, "STDOUT redirected for cache dump");

        my @exit = trap { $des->run({cache_dump => 2}); };

        eval { print STDOUT $trap->stdout; };
        is (! $trap->stdout, '', "output to stdout" );
        ok (! $@, "cache dump gave no errors" );

    };

    eval { open my $fh, '<', $file or die $!; };
    ok (! $@, "cache dump output file exists and can be read" );
    open my $fh, '<', $file or die $!;
    
    my @lines = <$fh>;
    is (@lines, 26, "Based on test data, cache dump dumps the correct info" );

    eval { close $fh; };
    ok (! $@, "cache dump output file closed successfully" );

    eval { unlink $file; };
    ok (! $@, "cache dump temp file deleted successfully" );
}
