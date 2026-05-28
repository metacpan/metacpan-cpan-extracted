use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";
use TestRepo;
use Path::Tiny;
use Git::Native;

# Need a working tree for status, so init non-bare.
my ( $repo, $tmp ) = TestRepo::new_repo();
my $wd = path( $repo->workdir );

# Write an untracked file.
$wd->child('new.txt')->spew('hello');

my $status = $repo->status;
ok exists $status->{'new.txt'}, 'untracked file shows up in status';

# GIT_STATUS_WT_NEW = 1 << 7 = 128.
my $flags = $status->{'new.txt'};
ok( ( $flags & 128 ), "WT_NEW bit set (got $flags)" );

# status_for_path on the same file.
my $single = $repo->status_for_path('new.txt');
is $single, $flags, 'status_for_path matches';

# Empty repo apart from the untracked file - only one entry.
is scalar( keys %$status ), 1, 'one entry in status';

done_testing;
