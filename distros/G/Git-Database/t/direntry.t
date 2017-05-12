use strict;
use warnings;
use Test::More;

use Git::Database::DirectoryEntry;

my @methods = qw(
    is_tree
    is_blob
    is_executable
    is_link
    is_submodule
);

# only tests the modes that Git produces
my @tests = (
    [ '040000', 1,  '', '', '', '' ],    # subdirectory (tree)
    [ '100644', '', 1,  '', '', '' ],    # file (blob)
    [ '100755', '', 1,  1,  '', '' ],    # executable (blob)
    [ '120000', '', 1,  '', 1,  '' ],    # symlink
    [ '160000', '', 1,  '', '', 1 ],     # submodule (commit)
);

for my $t (@tests) {
    my ( $mode, @bool ) = @$t;

    my $de = Git::Database::DirectoryEntry->new(
        mode     => $mode,
        filename => 'hello',
        digest   => '0000000000000000000000000000000000000000',    # not used
    );

    # test boolean methods
    is( $de->$_, shift @bool, "$mode - $_" ) for @methods;

    # test output methods
    is( $de->as_content, sprintf( "$mode %s\0" . "\0" x 20, $de->filename ),
        'as_content' );
    is( $de->as_string,
        sprintf(
            "$mode %s %s\t%s\n",
            $de->is_tree ? 'tree' : 'blob',
            '0' x 40, $de->filename
        ),
        'as_string'
    );
}

done_testing;
