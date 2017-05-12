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
    post_proc => ['file_lines_contain', 'subs', 'objects'],
);

{#2 - post_proc dump

    my $file = 't/post_proc_dump.debug';

    do {
        
        eval { open STDOUT, '>', $file or die $!; };
        ok (! $@, "STDOUT redirected for post_proc dump");

        my @exit = trap { $des->run({post_proc_dump => 2}); };

        eval { print STDOUT $trap->stdout; };
        is (! $trap->stdout, '', "output to stdout" );
        ok (! $@, "post_proc dump gave no errors" );

    };

    eval { open my $fh, '<', $file or die $!; };
    ok (! $@, "post_proc dump output file exists and can be read" );
    open my $fh, '<', $file or die $!;
    
    my @lines = <$fh>;
    is (@lines, 138, "Based on test data, post_proc dump dumps the correct info" );

    eval { close $fh; };
    ok (! $@, "post_proc dump output file closed successfully" );

    eval { unlink $file; };
    ok (! $@, "post_proc dump temp file deleted successfully" );
}

