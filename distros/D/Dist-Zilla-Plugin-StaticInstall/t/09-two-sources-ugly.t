use strict;
use warnings;

use Test::More 0.96;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

# before this revision, distmeta was merged with Hash::Meta::Merge which did
# not croak on conflicting hash values
use Test::Needs { 'Dist::Zilla' => '5.022' };

use lib 't/lib';

my @tests = (
    {
        x_static_install => 0,
        mode => 'on',
    },
    {
        x_static_install => 1,
        mode => 'off',
    },
);

subtest "preset x_static_install = input of $_->{x_static_install}, our mode = $_->{mode}" => sub
{
    my $config = $_;

    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ MetaConfig => ],
                    [ MetaJSON => ],
                    [ '=SimpleFlagSetter' => { value => $config->{x_static_install} } ],
                    [ 'MakeMaker' ],
                    [ 'StaticInstall' => { mode => $config->{mode} } ],
                ),
                path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);

    my $error = q{Can't merge attribute x_static_install}
        . (eval { +require CPAN::Meta::Merge; CPAN::Meta::Merge->VERSION('2.143240'); 1 }
          ? q{: '} . $config->{x_static_install} . q{' does not equal '} . ($config->{mode} eq 'on' ? 1 : 0) . q{' at }
          : '');

    like(
        exception { $tzil->build },
        qr/$error/,
        'build fails in setup_installer when the results conflict',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}
foreach @tests;

done_testing;
