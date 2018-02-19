package GlusterFS::GFAPI::FFI::Dir;

BEGIN
{
    our $AUTHOR  = 'cpan:potatogim';
    our $VERSION = '0.4';
}

use strict;
use warnings;
use utf8;

use Moo;
use GlusterFS::GFAPI::FFI;
use GlusterFS::GFAPI::FFI::Util qw/libgfapi_soname/;
use Carp;


#---------------------------------------------------------------------------
#   Attributes
#---------------------------------------------------------------------------
has 'api' =>
(
    is => 'rwp',
);

has 'fd' =>
(
    is => 'rw',
);

has 'readdirplus' =>
(
    is => 'rw',
);

has 'cursor' =>
(
    is => 'rwp',
);


#---------------------------------------------------------------------------
#   Contructor/Destructor
#---------------------------------------------------------------------------
sub BUILD
{
    my $self = shift;
    my $args = shift;

    $self->_set_api($args->{api});
    $self->fd($args->{fd});
    $self->readdirplus($args->{readdirplus} // 0);
    $self->_set_cursor(GlusterFS::GFAPI::FFI::Dirent->new());
}

sub DEMOLISH
{
    my ($self, $is_global) = @_;

    if (defined($self->fd)
        && GlusterFS::GFAPI::FFI::glfs_closedir($self->fd))
    {
        confess($!);
    }

    $self->_set_api(undef);
}


#---------------------------------------------------------------------------
#   Methods
#---------------------------------------------------------------------------
sub next
{
    my $self = shift;
    my %args = @_;

    my $entry = GlusterFS::GFAPI::FFI::Dirent->new(d_reclen => 256);
    my $stat;

    my $ret;

    if ($self->readdirplus)
    {
        $stat = GlusterFS::GFAPI::FFI::Stat->new();
        $ret  = glfs_readdirplus_r($self->fd, $stat, $entry, \$self->cursor);
    }
    else
    {
        $ret = GlusterFS::GFAPI::FFI::glfs_readdir_r($self->fd, $entry, \$self->cursor);
    }

    if ($ret != 0)
    {
        confess($!);
    }

    #if (!defined($self->cursor) || !defined($self->cursor->contents))
    if (!defined($self->cursor))
    {
        return undef;
    }

    return $self->readdirplus ? ($entry, $stat) : $entry;
}

1;

__END__

=encoding utf8

=head1 NAME

GlusterFS::GFAPI::FFI::Dir - GFAPI Directory Iterator API

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 BUGS

=head1 SEE ALSO

=head1 AUTHOR

Ji-Hyeon Gim E<lt>potatogim@gluesys.comE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright 2017-2018 by Ji-Hyeon Gim.

This is free software; you can redistribute it and/or modify it under the same terms as the GPLv2/LGPLv3.

=cut

