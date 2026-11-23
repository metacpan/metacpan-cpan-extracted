package Google::gRPC::Deadline;

use strict;
use warnings;
use Carp qw(croak);

sub parse_timeout {
    my ($val) = @_;
    return undef unless defined $val;

    if ($val =~ /^\s*(\d+(?:\.\d+)?)\s*$/) {
        return 0 + $1;
    }
    if ($val =~ /^\s*(\d+(?:\.\d+)?)\s*([nnumSMH])\s*$/) {
        my ($num, $unit) = ($1, $2);
        if ($unit eq 'n') { return $num / 1_000_000_000; }
        if ($unit eq 'u') { return $num / 1_000_000; }
        if ($unit eq 'm') { return $num / 1_000; }
        if ($unit eq 'S' || $unit eq 's') { return 0 + $num; }
        if ($unit eq 'M') { return $num * 60; }
        if ($unit eq 'H' || $unit eq 'h') { return $num * 3600; }
    }
    croak 'Invalid timeout format: ' . $val;
}

sub format_grpc_timeout {
    my ($sec) = @_;
    return undef unless defined $sec;

    my $val = parse_timeout($sec);
    return undef unless defined $val;

    if ($val < 0.001) {
        my $nano = int($val * 1_000_000_000);
        return $nano . 'n';
    }
    elsif ($val < 1.0) {
        my $milli = int($val * 1000);
        return $milli . 'm';
    }
    elsif ($val < 60) {
        my $s = int($val);
        return $s . 'S';
    }
    elsif ($val < 3600) {
        my $m = int($val / 60);
        return $m . 'M';
    }
    else {
        my $h = int($val / 3600);
        return $h . 'H';
    }
}


=encoding UTF-8

=head1 NAME

Google::gRPC::Deadline - Parsing and formatting for gRPC C<grpc-timeout> headers

=head1 SYNOPSIS

    use Google::gRPC::Deadline;

    my $seconds = Google::gRPC::Deadline::parse_timeout('500m');   # 0.5
    my $header  = Google::gRPC::Deadline::format_grpc_timeout(30); # '30S'

=head1 DESCRIPTION

C<Google::gRPC::Deadline> converts between numeric seconds and the gRPC HTTP/2
C<grpc-timeout> wire format (C<n> nanoseconds, C<u> microseconds, C<m>
milliseconds, C<S> seconds, C<M> minutes, C<H> hours).

=head1 FUNCTIONS

=head2 parse_timeout( $value )

Parses a numeric timeout in seconds or a gRPC timeout string (e.g., C<'500m'>,
C<'30S'>, C<'2M'>, C<'1H'>) and returns fractional seconds. Croaks on invalid
format.

=head2 format_grpc_timeout( $seconds )

Formats a timeout value into a canonical gRPC C<grpc-timeout> header string
(e.g., C<'250m'>, C<'30S'>, C<'5M'>).

=head1 SEE ALSO

L<Google::gRPC>, L<Google::gRPC::Client>, L<Google::gRPC::Channel>

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE

Apache License 2.0

=cut

1;
