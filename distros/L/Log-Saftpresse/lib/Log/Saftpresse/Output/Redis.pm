package Log::Saftpresse::Output::Redis;

use Moose;

# ABSTRACT: plugin to write events to a redis server
our $VERSION = '1.6'; # VERSION

extends 'Log::Saftpresse::Output';

use Redis;
use JSON qw(encode_json);


has 'server' => ( is => 'ro', isa => 'Str',
  default => '127.0.0.1:6379'
);
has 'sock' => ( is => 'ro', isa => 'Maybe[Str]' );
has 'db' => ( is => 'ro', isa => 'Int', default => 0 );

has '_redis' => ( is => 'rw', isa => 'Redis', lazy => 1,
  default => sub {
    my $self = shift;
    return $self->_connect_redis;
  },
);

has 'queue' => ( is => 'ro', isa => 'Str', default => 'logs' );

sub _connect_redis {
  my $self = shift;
  my $r = Redis->new(
    defined $self->sock ? (
      sock => $self->sock,
    ) : (
      server => $self->server,
    ),
  );
  $r->select( $self->db );
  return $r;
}

sub output {
	my ( $self, @events ) = @_;

	my @blobs = map {
		my %output = %$_;
		if( defined $output{'time'} &&
				ref($output{'time'}) eq 'Time::Piece' ) {
			$output{'@timestamp'} = $output{'time'}->datetime;
			delete $output{'time'};
    }
    encode_json(\%output)
  } @events;
	$self->_redis->lpush($self->queue, @blobs);

	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Output::Redis - plugin to write events to a redis server

=head1 VERSION

version 1.6

=head1 Description

Write events to a queue on a redis server.

=head1 Synopsis

  <Input myapp>
    module = "Redis"
    server = "127.0.0.1:6379"
    # sock = "/path/to/socket"
    db = 0
    queue = "logs"
  </Input>

=head1 Format

The plugin will write entries in JSON format.

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
