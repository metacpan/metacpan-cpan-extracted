package EntityModel::Gather;
{
  $EntityModel::Gather::VERSION = '0.102';
}
use EntityModel::Class {
};

=head1 NAME

EntityModel::Gather - asynchronous helper functions for L<EntityModel>

=head1 VERSION

version 0.102

=head1 SYNOPSIS

 use EntityModel::Gather;

=head1 DESCRIPTION

Wrapper class for executing code once data values have been populated.

Given a set of data key => value pairs, this module will request population from each provider.
Once all data values are available, the on_ready event is triggered, and the data values are
passed to the provided handler. If it is impossible to retrieve data values for some reason,
the on_error handler is called instead.

Each of the values passed must be one of the following:

=over 4

=item * Subclass of L<EntityModel::Pending> - requests callback when data value has been populated

=item * Subclass of L<EntityModel::EntityBase> - requests callback when populated

=item * Scalar value - this will be used as-is

=item * undef - this will be used as-is

=back

Any other value will cause the scalar handling to be used.

=head1 METHODS

=cut

=head2 new

Create a new instance. Takes a list of key, value pairs indicating which data values to wait for.

=cut

sub new {
	my $class = shift;
	my $self = bless {
		pending => { },
		ready	=> { },
	}, $class;

	while(@_) {
		my ($k, $v) = splice @_, 0, 2;
		$self->add_pending($k => $v);
	}
	$self->dispatch('ready') if $self->is_ready;
	return $self;
}

=head2 add_pending

Adds the given key and value to the pending list. If the value is immediately available (simple scalar, for example) then this
will pass the value through immediately.

=cut

sub add_pending {
	my $self = shift;
	my ($k, $v) = @_;
	die "Undefined key" unless defined $k;
	die "Reference given where string expected: $k" if ref $k;

	if(eval { $v->isa('EntityModel::Deferred') }) {
		$self->{pending}->{$k} = $v;
		$v->queue_callback('ready', $self->sap(sub {
			my $self = shift;
			$self->mark_ready($k);
		}), 'error', $self->sap(sub {
			my $self = shift;
			$self->raise_error($k);
		}));
	} elsif(eval { $v->isa('EntityModel::Support::Perl::Base') }) {
		$self->{pending}->{$k} = $v;
		$v->_request_load(
			on_complete	=> $self->sap(sub {
				my $self = shift;
				$self->mark_ready($k);
			}),
			on_error	=> $self->sap(sub {
				my $self = shift;
				$self->raise_error($k);
			})
		);
	} else {
		$self->{pending}->{$k} = $v;
		$self->mark_ready($k);
	};
	return $self;
}

sub mark_ready {
	my $self = shift;
	my $k = shift;
	die "Tried to mark non-existent key $k as ready" unless exists $self->{pending}->{$k};
	die "Key $k exists already" if exists $self->{ready}->{$k};

	my $v = delete $self->{pending}->{$k};
	$self->{ready}->{$k} = $self->extract_value($v);
	$self->dispatch('ready') if $self->is_ready;
	return $self;
}

sub extract_value {
	my $self = shift;
	my $v = shift;
	return $v->value if eval { $v->isa('EntityModel::Deferred'); };
	return $v;
}

sub is_ready {
	my $self = shift;
	return keys %{$self->{pending}} ? 0 : 1;
}

sub when_ready {
	my $self = shift;
	$self->{on_ready} = shift;
	$self->dispatch('ready') if $self->is_ready;
	return $self;
}

sub dispatch {
	my $self = shift;
	my $evt = shift;
	my $method = 'on_' . $evt;
	my $code = $self->{$method} || $self->can($method);
	$code->(%{$self->{ready}}) if $code;
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
