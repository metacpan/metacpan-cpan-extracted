use strict;
use warnings;
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }
use Test::More;

my $cli;
my $result = {};


{
    package CLI_Opts::Test;
    use MOP4Import::Base::CLI_Opts -as_base,
        [options =>
            [
                'dbname|d=s' => doc => "specify database name", default => "data.dat",
            ],
            [
                'root-dir|r=s' => doc => "root directory", default => "./",
            ],
            [
                'commit-num|N=i' => doc => "commit number in survey", default => 1,
            ],
            [
                'dry-run' => doc => "test run!", default => "foo.db",
            ],
            [
                'foo|f' => doc => "foo flag!",
            ],
            [
                'bar|b' => doc => "bar flag!",
            ],
            [
                'nya=s' => doc => "subcmd nya flag!", for_subcmd => 1,
            ],
            [
                'megumi|M=s' => doc => "subcmd imas flag!", for_subcmd => 1,
            ],
            [
                'verbose|v' => doc => "print extra stuff",
            ],
            [
                'config|c=s@' => doc => "config files",
            ],
            [
                'proc|p' => doc => "command!", command => 'process',
            ],
        ],
    ;

    sub cmd_default {
        my ( $c ) = @_;
        $cli = $c;
        $result->{default} = 'default';
    }

    sub cmd_hello {
        my ( $c, @args ) = @_;
        $cli = $c;
        $result->{hello} = [@args];
    }

    sub cmd_process {
        my ( $c, @args ) = @_;
        $cli = $c;
        $result->{process} = 'success';
    }

}


CLI_Opts::Test->run([]);
is_deeply( $result->{default}, 'default', 'call cmd_default when no subcommand specified');
is_deeply( $cli, default_state() );


CLI_Opts::Test->run([qw/-f -b/]);
is_deeply( $cli, default_state(foo => 1, bar => 1) );


CLI_Opts::Test->run([qw/hello/]);
is_deeply( $result->{hello}, [], 'subcommand' );
is_deeply( $cli, default_state() );


CLI_Opts::Test->run([qw/-d data/]);
is_deeply( $result->{default}, 'default', 'call cmd_default when no subcommand specified');
is_deeply( $cli, default_state( dbname => 'data' ) );


CLI_Opts::Test->run([qw/-d=hoge --root-dir=path --commit-num 3 hello foooo baaar/]);
is_deeply( $result->{hello}, [qw/foooo baaar/], 'subcommand and option' );
is_deeply( $cli, default_state( dbname => 'hoge', root_dir => 'path', commit_num => 3 ) );


CLI_Opts::Test->run([qw/-d=hoge --root-dir=path --commit-num 3 hello sakura makoto/]);
is_deeply( $result->{hello}, [qw/sakura makoto/], 'subcommand and option2' );
is_deeply( $cli, default_state( dbname => 'hoge', root_dir => 'path', commit_num => 3 ) );


CLI_Opts::Test->run([qw/-bf hello --nya wan/]);
is_deeply($result->{hello}, [], 'subcmd');
is_deeply( $cli, default_state( foo => 1, bar => 1, nya => 'wan' ) );


CLI_Opts::Test->run([qw/-bfd hoge hello -M makoto/]);
is_deeply( $result->{hello}, [], 'subcmd' );
is_deeply( $cli, default_state( foo => 1, bar => 1, dbname => 'hoge', megumi => 'makoto' ) );


CLI_Opts::Test->run([qw/-bvd hoge --dry-run -N=123 -r huga/]);
is_deeply( $result->{default}, 'default', 'complecated command' );
is_deeply( $cli, default_state( verbose => 1, bar => 1, dbname => 'hoge', dry_run => 1, root_dir => 'huga', commit_num => 123 ) );

CLI_Opts::Test->run([qw/-bvd hoge --dry-run -N=123 -r huga hello --megumi makoto anya/]);
is_deeply( $result->{hello}, [qw/anya/], 'complecated command2');
is_deeply( $cli, default_state( verbose => 1, bar => 1, dbname => 'hoge', dry_run => 1, root_dir => 'huga', commit_num => 123, megumi => 'makoto' ) );


eval { CLI_Opts::Test->run([qw/--nothing/]) };
like( $@, qr/Invalid option format/, $@ );
eval { CLI_Opts::Test->run([qw/-z/]) };
like( $@, qr/Invalid option format/, $@ );


CLI_Opts::Test->run([qw/-bfd-a hoge hello/]);
is_deeply($result->{hello}, [], 'This test is passed but should be fixed.');
is_deeply( $cli, default_state( foo => 1, bar => 1, dbname => 'hoge' ) );

CLI_Opts::Test->run([qw/-c abc -c def/]);
is_deeply( $result->{default}, 'default', 'complecated command' );
is_deeply( $cli, default_state( config => [qw/abc def/] ), 'duplicated opts' );

CLI_Opts::Test->run([qw/-bvc abc -N=123 --config def -r huga hello --megumi makoto anya/]);
is_deeply( $result->{hello}, [qw/anya/], 'complecated command3');
is_deeply( $cli, default_state( verbose => 1, bar => 1, root_dir => 'huga', commit_num => 123, megumi => 'makoto', config => [qw/abc def/] ) );

CLI_Opts::Test->run([qw/--proc/]);
is_deeply( $result->{process}, 'success', 'opt = command' );

done_testing;



sub default_state {
    my (%args) = @_;
    $result = {};
    return {
        'dbname' => 'data.dat',
        'commit_num' => 1,
        'root_dir' => './',
        'dry_run' => 'foo.db',
        '_cmd' => ($cli->{_cmd} // 'default'),
        %args,
    };
}


