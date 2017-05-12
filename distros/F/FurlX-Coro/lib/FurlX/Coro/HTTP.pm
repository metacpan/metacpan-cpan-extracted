package FurlX::Coro::HTTP;
use strict;
use warnings;

use parent qw(Furl::HTTP);
use Coro::Select qw(select);
use Errno qw(EINTR);

# just copied from Furl::HTTP
sub do_select {
    my($self, $is_write, $sock, $timeout_at) = @_;
    # wait for data
    while (1) {
        my $timeout = $timeout_at - time;
        if ($timeout <= 0) {
            $! = 0;
            return 0;
        }
        my($rfd, $wfd);
        my $efd = '';
        vec($efd, fileno($sock), 1) = 1;
        if ($is_write) {
            $wfd = $efd;
        } else {
            $rfd = $efd;
        }
        my $nfound   = select($rfd, $wfd, $efd, $timeout);
        return 1 if $nfound > 0;
        return 0 if $nfound == -1 && $! == EINTR && $self->{stop_if}->();
    }
    die 'not reached';
}

1;
__END__

=head1 NAME

FurlX::Coro::HTTP - Furl::HTTP wrapper for FurlX::Coro

=head1 VERSION

This document describes FurlX::Coro version 1.02.

=head1 SYNOPSIS

    use FurlX::Coro::HTTP;

=head1 DESCRIPTION

FurlX::Coro::HTTP is a coro-friendly Furl::HTTP, which just uses Coro's C<select()> instead of the built-in one. The usage is completely the same as HTTP::Furl.

=head1 SEE ALSO

L<FurlX::Coro>

L<Furl::HTTP>

=cut
