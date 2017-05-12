use strict;
use warnings;

use Test::More;
use Test::Requires 'Dist::Zilla::Plugin::SurgicalPodWeaver';

use Path::Tiny;
use Test::DZil;
use Test::Fatal;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw( source dist.ini )) => simple_ini(
                [ GatherDir         => ],
                [ MakeMaker         => ],
                [ ExecDir           => ],
                [ Prereqs           => { 'Foo' => '0' } ],
                [ 'Conflicts'       => { 'Module::X' => '0.02' } ],
                [ SurgicalPodWeaver => ],
            ),
            path(qw( source lib DZT Sample.pm )) =>
                "package DZT::Sample;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build() },
    undef,
    'build proceeds normally',
);

my $build_dir = path( $tzil->tempdir )->child('build');

my $module_filename = $build_dir->child(qw( lib DZT Sample Conflicts.pm ));
ok( -e $module_filename, 'conflicts module created' );

my $module_content = $module_filename->slurp_utf8();
unlike(
    $module_content, qr/=(pod|head)/,
    'no pod was added to conflicts module'
);

done_testing;
