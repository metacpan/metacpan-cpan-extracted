package Google::gRPC::Engine;

use strict;
use warnings;
use Carp qw(croak);

sub create {
    my ($class, %args) = @_;
    my $preferred = delete $args{engine};

    if (defined $preferred) {
        if ($preferred eq 'NGHTTP2') {
            require Google::gRPC::Engine::NGHTTP2;
            return Google::gRPC::Engine::NGHTTP2->new(%args);
        }
        elsif ($preferred eq 'PP') {
            require Google::gRPC::Engine::PP;
            return Google::gRPC::Engine::PP->new(%args);
        }
    }

    eval {
        require Google::gRPC::Engine::NGHTTP2;
        my $eng = Google::gRPC::Engine::NGHTTP2->new(%args);
        return $eng if $eng;
    };

    require Google::gRPC::Engine::PP;
    return Google::gRPC::Engine::PP->new(%args);
}


=head1 NAME

Google::gRPC::Engine - gRPC Transport Engine Base

=head1 SYNOPSIS

    use Google::gRPC::Engine;

=head1 DESCRIPTION

This module provides grpc transport engine base functionality for the Google gRPC Perl client SDK.

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE

Apache License 2.0

=cut

1;
