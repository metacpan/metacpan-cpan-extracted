package EntityModel::Hash;
$EntityModel::Hash::VERSION = '0.016';
use strict;
use warnings;

use EntityModel::Log ':all';

=head1 NAME

EntityModel::Hash - wrapper object for dealing with hashrefs

=head1 VERSION

Version 0.016

=head1 DESCRIPTION

Primarily intended as an abstract interface for use with L<EntityModel> backend storage.

=head1 METHODS

=cut

use overload
	'%{}' => sub {
		my $self = shift;
		return $self->hashref;
	},
	fallback => 1;

=head2 new

Instantiates with the given hashref.

=cut

sub new {
	my ($class, $data) = @_;
	bless { data => ($data // { }) }, $class;
}

=head2 count

Returns the number of items in the hashref (i.e. keys).

=cut

sub count {
	my $self = shift;
	return scalar keys %{$self->hashref};
}

=head2 list

Returns all values from the hashref.

=cut

sub list {
	my $self = shift;
	return unless $self->hashref;
	return values %{$self->hashref};
}

=head2 set

Sets an entry (identified by key) to the given value.

=cut

sub set {
	my $self = shift;
	my ($k, $v) = @_;
	unless(defined $k) {
		# logStack("No k?");
		return $self;
	}
	if(ref($k) && ref($k) eq 'HASH') {
		$self->hashref->{$_} = $k->{$_} foreach keys %$k;
	} else {
		$self->hashref->{$k} = $v;
	}
	return $self;
}

=head2 erase

Deletes the given key from the hashref.

=cut

sub erase {
	my $self = shift;
	my ($k) = @_;
	$k //= '';
	delete $self->hashref->{$k};
	return $self;
}

=head2 get

Retrieves the value for the given key.

=cut

sub get {
	my ($self, $k) = @_;
	$k //= '';
	return $self->hashref->{$k};
}

=head2 hashref

Returns the contained hashref.

=cut

sub hashref {
	my $self = shift;
	my $class = ref $self;
	bless $self, 'overload::dummy';
	my $out = $self->{data};
	bless $self, $class;
	return $out;
}

=head2 exists

Returns true if the given key exists in the hashref.

=cut

sub exists : method {
	my ($self, $k) = @_;
	$k //= '';
	return exists($self->hashref->{$k});
}

=head2 keys

Returns a list of all keys.

=cut

sub keys : method {
	my $self = shift;
	return keys %{$self->hashref};
}

=head2 clear

Clears the hashref.

=cut

sub clear : method {
	my $self = shift;
	my $class = ref $self;
	bless $self, 'overload::dummy';
	$self->{data} = { };
	bless $self, $class;
	return $self;
}

=head2 is_empty

Returns true if there's nothing in the hashref.

=cut

sub is_empty {
	my $self = shift;
	return !$self->keys;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
