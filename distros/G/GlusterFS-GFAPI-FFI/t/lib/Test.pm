package Test;

use strict;
use warnings;
use utf8;

use Test::Most;

sub _mock_glfs_close
{
    return 0;
}

sub _mock_glfs_closedir
{
    return;
}

sub _mock_glfs_new
{
    return 12345;
}

sub _mock_glfs_init
{
    return 0;
}

sub _mock_glfs_set_volfile_server
{
    return 0;
}

sub _mock_glfs_fini
{
    return 0;
}

sub _mock_glfs_set_logging
{
    return 0;
}

sub _init_class
{
    my $self  = shift;
    my $class = shift;
    my @args  = @_;

    $class = "GlusterFS::GFAPI::FFI::$class";

    $class->new(@args);
}

1;
