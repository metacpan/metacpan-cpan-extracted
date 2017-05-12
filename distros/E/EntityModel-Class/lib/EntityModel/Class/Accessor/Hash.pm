package EntityModel::Class::Accessor::Hash;
$EntityModel::Class::Accessor::Hash::VERSION = '0.016';
use strict;
use warnings;

use parent qw{EntityModel::Class::Accessor};

use EntityModel::Hash;

=head1 NAME

EntityModel::Class::Accessor::Array - generic class accessor for arrays

=head1 VERSION

Version 0.016

=head1 DESCRIPTION

See L<EntityModel::Class>.

=head1 METHODS

=cut

=head2 method_list

Returns a hash of method definitions.

=cut

sub method_list {
	my ($class, %opt) = @_;
	my $k = $opt{k};
	if(my $pre = $opt{pre}) {
		return sub {
			my $self = shift;

			$pre->($self, @_) or return;

			if(@_) {
				$self->{$k} = ref $_[0] eq 'HASH' ? EntityModel::Hash->new($_[0]) : $_[0];
			}
			unless($self->{$k}) {
				$self->{$k} = EntityModel::Hash->new($self->{$k});
			}
			return $self->{$k};
		};
	} else {
		return sub {
			my $self = shift;

			if(@_) {
				return $self->{$k}->get(@_) if @_ == 1 && !ref($_[0]);
				$self->{$k} = ref $_[0] eq 'HASH' ? EntityModel::Hash->new($_[0]) : $_[0];
			}
			unless($self->{$k}) {
				$self->{$k} = EntityModel::Hash->new($self->{$k});
			}
			return $self->{$k};
		};
	}
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2014. Licensed under the same terms as Perl itself.
