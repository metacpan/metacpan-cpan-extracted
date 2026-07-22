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


=head1 NAME

Google::gRPC::Deadline - gRPC Deadline Support

=head1 SYNOPSIS

    use Google::gRPC::Deadline;

=head1 DESCRIPTION

This module provides grpc deadline support functionality for the Google gRPC Perl client SDK.

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE

Apache License 2.0

=cut

1;
