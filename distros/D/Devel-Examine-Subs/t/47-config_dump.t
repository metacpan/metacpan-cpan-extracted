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
{#2 - config dump

    my $file = 't/config_dump.debug';
    $des->has(include => [qw(one)]);
    $des->has(include => [qw(one)]);

    do {
        
        eval { open STDOUT, '>', $file or die $!; };
        ok (! $@, "STDOUT redirected for config dump");

        my @exit = trap { $des->run({config_dump => 2}); };

        eval { print STDOUT $trap->stdout; };
        is (! $trap->stdout, '', "output to stdout" );
        ok (! $@, "config dump gave no errors" );

    };

    eval { open my $fh, '<', $file or die $!; };
    ok (! $@, "config dump output file exists and can be read" );
    open my $fh, '<', $file or die $!;
    
    my @lines = <$fh>;
    is (@lines, 6, "Based on test data, config dump dumps the correct info" );

    eval { close $fh; };
    ok (! $@, "config dump output file closed successfully" );

    eval { unlink $file; };
    ok (! $@, "config dump temp file deleted successfully" );
}
