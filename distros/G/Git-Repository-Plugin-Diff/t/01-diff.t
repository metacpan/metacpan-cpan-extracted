use strict;
use Test::More;

use Git::Repository qw/Diff Log/;
use Test::Git;
use Test::Requires::Git;
use Test::Exception;

# check there is a git binary available, or skip all
test_requires_git();

my $r = test_repository();

my $wt = $r->work_tree();

diag("working_tree $wt");

my $test_file = $wt . "/test";

$| = 1;

ok( open( my $fh, '>', $test_file ), 'Add test file.' )
  || diag("Failed to open $test_file for writing: $!");

print $fh join "\n", 1 .. 10;
close($fh);

$r->run( add    => $test_file );
$r->run( commit => '-m "10"' );

ok( open( my $fh, '>', $test_file ), 'Add test file.' )
  || diag("Failed to open $test_file for writing: $!");

print $fh join "\n", 0,
  2 .. 11;    # start from 0 then hop to 2 till 11 for generating 2 hunks
close($fh);

$r->run( add    => $test_file );
$r->run( commit => '-m "11"' );
close($fh);

my ($log) = $r->log('-1');

my @hunks;
lives_ok(
    sub {
        @hunks = $r->diff( $test_file, 'HEAD', 'HEAD~1' );
    },
    'Git repo get diff'
);

cmp_ok( scalar @hunks, '==', 2 );

my ( $first_hunk, $second_hunk ) = @hunks;

for my $line_kind (qw{from_lines to_lines}) {
    for my $l ( $first_hunk->$line_kind ) {
        my ( $line_num, $line_content ) = @$l;

        if ( ( $line_kind eq 'from_lines' ) && ( $line_num == 1 ) ) {
            cmp_ok( 0, '==', $line_content,
                'Hunk line count is ok for first hunk' );
        }
        else {
            cmp_ok( $line_num, '==', $line_content, 'Hunk line count is ok' );
        }
    }
}

for my $line_kind (qw{from_lines to_lines}) {
    for my $l ( $second_hunk->$line_kind ) {
        my ( $line_num, $line_content ) = @$l;
        cmp_ok( $line_num, '==', $line_content, 'Hunk line count is ok' );
    }
}

lives_ok(
    sub {
        @hunks = $r->diff( $test_file, 'HEAD', 'HEAD' );
    },
    'Git repo get no diff'
);

cmp_ok( scalar @hunks, '==', 0, 'No diff ok' );

done_testing();
