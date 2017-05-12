package EntityModel::Cache::Memcached::Async;
# ABSTRACT: Event-based memcached caching layer for EntityModel
use EntityModel::Class {
	_isa		=> [qw{EntityModel::Cache}],
	mc		=> 'Net::Async::Memcached',
};

our $VERSION = '0.001';

=head1 NAME

EntityModel::Cache::Memcached::Async - support for memcached via L<Net::Async::Memcached>

=head1 VERSION

version 0.001

=head1 SYNOPSIS

 EntityModel->new->add_cache('Memcached::Async' => {
 	servers => [qw(127.0.0.1:11211)],
 });

=head1 METHODS

=cut

=head2 get

Get value for the given key.

=cut

sub get {
	my $self = shift;
	my $k = shift;
	$self->mc->get($k, @_);
	return $self;
}

=head2 remove

Remove an entry from the cache.

=cut

sub remove {
	my $self = shift;
	my $k = shift;
	# FIXME Proper delete support
	$self->mc->delete($k => '', @_);
	return $self;
}

=head2 incr

Increment a cache value. Should be atomic, currently isn't.

=cut

sub incr {
	my $self = shift;
	my $k = shift;
	my %args = @_;
	# FIXME Atomic incr support
	$self->mc->get(
		$k,
		on_complete => sub {
			my $mc = shift;
			my $v = shift;
			++$v;
			$mc->set(
				$k => $v,
				%args
			);
		}
	);
	return $self;
}

=head2 decr

Decrement a cache value. Should be atomic, isn't yet.

=cut

sub decr {
	my $self = shift;
	my $k = shift;
	my %args = @_;
	# FIXME Atomic decr support
	$self->mc->get(
		$k,
		on_complete => sub {
			my $mc = shift;
			my $v = shift;
			--$v;
			$mc->set(
				$k => $v,
				%args
			);
		}
	);
	return $self;
}

=head2 set

=cut

sub set {
	my $self = shift;
	my $k = shift;
	my $v = shift;
	$self->mc->set($k => $v, @_);
	return $self;
}

=head2 atomic

Atomic access to a cache value. Not implemented.

=cut

sub atomic {
	my $self = shift;
	die 'Not yet implemented';
}

1;

__END__

=head1 SEE ALSO

=over 4

=item * Net::Async::Memcached

=item * Protocol::Memcached::Client

=back

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2011. Licensed under the same terms as Perl itself.
