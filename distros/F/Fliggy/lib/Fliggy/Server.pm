package Fliggy::Server;

use strict;
use warnings;

BEGIN {
    $ENV{TWIGGY_DEBUG} = $ENV{FLIGGY_DEBUG} || 0;
}

use base 'Twiggy::Server';

use Errno qw(EAGAIN EINTR);
use AnyEvent::Util qw(WSAEWOULDBLOCK);

use constant DEBUG => $ENV{FLIGGY_DEBUG};

# Copied from Twiggy::Server (can't stand copypasting, but this is the only way)
sub _try_read_headers {
    my ($self, $sock, undef) = @_;

    # FIXME add a timer to manage read timeouts
    local $/ = "\012";

  read_more: for my $headers ($_[2]) {
        if ($headers eq '') {
            my $buf = $self->_safe_read($sock, 1);
            return unless defined $buf;

            if ($buf eq '<') {
                $buf = $self->_safe_read($sock, 22);
                return unless defined $buf;

                if ($buf eq "policy-file-request/>\0") {
                    DEBUG && warn "Flash policy request\n";
                    $self->_write_flash_policy_response($sock);
                    die;
                }
                else {
                    $headers .= $buf;
                }
            }
            else {
                $headers .= $buf;
            }
        }

        if (defined(my $line = <$sock>)) {
            $headers .= $line;

            if ($line eq "\015\012" or $line eq "\012") {

                # got an empty line, we're done reading the headers
                return 1;
            }
            else {

                # try to read more lines using buffered IO
                redo read_more;
            }
        }
        elsif ($! and $! != EAGAIN && $! != EINTR && $! != WSAEWOULDBLOCK) {
            die $!;
        }
        elsif (!$!) {
            die "client disconnected";
        }
    }

    DEBUG
      && warn
      "$sock did not read to end of req, wait for more data to arrive\n";
    return;
}

sub _write_flash_policy_response {
    my ($self, $sock) = @_;

    return unless defined $sock and defined fileno $sock;

    # FIXME restrict domain and ports
    my $body = <<"EOF";
<?xml version="1.0"?>
<!DOCTYPE cross-domain-policy SYSTEM "/xml/dtds/cross-domain-policy.dtd">
<cross-domain-policy>
<site-control permitted-cross-domain-policies="master-only"/>
<allow-access-from domain="*" to-ports="*" secure="false"/>
</cross-domain-policy>
EOF

    my $cv = AE::cv;

    # From _write_psgi_response
    $self->_write_body($sock, [$body])->cb(
        sub {
            shutdown $sock, 1;
            close $sock;
            $self->{exit_guard}->end;
            local $@;
            eval { $cv->send($_[0]->recv); 1 } or $cv->croak($@);
        }
    );

    return;
}

sub _safe_read {
    my $self = shift;
    my ($sock, $size) = @_;

    my $rcount = sysread($sock, my $buf, $size);

    # $rcount contains number of bytes read, 0 at end of file
    if (defined $rcount && $rcount == 0) {
        die "client disconnected";
    }

    if (!defined $buf || !defined $rcount) {
        if ($! and $! != EAGAIN && $! != EINTR && $! != WSAEWOULDBLOCK) {
            die $!;
        }
        elsif (!$!) {
            die "client disconnected (unknown error)";
        }

        return;
    }

    return unless $rcount == $size;

    return $buf;
}

1;
__END__

=head1 NAME

Fliggy::Server - Fliggy implementation

=head1 DESCRIPTION

This is an actual L<Fliggy> implementation.

=head1 SEE ALSO

L<Fliggy> L<Twiggy>

=cut
