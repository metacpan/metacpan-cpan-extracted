use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use Test::Deep;

use Test::Needs { 'Dist::Zilla::Plugin::MakeMaker' => '5.022' };

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MakeMaker => ],
                [ DualLife  => { entered_core => '5.012' } ],
            ),
            path(qw(source lib warnings.pm)) => "package warnings;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

my $build_dir = path($tzil->tempdir)->child('build');

my $file = $build_dir->child('Makefile.PL');
ok(-e $file, 'Makefile.PL created');

my $makefile = $file->slurp_utf8;
unlike($makefile, qr/[^\S\n]\n/, 'no trailing whitespace in modified file');

unlike(
    $makefile,
    qr/\$WriteMakefileArgs\{INSTALLDIRS\} = 'perl'/,
    'Makefile.PL does not have INSTALLDIRS override when module entered core after 5.011',
);

cmp_deeply(
    [ grep { /^\[DualLife\]/ } @{ $tzil->log_messages } ],
    [ '[DualLife] this module entered core after 5.011 - nothing to do here' ],
    'warning given that this plugin is not adding anything',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
