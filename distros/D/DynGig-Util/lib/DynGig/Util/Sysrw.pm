=head1 NAME

DynGig::Util::Sysrw - sysread/syswrite wrappers reliable on EAGAIN

=cut
package DynGig::Util::Sysrw;

use warnings;
use strict;

use Errno qw( :POSIX );

use constant { MAX_BUF => 2 ** 10 };

=head1 SYNOPSIS

 use DynGig::Util::Sysrw;

 ## see sysread and syswrite for parameter
 my $read = DynGig::Util::Sysrw->read( $socket, $buffer, 1024 );
 my $written = DynGig::Util::Sysrw->write( $socket, $buffer );

=head1 DESCRIPTION

=head2 read

See sysread().

=cut
sub read
{
    my $class = shift;
    my ( $offset, $length ) = ( 0, $_[2] );

    while ( ! $length || $offset < $length )
    {
        my $limit = $length ? $length - $offset : MAX_BUF;
        my $length = sysread $_[0], $_[1], $limit, $offset;

        if ( defined $length )
        {
            last unless $length;
            $offset += $length;
        }
        elsif ( $! != EAGAIN )
        {
            return undef;
        }
    }

    return $offset;
}

=head2 write

See syswrite().

=cut
sub write
{
    my $class = shift;
    my ( $offset, $length ) = ( 0, length $_[1] );

    while ( $offset < $length )
    {
        my $length = syswrite $_[0], $_[1], MAX_BUF, $offset;

        if ( defined $length )
        {
            $offset += $length;
        }
        elsif ( $! != EAGAIN )
        {
            return undef;
        }
    }

    return $offset;
}

=head1 NOTE

see DynGig::Util

=cut

1;

__END__
