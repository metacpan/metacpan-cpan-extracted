use strict;
use warnings;

use Test::More tests => 34;

BEGIN { use_ok('IPC::Open3::Callback::Command') }

use IPC::Open3::Callback::Command
    qw(batch_command command command_options cp_command mkdir_command pipe_command rm_command sed_command write_command);

is( command('echo'), 'echo', 'command' );
is( command( 'echo', command_options( hostname => 'foo' ) ), 'ssh foo "echo"', 'remote command' );
is( command( 'echo', command_options( username => 'bar', hostname => 'foo' ) ),
    'ssh bar@foo "echo"',
    'remote command as user'
);
is( command( 'echo', command_options( username => 'bar', hostname => 'foo', ssh => 'plink' ) ),
    'plink -l bar foo "echo"',
    'plink command as user'
);
is( batch_command( 'cd foo', 'cd bar' ), 'cd foo;cd bar', 'batch cd foo then bar' );
is( batch_command( 'cd foo', 'cd bar', command_options( hostname => 'baz' ) ),
    'ssh baz "cd foo;cd bar"',
    'remote batch cd foo then bar'
);
is( batch_command(
        'cd foo', 'cd bar', command_options( hostname => 'baz', sudo_username => '' )
    ),
    'ssh baz "sudo cd foo;sudo cd bar"',
    'remote batch sudo cd foo then bar'
);
is( mkdir_command( 'foo', 'bar', command_options( hostname => 'baz' ) ),
    'ssh baz "mkdir -p \\"foo\\" \\"bar\\""',
    'remote mkdirs foo and bar'
);
is( pipe_command( 'cat abc', command( 'dd of=def', command_options( hostname => 'baz' ) ) ),
    'cat abc|ssh baz "dd of=def"',
    'pipe cat to remote dd'
);
is( rm_command(
        'foo', 'bar',
        command_options( username => 'fred', hostname => 'baz', sudo_username => 'joe' )
    ),
    'ssh fred@baz "sudo -u joe rm -rf \\"foo\\" \\"bar\\""',
    'remote sudo rm'
);
is( sed_command('s/foo/bar/'), 'sed -e \'s/foo/bar/\'', 'simple sed' );
is( batch_command(
        pipe_command(
            'curl http://www.google.com',
            sed_command( { replace_map => { google => 'gaggle' } } ),
            command(
                'dd of="/tmp/gaggle.com"',
                command_options( username => 'fred', hostname => 'baz', sudo_username => 'joe' )
            )
        ),
        rm_command(
            '/tmp/google.com',
            command_options( username => 'fred', hostname => 'baz', sudo_username => 'joe' )
        )
    ),
    'curl http://www.google.com|sed -e \'s/google/gaggle/g\'|ssh fred@baz "sudo -u joe dd of=\\"/tmp/gaggle.com\\"";ssh fred@baz "sudo -u joe rm -rf \\"/tmp/google.com\\""',
    'crazy command'
);
is( write_command( 'skeorules.reasons', 'good looks', 'smarts', 'cool shoes, not really' ),
    'printf "good looks\nsmarts\ncool shoes, not really"|dd of=skeorules.reasons',
    'write command'
);
is( write_command(
        'skeorules.reasons',
        'good looks',
        'smarts',
        'cool shoes, not really',
        command_options(
            hostname      => 'somewhere-out-there',
            sudo_username => 'over-the-rainbow'
        )
    ),
    'printf "good looks\\nsmarts\\ncool shoes, not really"|ssh somewhere-out-there "sudo -u over-the-rainbow dd of=skeorules.reasons"',
    'write command with command_options'
);
is( write_command(
        'skeorules.reasons',
        'good looks',
        'smarts',
        'cool shoes, not really',
        { mode => 700 },
        command_options(
            hostname      => 'somewhere-out-there',
            sudo_username => 'over-the-rainbow'
        )
    ),
    'printf "good looks\\nsmarts\\ncool shoes, not really"|ssh somewhere-out-there "sudo -u over-the-rainbow dd of=skeorules.reasons;sudo -u over-the-rainbow chmod 700 skeorules.reasons"',
    'write command with mode'
);
is( write_command(
        'skeorules.reasons',
        'good looks',
        'smarts',
        'cool shoes, not really',
        { mode => 700, line_separator => '\r\n' },
        command_options(
            hostname      => 'somewhere-out-there',
            sudo_username => 'over-the-rainbow'
        )
    ),
    'printf "good looks\\r\\nsmarts\\r\\ncool shoes, not really"|ssh somewhere-out-there "sudo -u over-the-rainbow dd of=skeorules.reasons;sudo -u over-the-rainbow chmod 700 skeorules.reasons"',
    'write command with line_separator'
);
is( write_command(
        'skeorules.reasons',
        "good\\nlooks",
        'smarts',
        'cool shoes, not really',
        { mode => 700, line_separator => '\r\n' },
        command_options(
            hostname      => 'somewhere-out-there',
            sudo_username => 'over-the-rainbow'
        )
    ),
    'printf "good\\nlooks\\r\\nsmarts\\r\\ncool shoes, not really"|ssh somewhere-out-there "sudo -u over-the-rainbow dd of=skeorules.reasons;sudo -u over-the-rainbow chmod 700 skeorules.reasons"',
    'write command with embedded newline'
);
is( command("find . -exec cat {} \\;"), 'find . -exec cat {} \;', 'wrap doesn\'t remove ;' );
is( batch_command( "echo abc;", "echo def;" ), 'echo abc;echo def', 'wrap does remove ;' );
is( batch_command( "echo abc;", "echo def;", { subshell => 'bash -c ' } ),
    'bash -c "echo abc;echo def"',
    'batch subshell'
);
is( cp_command( "abc", "def", file => 1 ), 'cat abc|dd of=def', 'cp_command file simple' );
is( cp_command( "chick'n biscuit", "\"real\" food", file => 1 ),
    'cat chick\\\'n\ biscuit|dd of=\"real\"\ food',
    'cp_command file simple with escaped file names.'
);
is( cp_command( "abc", command_options( hostname => 'foo' ), "def", file => 1 ),
    'ssh foo "cat abc"|dd of=def',
    'cp_command file source command options'
);
is( cp_command( "abc", "def", command_options( hostname => 'foo' ), file => 1 ),
    'cat abc|ssh foo "dd of=def"',
    'cp_command file destination command options'
);
is( cp_command(
        "abc", command_options( hostname => 'foo' ),
        "def", command_options( hostname => 'bar' ),
        file => 1
    ),
    'ssh foo "cat abc"|ssh bar "dd of=def"',
    'cp_command file source and destination command options'
);
is( cp_command(
        "abc", command_options( hostname => 'foo' ), "def", command_options( hostname => 'bar' ),
        file     => 1,
        compress => 1
    ),
    'ssh foo "gzip -c abc"|ssh bar "gunzip|dd of=def"',
    'cp_command file source and destination command options compressed'
);
is( cp_command( "abc", "def" ), 'tar c -C abc .|tar x -C def', 'directory cp_command simple' );
is( cp_command( "abc", command_options( hostname => 'foo', sudo_username => 'foo_user' ), "def" ),
    'ssh foo "sudo -u foo_user tar c -C abc ."|tar x -C def',
    'directory cp_command source options'
);
is( cp_command(
        "abc", command_options( hostname => 'foo', sudo_username => 'foo_user' ),
        "def", command_options( hostname => 'bar', sudo_username => 'bar_user' )
    ),
    'ssh foo "sudo -u foo_user tar c -C abc ."|ssh bar "sudo -u bar_user tar x -C def"',
    'directory cp_command source and destination options'
);
is( cp_command(
        "abc", command_options( hostname => 'foo', sudo_username => 'foo_user' ),
        "def",
        command_options( hostname => 'bar', sudo_username => 'bar_user' ),
        compress => 1
    ),
    'ssh foo "sudo -u foo_user tar c -C abc .|gzip"|ssh bar "gunzip|sudo -u bar_user tar x -C def"',
    'directory compress cp_command source and destination options'
);
is( cp_command(
        "abc", command_options( hostname => 'foo', sudo_username => 'foo_user' ),
        "def", command_options( hostname => 'bar', sudo_username => 'bar_user' ),
        compress => 1,
        status   => 1
    ),
    'ssh foo "sudo -u foo_user tar c -C abc .|pv -f -s \`sudo -u foo_user du -sb abc|cut -f1\`|gzip"|ssh bar "gunzip|sudo -u bar_user tar x -C def"',
    'directory compress cp_command source and destination options with status'
);
is( cp_command( "abc", "def", archive => 'zip' ),
    'bash -c "cd abc;zip -qr - ."|dd of=def/temp_cp_command.zip;unzip -qod def def/temp_cp_command.zip;rm -rf "def/temp_cp_command.zip"',
    'directory unzip cp_command simple'
);
is( cp_command(
        "abc", command_options( hostname => 'foo', sudo_username => 'foo_user' ),
        "def",
        command_options( hostname => 'bar', sudo_username => 'bar_user' ),
        archive => 'zip'
    ),
    'ssh foo "sudo -u foo_user bash -c \"cd abc;zip -qr - .\""|ssh bar "sudo -u bar_user dd of=def/temp_cp_command.zip;sudo -u bar_user unzip -qod def def/temp_cp_command.zip;sudo -u bar_user rm -rf \"def/temp_cp_command.zip\""',
    'directory unzip cp_command with command options'
);
