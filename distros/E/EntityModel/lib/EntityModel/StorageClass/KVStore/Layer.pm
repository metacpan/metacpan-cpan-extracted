package EntityModel::StorageClass::KVStore::Layer;
{
  $EntityModel::StorageClass::KVStore::Layer::VERSION = '0.102';
}
use strict;
use warnings;

sub new { bless {}, shift }
sub lookup { () }

=head2 underlayer

Accessor for the next storage layer down.

=cut

sub underlayer {
	my $self = shift;
	if(@_) {
		$self->{underlayer} = shift;
		return $self
	}
	return $self->{underlayer}
}

=head2 key_mangle

Applies any modifications necessary to convert the query into a key suitable
for this caching layer.

Takes the following parameters:

=over 4

=item * $query - the value to mangle

=back

Returns the modified result (actual modification performed is implementation-dependent).

=cut

sub key_mangle { $_[1] }

=head2 retrieve

Attempts to retrieve the given value from storage.

Takes the following parameters:

=over 4

=item * query - the query we're trying to find

=item * on_success - what to do when we win

=item * on_failure - how to deal with defeat

=back

Returns $self.

=cut

sub retrieve {
	my $self = shift;
	my %args = @_;
	my $k = $args{query};

	# We'll get an empty list back if we don't have the value
	return $args{on_success}->($_) for $self->lookup($k);

	$self->retrieval_fallback(%args);
}

sub retrieval_fallback {
	my $self = shift;
	my %args = @_;
	die "Without an underlayer I must concede defeat" unless my $underlayer = $self->underlayer;

	my $k = $args{query};
	# Delegate to the next layer down
	$underlayer->retrieve(
		query => $k,
		on_success => sub {
			my $v = shift;
			$self->store($k => $v);
			$args{on_success}->($v);
		},
		on_failure => sub { die "AIEE" },
	);
	$self
}

sub shutdown {
	my $self = shift;
	my %args = @_;
	$args{on_success}->() if $args{on_success};
	$self;
}

1;

