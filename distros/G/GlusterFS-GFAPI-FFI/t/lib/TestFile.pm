package TestFile;

use parent 'Test', 'Test::Class';

use Fcntl       qw/:mode :seek/;
use Try::Tiny;
use Test::Most;
use GlusterFS::GFAPI::FFI;
use GlusterFS::GFAPI::FFI::File;
use FFI::Platypus::Memory;

sub startup : Test(startup)
{
    my $self = shift;

    $self->{fd} = GlusterFS::GFAPI::FFI::File->new(
                    fd   => 2,
                    path => 'fakefile');
}

sub setup : Test(setup)
{
    my $self = shift;

    $self->{_saved_glfs_close} = \&GlusterFS::GFAPI::FFI::glfs_close;

    no warnings 'redefine';

    ${GlusterFS::GFAPI::FFI::}{glfs_close} = \&Test::_mock_glfs_close;
}

sub teardown : Test(teardown)
{
    my $self = shift;

    no warnings 'redefine';

    ${GlusterFS::GFAPI::FFI::}{glfs_close} = $self->{_saved_glfs_close};
}

sub shutdown : Test(shutdown)
{
    my $self = shift;

    $self->{fd}->_set_fd(undef);
}

sub test_validate_init : Test(2)
{
    my $self = shift;

    throws_ok {
        GlusterFS::GFAPI::FFI::File->new();
    } qr/I\/O operation on invalid fd/;

    throws_ok {
        GlusterFS::GFAPI::FFI::File->new(fd => 'not_int');
    } qr/I\/O operation on invalid fd/;
}

sub test_fchmod_success : Test
{
    my $self = shift;

    my $mock_glfs_fchmod = sub {
        return 0;
    };

    no warnings 'redefine';

    my $glfs_fchmod = \&GlusterFS::GFAPI::FFI::glfs_fchmod;

    ${GlusterFS::GFAPI::FFI::}{glfs_fchmod} = $mock_glfs_fchmod;

    ok(!$self->{fd}->fchmod(mode => 0600), '$f->fchmod() is returned with 0');

    ${GlusterFS::GFAPI::FFI::}{glfs_fchmod} = $glfs_fchmod;
}

sub test_fchmod_fail_exception : Test
{
    my $self = shift;

    my $mock_glfs_fchmod = sub {
        return -1;
    };

    no warnings 'redefine';

    my $glfs_fchmod = \&GlusterFS::GFAPI::FFI::glfs_fchmod;

    ${GlusterFS::GFAPI::FFI::}{glfs_fchmod} = $mock_glfs_fchmod;

    throws_ok {
        $self->{fd}->fchmod(mode => 0600);
    } qr/glfs_fchmod\(${\$self->{fd}->fd}, 0600\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_fchmod} = $glfs_fchmod;
}

sub test_fchown_success : Test
{
    my $self = shift;

    my $mock_glfs_fchown = sub {
        return 0;
    };

    no warnings 'redefine';

    my $glfs_fchown = \&GlusterFS::GFAPI::FFI::glfs_fchown;

    ${GlusterFS::GFAPI::FFI::}{glfs_fchown} = $mock_glfs_fchown;

    ok(!$self->{fd}->fchown(uid => 9, gid => 11)
        , '$f->fchown(uid => 9, gid => 11) is returned with 0');

    ${GlusterFS::GFAPI::FFI::}{glfs_fchown} = $glfs_fchown;
}

sub test_fchown_exception : Test
{
    my $self = shift;

    my $mock_glfs_fchown = sub {
        return -1;
    };

    no warnings 'redefine';

    my $glfs_fchown = \&GlusterFS::GFAPI::FFI::glfs_fchown;

    ${GlusterFS::GFAPI::FFI::}{glfs_fchown} = $mock_glfs_fchown;

    throws_ok {
        $self->{fd}->fchown(uid => 9, gid => 11);
    } qr/glfs_fchown\(${\$self->{fd}->fd}, 9, 11\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_fchown} = $glfs_fchown;
}

sub test_dup : Test(3)
{
    my $self = shift;

    my $mock_glfs_dup = sub {
        return 2;
    };

    no warnings 'redefine';

    my $glfs_dup = \&GlusterFS::GFAPI::FFI::glfs_dup;

    ${GlusterFS::GFAPI::FFI::}{glfs_dup} = $mock_glfs_dup;

    my $dup_f = $self->{fd}->dup();

    isa_ok($dup_f, 'GlusterFS::GFAPI::FFI::File'
        , '$f->dup() is returned with GlusterFS::GFAPI::FFI::File instance');

    cmp_ok($dup_f->originalpath, 'eq', 'fakefile'
        , '$dup_f->originalpath is "fakefile"');

    cmp_ok($dup_f->fd, '==', 2, '$dup_f->fd is "2"');

    ${GlusterFS::GFAPI::FFI::}{glfs_dup} = $glfs_dup;
}

sub test_fdatasync_success : Test
{
    my $self = shift;

    my $mock_glfs_fdatasync = sub {
        return 4;
    };

    no warnings 'redefine';

    my $glfs_fdatasync = \&GlusterFS::GFAPI::FFI::glfs_fdatasync;

    ${GlusterFS::GFAPI::FFI::}{glfs_fdatasync} = $mock_glfs_fdatasync;

    cmp_ok($self->{fd}->fdatasync(), '==', 4, '$f->fdatasync() is returned with 4');

    ${GlusterFS::GFAPI::FFI::}{glfs_fdatasync} = $glfs_fdatasync;
}

sub test_fdatasync_fail_exception : Test
{
    my $self = shift;

    my $mock_glfs_fdatasync = sub {
        return -1;
    };

    no warnings 'redefine';

    my $glfs_fdatasync = \&GlusterFS::GFAPI::FFI::glfs_fdatasync;

    ${GlusterFS::GFAPI::FFI::}{glfs_fdatasync} = $mock_glfs_fdatasync;

    throws_ok {
        $self->{fd}->fdatasync();
    } qr/glfs_fdatasync\(${\$self->{fd}->fd}\) failed: /;

    ${GlusterFS::GFAPI::FFI::}{glfs_fdatasync} = $glfs_fdatasync;
}

sub test_fstat_success : Test
{
    my $self = shift;

    my $mock_glfs_fstat = sub {
        return 0;
    };

    no warnings 'redefine';

    my $glfs_fstat = \&GlusterFS::GFAPI::FFI::glfs_fstat;

    ${GlusterFS::GFAPI::FFI::}{glfs_fstat} = $mock_glfs_fstat;

    my $s = $self->{fd}->fstat();

    isa_ok($s, 'GlusterFS::GFAPI::FFI::Stat',
        , '$f->fstat() is returned with GlusterFS::GFAPI::FFI::Stat instance');

    ${GlusterFS::GFAPI::FFI::}{glfs_fstat} = $glfs_fstat;
}

sub test_fstat_fail_exception : Test
{
    my $self = shift;

    my $mock_glfs_fstat = sub {
        return -1;
    };

    no warnings 'redefine';

    my $glfs_fstat = \&GlusterFS::GFAPI::FFI::glfs_fstat;

    ${GlusterFS::GFAPI::FFI::}{glfs_fstat} = $mock_glfs_fstat;

    throws_ok {
        $self->{fd}->fstat();
    } qr/glfs_fstat\(${\$self->{fd}->fd}, GlusterFS::GFAPI::FFI::Stat=.+\) failed: /;

    ${GlusterFS::GFAPI::FFI::}{glfs_fstat} = $glfs_fstat;
}

sub test_fsync_success : Test
{
    my $self = shift;

    my $mock_glfs_fsync = sub {
        return 0;
    };

    no warnings 'redefine';

    my $glfs_fsync = \&GlusterFS::GFAPI::FFI::glfs_fsync;

    ${GlusterFS::GFAPI::FFI::}{glfs_fsync} = $mock_glfs_fsync;

    cmp_ok($self->{fd}->fsync(), '==', 0
        , "\$f->fsync(${\$self->{fd}->fd}) is returned with 0");

    ${GlusterFS::GFAPI::FFI::}{glfs_fsync} = $glfs_fsync;
}

sub test_fsync_fail_exception : Test
{
    my $self = shift;

    my $mock_glfs_fsync = sub {
        return -1;
    };

    no warnings 'redefine';

    my $glfs_fsync = \&GlusterFS::GFAPI::FFI::glfs_fsync;

    ${GlusterFS::GFAPI::FFI::}{glfs_fsync} = $mock_glfs_fsync;

    throws_ok {
        $self->{fd}->fsync();
    } qr/glfs_fsync\(${\$self->{fd}->fd}\) failed: /;

    ${GlusterFS::GFAPI::FFI::}{glfs_fsync} = $glfs_fsync;
}

sub test_lseek_success : Test
{
    my $self = shift;

    my $mock_glfs_lseek = sub {
        return 20;
    };

    no warnings 'redefine';

    my $glfs_lseek = \&GlusterFS::GFAPI::FFI::glfs_lseek;

    ${GlusterFS::GFAPI::FFI::}{glfs_lseek} = $mock_glfs_lseek;

    my $o = $self->{fd}->lseek(20, SEEK_SET);

    cmp_ok($o, '==', 20
        , "\$f->lseek(${\$self->{fd}->fd}) is returned with \"20\"");

    ${GlusterFS::GFAPI::FFI::}{glfs_lseek} = $glfs_lseek;
}

sub test_read_success : Test
{
    my $self = shift;

    my $mock_glfs_read = sub {
        my ($fd, $rbuf, $buflen, $flags) = @_;

        my $buf = strdup('hello');

        memcpy($rbuf, $buf, 5);

        return 5;
    };

    no warnings 'redefine';

    my $glfs_read = \&GlusterFS::GFAPI::FFI::glfs_read;

    ${GlusterFS::GFAPI::FFI::}{glfs_read} = $mock_glfs_read;

    my $b = $self->{fd}->read(size => 5);

    cmp_ok($b, 'eq', 'hello'
        , "\$f->read(size => 5) is returned with \"hello\"");

    ${GlusterFS::GFAPI::FFI::}{glfs_read} = $glfs_read;
}

sub test_read_fail_exception : Test
{
    my $self = shift;

    my $mock_glfs_read = sub {
        return -1;
    };

    no warnings 'redefine';

    my $glfs_read = \&GlusterFS::GFAPI::FFI::glfs_read;

    ${GlusterFS::GFAPI::FFI::}{glfs_read} = $mock_glfs_read;

    throws_ok {
        $self->{fd}->read(size => 5);
    } qr/glfs_read\(${\$self->{fd}->fd}, \$buf, 5, 0\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_read} = $glfs_read;
}

sub test_read_buflen_negative : Test(3)
{
    my $self = shift;

    my $mock_glfs_read = sub {
        my ($fd, $rbuf, $buflen, $flags) = @_;

        cmp_ok($buflen, '==', 12345, '$buflen: 12345');

        return $buflen;
    };

    my $mock_fgetsize = sub {
        return 12345;
    };

    no warnings 'redefine';

    my $glfs_read     = \&GlusterFS::GFAPI::FFI::glfs_read;
    my $file_fgetsize = \&GlusterFS::GFAPI::FFI::File::fgetsize;

    ${GlusterFS::GFAPI::FFI::}{glfs_read}    = $mock_glfs_read;
    ${GlusterFS::GFAPI::FFI::File::}{fgetsize} = $mock_fgetsize;

    foreach my $buflen (-1, -2, -999)
    {
        $self->{fd}->read(size => $buflen);
    }

    ${GlusterFS::GFAPI::FFI::}{glfs_read}    = $glfs_read;
    ${GlusterFS::GFAPI::FFI::File::}{fgetsize} = $file_fgetsize;
}

sub test_readinto : Test
{
    my $self = shift;

    my $mock_glfs_read = sub {
        return 5;
    };

    no warnings 'redefine';

    my $glfs_read = \&GlusterFS::GFAPI::FFI::glfs_read;

    ${GlusterFS::GFAPI::FFI::}{glfs_read} = $mock_glfs_read;

    my $buf = calloc(10, 1);

    cmp_ok($self->{fd}->readinto(buf => $buf), '==', 5
            , '$f->readinto(buf => $buf) is returned with 5');

    free($buf);

    ${GlusterFS::GFAPI::FFI::}{glfs_read} = $glfs_read;
}

sub test_write_success : Test
{
    my $self = shift;

    my $mock_glfs_write = sub {
        return 5;
    };

    no warnings 'redefine';

    my $glfs_write = \&GlusterFS::GFAPI::FFI::glfs_write;

    ${GlusterFS::GFAPI::FFI::}{glfs_write} = $mock_glfs_write;

    cmp_ok($self->{fd}->write(data => 'hello'), '==', 5
        , "\$f->write(data => 'hello') is returned with \"5\"");

    ${GlusterFS::GFAPI::FFI::}{glfs_write} = $glfs_write;
}

sub test_write_binary_success : Test
{
    my $self = shift;

    my $mock_glfs_write = sub {
        return 3;
    };

    no warnings 'redefine';

    my $glfs_write = \&GlusterFS::GFAPI::FFI::glfs_write;

    ${GlusterFS::GFAPI::FFI::}{glfs_write} = $mock_glfs_write;

    my $b = calloc(3, 1);

    cmp_ok($self->{fd}->write(data => $b), '==', 3
        , "\$f->write(data => \$byte(3)) is returned with \"3\"");

    ${GlusterFS::GFAPI::FFI::}{glfs_write} = $glfs_write;
}

sub test_write_fail_exception : Test
{
    my $self = shift;

    my $mock_glfs_write = sub {
        return -1;
    };

    no warnings 'redefine';

    my $glfs_write = \&GlusterFS::GFAPI::FFI::glfs_write;

    ${GlusterFS::GFAPI::FFI::}{glfs_write} = $mock_glfs_write;

    throws_ok {
        $self->{fd}->write(data => 'hello');
    } qr/glfs_write\(${\$self->{fd}->fd}, \$buf, 5, 0\) failed/;

    ${GlusterFS::GFAPI::FFI::}{glfs_write} = $glfs_write;
}

sub test_fallocate_success : Test
{
    my $self = shift;

#    $self->builder->skip("need to solve issue with dependency on gluster.so");

    my $mock_glfs_fallocate = sub {
        return 0;
    };

    no warnings 'redefine';

    my $glfs_fallocate = \&GlusterFS::GFAPI::FFI::glfs_fallocate;

    ${GlusterFS::GFAPI::FFI::}{glfs_fallocate} = $mock_glfs_fallocate;

    cmp_ok($self->{fd}->fallocate(mode => 0, offset => 0, length => 1024),
            '==',
            0,
            '$f->fallocate(mode => 0, offset => 0, length => 1024) is returned with 0');

    ${GlusterFS::GFAPI::FFI::}{glfs_fallocate} = $glfs_fallocate;
}

sub test_fallocate_fail_exception : Test
{
    my $self = shift;

    my $mock_glfs_fallocate = sub {
        return -1;
    };

    no warnings 'redefine';

    my $glfs_fallocate = \&GlusterFS::GFAPI::FFI::glfs_fallocate;

    ${GlusterFS::GFAPI::FFI::}{glfs_fallocate} = $mock_glfs_fallocate;

    throws_ok {
        $self->{fd}->fallocate(mode => 0, offset => 0, length => 1024);
    } qr/glfs_fallocate\(${\$self->{fd}->fd}, 0, 0, 1024\) failed: /;

    ${GlusterFS::GFAPI::FFI::}{glfs_fallocate} = $glfs_fallocate;
}

sub test_discard_success : Test
{
    my $self = shift;

    my $mock_glfs_discard = sub {
        return 0;
    };

    no warnings 'redefine';

    my $glfs_discard = \&GlusterFS::GFAPI::FFI::glfs_discard;

    ${GlusterFS::GFAPI::FFI::}{glfs_discard} = $mock_glfs_discard;

    cmp_ok($self->{fd}->discard(offset => 1024, length => 1024),
            '==',
            0,
            '$f->discard(offset => 1024, length => 1024) is returned with 0');

    ${GlusterFS::GFAPI::FFI::}{glfs_discard} = $glfs_discard;
}

sub test_discard_fail_exception : Test
{
    my $self = shift;

    my $mock_glfs_discard = sub {
        return -1;
    };

    no warnings 'redefine';

    my $glfs_discard = \&GlusterFS::GFAPI::FFI::glfs_discard;

    ${GlusterFS::GFAPI::FFI::}{glfs_discard} = $mock_glfs_discard;

    throws_ok {
        $self->{fd}->discard(offset => 1024, length => 1024);
    } qr/glfs_discard\(${\$self->{fd}->fd}, 1024, 1024\) failed: /;

    ${GlusterFS::GFAPI::FFI::}{glfs_discard} = $glfs_discard;
}

1;
