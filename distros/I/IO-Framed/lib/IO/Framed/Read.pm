package IO::Framed::Read;

use strict;
use warnings;

use IO::SigGuard ();

use IO::Framed::X ();

sub new {
    my ( $class, $in_fh, $initial_buffer ) = @_;

    if ( !defined $initial_buffer ) {
        $initial_buffer = q<>;
    }

    my $self = {
        _in_fh         => $in_fh,
        _read_buffer   => $initial_buffer,
        _bytes_to_read => 0,
    };

    return bless $self, $class;
}

sub get_read_fh { return $_[0]->{'_in_fh'} }

#----------------------------------------------------------------------
# IO subclass interface

sub allow_empty_read {
    my ($self) = @_;
    $self->{'_ALLOW_EMPTY_READ'} = 1;
    return $self;
}

my $buf_len;

#We assume here that whatever read may be incomplete at first
#will eventually be repeated so that we can complete it. e.g.:
#
#   - read 4 bytes, receive 1, cache it - return q<>
#   - select()
#   - read 4 bytes again; since we already have 1 byte, only read 3
#       … and now we get the remaining 3, so return the buffer.
#
sub read {
    my ( $self, $bytes ) = @_;

    die "I refuse to read zero!" if !$bytes;

    if ( $buf_len = length $self->{'_read_buffer'} ) {
        if ( $buf_len + $self->{'_bytes_to_read'} != $bytes ) {
            my $should_be = $buf_len + $self->{'_bytes_to_read'};
            die "Continuation: should want “$should_be” bytes, not $bytes!";
        }
    }

    if ( $bytes > $buf_len ) {
        $bytes -= $buf_len;

        local $!;

        $bytes -= IO::SigGuard::sysread( $self->{'_in_fh'}, $self->{'_read_buffer'}, $bytes, $buf_len ) || do {
            if ($!) {
                if ( !$!{'EAGAIN'} && !$!{'EWOULDBLOCK'}) {
                    die IO::Framed::X->create( 'ReadError', $! );
                }
            }
            elsif ($self->{'_ALLOW_EMPTY_READ'}) {
                return q<>;
            }
            else {
                die IO::Framed::X->create('EmptyRead');
            }
        };
    }

    $self->{'_bytes_to_read'} = $bytes;

    if ($bytes) {
        return undef;
    }

    return substr( $self->{'_read_buffer'}, 0, length($self->{'_read_buffer'}), q<> );
}

#----------------------------------------------------------------------

1;
