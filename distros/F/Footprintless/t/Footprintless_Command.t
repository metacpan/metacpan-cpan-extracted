use strict;
use warnings;

use Data::Dumper;
use Footprintless::Command qw(
    batch_command
    command
    command_options
    cp_command
    mkdir_command
    pipe_command
    rm_command
    sed_command
    tail_command
    write_command
);
use Test::More tests => 48;

BEGIN { use_ok('Footprintless::Command') }

eval {
    require Log::Any::Adapter;
    Log::Any::Adapter->set( 'Stdout', log_level => 'error' );
};

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
    'curl http://www.google.com|sed -e \'s/google/gaggle/g\'|ssh fred@baz "sudo -u joe dd of=\\"/tmp/gaggle.com\\"";ssh fred@baz "sudo -u joe rm -f \\"/tmp/google.com\\""',
    'crazy command'
);
is( batch_command( "echo abc;", "echo def;" ), 'echo abc;echo def', 'wrap does remove ;' );
is( batch_command( "echo abc;", "echo def;", { subshell => 'bash -c ' } ),
    'bash -c "echo abc;echo def"',
    'batch subshell'
);
is( command(
        batch_command(
            "pid=\$(cat /var/run/bard/bard.pid)",
            "kill -0 \$pid",
            "if [[ \$? ]]",
            "then printf 'bard (pid \%s) is running...' \"\$pid\"",
            "else printf 'bard is stopped...'",
            "fi",
            { subshell => 'bash -c ' },
        ),
        command_options(
            ssh           => 'ssh -q -t',
            hostname      => 'foo',
            sudo_username => 'bar'
        )
    ),
    'ssh -q -t foo "sudo -u bar bash -c \\"pid=\\\\\\$(cat /var/run/bard/bard.pid);kill -0 \\\\\\$pid;if [[ \\\\\\$? ]];then printf \'bard (pid %s) is running...\' \\\\\\"\\\\\\$pid\\\\\\";else printf \'bard is stopped...\';fi\""',
    'batch subshell status'
);

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
is( command("find . -exec cat {} \\;"), 'find . -exec cat {} \;', 'wrap doesn\'t remove ;' );
is( command( 'echo', command_options( sudo_command => '/opt/sudo' ) ),
    'echo', 'sudo command no sudo user' );
is( command( 'echo', command_options( sudo_command => '/opt/sudo', sudo_username => 'foo' ) ),
    '/opt/sudo -u foo echo',
    'sudo command and sudo user'
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
is( cp_command( "abc", "def" ),
    'tar -c -C abc .|tar --no-overwrite-dir -x -C def',
    'directory cp_command simple'
);
is( cp_command( "abc", command_options( hostname => 'foo', sudo_username => 'foo_user' ), "def" ),
    'ssh foo "sudo -u foo_user tar -c -C abc ."|tar --no-overwrite-dir -x -C def',
    'directory cp_command source options'
);
is( cp_command(
        "abc", command_options( hostname => 'foo', sudo_username => 'foo_user' ),
        "def", command_options( hostname => 'bar', sudo_username => 'bar_user' )
    ),
    'ssh foo "sudo -u foo_user tar -c -C abc ."|ssh bar "sudo -u bar_user tar --no-overwrite-dir -x -C def"',
    'directory cp_command source and destination options'
);
is( cp_command(
        "abc", command_options( hostname => 'foo', sudo_username => 'foo_user' ),
        "def",
        command_options( hostname => 'bar', sudo_username => 'bar_user' ),
        compress => 1
    ),
    'ssh foo "sudo -u foo_user tar -c -C abc .|gzip"|ssh bar "gunzip|sudo -u bar_user tar --no-overwrite-dir -x -C def"',
    'directory compress cp_command source and destination options'
);
is( cp_command(
        "abc", command_options( hostname => 'foo', sudo_username => 'foo_user' ),
        "def", command_options( hostname => 'bar', sudo_username => 'bar_user' ),
        compress => 1,
        status   => 1
    ),
    'ssh foo "sudo -u foo_user tar -c -C abc .|pv -f -s \`sudo -u foo_user du -sb abc|cut -f1\`|gzip"|ssh bar "gunzip|sudo -u bar_user tar --no-overwrite-dir -x -C def"',
    'directory compress cp_command source and destination options with status'
);
is( cp_command( "abc", "def", archive => 'zip' ),
    'bash -c "cd abc;zip -qr - ."|dd of=def/temp_cp_command.zip;unzip -qod def def/temp_cp_command.zip;rm -f "def/temp_cp_command.zip"',
    'directory unzip cp_command simple'
);
is( cp_command(
        "abc", command_options( hostname => 'foo', sudo_username => 'foo_user' ),
        "def",
        command_options( hostname => 'bar', sudo_username => 'bar_user' ),
        archive => 'zip'
    ),
    'ssh foo "sudo -u foo_user bash -c \"cd abc;zip -qr - .\""|ssh bar "sudo -u bar_user dd of=def/temp_cp_command.zip;sudo -u bar_user unzip -qod def def/temp_cp_command.zip;sudo -u bar_user rm -f \"def/temp_cp_command.zip\""',
    'directory unzip cp_command with command options'
);
is( cp_command(
        "abc",
        command_options(
            hostname      => 'foo',
            sudo_command  => '/opt/sudo',
            sudo_username => 'foo_user'
        ),
        "def",
        command_options(
            hostname      => 'bar',
            sudo_command  => '/usr/depot/bin/sudo',
            sudo_username => 'bar_user'
        ),
        archive => 'zip'
    ),
    'ssh foo "/opt/sudo -u foo_user bash -c \"cd abc;zip -qr - .\""|ssh bar "/usr/depot/bin/sudo -u bar_user dd of=def/temp_cp_command.zip;/usr/depot/bin/sudo -u bar_user unzip -qod def def/temp_cp_command.zip;/usr/depot/bin/sudo -u bar_user rm -f \"def/temp_cp_command.zip\""',
    'directory unzip cp_command with sudo command and command options'
);

is( mkdir_command( 'foo', 'bar', command_options( hostname => 'baz' ) ),
    'ssh baz "mkdir -p \\"foo\\" \\"bar\\""',
    'remote mkdirs foo and bar'
);

is( pipe_command( 'cat abc', command( 'dd of=def', command_options( hostname => 'baz' ) ) ),
    'cat abc|ssh baz "dd of=def"',
    'pipe cat to remote dd'
);

is( rm_command('/foo'),  'rm -f "/foo"',   'rm file' );
is( rm_command('/foo/'), 'rm -rf "/foo/"', 'rm dir' );
is( rm_command( '/foo',  '/bar',  'baz' ),  'rm -f "/bar" "/foo" "baz"',     'rm files' );
is( rm_command( '/foo/', '/bar/', 'baz/' ), 'rm -rf "/bar/" "/foo/" "baz/"', 'rm dirs' );
is( rm_command( '/foo', '/bar/', 'baz', 'foz/' ),
    'bash -c "rm -rf \\"/bar/\\" \\"foz/\\";rm -f \\"/foo\\" \\"baz\\""',
    'rm files and dirs'
);

is( sed_command('s/foo/bar/'), 'sed -e \'s/foo/bar/\'', 'simple sed' );

is( tail_command( 'access_log', lines => 10 ),
    'tail -n 10 access_log',
    'tail 10 lines access_log'
);
is( tail_command( 'access_log', follow => 1 ), 'tail -f access_log', 'tail access_log' );
is( tail_command( 'access_log', follow => 1, command_options( sudo_username => 'apache' ) ),
    'sudo -u apache tail -f access_log',
    'tail access_log'
);
is( tail_command(
        'access_log',
        follow => 1,
        command_options( sudo_username => 'apache', hostname => 'localhost' )
    ),
    'ssh localhost "sudo -u apache tail -f access_log"',
    'tail access_log localhost'
);
is( tail_command(
        'access_log',
        follow => 1,
        command_options( sudo_username => 'apache', hostname => 'foo' )
    ),
    'ssh foo "sudo -u apache tail -f access_log"',
    'tail access_log foo'
);
is( tail_command(
        'access_log',
        follow => 1,
        command_options( ssh => 'ssh -q', sudo_username => 'apache', hostname => 'foo' )
    ),
    'ssh -q foo "sudo -u apache tail -f access_log"',
    'ssh -q tail access_log foo'
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
