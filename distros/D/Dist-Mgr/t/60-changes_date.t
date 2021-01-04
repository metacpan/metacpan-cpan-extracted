use warnings;
use strict;
use feature 'say';

use Carp;
use Cwd qw(getcwd);
use Data::Dumper;
use Test::More;
use Dist::Mgr qw(:all);
use version;

use lib 't/lib';
use Helper qw(:all);

my $cwd = getcwd();
like $cwd, qr/dist-mgr$/, "in root dir ok";
die "not in the root dir" if $cwd !~ /dist-mgr$/;

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
