package EntityModel::StorageClass::KVStore;
{
  $EntityModel::StorageClass::KVStore::VERSION = '0.102';
}
use strict;
use warnings;
use List::UtilsBy qw(extract_by);
use Future;

=pod

Layers:

LRU cache - exists if we know the answer, undef means "ain't there"
Memcached
PostgreSQL select
PostgreSQL insert

=cut

sub new { bless { underlayer => [] }, shift }

sub lookup {
	my $self = shift;
	my %args = @_;
	$self->{underlayer}[-1]->retrieve(%args);
	$self;
}

=head2 add_layer

Adds a new layer to KV storage. Links it to the current layers
as appropriate.

Takes a single parameter:

=over 4

=item * $layer - the new layer to add

=back

Returns $self.

=cut

sub add_layer {
	my $self = shift;
	my $layer = shift;
	my $prev = $self->{underlayer}[-1];
	push @{ $self->{underlayer} }, $layer;
	$layer->underlayer($prev) if $prev;
	$self
}

=head2 remove_layer

Removes an existing layer to KV storage. Unlinks the other layers
as appropriate.

Takes a single parameter:

=over 4

=item * $layer - the new layer to add

=back

Returns $self.

=cut

sub remove_layer {
	my $self = shift;
	my $layer = shift;

	# First, remove it from the stack
	my ($l) = extract_by { $_ eq $layer } @{$self->{underlayer}};
	return $self unless $l;

	# Then update any layers so we don't have dangling references
	foreach my $ul (@{$self->{underlayer}}) {
		$ul->underlayer($l->underlayer) if $ul->underlayer && $ul->underlayer eq $l;
	}
	$self
}

sub shutdown {
	my $self = shift;
	my %args = @_;
	my @pending;
	foreach my $l (@{$self->{underlayer}}) {
		push @pending, my $f = Future->new;
		$l->shutdown(on_success => sub { $f->done });
	}
	# I think we need to hold onto this...?
	$self->{pending_shutdown} = Future->wait_all(@pending)->on_ready(sub {
		delete $self->{pending_shutdown};
		$args{on_success}->()
	}) if $args{on_success};
	$self->{underlayer} = [];
	$self
}

1;

