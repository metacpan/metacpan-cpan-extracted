use warnings;
use strict;

use Cwd qw(getcwd);
use Data::Dumper;
use Test::More;
use Hook::Output::Tiny;
use Dist::Mgr qw(:all);
use Mock::Sub;

use lib 't/lib';
use Helper qw(:all);

my $cwd = getcwd();
my $in_cwd = getcwd() =~ qr/dist-mgr$/;

my $init_dir = 't/data/work/init';

my $h = Hook::Output::Tiny->new;
my $m = Mock::Sub->new;

my $sub = $m->mock(
    'Dist::Mgr::_default_distribution_file_count',
    return_value => files_data()
);

my %module_args = (
    author  => 'Steve Bertrand',
    email   => 'steveb@cpan.org',
    modules => [qw(Test::MoveFiles)],
    license => 'artistic2',
    builder => 'ExtUtils::MakeMaker',
);

is $in_cwd, 1, "in repo root dir ok";

remove_init();

{
    # No module name param

    is
        eval { move_distribution_files(); 1 },
        undef,
        "move_distribution_files() needs a module name sent in";
    like $@, qr/requires a module name/, "...and error is sane";

    # Invalid source dir check (Not a directory)

    is
        eval { move_distribution_files('Test/Module'); 1 },
        undef,
        "move_distribution_files() croaks with bad source dir";
    like $@, qr/move files from the/, "...and error is sane";

    # Bad file count data comparison

    mkdir $init_dir or die $! if ! -e $init_dir;
    chdir $init_dir or die $!;

    my $in_init_dir = getcwd() =~ qr|dist-mgr/$init_dir$|;
    is $in_init_dir, 1, "in the init directory ok";

    if (! $in_init_dir) {
        my $dir = getcwd();
        die "We're not in the 'init' directory, we're in $dir!";
    }

    $h->hook('stderr');
    init(%module_args);
    $h->unhook('stderr');

    is
        eval { move_distribution_files('Test-MoveFiles'); 1 },
        undef,
        "move_distribution_files() croaks with mismatched file move count";
    is $sub->called, 1, "_default_distribution_file_count() mock called ok";
    like $@, qr/Results.*are mismatched/, "...and error is sane";
}

chdir $cwd or die $!;
is $in_cwd, 1, "back in repo root dir";
remove_init();

done_testing;

sub files_data {
    return [
        [ [1, 0, 0] ],
        [ [1, 0, 0] ],
        [ [3, 2, 0] ],
        [ [1, 0, 0] ],
        [ [1, 0, 0] ],
        [ [1, 0, 0] ],
        [ [5, 1, 0] ],
        [ [2, 1, 99] ], # modified very last entry for test
    ];
};
