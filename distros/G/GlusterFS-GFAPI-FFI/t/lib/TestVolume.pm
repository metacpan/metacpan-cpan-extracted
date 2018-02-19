package TestVolume;

use parent 'Test', 'Test::Class';

use Carp;
use POSIX;
use Fcntl   qw/:mode/;
use Errno   qw/EEXIST/;
use Try::Tiny;
use Test::Most;
use GlusterFS::GFAPI::FFI;
use GlusterFS::GFAPI::FFI::File;
use GlusterFS::GFAPI::FFI::Dir;
use GlusterFS::GFAPI::FFI::DirEntry;
use GlusterFS::GFAPI::FFI::Volume;
use FFI::Platypus::Memory   qw/memcpy strdup free/;
use Generator::Object;

sub setup : Test(setup)
{
    my $self = shift;

    no warnings 'redefine';

    map
    {
        ${GlusterFS::GFAPI::FFI::}{"glfs_$_"} = $self->{"_saved_glfs_$_"}
            if (defined($self->{"_saved_glfs-$_"}));
    } qw/new set_volfile_server init fini close closedir set_logging/;

    $self->{_saved_glfs_new} = \&GlusterFS::GFAPI::FFI::glfs_new;
    ${GlusterFS::GFAPI::FFI::}{glfs_new} = \&Test::_mock_glfs_new;

    $self->{_saved_glfs_set_volfile_server} = \&GlusterFS::GFAPI::FFI::glfs_set_volfile_server;
    ${GlusterFS::GFAPI::FFI::}{glfs_set_volfile_server} = \&Test::_mock_glfs_set_volfile_server;

    $self->{_saved_glfs_init} = \&GlusterFS::GFAPI::FFI::glfs_init;
    ${GlusterFS::GFAPI::FFI::}{glfs_init} = \&Test::_mock_glfs_init;

    $self->{_saved_glfs_fini} = \&GlusterFS::GFAPI::FFI::glfs_fini;
    ${GlusterFS::GFAPI::FFI::}{glfs_fini} = \&Test::_mock_glfs_fini;

    $self->{_saved_glfs_close} = \&GlusterFS::GFAPI::FFI::glfs_close;
    ${GlusterFS::GFAPI::FFI::}{glfs_close} = \&Test::_mock_glfs_close;

    $self->{_saved_glfs_closedir} = \&GlusterFS::GFAPI::FFI::glfs_closedir;
    ${GlusterFS::GFAPI::FFI::}{glfs_closedir} = \&Test::_mock_glfs_closedir;

    $self->{_saved_glfs_set_logging} = \&GlusterFS::GFAPI::FFI::glfs_set_logging;
    ${GlusterFS::GFAPI::FFI::}{glfs_set_logging} = \&Test::_mock_glfs_set_logging;

    $self->{vol} = GlusterFS::GFAPI::FFI::Volume->new(host => 'mockhost', volname => 'test');
    $self->{vol}->_set_fs(12345);
    $self->{vol}->_set_mounted(1);
}

sub teardown : Test(teardown)
{
    my $self = shift;

    no warnings 'redefine';

    undef($self->{vol});

    # :WARNING 2018/02/12 18:14:58: by P.G.
    # This can cause segfault with glfs_fini() due to refcnt based freeing
#    map
#    {
#        ${GlusterFS::GFAPI::FFI::}{"glfs_$_"} = $self->{"_saved_glfs_$_"}
#            if (defined($self->{"_saved_glfs-$_"}));
#    } qw/new set_volfile_server init fini close closedir set_logging/;
}

sub test_initialization_error : Test(5)
{
    my $self = shift;

    throws_ok {
        $self->_init_class('Volume', host => 'host', volname => undef);
    } qr/Host and Volume name should not be undefined/;

    throws_ok {
        $self->_init_class('Volume', host => undef,  volname => 'vol');
    } qr/Host and Volume name should not be undefined/;

    throws_ok {
        $self->_init_class('Volume', host => undef,  volname => undef);
    } qr/Host and Volume name should not be undefined/;

    throws_ok {
        $self->_init_class('Volume', host => 'host', volname => 'vol', proto => 'ZZ');
    } qr/Invalid protocol specified/;

    throws_ok {
        $self->_init_class('Volume', host => 'host', volname => 'vol', proto => 'tcp', port => 'invalid_port');
    } qr/Invalid port specified/;
}

sub test_initialization_success : Test(4)
{
    my $v = GlusterFS::GFAPI::FFI::Volume->new(
                host    => 'host',
                volname => 'vol',
                proto   => 'tcp',
                port    => 8858,
            );

    ok($v->host     eq 'host', '$v->host eq "host"');
    ok($v->volname  eq 'vol',  '$v->volname eq "vol"');
    ok($v->protocol eq 'tcp',  '$v->protocol eq "tcp"');
    ok($v->port     == 8858,   '$v->port == 8858');
}

sub test_mount_umount_success : Test(4)
{
    my $v = GlusterFS::GFAPI::FFI::Volume->new(
                host    => 'host',
                volname => 'vol');

    $v->mount();

    cmp_ok($v->mounted, '==', 1, '$v->mounted is 1');
    ok($v->fs, '$v->fs is not undefined');

    $v->umount();

    cmp_ok($v->mounted, '==', 0, '$v->mounted is 0');
    ok(!defined($v->fs),'$v->fs is undefined');
}

sub test_mount_multiple : Test(13)
{
    my $v = GlusterFS::GFAPI::FFI::Volume->new(
                host    => 'host',
                volname => 'vol');

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    my $called_once_with = sub
    {
        $mock_info{call_count}++;
        push(@{$mock_info{args}}, [@_]);
    };

    no warnings 'redefine';

    my $glfs_new = \&GlusterFS::GFAPI::FFI::glfs_new;

    ${GlusterFS::GFAPI::FFI::}{glfs_new} = $called_once_with;

    $v->mount();

    ok($mock_info{call_count} == 1
        && $mock_info{args}->[0][0] eq 'vol'
        , 'glfs_new() called once with [vol]');

    @mock_info{qw/call_count args/} = (0, []);

    foreach my $i (0..5)
    {
        $v->mount();

        ok($mock_info{call_count} == 0, 'glfs_new() not called');
        ok($v->mounted, '$v->mounted is 1');
    }

    ${GlusterFS::GFAPI::FFI::}{glfs_new} = $glfs_new;
}

sub test_mount_error : Test(11)
{
    my $self = shift;

    my %mock_info = (
        glfs_new => {
            call_count => 0,
            args       => [],
        },
        glfs_set_volfile_server =>
        {
            call_count => 0,
            args       => [],
        },
        glfs_init => {
            call_count => 0,
            args       => [],
        },
    );

    no warnings 'redefine';

    # glfs_new() failed
    my $glfs_new = \&GlusterFS::GFAPI::FFI::glfs_new;

    try
    {
        my $v = GlusterFS::GFAPI::FFI::Volume->new(
                    host    => 'host',
                    volname => 'vol');

        my $mock_glfs_new = sub
        {
            $mock_info{glfs_new}{call_count}++;
            push(@{$mock_info{glfs_new}{args}}, [@_]);

            return undef;
        };

        ${GlusterFS::GFAPI::FFI::}{glfs_new} = $mock_glfs_new;

        throws_ok { $v->mount(); } qr/glfs_new\(vol\) failed/;

        ok(!defined($v->fs), '$v->fs is undefined');
        ok(!$v->mounted, '$v->mounted is 0');
        ok($mock_info{glfs_new}{call_count} == 1
                && $mock_info{glfs_new}{args}->[0][0] eq 'vol'
            , 'glfs_new() called once');
    }
    finally
    {
        ${GlusterFS::GFAPI::FFI::}{glfs_new} = $glfs_new;
    };

    # glfs_set_volfile_server() failed
    my $glfs_set_vol = \&GlusterFS::GFAPI::FFI::glfs_set_volfile_server;

    try
    {
        my $mock_set_vol = sub
        {
            $mock_info{glfs_set_volfile_server}{call_count}++;
            push(@{$mock_info{glfs_set_volfile_server}{args}}, [@_]);

            return -1;
        };

        my $v = GlusterFS::GFAPI::FFI::Volume->new(
            host    => 'host',
            volname => 'vol');

        ${GlusterFS::GFAPI::FFI::}{glfs_set_volfile_server} = $mock_set_vol;

        throws_ok {
            $v->mount();
        } qr/
        glfs_set_volfile_server\(
            ${\$self->_mock_glfs_new()},
            \ ${\$v->protocol},
            \ ${\$v->host},
            \ ${\$v->port}\)\ failed/x;

        ok(!$v->mounted, '$v->mounted is 0');
        ok($mock_info{glfs_new}{call_count} == 1
            && $mock_info{glfs_new}{args}->[0][0] eq 'vol'
                , 'glfs_new() called once with [vol]');
        ok($mock_info{glfs_set_volfile_server}{call_count} == 1
            && $mock_info{glfs_set_volfile_server}{args}->[0][0] eq $v->fs
            && $mock_info{glfs_set_volfile_server}{args}->[0][1] eq $v->protocol
            && $mock_info{glfs_set_volfile_server}{args}->[0][2] eq $v->host
            && $mock_info{glfs_set_volfile_server}{args}->[0][3] eq $v->port
                , sprintf('glfs_set_volfile_server() called once with [%s, %s, %s, %s]'
                    , $v->fs // 'undef'
                    , $v->protocol // 'undef'
                    , $v->host // 'undef'
                    , $v->port // 'undef'));
    }
    finally
    {
        ${GlusterFS::GFAPI::FFI::}{glfs_set_volfile_server} = $glfs_set_vol;
    };

    # glfs_init() failed
    my $glfs_init = \&GlusterFS::GFAPI::FFI::glfs_init;

    try
    {
        my $mock_init = sub
        {
            $mock_info{glfs_init}{call_count}++;
            push(@{$mock_info{glfs_init}{args}}, [@_]);

            return -1;
        };

        my $v = GlusterFS::GFAPI::FFI::Volume->new(
                host    => 'host',
                volname => 'vol');

        ${GlusterFS::GFAPI::FFI::}{glfs_init} = $mock_init;

        throws_ok {
            $v->mount();
        } qr/glfs_init\(${\$self->_mock_glfs_new()}\) failed/;

        ok(!$v->mounted, '$v->mounted is 0');
        ok($mock_info{glfs_init}{call_count} == 1
                && $mock_info{glfs_init}{args}->[0][0] eq $v->fs
            , "glfs_init() called once with [${\$self->_mock_glfs_new()}]");
    }
    finally
    {
        ${GlusterFS::GFAPI::FFI::}{glfs_init} = $glfs_init;
    };
}

sub test_umount_error : Test(3)
{
    my $self = shift;

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    # glfs_fini() failed
    my $glfs_fini = \&GlusterFS::GFAPI::FFI::glfs_fini;

    no warnings 'redefine';

    my $v;

    try
    {
        my $mock_fini = sub
        {
            $mock_info{call_count}++;
            push(@{$mock_info{args}}, [@_]);

            return -1;
        };

        $v = GlusterFS::GFAPI::FFI::Volume->new(
                    host    => 'host',
                    volname => 'vol');

        $v->mount();

        ${GlusterFS::GFAPI::FFI::}{glfs_fini} = $mock_fini;

        throws_ok {
            $v->umount();
        } qr/glfs_fini\(${\$self->_mock_glfs_new()}\) failed/;

        ok($mock_info{call_count} == 1 && $mock_info{args}->[0][0] eq $v->fs
            , "glfs_fini() called once with [${\$self->_mock_glfs_new()}]");
    }
    finally
    {
        ${GlusterFS::GFAPI::FFI::}{glfs_fini} = $glfs_fini;
    };
}

sub test_set_logging : Test(2)
{
    my $self = shift;

    my $v = GlusterFS::GFAPI::FFI::Volume->new(
                host    => 'host',
                volname => 'vol');

    my $glfs_set_log = \&GlusterFS::GFAPI::FFI::glfs_set_logging;

    no warnings 'redefine';

    # called after mount()
    try
    {
        #${GlusterFS::GFAPI::FFI::}{glfs_set_logging} = $mock_set_logging;

        $v->mount();
        $v->set_logging(log_file => "/path/whatever", log_level => 7);

        cmp_ok($v->log_file, 'eq', '/path/whatever', '$v->log_file is "/path/whatever"');
        cmp_ok($v->log_level, '==', 7, '$v->log_level is 7');
    }
    finally
    {
        ${GlusterFS::GFAPI::FFI::}{glfs_set_logging} = $glfs_set_log;
    };
}

sub test_set_logging_err : Test(2)
{
    my $self = shift;

    my $v = GlusterFS::GFAPI::FFI::Volume->new(
                host    => 'host',
                volname => 'vol');

    $v->_set_fs(12345);

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    # glfs_set_logging() failed
    my $glfs_set_log = \&GlusterFS::GFAPI::FFI::glfs_set_logging;

    no warnings 'redefine';

    my $mock_set_log = sub
    {
        $mock_info{call_count}++;
        push(@{$mock_info{args}}, [@_]);

        return -1;
    };

    ${GlusterFS::GFAPI::FFI::}{glfs_set_logging} = $mock_set_log;

    throws_ok {
        $v->set_logging('/dev/null', 7);
    } qr/glfs_set_logging\(undef, 7\) failed/;

    ok($mock_info{call_count} == 1
        && $mock_info{args}->[0][0] eq $v->fs
        && !defined($mock_info{args}->[0][1])
        && $mock_info{args}->[0][2] == 7
        , "glfs_fini() called once with [${\$self->_mock_glfs_new()}]");

    ${GlusterFS::GFAPI::FFI::}{glfs_set_logging} = $glfs_set_log;
}

sub test_chmod_success : Test(1)
{
    my $self = shift;

    my $mock_chmod = sub
    {
        return 0;
    };

    my $glfs_chmod = \&GlusterFS::GFAPI::FFI::glfs_chmod;

    no warnings 'redefine';

    ${GlusterFS::GFAPI::FFI::}{glfs_chmod} = $mock_chmod;

    ok($self->{vol}->chmod(path => 'file.txt', mode => 0600) == 0
        , '$vol->chmod has returned with 0');

    ${GlusterFS::GFAPI::FFI::}{glfs_chmod} = $glfs_chmod;
}

sub test_chmod_fail_exception : Test(1)
{
    my $self = shift;

    my $mock_chmod = sub
    {
        return -1;
    };

    my $glfs_chmod = \&GlusterFS::GFAPI::FFI::glfs_chmod;

    no warnings 'redefine';

    ${GlusterFS::GFAPI::FFI::}{glfs_chmod} = $mock_chmod;

    throws_ok {
        $self->{vol}->chmod(path => 'file.txt', mode => 0600);
    } qr/glfs_chmod\(${\$self->_mock_glfs_new()}, file.txt, 0600\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_chmod} = $glfs_chmod;
}

sub test_chown_success : Test
{
    my $self = shift;

    my $mock_chown = sub
    {
        return 0;
    };

    my $glfs_chown = \&GlusterFS::GFAPI::FFI::glfs_chown;

    no warnings 'redefine';

    ${GlusterFS::GFAPI::FFI::}{glfs_chown} = $mock_chown;

    ok($self->{vol}->chown(path => 'file.txt', uid => 9, gid => 11) == 0
        , '$vol->chown has returned with 0');

    ${GlusterFS::GFAPI::FFI::}{glfs_chown} = $glfs_chown;
}

sub test_chown_fail_exception : Test
{
    my $self = shift;

    my $mock_chown = sub
    {
        return -1;
    };

    my $glfs_chown = \&GlusterFS::GFAPI::FFI::glfs_chown;

    no warnings 'redefine';

    ${GlusterFS::GFAPI::FFI::}{glfs_chown} = $mock_chown;

    throws_ok {
        $self->{vol}->chown(path => 'file.txt', uid => 9, gid => 11);
    } qr/glfs_chown\(${\$self->_mock_glfs_new()}, file\.txt, 9, 11\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_chown} = $glfs_chown;
}

sub test_creat_success : Test(2)
{
    my $self = shift;

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    no warnings 'redefine';

    my $glfs_creat = \&GlusterFS::GFAPI::FFI::glfs_creat;

    try
    {
        my $mock_creat = sub
        {
            $mock_info{call_count}++;
            push(@{$mock_info{args}}, [@_]);

            return 2;
        };

        ${GlusterFS::GFAPI::FFI::}{glfs_creat} = $mock_creat;

        my $f = GlusterFS::GFAPI::FFI::File->new(
                    fd => $self->{vol}->open(
                            path  => 'file.txt',
                            flags => &POSIX::O_CREAT,
                            mode  => 0644));

        isa_ok($f, 'GlusterFS::GFAPI::FFI::File'
            , '$f is a instance of GlusterFS::GFAPI::FFI::File');

        ok($mock_info{call_count} == 1
                && $mock_info{args}->[0][0] eq ${\$self->_mock_glfs_new()}
                && $mock_info{args}->[0][1] eq 'file.txt'
                && $mock_info{args}->[0][2] == &POSIX::O_CREAT
                && $mock_info{args}->[0][3] == 0644
            , sprintf("glfs_creat() called once with [%s, %s, %s, %s]"
                , $self->_mock_glfs_new()
                , 'file.txt'
                , 'O_CREAT'
                , '0644'));
    }
    finally
    {
        ${GlusterFS::GFAPI::FFI::}{glfs_creat} = $glfs_creat;
    };
}

sub test_exists_true : Test
{
    my $self = shift;

    my $mock_stat = sub
    {
        return 0;
    };

    no warnings 'redefine';

    my $glfs_stat = \&GlusterFS::GFAPI::FFI::glfs_stat;

    ${GlusterFS::GFAPI::FFI::}{glfs_stat} = $mock_stat;

    ok($self->{vol}->exists(path => 'file.txt') == 1
        , '$vol->exists() has returned with 1');

    ${GlusterFS::GFAPI::FFI::}{glfs_stat} = $glfs_stat;
}

sub test_not_exists_false : Test
{
    my $self = shift;

    my $mock_stat = sub
    {
        return -1;
    };

    no warnings 'redefine';

    my $glfs_stat = \&GlusterFS::GFAPI::FFI::glfs_stat;

    ${GlusterFS::GFAPI::FFI::}{glfs_stat} = $mock_stat;

    ok($self->{vol}->exists(path => 'file.txt') == 0
        , '$vol->exists() has returned with 0');

    ${GlusterFS::GFAPI::FFI::}{glfs_stat} = $glfs_stat;
}

sub test_isdir_true : Test
{
    my $self = shift;

    my $mock_stat = sub
    {
        my ($fs, $path, $stat) = @_;

        $stat->st_mode(S_IFDIR);

        return 0;
    };

    no warnings 'redefine';

    my $glfs_stat = \&GlusterFS::GFAPI::FFI::glfs_stat;

    ${GlusterFS::GFAPI::FFI::}{glfs_stat} = $mock_stat;

    ok($self->{vol}->isdir(path => 'dir')
        , "\$vol->isdir(path => 'dir') has returned with 1");

    ${GlusterFS::GFAPI::FFI::}{glfs_stat} = $glfs_stat;
}

sub test_isdir_false : Test
{
    my $self = shift;

    my $mock_stat = sub
    {
        my ($fs, $path, $stat) = @_;

        $stat->st_mode(S_IFREG);

        return 0;
    };

    no warnings 'redefine';

    my $glfs_stat = \&GlusterFS::GFAPI::FFI::glfs_stat;

    ${GlusterFS::GFAPI::FFI::}{glfs_stat} = $mock_stat;

    ok(!$self->{vol}->isdir(path => 'file')
        , "\$vol->isdir(path => 'file') has returned with 0");

    ${GlusterFS::GFAPI::FFI::}{glfs_stat} = $glfs_stat;
}

sub test_isdir_false_nodir : Test
{
    my $self = shift;

    my $mock_stat = sub
    {
        return -1;
    };

    no warnings 'redefine';

    my $glfs_stat = \&GlusterFS::GFAPI::FFI::glfs_stat;

    ${GlusterFS::GFAPI::FFI::}{glfs_stat} = $mock_stat;

    ok(!$self->{vol}->isdir(path => 'dirdoesnotexist')
        , "\$vol->isdir(path => 'dirdoesnotexist') has returned with 0");

    ${GlusterFS::GFAPI::FFI::}{glfs_stat} = $glfs_stat;
}

sub test_isfile_true : Test
{
    my $self = shift;

    my $mock_stat = sub
    {
        my ($fs, $path, $stat) = @_;

        $stat->st_mode(S_IFREG);

        return 0;
    };

    no warnings 'redefine';

    my $glfs_stat = \&GlusterFS::GFAPI::FFI::glfs_stat;

    ${GlusterFS::GFAPI::FFI::}{glfs_stat} = $mock_stat;

    ok($self->{vol}->isfile(path => 'file')
        , "\$vol->isfile(path => 'file') has returned with 1");

    ${GlusterFS::GFAPI::FFI::}{glfs_stat} = $glfs_stat;
}

sub test_isfile_false : Test
{
    my $self = shift;

    my $mock_stat = sub
    {
        my ($fs, $path, $stat) = @_;

        $stat->st_mode(S_IFDIR);

        return 0;
    };

    no warnings 'redefine';

    my $glfs_stat = \&GlusterFS::GFAPI::FFI::glfs_stat;

    ${GlusterFS::GFAPI::FFI::}{glfs_stat} = $mock_stat;

    ok(!$self->{vol}->isfile(path => 'dir')
        , "\$vol->isfile(path => 'dir') has returned with 0");

    ${GlusterFS::GFAPI::FFI::}{glfs_stat} = $glfs_stat;
}

sub test_isfile_false_nofile : Test
{
    my $self = shift;

    my $mock_stat = sub
    {
        return -1;
    };

    no warnings 'redefine';

    my $glfs_stat = \&GlusterFS::GFAPI::FFI::glfs_stat;

    ${GlusterFS::GFAPI::FFI::}{glfs_stat} = $mock_stat;

    ok(!$self->{vol}->isfile(path => 'filedoesnotexist')
        , "\$vol->isfile(path => 'filedoesnotexist') has returned with 0");

    ${GlusterFS::GFAPI::FFI::}{glfs_stat} = $glfs_stat;
}

sub test_islink_true : Test
{
    my $self = shift;

    my $mock_lstat = sub
    {
        my ($fs, $path, $stat) = @_;

        $stat->st_mode(S_IFLNK);

        return 0;
    };

    no warnings 'redefine';

    my $glfs_lstat = \&GlusterFS::GFAPI::FFI::glfs_lstat;

    ${GlusterFS::GFAPI::FFI::}{glfs_lstat} = $mock_lstat;

    ok($self->{vol}->islink(path => 'solnk')
        , "\$vol->islink(path => 'solnk') has returned with 1");

    ${GlusterFS::GFAPI::FFI::}{glfs_lstat} = $glfs_lstat;
}

sub test_islink_false : Test
{
    my $self = shift;

    my $mock_lstat = sub
    {
        my ($fs, $path, $stat) = @_;

        $stat->st_mode(S_IFREG);

        return 0;
    };

    no warnings 'redefine';

    my $glfs_lstat = \&GlusterFS::GFAPI::FFI::glfs_lstat;

    ${GlusterFS::GFAPI::FFI::}{glfs_lstat} = $mock_lstat;

    ok(!$self->{vol}->islink(path => 'file')
        , "\$vol->islink(path => 'file') has returned with 1");

    ${GlusterFS::GFAPI::FFI::}{glfs_lstat} = $glfs_lstat;
}

sub test_islink_false_nolink : Test
{
    my $self = shift;

    my $mock_lstat = sub
    {
        return -1;
    };

    no warnings 'redefine';

    my $glfs_lstat = \&GlusterFS::GFAPI::FFI::glfs_lstat;

    ${GlusterFS::GFAPI::FFI::}{glfs_lstat} = $mock_lstat;

    ok(!$self->{vol}->islink(path => 'linkdoesnotexist')
        , "\$vol->isfile(path => 'linkdoesnotexist') has returned with 0");

    ${GlusterFS::GFAPI::FFI::}{glfs_lstat} = $glfs_lstat;
}

sub test_getxattr_success : Test
{
    my $self = shift;

    my $mock_getxattr = sub {
        my ($fs, $path, $key, $buf, $bufsz) = @_;

        my $str = strdup('fake_xattr');

        memcpy($buf, $str, 10);

        free($str);

        return 10;
    };

    no warnings 'redefine';

    my $glfs_getxattr = \&GlusterFS::GFAPI::FFI::glfs_getxattr;

    ${GlusterFS::GFAPI::FFI::}{glfs_getxattr} = $mock_getxattr;

    cmp_ok($self->{vol}->getxattr(path => 'file.txt', key => 'key1', size => 32),
            'eq',
            'fake_xattr',
        , "\$vol->getxattr(path => 'file.txt', key => 'key1', size => 32) has returned with 0");

    ${GlusterFS::GFAPI::FFI::}{glfs_getxattr} = $glfs_getxattr;
}

sub test_getxattr_fail_exception : Test
{
    my $self = shift;

    my $mock_getxattr = sub {
        return -1;
    };

    no warnings 'redefine';

    my $glfs_getxattr = \&GlusterFS::GFAPI::FFI::glfs_getxattr;

    ${GlusterFS::GFAPI::FFI::}{glfs_getxattr} = $mock_getxattr;

    throws_ok {
        $self->{vol}->getxattr(path => 'file.txt', key => 'key1', size => 32);
    } qr/glfs_getxattr\(${\$self->_mock_glfs_new()}, file.txt, key1, buf, 32\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_getxattr} = $glfs_getxattr;
}

sub test_listdir_success : Test
{
    my $self = shift;

    my $mock_opendir = sub {
        return 2;
    };

    my $dirent1 = GlusterFS::GFAPI::FFI::Dirent->new(
                    d_name   => 'mockfile',
                    d_reclen => 8);
    my $dirent2 = GlusterFS::GFAPI::FFI::Dirent->new(
                    d_name   => 'mockdir',
                    d_reclen => 7);
    my $dirent3 = GlusterFS::GFAPI::FFI::Dirent->new(
                    d_name   => '.',
                    d_reclen => 1);

    my @side_effect   = ($dirent1, $dirent2, $dirent3, undef);
    my $mock_Dir_next = sub { return shift(@side_effect); };

    no warnings 'redefine';

    my $glfs_opendir = \&GlusterFS::GFAPI::FFI::glfs_opendir;
    my $Dir_next     = \&GlusterFS::GFAPI::FFI::Dir::next;

    ${GlusterFS::GFAPI::FFI::}{glfs_opendir} = $mock_opendir;
    ${GlusterFS::GFAPI::FFI::Dir::}{next}    = $mock_Dir_next;

    my @d = $self->{vol}->listdir(path => 'testdir');

    cmp_ok(scalar(@d), '==', 2, '$v->listdir() is returned with 2 elements');

    ${GlusterFS::GFAPI::FFI::}{glfs_opendir} = $glfs_opendir;
    ${GlusterFS::GFAPI::FFI::Dir::}{next}    = $Dir_next;
}

sub test_listdir_fail_exception : Test
{
    my $self = shift;

    my $mock_opendir = sub {
        return undef;
    };

    no warnings 'redefine';

    my $glfs_opendir = \&GlusterFS::GFAPI::FFI::glfs_opendir;

    ${GlusterFS::GFAPI::FFI::}{glfs_opendir} = $mock_opendir;

    throws_ok {
        $self->{vol}->listdir(path => 'test.txt');
    } qr/glfs_opendir\(${\$self->_mock_glfs_new()}, test\.txt\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_opendir} = $glfs_opendir;
}

sub test_listdir_with_stat_success : Test(5)
{
    my $self = shift;

    my $mock_opendir = sub {
        return 2;
    };

    my $dirent1 = GlusterFS::GFAPI::FFI::Dirent->new(
                    d_name   => 'mockfile',
                    d_reclen => 8);
    my $dirent2 = GlusterFS::GFAPI::FFI::Dirent->new(
                    d_name   => 'mockdir',
                    d_reclen => 7);
    my $dirent3 = GlusterFS::GFAPI::FFI::Dirent->new(
                    d_name   => '.',
                    d_reclen => 1);

    my $stat1 = GlusterFS::GFAPI::FFI::Stat->new(st_nlink => 1);
    my $stat2 = GlusterFS::GFAPI::FFI::Stat->new(st_nlink => 2);
    my $stat3 = GlusterFS::GFAPI::FFI::Stat->new(st_nlink => 2);

    my @side_effect = (
        [$dirent1, $stat1],
        [$dirent2, $stat2],
        [$dirent3, $stat3],
        undef
    );

    my $mock_Dir_next = sub {
        my $pair = shift(@side_effect);

        return $pair ? @{$pair} : undef;
    };

    no warnings 'redefine';

    my $glfs_opendir = \&GlusterFS::GFAPI::FFI::glfs_opendir;
    my $Dir_next     = \&GlusterFS::GFAPI::FFI::Dir::next;

    ${GlusterFS::GFAPI::FFI::}{glfs_opendir} = $mock_opendir;
    ${GlusterFS::GFAPI::FFI::Dir::}{next}    = $mock_Dir_next;

    my @d = $self->{vol}->listdir_with_stat(path => 'testdir');

    cmp_ok(scalar(@d), '==', 2, '$v->listdir_with_stat() is returned with 2 elements');
    cmp_ok($d[0]->[0], 'eq', 'mockfile', "entry name is 'mockfile'");
    cmp_ok($d[0]->[1]->st_nlink, '==', 1, "entry st_nlink is 1");
    cmp_ok($d[1]->[0], 'eq', 'mockdir', "entry name is 'mockdir'");
    cmp_ok($d[1]->[1]->st_nlink, '==', 2, "entry st_nlink is 2");

    ${GlusterFS::GFAPI::FFI::}{glfs_opendir} = $glfs_opendir;
    ${GlusterFS::GFAPI::FFI::Dir::}{next}    = $Dir_next;
}

sub test_listdir_with_fail_exception : Test
{
    my $self = shift;

    my $mock_opendir = sub {
        return undef;
    };

    no warnings 'redefine';

    my $glfs_opendir = \&GlusterFS::GFAPI::FFI::glfs_opendir;

    ${GlusterFS::GFAPI::FFI::}{glfs_opendir} = $mock_opendir;

    throws_ok {
        $self->{vol}->listdir_with_stat(path => 'dir');
    } qr/glfs_opendir\(${\$self->_mock_glfs_new()}, dir\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_opendir} = $glfs_opendir;
}

sub test_scandir_success : Test(11)
{
    my $self = shift;

    my $dirent1 = GlusterFS::GFAPI::FFI::Dirent->new(
                    d_name   => 'mockfile',
                    d_reclen => 8);
    my $dirent2 = GlusterFS::GFAPI::FFI::Dirent->new(
                    d_name   => 'mockdir',
                    d_reclen => 7);
    my $dirent3 = GlusterFS::GFAPI::FFI::Dirent->new(
                    d_name   => '.',
                    d_reclen => 1);

    my $stat1 = GlusterFS::GFAPI::FFI::Stat->new(st_nlink => 1, st_mode => 33188);
    my $stat2 = GlusterFS::GFAPI::FFI::Stat->new(st_nlink => 2, st_mode => 16877);
    my $stat3 = GlusterFS::GFAPI::FFI::Stat->new(st_nlink => 2, st_mode => 16877);

    my @side_effect = (
        [$dirent1, $stat1],
        [$dirent2, $stat2],
        [$dirent3, $stat3],
        undef
    );

    my $mock_opendir = sub {
        return 2;
    };

    my $mock_Dir_next = sub {
        my $pair = shift(@side_effect);

        return $pair ? @{$pair} : undef;
    };

    no warnings 'redefine';

    my $glfs_opendir = \&GlusterFS::GFAPI::FFI::glfs_opendir;
    my $Dir_next     = \&GlusterFS::GFAPI::FFI::Dir::next;

    ${GlusterFS::GFAPI::FFI::}{glfs_opendir} = $mock_opendir;
    ${GlusterFS::GFAPI::FFI::Dir::}{next}    = $mock_Dir_next;

    my $i=0;

    my $direntry = $self->{vol}->scandir(path => 'testdir');

    while (defined(my $entry = $direntry->next))
    {
        isa_ok(ref($entry), 'GlusterFS::GFAPI::FFI::DirEntry');

        if ($entry->name eq 'mockfile')
        {
            cmp_ok($entry->path, 'eq', 'testdir/mockfile', '$entry->path is "mockfile"');
            ok($entry->is_file(), '$entry->is_file() is true');
            ok(!$entry->is_dir(), '$entry->is_dir() is false');
            cmp_ok($entry->stat->st_nlink, '==', 1, '$entry->stat->st_nlink is 1');
        }
        elsif ($entry->name eq 'mockdir')
        {
            cmp_ok($entry->path, 'eq', 'testdir/mockdir', '$entry->path is "mockdir"');
            ok(!$entry->is_file(), '$entry->is_file() is false');
            ok($entry->is_dir(), '$entry->is_dir() is true');
            cmp_ok($entry->stat->st_nlink, '==', 2, '$entry->stat->st_nlink is 2');
        }
        else
        {
            fail('Unexpected entry');
        }

        $i++;
    }

    cmp_ok($i, '==', 2, 'scandir->next() returns 2 entries');

    ${GlusterFS::GFAPI::FFI::}{glfs_opendir} = $glfs_opendir;
    ${GlusterFS::GFAPI::FFI::Dir::}{next}    = $Dir_next;
}

sub test_listxattr_success : Test(2)
{
    my $self = shift;

    my $mock_listxattr = sub {
        my ($fs, $path, $buf, $bufsz) = @_;

        if (defined($buf))
        {
            my $str = "key1\0key2\0";
            my $ptr = pack('P', $str);

            memcpy($buf, unpack('L!', $ptr), 10);
        }

        return 10;
    };

    no warnings 'redefine';

    my $glfs_listxattr = \&GlusterFS::GFAPI::FFI::glfs_listxattr;

    ${GlusterFS::GFAPI::FFI::}{glfs_listxattr} = $mock_listxattr;

    my @xattrs = $self->{vol}->listxattr(path => 'file.txt');

    ok(grep { $_ eq 'key1'; } @xattrs, '"key1" exists in listxattr()');
    ok(grep { $_ eq 'key2'; } @xattrs, '"key2" exists in listxattr()');

    ${GlusterFS::GFAPI::FFI::}{glfs_listxattr} = $glfs_listxattr;
}

sub test_listxattr_fail_exception : Test
{
    my $self = shift;

    my $mock_listxattr = sub {
        return -1;
    };

    no warnings 'redefine';

    my $glfs_listxattr = \&GlusterFS::GFAPI::FFI::glfs_listxattr;

    ${GlusterFS::GFAPI::FFI::}{glfs_listxattr} = $mock_listxattr;

    throws_ok {
        $self->{vol}->listxattr(path => 'file.txt');
    } qr/glfs_listxattr\(${\$self->_mock_glfs_new()}, file.txt, undef, 0\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_listxattr} = $glfs_listxattr;
}

sub test_lstat_success : Test
{
    my $self = shift;

    my $mock_lstat = sub {
        return 0;
    };

    no warnings 'redefine';

    my $glfs_lstat = \&GlusterFS::GFAPI::FFI::glfs_lstat;

    ${GlusterFS::GFAPI::FFI::}{glfs_lstat} = $mock_lstat;

    my $s = $self->{vol}->lstat(path => 'file.txt');

    isa_ok($s, 'GlusterFS::GFAPI::FFI::Stat', '$v->lstat() is returned with Stat');

    ${GlusterFS::GFAPI::FFI::}{glfs_lstat} = $glfs_lstat;
}

sub test_lstat_fail_exception : Test
{
    my $self = shift;

    my $mock_lstat = sub {
        return -1;
    };

    no warnings 'redefine';

    my $glfs_lstat = \&GlusterFS::GFAPI::FFI::glfs_lstat;

    ${GlusterFS::GFAPI::FFI::}{glfs_lstat} = $mock_lstat;


    throws_ok {
        $self->{vol}->lstat(path => 'file.txt');
    } qr/glfs_lstat\(${\$self->_mock_glfs_new()}, file.txt, .+::Stat.+\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_lstat} = $glfs_lstat;
}

sub test_stat_success : Test
{
    my $self = shift;

    my $mock_stat = sub {
        return 0;
    };

    no warnings 'redefine';

    my $glfs_stat = \&GlusterFS::GFAPI::FFI::glfs_stat;

    ${GlusterFS::GFAPI::FFI::}{glfs_stat} = $mock_stat;

    my $s = $self->{vol}->stat(path => 'file.txt');

    isa_ok($s, 'GlusterFS::GFAPI::FFI::Stat', '$v->stat() is returned with Stat');

    ${GlusterFS::GFAPI::FFI::}{glfs_stat} = $glfs_stat;
}

sub test_stat_fail_exception : Test
{
    my $self = shift;

    my $mock_stat = sub {
        return -1;
    };

    no warnings 'redefine';

    my $glfs_stat = \&GlusterFS::GFAPI::FFI::glfs_stat;

    ${GlusterFS::GFAPI::FFI::}{glfs_stat} = $mock_stat;


    throws_ok {
        $self->{vol}->stat(path => 'file.txt');
    } qr/glfs_stat\(${\$self->_mock_glfs_new()}, file.txt, .+::Stat.+\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_stat} = $glfs_stat;
}

sub test_statvfs_success : Test
{
    my $self = shift;

    my $mock_statvfs = sub {
        return 0;
    };

    no warnings 'redefine';

    my $glfs_statvfs = \&GlusterFS::GFAPI::FFI::glfs_statvfs;

    ${GlusterFS::GFAPI::FFI::}{glfs_statvfs} = $mock_statvfs;

    my $s = $self->{vol}->statvfs(path => '/');

    isa_ok($s, 'GlusterFS::GFAPI::FFI::Statvfs', '$v->statvfs() is returned with Statvfs');

    ${GlusterFS::GFAPI::FFI::}{glfs_statvfs} = $glfs_statvfs;
}

sub test_statvfs_fail_exception : Test
{
    my $self = shift;

    my $mock_statvfs = sub {
        return -1;
    };

    no warnings 'redefine';

    my $glfs_statvfs = \&GlusterFS::GFAPI::FFI::glfs_statvfs;

    ${GlusterFS::GFAPI::FFI::}{glfs_statvfs} = $mock_statvfs;

    throws_ok {
        $self->{vol}->statvfs(path => '/');
    } qr/glfs_statvfs\(${\$self->_mock_glfs_new()}, \/, .+::Statvfs.+\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_statvfs} = $glfs_statvfs;
}

sub test_makedirs_success : Test(2)
{
    my $self = shift;

    my @mkdir_side_effect = (
        [0, 0],
    );

    my @exist_side_effect = (
        [0, 1, 0],
    );

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    my $mock_mkdir = sub
    {
        $mock_info{call_count}++;
        push(@{$mock_info{args}}, [@_]);

        my $pair = shift(@mkdir_side_effect);

        return $pair ? @{$pair} : undef;
    };

    my $mock_exists = sub {
        my $pair = shift(@exist_side_effect);

        return $pair ? @{$pair} : undef;
    };

    no warnings 'redefine';

    my $glfs_mkdir = \&GlusterFS::GFAPI::FFI::glfs_mkdir;
    my $vol_exists = \&GlusterFS::GFAPI::FFI::Volume::exists;

    ${GlusterFS::GFAPI::FFI::}{glfs_mkdir}     = $mock_mkdir;
    ${GlusterFS::GFAPI::FFI::Volume::}{exists} = $mock_exists;

    $self->{vol}->makedirs(path => 'dir1/', mode => 0775);

    cmp_ok($mock_info{call_count}, '==', 1, 'glfs_mkdir() called once');

    my $any = 0;

    foreach my $args (@{$mock_info{args}})
    {
        if ($args->[0] == $self->{vol}->fs
            && $args->[1] eq 'dir1/'
            && sprintf('0%o', $args->[2]) eq '0775')
        {
            $any = 1;
        }
    }

    ok($any, sprintf("glfs_mkdir() called with(%s, %s, %s)"
                , $self->{vol}->fs
                , 'dir1/'
                , '0755'));

    ${GlusterFS::GFAPI::FFI::}{glfs_mkdir}     = $glfs_mkdir;
    ${GlusterFS::GFAPI::FFI::Volume::}{exists} = $vol_exists;
}

sub test_makedirs_success_EEXIST : Test(3)
{
    my $self = shift;

    my @mkdir_side_effect = ('EEXIST', 0);
    my @exist_side_effect = (0, 1, 0);

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    my $mock_mkdir = sub
    {
        $mock_info{call_count}++;
        push(@{$mock_info{args}}, [@_]);

        my $retval = shift(@mkdir_side_effect);

        if ($retval eq 'EEXIST')
        {
            $! = EEXIST;
            return -1;
        }

        return $retval;
    };

    my $mock_exists = sub {
        return shift(@exist_side_effect);
    };

    no warnings 'redefine';

    my $glfs_mkdir = \&GlusterFS::GFAPI::FFI::glfs_mkdir;
    my $vol_exists = \&GlusterFS::GFAPI::FFI::Volume::exists;

    ${GlusterFS::GFAPI::FFI::}{glfs_mkdir}     = $mock_mkdir;
    ${GlusterFS::GFAPI::FFI::Volume::}{exists} = $mock_exists;

    $self->{vol}->makedirs(path => './dir1/dir2', mode => 0775);

    cmp_ok($mock_info{call_count}, '==', 2, 'glfs_mkdir() called 2');

    my $any_parent = 0;

    foreach my $args (@{$mock_info{args}})
    {
        if ($args->[0] == $self->{vol}->fs
            && $args->[1] eq './dir1'
            && sprintf('0%o', $args->[2]) eq '0775')
        {
            $any_parent = 1;
        }
    }

    ok($any_parent, sprintf("glfs_mkdir() called with(%s, %s, %s)"
                , $self->{vol}->fs
                , 'dir1/'
                , '0775'));

    ok($mock_info{args}->[-1][0] == $self->{vol}->fs
        && $mock_info{args}->[-1][1] eq './dir1/dir2'
        && sprintf('0%o', $mock_info{args}->[-1][2]) eq '0775'
        , sprintf("glfs_mkdir() called with(%s, %s, %s)"
                , $self->{vol}->fs
                , './dir1/dir2'
                , '0775'));

    ${GlusterFS::GFAPI::FFI::}{glfs_mkdir}     = $glfs_mkdir;
    ${GlusterFS::GFAPI::FFI::Volume::}{exists} = $vol_exists;
}

sub test_makedirs_fail_exception : Test
{
    my $self = shift;

    my $mock_mkdir = sub {
        return -1;
    };

    my $mock_exists = sub {
        return 0;
    };

    no warnings 'redefine';

    my $glfs_mkdir = \&GlusterFS::GFAPI::FFI::glfs_mkdir;
    my $vol_exists = \&GlusterFS::GFAPI::FFI::Volume::exists;

    ${GlusterFS::GFAPI::FFI::}{glfs_mkdir}     = $mock_mkdir;
    ${GlusterFS::GFAPI::FFI::Volume::}{exists} = $mock_exists;

    throws_ok {
        $self->{vol}->makedirs(path => 'dir1/dir2', mode => 0755);
    } qr/makedirs\(dir1, 0755\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_mkdir}     = $glfs_mkdir;
    ${GlusterFS::GFAPI::FFI::Volume::}{exists} = $vol_exists;
}

sub test_mkdir_success : Test
{
    my $self = shift;
}

sub test_mkdir_fail_exception : Test
{
    my $self = shift;

    my $mock_mkdir = sub {
        return -1;
    };

    no warnings 'redefine';

    my $glfs_mkdir = \&GlusterFS::GFAPI::FFI::glfs_mkdir;

    ${GlusterFS::GFAPI::FFI::}{glfs_mkdir} = $mock_mkdir;

    throws_ok {
        $self->{vol}->mkdir(path => 'testdir', mode => 0755);
    } qr/glfs_mkdir\(12345, testdir, 0755\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_mkdir} = $glfs_mkdir;
}

sub test_open_success : Test(2)
{
    my $self = shift;

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    my $mock_open = sub {
        $mock_info{call_count}++;
        push(@{$mock_info{args}}, [@_]);

        return 2;
    };

    no warnings 'redefine';

    my $glfs_open = \&GlusterFS::GFAPI::FFI::glfs_open;

    ${GlusterFS::GFAPI::FFI::}{glfs_open} = $mock_open;

    my $f = GlusterFS::GFAPI::FFI::File->new(
                fd => $self->{vol}->open(
                        path  => 'file.txt',
                        flags => &POSIX::O_WRONLY));

    isa_ok($f, 'GlusterFS::GFAPI::FFI::File', 'File is created with file descriptor');

    ok($mock_info{call_count} == 1
        && $mock_info{args}->[0][0] == $self->_mock_glfs_new()
        && $mock_info{args}->[0][1] eq 'file.txt'
        && $mock_info{args}->[0][2] == &POSIX::O_WRONLY
        , sprintf('glfs_open() called once with [%s, %s, %s]'
            , $self->_mock_glfs_new()
            , 'file.txt'
            , 'O_WRONLY'));

    ${GlusterFS::GFAPI::FFI::}{glfs_open} = $glfs_open;
}

sub test_open_fail_exception : Test
{
    my $self = shift;

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    my $mock_open = sub {
        $mock_info{call_count}++;
        push(@{$mock_info{args}}, [@_]);

        return undef;
    };

    no warnings 'redefine';

    my $glfs_open = \&GlusterFS::GFAPI::FFI::glfs_open;

    ${GlusterFS::GFAPI::FFI::}{glfs_open} = $mock_open;

    throws_ok {
        my $fd = $self->{vol}->open(
                    path  => 'file.txt',
                    flags => &POSIX::O_WRONLY);
    } qr/glfs_open\(${\$self->_mock_glfs_new()},\ file\.txt
            ,\ ${\POSIX::O_WRONLY}\)\ failed/x;

    ${GlusterFS::GFAPI::FFI::}{glfs_open} = $mock_open;
}

sub test_open_direct_success : Test(2)
{
    my $self = shift;

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    my $mock_open = sub {
        $mock_info{call_count}++;
        push(@{$mock_info{args}}, [@_]);

        return 2;
    };

    no warnings 'redefine';

    my $glfs_open = \&GlusterFS::GFAPI::FFI::glfs_open;

    ${GlusterFS::GFAPI::FFI::}{glfs_open} = $mock_open;

    my $f = GlusterFS::GFAPI::FFI::File->new(
                fd => $self->{vol}->open(
                        path  => 'file.txt',
                        flags => &POSIX::O_WRONLY));

    isa_ok($f, 'GlusterFS::GFAPI::FFI::File', 'File is created with file descriptor');

    ok($mock_info{call_count} == 1
        && $mock_info{args}->[0][0] == $self->_mock_glfs_new()
        && $mock_info{args}->[0][1] eq 'file.txt'
        && $mock_info{args}->[0][2] == &POSIX::O_WRONLY
        , sprintf('glfs_open() called once with [%s, %s, %s]'
            , $self->_mock_glfs_new()
            , 'file.txt'
            , 'O_WRONLY'));

    ${GlusterFS::GFAPI::FFI::}{glfs_open} = $glfs_open;
}

sub test_opendir_success : Test
{
    my $self = shift;

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    my $mock_opendir = sub {
        $mock_info{call_count}++;
        push(@{$mock_info{args}}, [@_]);

        return 2;
    };

    no warnings 'redefine';

    my $glfs_opendir = \&GlusterFS::GFAPI::FFI::glfs_opendir;

    ${GlusterFS::GFAPI::FFI::}{glfs_opendir} = $mock_opendir;

    my $d = $self->{vol}->opendir(path => 'testdir');

    isa_ok($d, 'GlusterFS::GFAPI::FFI::Dir', 'Dir is created with path');

    ${GlusterFS::GFAPI::FFI::}{glfs_opendir} = $glfs_opendir;
}

sub test_opendir_fail_exception : Test
{
    my $self = shift;

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    my $mock_opendir = sub {
        $mock_info{call_count}++;
        push(@{$mock_info{args}}, [@_]);

        return undef;
    };

    no warnings 'redefine';

    my $glfs_opendir = \&GlusterFS::GFAPI::FFI::glfs_opendir;

    ${GlusterFS::GFAPI::FFI::}{glfs_opendir} = $mock_opendir;

    throws_ok {
        my $d = $self->{vol}->opendir(path => 'testdir');
    } qr/glfs_opendir\(${\$self->_mock_glfs_new()}, testdir\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_opendir} = $glfs_opendir;
}

sub test_rename_success : Test
{
    my $self = shift;

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    my $mock_rename = sub {
        $mock_info{call_count}++;
        push(@{$mock_info{args}}, [@_]);

        return 0;
    };

    no warnings 'redefine';

    my $glfs_rename = \&GlusterFS::GFAPI::FFI::glfs_rename;

    ${GlusterFS::GFAPI::FFI::}{glfs_rename} = $mock_rename;

    ok(!$self->{vol}->rename(src => 'file.txt', dst => 'newfile.txt')
        , 'glfs_rename() returned with 0');

    ${GlusterFS::GFAPI::FFI::}{glfs_rename} = $glfs_rename;
}

sub test_rename_fail_exception : Test
{
    my $self = shift;

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    my $mock_rename = sub {
        $mock_info{call_count}++;
        push(@{$mock_info{args}}, [@_]);

        return -1;
    };

    no warnings 'redefine';

    my $glfs_rename = \&GlusterFS::GFAPI::FFI::glfs_rename;

    ${GlusterFS::GFAPI::FFI::}{glfs_rename} = $mock_rename;

    throws_ok {
        $self->{vol}->rename(src => 'file.txt', dst => 'newfile.txt');
    } qr/glfs_rename\(${\$self->_mock_glfs_new()}, file\.txt, newfile\.txt\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_rename} = $glfs_rename;
}

sub test_rmdir_success : Test
{
    my $self = shift;

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    my $mock_rmdir = sub {
        $mock_info{call_count}++;
        push(@{$mock_info{args}}, [@_]);

        return 0;
    };

    no warnings 'redefine';

    my $glfs_rmdir = \&GlusterFS::GFAPI::FFI::glfs_rmdir;

    ${GlusterFS::GFAPI::FFI::}{glfs_rmdir} = $mock_rmdir;

    ok(!$self->{vol}->rmdir(path => 'testdir'), 'glfs_rmdir() returned with 0');

    ${GlusterFS::GFAPI::FFI::}{glfs_rmdir} = $glfs_rmdir;
}

sub test_rmdir_fail_exception : Test
{
    my $self = shift;

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    my $mock_rmdir = sub {
        $mock_info{call_count}++;
        push(@{$mock_info{args}}, [@_]);

        return -1;
    };

    no warnings 'redefine';

    my $glfs_rmdir = \&GlusterFS::GFAPI::FFI::glfs_rmdir;

    ${GlusterFS::GFAPI::FFI::}{glfs_rmdir} = $mock_rmdir;

    throws_ok {
        $self->{vol}->rmdir(path => 'testdir');
    } qr/glfs_rmdir\(${\$self->_mock_glfs_new()}\, testdir\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_rmdir} = $glfs_rmdir;
}

sub test_unlink_success : Test
{
    my $self = shift;

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    my $mock_unlink = sub {
        $mock_info{call_count}++;
        push(@{$mock_info{args}}, [@_]);

        return 0;
    };

    no warnings 'redefine';

    my $glfs_unlink = \&GlusterFS::GFAPI::FFI::glfs_unlink;

    ${GlusterFS::GFAPI::FFI::}{glfs_unlink} = $mock_unlink;

    ok(!$self->{vol}->unlink(path => 'file.txt'), 'glfs_unlink() returned with 0');

    ${GlusterFS::GFAPI::FFI::}{glfs_unlink} = $glfs_unlink;
}

sub test_unlink_fail_exception : Test
{
    my $self = shift;

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    my $mock_unlink = sub {
        $mock_info{call_count}++;
        push(@{$mock_info{args}}, [@_]);

        return -1;
    };

    no warnings 'redefine';

    my $glfs_unlink = \&GlusterFS::GFAPI::FFI::glfs_unlink;

    ${GlusterFS::GFAPI::FFI::}{glfs_unlink} = $mock_unlink;

    throws_ok {
        $self->{vol}->unlink(path => 'testdir');
    } qr/glfs_unlink\(${\$self->_mock_glfs_new()}\, testdir\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_unlink} = $glfs_unlink;
}

sub test_removexattr_success : Test
{
    my $self = shift;

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    my $mock_removexattr = sub {
        $mock_info{call_count}++;
        push(@{$mock_info{args}}, [@_]);

        return 0;
    };

    no warnings 'redefine';

    my $glfs_removexattr = \&GlusterFS::GFAPI::FFI::glfs_removexattr;

    ${GlusterFS::GFAPI::FFI::}{glfs_removexattr} = $mock_removexattr;

    ok(!$self->{vol}->removexattr(path => 'file.txt', key => 'key1'), 'glfs_removexattr() returned with 0');

    ${GlusterFS::GFAPI::FFI::}{glfs_removexattr} = $glfs_removexattr;
}

sub test_removexattr_fail_exception : Test
{
    my $self = shift;

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    my $mock_removexattr = sub {
        $mock_info{call_count}++;
        push(@{$mock_info{args}}, [@_]);

        return -1;
    };

    no warnings 'redefine';

    my $glfs_removexattr = \&GlusterFS::GFAPI::FFI::glfs_removexattr;

    ${GlusterFS::GFAPI::FFI::}{glfs_removexattr} = $mock_removexattr;

    throws_ok {
        $self->{vol}->removexattr(path => 'file.txt', key => 'key1');
    } qr/glfs_removexattr\(${\$self->_mock_glfs_new()}\, file\.txt, key1\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_removexattr} = $glfs_removexattr;
}

sub test_rmtree_success : Test(no_plan)
{
    my $self = shift;

    my %mock_info = (
        scandir => {
            call_count => 0,
            args       => [],
        },
        islink => {
            call_count => 0,
            args       => [],
        },
        unlink => {
            call_count => 0,
            args       => [],
        },
        rmdir => {
            call_count => 0,
            args       => [],
        },
    );

    my %vol = (
        scandir => \&GlusterFS::GFAPI::FFI::Volume::scandir,
        islink  => \&GlusterFS::GFAPI::FFI::Volume::islink,
        unlink  => \&GlusterFS::GFAPI::FFI::Volume::unlink,
        rmdir   => \&GlusterFS::GFAPI::FFI::Volume::rmdir,
    );

    no warnings 'redefine';

    my $s_file = GlusterFS::GFAPI::FFI::Stat->new(
        st_mode => S_IFREG
    );

    my $d = GlusterFS::GFAPI::FFI::DirEntry->new(
        vol   => undef,
        path  => 'dirpath',
        name  => 'file1',
        lstat => $s_file,
    );

    my %mock = (
        scandir => sub {
            return generator { $_->yield($d); };
        },
        islink => sub {
            $mock_info{islink}->{call_count}++;
            push(@{$mock_info{islink}->{args}}, [@_]);
            return 0;
        },
        unlink => sub {
            $mock_info{unlink}->{call_count}++;
            push(@{$mock_info{unlink}->{args}}, [@_]);
            return 0;
        },
        rmdir => sub {
            $mock_info{rmdir}->{call_count}++;
            push(@{$mock_info{rmdir}->{args}}, [@_]);
            return 0;
        }
    );

    ${GlusterFS::GFAPI::FFI::Volume::}{scandir} = $mock{scandir};
    ${GlusterFS::GFAPI::FFI::Volume::}{islink}  = $mock{islink};
    ${GlusterFS::GFAPI::FFI::Volume::}{unlink}  = $mock{unlink};
    ${GlusterFS::GFAPI::FFI::Volume::}{rmdir}   = $mock{rmdir};

    $self->{vol}->rmtree(path => 'dirpath');

    cmp_ok($mock_info{islink}->{call_count}
        , '=='
        , 1
        , 'glfs_islink() called once');

    cmp_ok($mock_info{islink}->{args}->[0][2]
        , 'eq'
        , 'dirpath'
        , 'glfs_islink() called once with');

    cmp_ok($mock_info{unlink}->{call_count}
        , '=='
        , 1
        , 'glfs_unlink() called once');

    cmp_ok($mock_info{unlink}->{args}->[0][2]
        , 'eq'
        , 'dirpath/file1'
        , 'glfs_unlink() called once with');

    cmp_ok($mock_info{rmdir}->{call_count}
        , '=='
        , 1
        , 'glfs_rmdir() called once');

    cmp_ok($mock_info{rmdir}->{args}->[0][2]
        , 'eq'
        , 'dirpath'
        , 'glfs_rmdir() called once with');

    ${GlusterFS::GFAPI::FFI::Volume::}{scandir} = $vol{scandir};
    ${GlusterFS::GFAPI::FFI::Volume::}{islink}  = $vol{islink};
    ${GlusterFS::GFAPI::FFI::Volume::}{unlink}  = $vol{unlink};
    ${GlusterFS::GFAPI::FFI::Volume::}{rmdir}   = $vol{rmdir};
}

sub test_rmtree_listdir_exception : Test
{
    my $self = shift;

    my $mock_scandir = sub {
        die "OSError";
    };

    my $mock_islink = sub {
        return 0;
    };

    no warnings 'redefine';

    my $vol_scandir = \&GlusterFS::GFAPI::FFI::Volume::scandir;
    my $vol_islink  = \&GlusterFS::GFAPI::FFI::Volume::islink;

    ${GlusterFS::GFAPI::FFI::Volume::}{scandir} = $mock_scandir;
    ${GlusterFS::GFAPI::FFI::Volume::}{islink}  = $mock_islink;

    throws_ok {
        $self->{vol}->rmtree(path => 'dir1');
    } qr/OSError/;

    ${GlusterFS::GFAPI::FFI::Volume::}{scandir} = $vol_scandir;
    ${GlusterFS::GFAPI::FFI::Volume::}{islink}  = $vol_islink;
}

sub test_rmtree_islink_exception : Test
{
    my $self = shift;

    my $mock_islink = sub {
        return 1;
    };

    no warnings 'redefine';

    my $vol_islink = \&GlusterFS::GFAPI::FFI::Volume::islink;

    ${GlusterFS::GFAPI::FFI::Volume::}{islink} = $mock_islink;

    throws_ok {
        $self->{vol}->rmtree(path => 'dir1');
    } qr/Cannot call rmtree on a symbolic link/;

    ${GlusterFS::GFAPI::FFI::Volume::}{islink} = $vol_islink;
}

sub test_rmtree_ignore_unlink_rmdir_exception : Test(6)
{
    my $self = shift;

    my $s_file = GlusterFS::GFAPI::FFI::Stat->new(
        st_mode => S_IFREG
    );

    my $d = GlusterFS::GFAPI::FFI::DirEntry->new(
        vol   => undef,
        path  => 'dirpath',
        name  => 'file1',
        lstat => $s_file,
    );

    my %mock_info = ();

    my %mock = (
        scandir => sub {
            $mock_info{scandir}->{call_count}++;
            push(@{$mock_info{scandir}->{args}}, [@_]);
            return generator { $_->yield($d); };
        },
        islink => sub {
            $mock_info{islink}->{call_count}++;
            push(@{$mock_info{islink}->{args}}, [@_]);
            return 0;
        },
        unlink => sub {
            $mock_info{unlink}->{call_count}++;
            push(@{$mock_info{unlink}->{args}}, [@_]);
            confess('unlink');
        },
        rmdir => sub {
            $mock_info{rmdir}->{call_count}++;
            push(@{$mock_info{rmdir}->{args}}, [@_]);
            confess('rmdir');
        },
    );

    my %vol = ();

    no strict;
    no warnings 'redefine';

    map {
        $mock_info{$_} = { call_count => 0, args => [] };
        $vol{$_} = \&{*{"GlusterFS::GFAPI::FFI::Volume::$_"}{CODE}};
        ${GlusterFS::GFAPI::FFI::Volume::}{$_} = $mock{$_};
    } qw/scandir islink unlink rmdir/;

    $self->{vol}->rmtree(path => 'dirpath', ignore_errors => 1);

    cmp_ok($mock_info{islink}->{call_count}
        , '=='
        , 1
        , 'glfs_islink() called once');

    cmp_ok($mock_info{islink}->{args}->[0][2]
        , 'eq'
        , 'dirpath'
        , 'glfs_islink() called once with');

    cmp_ok($mock_info{unlink}->{call_count}
        , '=='
        , 1
        , 'glfs_unlink() called once');

    cmp_ok($mock_info{unlink}->{args}->[0][2]
        , 'eq'
        , 'dirpath/file1'
        , 'glfs_unlink() called once with');

    cmp_ok($mock_info{rmdir}->{call_count}
        , '=='
        , 1
        , 'glfs_rmdir() called once');

    cmp_ok($mock_info{rmdir}->{args}->[0][2]
        , 'eq'
        , 'dirpath'
        , 'glfs_rmdir() called once with');

    map {
        ${GlusterFS::GFAPI::FFI::Volume::}{$_} = $vol{$_};
    } keys(%vol);
}

sub test_setfsuid_success : Test
{
    my $self = shift;

    my $mock_setfsuid = sub {
        return 0;
    };

    no warnings 'redefine';

    my $glfs_setfsuid = \&GlusterFS::GFAPI::FFI::glfs_setfsuid;

    ${GlusterFS::GFAPI::FFI::}{glfs_setfsuid} = $mock_setfsuid;

    ok(!$self->{vol}->setfsuid(uid => 1000), 'glfs_setfsuid() returned with 0');

    ${GlusterFS::GFAPI::FFI::}{glfs_setfsuid} = $glfs_setfsuid;
}

sub test_setfsuid_fail_exception : Test
{
    my $self = shift;

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    my $mock_setfsuid = sub {
        $mock_info{call_count}++;
        push(@{$mock_info{args}}, [@_]);

        return -1;
    };

    no warnings 'redefine';

    my $glfs_setfsuid = \&GlusterFS::GFAPI::FFI::glfs_setfsuid;

    ${GlusterFS::GFAPI::FFI::}{glfs_setfsuid} = $mock_setfsuid;

    throws_ok {
        $self->{vol}->setfsuid(uid => 1001);
    } qr/glfs_setfsuid\(1001\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_setfsuid} = $glfs_setfsuid;
}

sub test_setfsgid_success : Test
{
    my $self = shift;

    my $mock_setfsgid = sub {
        return 0;
    };

    no warnings 'redefine';

    my $glfs_setfsgid = \&GlusterFS::GFAPI::FFI::glfs_setfsgid;

    ${GlusterFS::GFAPI::FFI::}{glfs_setfsgid} = $mock_setfsgid;

    ok(!$self->{vol}->setfsgid(gid => 1000), 'glfs_setfsgid() returned with 0');

    ${GlusterFS::GFAPI::FFI::}{glfs_setfsgid} = $glfs_setfsgid;
}

sub test_setfsgid_fail_exception : Test
{
    my $self = shift;

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    my $mock_setfsgid = sub {
        $mock_info{call_count}++;
        push(@{$mock_info{args}}, [@_]);

        return -1;
    };

    no warnings 'redefine';

    my $glfs_setfsgid = \&GlusterFS::GFAPI::FFI::glfs_setfsgid;

    ${GlusterFS::GFAPI::FFI::}{glfs_setfsgid} = $mock_setfsgid;

    throws_ok {
        $self->{vol}->setfsgid(gid => 1001);
    } qr/glfs_setfsgid\(1001\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_setfsgid} = $glfs_setfsgid;
}

sub test_setxattr_success : Test
{
    my $self = shift;

    my $mock_setxattr = sub {
        return 0;
    };

    no warnings 'redefine';

    my $glfs_setxattr = \&GlusterFS::GFAPI::FFI::glfs_setxattr;

    ${GlusterFS::GFAPI::FFI::}{glfs_setxattr} = $mock_setxattr;

    ok(!$self->{vol}->setxattr(path => 'file.txt', key => 'key1', value => 'hello'), 'glfs_setxattr() returned with 0');

    ${GlusterFS::GFAPI::FFI::}{glfs_setxattr} = $glfs_setxattr;
}

sub test_setxattr_fail_exception : Test
{
    my $self = shift;

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    my $mock_setxattr = sub {
        $mock_info{call_count}++;
        push(@{$mock_info{args}}, [@_]);

        return -1;
    };

    no warnings 'redefine';

    my $glfs_setxattr = \&GlusterFS::GFAPI::FFI::glfs_setxattr;

    ${GlusterFS::GFAPI::FFI::}{glfs_setxattr} = $mock_setxattr;

    throws_ok {
        $self->{vol}->setxattr(path => 'file.txt', key => 'key1', value => 'hello');
    } qr/
        glfs_setxattr\(${\$self->_mock_glfs_new()},\ file\.txt,\ key1,\ hello,\ 5,\ 00\)\ failed
    /x;


    ${GlusterFS::GFAPI::FFI::}{glfs_setxattr} = $glfs_setxattr;
}

sub test_symlink_success : Test
{
    my $self = shift;

    my $mock_symlink = sub {
        return 0;
    };

    no warnings 'redefine';

    my $glfs_symlink = \&GlusterFS::GFAPI::FFI::glfs_symlink;

    ${GlusterFS::GFAPI::FFI::}{glfs_symlink} = $mock_symlink;

    ok(!$self->{vol}->symlink(src => 'file.txt', link => 'filelink'), 'glfs_symlink() returned with 0');

    ${GlusterFS::GFAPI::FFI::}{glfs_symlink} = $glfs_symlink;
}

sub test_symlink_fail_exception : Test
{
    my $self = shift;

    my %mock_info = (
        call_count => 0,
        args       => [],
    );

    my $mock_symlink = sub {
        $mock_info{call_count}++;
        push(@{$mock_info{args}}, [@_]);

        return -1;
    };

    no warnings 'redefine';

    my $glfs_symlink = \&GlusterFS::GFAPI::FFI::glfs_symlink;

    ${GlusterFS::GFAPI::FFI::}{glfs_symlink} = $mock_symlink;

    throws_ok {
        $self->{vol}->symlink(src => 'file.txt', link => 'filelink');
    } qr/glfs_symlink\(${\$self->_mock_glfs_new()}\, file\.txt\, filelink\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_symlink} = $glfs_symlink;
}

sub test_walk_success : Test(4)
{
    my $self = shift;

    my $s_dir = GlusterFS::GFAPI::FFI::Stat->new(
        st_mode => S_IFDIR
    );

    my $d1 = GlusterFS::GFAPI::FFI::DirEntry->new(
        vol   => undef,
        path  => 'dirpath',
        name  => 'dir1',
        lstat => $s_dir,
    );

    my $d2 = GlusterFS::GFAPI::FFI::DirEntry->new(
        vol   => undef,
        path  => 'dirpath',
        name  => 'dir2',
        lstat => $s_dir,
    );

    my $s_file = GlusterFS::GFAPI::FFI::Stat->new(
        st_mode => S_IFREG
    );

    my $d3 = GlusterFS::GFAPI::FFI::DirEntry->new(
        vol   => undef,
        path  => 'dirpath',
        name  => 'file1',
        lstat => $s_file,
    );

    my $d4 = GlusterFS::GFAPI::FFI::DirEntry->new(
        vol   => undef,
        path  => 'dirpath',
        name  => 'file2',
        lstat => $s_file,
    );

    my $mock_scandir = sub {
        return generator {
            my @entries = ($d1, $d3, $d2, $d4);

            foreach my $dentry (@entries)
            {
                $_->yield($dentry);
            }
        };
    };

    no warnings 'redefine';

    my $vol_scandir = \&GlusterFS::GFAPI::FFI::Volume::scandir;

    ${GlusterFS::GFAPI::FFI::Volume::}{scandir} = $mock_scandir;

    my $gen = $self->{vol}->walk(path => 'dirpath');

    while (my ($path, $dirs, $files) = $gen->next)
    {
        cmp_ok($dirs->[0],  'eq', 'dir1',  '$dirs->[0] is dir1');
        cmp_ok($dirs->[1],  'eq', 'dir2',  '$dirs->[1] is dir2');
        cmp_ok($files->[0], 'eq', 'file1', '$files->[0] is file1');
        cmp_ok($files->[1], 'eq', 'file2', '$files->[1] is file2');

        last;
    }

    ${GlusterFS::GFAPI::FFI::Volume::}{scandir} = $vol_scandir;
}

sub test_walk_scandir_exception : Test
{
    my $self = shift;

    my $mock_scandir = sub
    {
        die 'OSError';
    };

    my $mock_onerror = sub
    {
        my $e = shift;

        like($e, '/OSError/', 'onerror with OSError');
    };

    my $vol_scandir = \&GlusterFS::GFAPI::FFI::Volume::scandir;

    no warnings 'redefine';

    ${GlusterFS::GFAPI::FFI::Volume::}{scandir} = $mock_scandir;

    my $walker = $self->{vol}->walk(path => 'dir1', onerror => $mock_onerror);

    while (my ($path, $dirs, $files) = $walker->next)
    {
        next;
    }

    ${GlusterFS::GFAPI::FFI::Volume::}{scandir} = $vol_scandir;
}

sub test_copytree_success : Test(no_plan)
{
    my $self = shift;

    my $d_stat = GlusterFS::GFAPI::FFI::Stat->new(
        st_mode => S_IFDIR
    );

    my $f_stat = GlusterFS::GFAPI::FFI::Stat->new(
        st_mode => S_IFREG
    );

    # So there are 5 files inn total that should to be copied
    # and (3 + 1) directories should be created, including the destination

    my %mock_info = ();

    my $iter = generator {
        my @entries = (
            # Depth = 0
            ['dir1', $d_stat, 'dir2', $d_stat, 'file1', $f_stat],
            # Depth = 1, dir1
            ['file2', $f_stat, 'file3', $f_stat],
            # Depth = 1, dir2
            ['file4', $f_stat, 'dir3', $d_stat, 'file5', $f_stat],
            # Depth = 1, dir3
            []                  # Empty directory.
        );

        while (my $entry = shift(@entries))
        {
            $_->yield(@{$entry});
        }
    };

    my $m_listdir_with_stat = sub {
        $mock_info{listdir_with_stat}->{call_count}++;
        push(@{$mock_info{listdir_with_stat}->{args}}, \@_);

        return $iter->next;
    };

    my $m_makedirs = sub {
        $mock_info{makedirs}->{call_count}++;
        push(@{$mock_info{makedirs}->{args}}, \@_);
    };

    my $m_fopen = sub {
        $mock_info{fopen}->{call_count}++;
        push(@{$mock_info{fopen}->{args}}, \@_);
    };

    my $m_copyfileobj = sub {
        $mock_info{copyfileobj}->{call_count}++;
        push(@{$mock_info{copyfileobj}->{args}}, \@_);
    };

    my $m_utime = sub {
        $mock_info{utime}->{call_count}++;
        push(@{$mock_info{utime}->{args}}, \@_);
    };

    my $m_chmod = sub {
        $mock_info{chmod}->{call_count}++;
        push(@{$mock_info{chmod}->{args}}, \@_);
    };

    my $m_copystat = sub {
        $mock_info{copystat}->{call_count}++;
        push(@{$mock_info{copystat}->{args}}, \@_);
    };

    no warnings 'redefine';

    my %vol = ();

    map { my $name = $_;

        eval "\$vol{$name} = \\&GlusterFS::GFAPI::FFI::Volume::$name";
        eval "\${GlusterFS::GFAPI::FFI::Volume::}{$name} = \$m_$name";

        $mock_info{$name} = {
            call_count => 0,
            args       => [],
        };
    } qw/listdir_with_stat makedirs fopen copyfileobj utime chmod copystat/;

    $self->{vol}->copytree(src => '/source', dst => '/destination');

    # Assert that listdir_with_stat() was called on all directories
    cmp_ok($mock_info{listdir_with_stat}->{call_count}
            , '=='
            , 1 + 3
            , 'listdir_with_stat() called 1 + 3 times');

    # Assert that fopen() was called 10 times - twice for each file
    # i.e once for reading and another time for writing.
    cmp_ok($mock_info{fopen}->{call_count}, '==', 10
            , 'fopen() called 10 times');

    # Assert number of files copied
    cmp_ok($mock_info{copyfileobj}->{call_count}, '==', 5
            , 'copyfileobj() called 5 times');

    # Assert that utime and chmod was caled on the files
    cmp_ok($mock_info{utime}->{call_count}, '==', 5
            , 'utime() called 5 times');

    cmp_ok($mock_info{chmod}->{call_count}, '==', 5
            , 'chmod() called 5 times');

    # Assert number of directories created
    cmp_ok($mock_info{makedirs}->{call_count}
            , '=='
            , 1 + 3
            , 'makedirs() called 1 + 3 times');

    # Assert that copystat() was called on source and destination dir
    my $called = 0;
    my $index  = 0;

    for (my $i=0; $i<@{$mock_info{copystat}->{args}}; $i++)
    {
        my $args = $mock_info{copystat}->{args}->[$i];

        if ($args->[2] eq '/source'
            && $args->[4] eq '/destination')
        {
            $called++;
            $index = $i;
        }
    }

    cmp_ok($called, '==', 1, 'copystat() called once');

    cmp_ok($mock_info{copystat}->{args}->[$index][2]
        , 'eq'
        , '/source'
        , 'copystat() called once with [/source, /destination]');

    cmp_ok($mock_info{copystat}->{args}->[$index][4]
        , 'eq'
        , '/destination'
        , 'copystat() called once with [/source, /destination]');

    map { ${GlusterFS::GFAPI::FFI::Volume::}{$_} = $vol{$_}; } keys(%vol);
}

sub test_utime : Test(6)
{
    my $self = shift;

    foreach my $junk (
        ['a', undef],
        [1234.1234, undef],
        [undef, 'b'],
        [undef, 1234.1234])
    {
        throws_ok {
            $self->{vol}->utime(
                path  => '/path',
                atime => $junk->[0],
                mtime => $junk->[1]);
        } qr/Invalid type/;
    }

    my %mock_info = (
        glfs_utimens => {
            call_count => 0,
            args       => [],
        },
#        time => {
#            call_count => 0,
#            args       => [],
#        }
    );

    # Test times = None
    my $mock_utimens = sub {
        $mock_info{glfs_utimens}->{call_count}++;
        push(@{$mock_info{glfs_utimens}->{args}}, \@_);

        return 1;
    };

#    my $mock_time = sub () {
#        $mock_info{time}->{call_count}++;
#        push(@{$mock_info{time}->{args}}, \@_);
#
#        return 12345.6789;
#    };

    no warnings 'redefine';

    my $glfs_utimens = \&GlusterFS::GFAPI::FFI::glfs_utimens;
#    my $core_time    = \&CORE::GLOBAL::time;

    ${GlusterFS::GFAPI::FFI::}{glfs_utimens} = $mock_utimens;
#    ${CORE::GLOBAL::}{time} = $mock_time;

    $self->{vol}->utime(path => '/path');

    ok($mock_info{glfs_utimens}->{call_count}, 'glfs_utimens() called');
#    ok($mock_info{time}->{call_count}, 'time() called');

    ${GlusterFS::GFAPI::FFI::}{glfs_utimens} = $glfs_utimens;
#    ${CORE::GLOBAL::}{time} = $core_time;
}

1;
