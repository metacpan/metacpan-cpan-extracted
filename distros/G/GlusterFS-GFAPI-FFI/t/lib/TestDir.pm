package TestDir;

use parent 'Test', 'Test::Class';

use Test::Most;
use GlusterFS::GFAPI::FFI;
use GlusterFS::GFAPI::FFI::Dir;

sub setup : Test(setup)
{
    my $self = shift;

    $self->{_saved_glfs_closedir} = \&GlusterFS::GFAPI::FFI::glfs_closedir;

    no warnings 'redefine';

    ${GlusterFS::GFAPI::FFI::}{glfs_closedir} = \&Test::_mock_glfs_closedir;
}

sub teardown : Test(teardown)
{
    my $self = shift;

    no warnings 'redefine';

    ${GlusterFS::GFAPI::FFI::}{glfs_closedir} = $self->{_saved_glfs_closedir};
}

sub test_next_success : Test(2)
{
    my $self = shift;

    $self->builder->skip("need to solve issue with dependency on gluster.so");

    my $mock_glfs_readdir_r = sub
    {
        my ($fd, $ent, $cursor) = @_;

        #$cursor->contents('bla');

        return 0;
    };

    no warnings 'redefine';

    my $old = ${GlusterFS::GFAPI::FFI::}{glfs_readdir_r};

    ${GlusterFS::GFAPI::FFI::}{glfs_readdir_r} = $mock_glfs_readdir_r;

    my $fd    = GlusterFS::GFAPI::FFI::Dir->new(fd => 2);
    my $entry = $fd->next();

    isa_ok($entry, 'GlusterFS::GFAPI::FFI::Dirent');

    ${GlusterFS::GFAPI::FFI::}{glfs_readdir_r} = $old;
}

1;
