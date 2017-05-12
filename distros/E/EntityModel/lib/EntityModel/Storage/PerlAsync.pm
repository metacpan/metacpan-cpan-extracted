package EntityModel::Storage::PerlAsync;
{
  $EntityModel::Storage::PerlAsync::VERSION = '0.102';
}
use EntityModel::Class {
	_isa		=> [qw{EntityModel::Storage::Perl}],
	loop		=> { type => 'IO::Async::Loop' }
};

=head1 NAME

EntityModel::Storage::PerlAsync - backend storage interface for L<EntityModel>

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<EntityModel>.

=head1 DESCRIPTION

Wrapper around the Perl storage module to defer responses until idle point in an L<IO::Async> loop.

=cut

use Scalar::Util ();

=head1 METHODS

=cut

=head2 new

Subclassed instantiation, requires an L<IO::Async::Loop> passed as the C<loop> named parameter.

=cut

sub setup {
	my $self = shift;
	my %args = %{+shift};
	my $loop = delete $args{loop} or die "No IO::Async::Loop provided?";
	$self->SUPER::setup(\%args);
	Scalar::Util::weaken($self->{loop} = $loop);
	return $self;
}

=head2 read

Reads the data for the given entity and returns hashref with the appropriate data.

Parameters:

=over 4

=item * entity - L<EntityModel::Entity>

=item * id - ID to read data from

=back

Callbacks (included in parameter list above):

=over 4

=item * on_complete - called when the value has been read, includes the value

=item * on_not_found - called if entry not found

=back

Returns $self.

=cut

use Carp qw/cluck/;
sub read {
	my $self = shift;
	my %args = @_;
	return unless exists $args{on_complete};
	# cluck "Request for id " . ($args{id} // 'undef') . " from " . $args{entity}->name;

	my $complete = delete $args{on_complete};
	$self->loop->later($self->sap(sub {
		my $self = shift;
		my $v = $self->SUPER::read(%args);
		warn "Reading " . ($v // "undef") . "\n";
		$complete->($v);
	}));
	return $self;
}

=head2 create

Creates new entry for the given L<EntityModel::Entity>.

Parameters:

=over 4

=item * entity - L<EntityModel::Entity>

=item * data - actual data values

=back

Callbacks (included in parameter list above):

=over 4

=item * on_complete - called when the value has been created, will be passed the assigned ID

=back

Returns $self.

=cut

sub create {
	my $self = shift;
	my %args = @_;
	my $complete = delete $args{on_complete};
	$self->loop->later($self->sap(sub {
		my $self = shift;
		my $v = $self->SUPER::create(%args);
#		warn "Creating $v\n";
		$complete->($v) if $complete;
	}));
	return $self;
}

=head2 store

Stores data to the given entity and ID.

Parameters:

=over 4

=item * entity - L<EntityModel::Entity>

=item * id - ID to store data to

=item * data - actual data values

=back

Callbacks (included in parameter list above):

=over 4

=item * on_complete - called when the value has been stored, will be passed the assigned ID

=back

Returns $self.

=cut

sub store {
	my $self = shift;
	my %args = @_;
	my $complete = delete $args{on_complete};
	$self->loop->later($self->sap(sub {
		my $self = shift;
		my $v = $self->SUPER::store(%args);
		$complete->($args{id}) if $complete;
	}));
	return $self;
}

=head2 remove

Removes given ID from storage.

Parameters:

=over 4

=item * entity - L<EntityModel::Entity>

=item * id - ID to store data to

=back

Callbacks (included in parameter list above):

=over 4

=item * on_complete - called when the value has been removed

=back

Returns $self.

=cut

sub remove {
	my $self = shift;
	my %args = @_;
	my $complete = delete $args{on_complete};
	$self->loop->later($self->sap(sub {
		my $self = shift;
		my $v = $self->SUPER::remove(%args);
		$complete->($args{id}) if $complete;
	}));
	return $self;
}

=head2 find

Callbacks (included in parameter list above):

=over 4

=item * on_item - called for each item

=item * on_not_found - called once if no items were found

=item * on_complete - called when no more items are forthcoming (regardless of whether any
were found or not)

=item * on_fail - called if there was an error

=back

Returns $self.

=cut

sub find {
	my $self = shift;
	my %args = @_;

	$self->loop->later($self->sap(sub {
		my $self = shift;

		# Defer all the events
		foreach my $k (grep /^on_/, keys %args) {
			my $orig = $args{$k};
			$args{$k} = $self->sap(sub {
				my ($self, @param) = @_;
				$self->loop->later(sub {
					$orig->(@param);
				});
			});
		}
		$self->SUPER::find(%args);
	}));
	return $self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
