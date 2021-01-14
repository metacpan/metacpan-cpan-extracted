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
use Hook::Output::Tiny;

my $cwd = getcwd();
like $cwd, qr/dist-mgr(-\d+\.\d+)?(-\d+)?$/i, "in root dir ok";
die "not in the root dir" if $cwd !~ /dist-mgr(-\d+\.\d+)?(-\d+)?$/i;

my $module_starter_changes_sha = '97624d56464d7254ef5577e4a0c8a098d6c6d9e6';

my $work = 't/data/work';
my $orig_changes = 't/data/orig/Changes';
my $tpl = "t/data/template/module_template/Changes"; # Custom one created by this dist

unlink_changes();

# SHA1 & content comparisons
{
    copy_changes();

    is
        sha1sum("$work/Changes"),
        $module_starter_changes_sha,
        "Changes file created by Module::Starter SHA match ok";

    file_compare("$work/Changes", $orig_changes);

    changes('Acme-STEVEB', "$work/Changes");

    isnt
        sha1sum("$work/Changes"),
        $module_starter_changes_sha,
        "Changes updated has different SHA as the template ok";

    file_compare("$work/Changes", $tpl);

    unlink_changes();
}

unlink_changes();

done_testing;
