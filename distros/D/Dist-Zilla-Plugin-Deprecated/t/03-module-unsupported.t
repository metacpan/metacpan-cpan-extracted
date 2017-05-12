use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Path::Tiny;

use Test::Needs { 'Dist::Zilla' => '5.022' };
plan skip_all => 'CPAN::Meta::Merge earlier than 2.150002 required for these tests'
    if eval { require CPAN::Meta::Merge; CPAN::Meta::Merge->VERSION('2.150002') };

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MetaConfig => ],
                [ 'Deprecated' => { module => 'Foo::Bar' } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            path(qw(source lib Foo Bar.pm)) => "package Foo::Bar;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
like(
    exception { $tzil->build },
    qr/^\Q[Deprecated] CPAN::Meta::Merge 2.150002 required to deprecate an individual module!\E/,
    'build fails with the appropriate error',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
