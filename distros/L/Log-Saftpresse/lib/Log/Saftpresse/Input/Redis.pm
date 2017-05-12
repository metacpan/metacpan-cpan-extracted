package Log::Saftpresse::Input::Redis;

use Moose;

# ABSTRACT: log input for reading a redis queue
our $VERSION = '1.6'; # VERSION


extends 'Log::Saftpresse::Input';

use Redis;
use JSON qw(decode_json);

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

has 'max_bulk' => ( is => 'ro', isa => 'Int', default => 100 );

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

sub io_handles {
	my $self = shift;
	return;
}

sub queue_len {
  my $self = shift;
  return $self->_redis->llen($self->queue);
}

sub read_events {
	my ( $self ) = @_;
	my @queue;
	my @events;

  my $cnt = $self->queue_len;
  if( $cnt > $self->max_bulk ) {
    $cnt = $self->max_bulk;
  }

  foreach (1..$cnt) {
    $self->_redis->rpop($self->queue, sub {push @queue, $_[0]});
  }
  $self->_redis->wait_all_responses;

  foreach my $entry ( grep { defined $_ } @queue ) {
    push( @events, decode_json($entry) );
  }

	return @events;
}

sub eof {
	my $self = shift;
	return 0; # queues dont have an end?
}

sub can_read {
	my $self = shift;
	return $self->queue_len;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Input::Redis - log input for reading a redis queue

=head1 VERSION

version 1.6

=head1 Description

This input reads new events from a redis queue.

=head1 Synopsis

  <Input myapp>
    module = "Redis"
    server = "127.0.0.1:6379"
    # sock = "/path/to/socket"
    db = 0
    queue = "logs"
  </Input>

=head1 Format

Format is expected to be in JSON format.
Each event must be a hash.

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
