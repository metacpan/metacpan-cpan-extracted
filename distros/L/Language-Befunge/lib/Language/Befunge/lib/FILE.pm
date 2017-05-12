#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package Language::Befunge::lib::FILE;
# ABSTRACT: file operations
$Language::Befunge::lib::FILE::VERSION = '5.000';
use Class::XSAccessor accessors => {
    _iohs => '_iohs',
    _bufs => '_bufs',
};
use IO::File;

sub new { return bless { _iohs=>{}, _bufs=>{} }, shift; }


#
# C( $fid )
#
# Close filehandle corresponding to $fid
#
sub C {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    my $fid = $ip->spop;
    my $fh = $self->_iohs->{$fid};
    defined $fh or return $ip->dir_reverse;

    #use Data::Dumper; print Dumper($self);
    #warn ">>>$fid=$fh<<<\n";
    delete $self->_iohs->{$fid};
    delete $self->_bufs->{$fid};

    $fh->close or $ip->dir_reverse;
}

sub D {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    my $file = $ip->spop_gnirts;
    unlink $file or $ip->dir_reverse;
}

sub G {
    my ($self, $interp) = @_;
    my $ip  = $interp->get_curip;

    my $fid = $ip->spop;
    my $fh  = $self->_iohs->{$fid};
    defined $fh or return $ip->dir_reverse;

    my $line = $fh->getline // '';
    $ip->spush_args( $fid, $line, length($line) );
}

sub L {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    my $fid = $ip->spop;
    my $fh  = $self->_iohs->{$fid};
    defined $fh or return $ip->dir_reverse;
    my $pos = $fh->tell;
    $pos == -1
        ? $ip->dir_reverse
        : $ip->spush( $fid, $pos );
}

sub O {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    # pop the values
    my $path = $ip->spop_gnirts;
    my $mode = $ip->spop;
    my $vec  = $ip->spop_vec;

    # try to open the file
    my @modes = ( '<', '>', '>>', '+<', '+>', '+>>' );
    my $fh = IO::File->new;
    $fh->open( $path, $modes[$mode] ) or return $ip->dir_reverse;

    # store handles & whatnots
    my $fid = $fh->fileno;
    $self->_iohs->{$fid} = $fh;
    $self->_bufs->{$fid} = $vec;

    $ip->spush( $fid );
}

sub P {
    my ($self, $interp) = @_;
    my $ip  = $interp->get_curip;

    my $str = $ip->spop_gnirts;
    my $fid = $ip->spop;
    my $fh  = $self->_iohs->{$fid};
    defined $fh or return $ip->dir_reverse;

    $fh->print($str) or return $ip->dir_reverse;
    $ip->spush($fid);
}

sub R {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    my $c    = $ip->spop;
    my $fid  = $ip->spop;
    my $fh   = $self->_iohs->{$fid};
    defined $fh or return $ip->dir_reverse;

    my $buf;
    $fh->read( $buf, $c );
    $ip->spush( $fid );

    my $storage = $interp->get_storage;
    my $vec     = $self->_bufs->{$fid};
    $storage->store_binary( $buf, $vec );
}

sub S {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    # pop the values
    my $pos  = $ip->spop;
    my $from = $ip->spop;
    my $fid  = $ip->spop;
    my $fh   = $self->_iohs->{$fid};
    defined $fh or return $ip->dir_reverse;

    $fh->seek( $pos, $from );
    $ip->spush( $fid );
}

sub W {
    my ($self, $interp) = @_;
    my $ip = $interp->get_curip;

    # pop the values
    my $c    = $ip->spop;
    my $fid  = $ip->spop;
    my $fh   = $self->_iohs->{$fid};
    defined $fh or return $ip->dir_reverse;

    my $storage = $interp->get_storage;
    my $pos     = $self->_bufs->{$fid};
    my $size    = Language::Befunge::Vector->new_zeroes( $pos->get_dims );
    $size->set_component($_,1) for 1 .. $pos->get_dims - 1;
    $size->set_component(0, $c);
    my $buf     = $storage->rectangle($pos, $size);
    $fh->syswrite( $buf );
    $ip->spush( $fid );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::Befunge::lib::FILE - file operations

=head1 VERSION

version 5.000

=head1 DESCRIPTION

The FILE fingerprint (0x46494C45) allows to do file operations.

=head1 FUNCTIONS

=head2 new

Create a new FILE instance.

=head2 file operations

Those operations act as C<r> upon failure.

=over 4

=item C( $fid )

Close filehandle corresponding to C<$fid>.

=item D ( $path )

Delete file C<$path> (a 0gnirts).

=item ($fid, $line, $count) = G ( $fid )

Read C<$line> from filehandle corresponding to C<$fid>, and push back the file
id, as well as the line read and the C<$count> bytes read.

=item ($fid, $pos) = L( $fid )

Fetch current C<$pos> within the file corresponding to filehandle C<$fid>, and
push it back on the stack (as well as C<$fid> again).

=item $fid = O( $vec, $mode, $path )

Open the file C<$path> (a 0gnirts) with C<$mode>, storing C<$vec> as the i/o
buffer. Push back C<$fid> on the stack, the filehandle id. Mode can be one of:

=over 4

=item * 0 read

=item * 1 write

=item * 2 append

=item * 3 read/write

=item * 4 truncate read/write

=item * 5 append read/write

=back

=item $fid = P( $fid, $string )

Write C<$string> to file corresponding to C<$fid>.

=item $fid = R( $fid, $count )

Read C<$count> bytes from file C<$fid> and put it to i/o buffer. Put back
C<$fid> on the stack.

=item $fid = S( $fid, $mode, $pos )

Seek to position C<$pos> in file C<$fid>. C<$mode> can be one of:

=over 4

=item * 0 from beginning

=item * 1 from current location

=item * 2 from end

=back

=item $fid = W( $fid, $count )

Write C<$count> bytes from buffer to file C<$fid>. Put back C<$fid> on the
stack.

=back

=head1 SEE ALSO

L<http://www.rcfunge98.com/rcsfingers.html#FILE>.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2003 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
