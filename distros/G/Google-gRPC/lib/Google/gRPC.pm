package Google::gRPC;

use strict;
use warnings;

our $VERSION = '0.04';

1;

__END__

=head1 NAME

Google::gRPC - High-performance gRPC client library for Perl

=head1 SYNOPSIS

    use Google::gRPC::Client;

    my $client = Google::gRPC::Client->new(
        target => 'spanner.googleapis.com:443',
    );

=head1 DESCRIPTION

C<Google::gRPC> provides high-performance gRPC channel management, framing, streams, deadlines, and transport engine integration.

=head1 SUBMODULES

=over 4

=item * L<Google::gRPC::Client>

=item * L<Google::gRPC::Channel>

=item * L<Google::gRPC::ChannelPool>

=item * L<Google::gRPC::Stream>

=item * L<Google::gRPC::Deadline>

=item * L<Google::gRPC::Status>

=item * L<Google::gRPC::Engine>

=back

=head1 AUTHOR

C.J. Collier E<lt>cjac@google.comE<gt>

=head1 LICENSE

Apache License, Version 2.0

=cut
