package MYDan::Util::Sysrw;

use warnings;
use strict;

use Errno qw( :POSIX );

use constant { MAX_BUF => 2 ** 10 };

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

1;
