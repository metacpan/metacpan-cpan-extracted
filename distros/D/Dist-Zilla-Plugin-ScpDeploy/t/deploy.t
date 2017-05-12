#! perl

use strict;
use warnings;

use Test::More  0.88;
use Test::Fatal 0.006;
use Test::DZil;

main( 'Dist::Zilla::Plugin::ScpDeploy' );

sub main
{
    my $module = shift;
    setup( $module );

    use_ok( $module ) or exit;

    test_release( $module );

    done_testing();
}

sub make_deployer
{
    return Builder->from_config(
        { dist_root => 'corpus/DeployTest' },
        {
            add_files => {
                'source/dist.ini' => simple_ini(
                    {
                        name      => 'DeployTest',
                        version   => '1.2.3',
                    },
                    [
                        'ScpDeploy' =>
                        {
                            hosts      => 'huey, dewey,louie',
                            command    => 'run_me',
                            remote_dir => '/home/cbarks/vault',
                        },
                    ]
                ),
            },
        },
    );

}

sub test_release
{
    my $module   = shift;

    # all the magic happens here
    make_deployer()->release;

    my @calls    = map { read_system() } 1 .. 6;

    is_deeply $calls[0],
        [qw( scp DeployTest-1.2.3.tar.gz huey:/home/cbarks/vault )],
        'release() should scp archive file to archive dir at host';

    is_deeply $calls[2],
        [qw( scp DeployTest-1.2.3.tar.gz dewey:/home/cbarks/vault )],
        '... for each host';

    is_deeply $calls[4],
        [qw( scp DeployTest-1.2.3.tar.gz louie:/home/cbarks/vault )],
        '... in comma and space separated list';

    is_deeply $calls[1],
        [qw( ssh huey run_me /home/cbarks/vault/DeployTest-1.2.3.tar.gz )],
        '... and should use ssh to run command with archived location';

    is_deeply $calls[3],
        [qw( ssh dewey run_me /home/cbarks/vault/DeployTest-1.2.3.tar.gz )],
        '... for each host';

    is_deeply $calls[5],
        [qw( ssh louie run_me /home/cbarks/vault/DeployTest-1.2.3.tar.gz )],
        '... in comma and space separated list';
}

sub setup
{
    my $module = shift;
    eval <<END_PACKAGE;
    package $module;
    use subs 'system';
END_PACKAGE

    no strict 'refs';
    *{ $module . '::system' } = \&fake_system;
}

{
    my @system;

    sub fake_system { push @system, [ @_ ] }
    sub read_system { return shift @system }
}
