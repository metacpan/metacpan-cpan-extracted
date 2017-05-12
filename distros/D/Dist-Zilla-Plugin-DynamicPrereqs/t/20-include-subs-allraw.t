use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;
use Test::Deep;
use Dist::Zilla::Plugin::DynamicPrereqs;

use Test::File::ShareDir
    -share => { -module => { 'Dist::Zilla::Plugin::DynamicPrereqs' => 'share/DynamicPrereqs' } };

use lib 't/lib';
use Helper;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MakeMaker => ],
                [ DynamicPrereqs => {
                        -raw => [
                            q|if (isnt_os('bunk')) {|,
                            q|$WriteMakefileArgs{PREREQ_PM}{strict} = substr('123', 0, 1);|,
                            '}',
                        ],
                    } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

cmp_deeply(
    $tzil->distmeta,
    superhashof({
        dynamic_config => 1,
        prereqs => {
            configure => {
                requires => {
                    'ExtUtils::MakeMaker' => ignore,
                }
            },
        },
    }),
    'no prereqs added for included subs',
)
or diag 'found metadata: ', explain $tzil->distmeta;

my $build_dir = path($tzil->tempdir)->child('build');
my $file = $build_dir->child('Makefile.PL');
ok(-e $file, 'Makefile.PL created');

my $makefile = $file->slurp_utf8;
unlike($makefile, qr/[^\S\n]\n/, 'no trailing whitespace in modified file');
unlike($makefile, qr/\t/m, 'no tabs in modified file');

isnt(
    index(
        $makefile,
        "if (isnt_os('bunk')) {\n\$WriteMakefileArgs{PREREQ_PM}{strict} = substr('123', 0, 1);\n}\n",
    ),
    -1,
    'code inserted into Makefile.PL is correct',
);

#(^  \S+$)+
#\}.*\z/sm,
like(
    $makefile,
    qr/
# inserted by Dist::Zilla::Plugin::DynamicPrereqs $Dist::Zilla::Plugin::DynamicPrereqs::VERSION
sub isnt_os \{
(^  [^\n]+\n)+\}\n\z/sm,
    "Makefile.PL contains definition for isnt_os(), and no other subs",
);

run_makemaker($tzil);

{
    no strict 'refs';
    cmp_deeply(
        \%{'main::MyTestMakeMaker::'},
        superhashof({
            map {; $_ => *{"MyTestMakeMaker::$_"} } 'isnt_os',
        }),
        'Makefile.PL defined all required subroutines',
    ) or diag 'Makefile.PL defined symbols: ', explain \%{'main::MyTestMakeMaker::'};
}

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
