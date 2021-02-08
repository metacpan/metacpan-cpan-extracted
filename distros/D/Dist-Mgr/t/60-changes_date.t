use warnings;
use strict;
use feature 'say';

use Carp;
use Cwd qw(getcwd);
use Data::Dumper;
use Test::More;
use Dist::Mgr qw(:private);
use version;

use lib 't/lib';
use Helper qw(:all);

check_skip();

my $cwd = getcwd();
like $cwd, _dist_dir_re(), "in root dir ok";
die "not in the root dir" if $cwd !~ _dist_dir_re();

my $work = 't/data/work';
my $orig_changes = 't/data/orig/Changes-release';

unlink_changes();

# MD5 & content comparisons
{
    copy_changes();

    changes_date("$work/Changes-prerelease");

    file_compare("$work/Changes-prerelease", "$work/Changes-release");

    unlink_changes();
}

unlink_changes();

done_testing;
