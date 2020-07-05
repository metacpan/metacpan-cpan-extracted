package Mail::DataFeed::Abusix;
use Moo;
use v5.20;
use strict;
use warnings;
use feature qw(postderef);
no warnings qw(experimental::postderef);
# ABSTRACT: Send SMTP transaction data to the Abusix transaction feed
our $VERSION = '1.20200617.1'; ## VERSION
use Digest::MD5 qw(md5_hex);
use IO::Socket;

  has feed_name => ( is => 'ro', required => 1 );
  has feed_key => ( is => 'ro', required => 1);
  has feed_dest => ( is => 'ro', required => 1);

  has sockets => ( is => 'ro', lazy => 1, builder => '_sockets' );

  has port => ( is => 'rw' );
  has ip_address => ( is => 'rw' );
  has reverse_dns => ( is => 'rw' );
  has helo => ( is => 'rw' );
  has used_esmtp => ( is => 'rw', default => undef );
  has used_tls => ( is => 'rw', default => undef );
  has used_auth => ( is => 'rw', default => undef );
  has mail_from_domain => ( is => 'rw' );
  has time => ( is => 'rw', lazy => 1, builder => '_build_time' );



sub _sockets {
  my ($self) = @_;
  my @sockets;
  foreach my $dest ( split ',', $self->feed_dest ) {
    my ( $peer_address, $peer_port ) = split(':', $dest, 2);
    $peer_port = 12211 if !$peer_port;
    my $socket = IO::Socket::INET->new(
      PeerAddr => $peer_address,
      PeerPort => $peer_port,
      Proto => 'udp',
      Type => SOCK_DGRAM,
    );
    push @sockets, $socket;
  }
  return \@sockets;
}


sub send {
  my ($self) = @_;
  my $report = $self->_build_report();
  foreach my $socket ($self->sockets->@*) {
    $socket->send($report);
  }

}

sub _build_time {
  my ($self) = @_;
  return time;
}

sub _build_report {
  my ($self,$args) = @_;

  my $time = $args->{_time} // $self->time; # Ability to override time for testing!
  my $extended_json = ''; # Reserved for future use, should be empty.

  my $packet = join( "\n",
    $self->feed_name,
    $time,
    $self->port // '',
    $self->ip_address // '',
    $self->reverse_dns // '',
    $self->helo // '',
    !defined $self->used_esmtp ? '' : $self->used_esmtp ? 'Y' : 'N',
    !defined $self->used_tls   ? '' : $self->used_tls   ? 'Y' : 'N',
    !defined $self->used_auth  ? '' : $self->used_auth  ? 'Y' : 'N',
    $self->mail_from_domain // '',
    $extended_json,
  );

  $packet = join( "\n",
    $packet,
    $self->_checksum($packet),
  );

  return $packet;
}

sub _checksum {
  my ($self, $packet) = @_;
  my $checksum = md5_hex(join( "\n", $packet, $self->feed_key ));
  return $checksum;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DataFeed::Abusix - Send SMTP transaction data to the Abusix transaction feed

=head1 VERSION

version 1.20200617.1

=head1 SYNOPSIS

  use Mail::DataFeed::Abusix;

  my $abusix_feed = Mail::DataFeed::Abusix->new(
    feed_name => 'testing_feed',
    feed_dest => 'test.endpoint.example.com:1234',
    feed_key => 'this_is_a_secret',
  );

  $abusix_feed->port(25);
  $abusix_feed->ip_address('1.2.3.4');
  $abusix_feed->reverse_dns('test.example.org');
  $abusix_feed->helo('server.example.org');
  $abusix_feed->used_esmtp(1);
  $abusix_feed->used_tls(1);
  $abusix_feed->used_auth(0);
  $abusix_feed->mail_from_domain('from.example.org');

  $abusix_feed->send();

=head1 DESCRIPTION

Send SMTP transaction data via udp to the Abusix real-time transaction feed.

=head1 CONSTRUCTOR

=head2 I<new(%args)>

  Create a new Abusix feed object

  Required args

  * feed_name - This identifies the feed to the collector.
  * feed_key - This authenticates the feed data against the feed_name to the collector
  * feed_dest -  The host or host:port where the data should be sent.
                 If the port is not specified then it defaults to port 12211.
                 Multiple destinations can be specified using comma, semicolon or whitespace to delimit the hosts.
                 If multiple hosts are specified then the data is sent to them all.

=head1 METHODS

=head2 I<port($port)>

  Set the port used to connect to the SMTP server

=head2 I<ip_address($ip_address)>

  Set the IP address (ipv4 or ipv6) connecting to the SMTP server

=head2 I<reverse_dns($hostname)>

  Set the reverse DNS of the connecting IP address.

=head2 I<helo($helo)>

  Set the HELO string used to connect to the SMTP server.

=head2 I<used_esmtp()>

  Set to true if ESMTP (EHLO) was used in the connection.
  Set to false if SMTP (HELO) was used in the connection.

=head2 I<used_tls()>

  Set to true if TLS was used in the connection.
  Set to false if TLS was NOT used in the connection.

=head2 I<used_auth()>

  Set to true if SMTP authentication was used in the connection.
  Set to false if SMTP authentication was NOT used in the connection.

=head2 I<mail_from_domain()>

  Set the mail from domain.

=head2 I<send()>

  Send the report to abusix.

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
