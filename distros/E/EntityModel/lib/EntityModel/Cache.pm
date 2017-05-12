package EntityModel::Cache;
{
  $EntityModel::Cache::VERSION = '0.102';
}
use EntityModel::Class {
};

=head1 NAME

EntityModel::Cache - base class for L<EntityModel> caching support

=head1 VERSION

version 0.102

=head1 SYNOPSIS

See L<EntityModel>.

=head1 DESCRIPTION

See L<EntityModel>.

=cut

=head1 METHODS

=cut

=head2 new

Instantiate class. Currently takes no parameters.

=cut

sub new {
	my $class = shift;
	my $self = bless { }, $class;
	return $self;
}

=head2 get

Get value from the cache corresponding to the given key.

=cut

sub get { die 'Virtual method' }

=head2 remove

Remove the given key from the cache.

=cut

sub remove { die 'Virtual method' }

=head2 incr

Atomically increment the value for the given key.

=cut

sub incr { die 'Virtual method' }

=head2 incr

Atomically decrement the value for the given key.

=cut

sub decr { die 'Virtual method' }

=head2 set

Set the value for the given key. Optionally provide a timeout value as 3rd parameter.

=cut

sub set { die 'Virtual method' }

=head2 atomic

Atomic set. Locks until the coderef is complete and returns the value.

=cut

sub atomic { die 'Virtual method' }

1;

__END__

=head1 SEE ALSO

=over 4

=item * L<CHI> - Unified cache handling interface

=back

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
