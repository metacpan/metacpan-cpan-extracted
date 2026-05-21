use strict;
use warnings;
use Test::More;
use Path::Tiny qw( tempdir );

# This test only verifies the module loads without crashing
# Git functionality requires Git::Raw which may not be available
subtest 'Git module loads without segfault' => sub {
    # Just try to load the module, don't actually use Git::Raw
    eval 'require MCP::Wiki::Git; 1';
    ok(!$@ || $@ =~ /Git::Raw/, 'module loads (or fails gracefully on Git::Raw)');
};

done_testing;