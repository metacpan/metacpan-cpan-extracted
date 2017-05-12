package EntityModel::StorageClass::KVStore::Layer::LRU;
{
  $EntityModel::StorageClass::KVStore::Layer::LRU::VERSION = '0.102';
}
use parent qw(EntityModel::StorageClass::KVStore::Layer);
use Tie::Hash::LRU;

sub new {
	my $class = shift;
	my %args = @_;
	my $self = $class->SUPER::new;
	tie my %h, 'Tie::Hash::LRU', $args{entries} || 50;
	$self->{cache} = \%h;
	$self
}

=head2 lookup

Returns the cached value if we have it. Intended to be a low-overhead method for
interacting with local, nonblocking caches.

Takes a single $query parameter which will be the query we're trying to find.

Returns an empty list if we don't have an answer in the cache, undef if we
have an answer and that answer is "no value", otherwise returns whatever
value we have on file.

=cut

sub lookup {
	my $self = shift;
	my $k = shift;
	return $self->{cache}->{$k} if exists $self->{cache}->{$k};
	return;
}

=head2 store

Store a value in the cache.

Takes the following parameters:

=over 4

=item * $query - query to store under

=item * $value - value to store in key (can be undef)

=back

Returns $self.

=cut

sub store {
	my ($self, $k, $v) = @_;
	$self->{cache}->{$k} = $v;
	$self
}

1;
