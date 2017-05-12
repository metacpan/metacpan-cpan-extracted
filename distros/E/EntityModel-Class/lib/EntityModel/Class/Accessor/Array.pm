package EntityModel::Class::Accessor::Array;
$EntityModel::Class::Accessor::Array::VERSION = '0.016';
use strict;
use warnings;

use parent qw{EntityModel::Class::Accessor};

use EntityModel::Array;
use EntityModel::Log ':all';
use Class::ISA;

my %watcher;

=head1 NAME

EntityModel::Class::Accessor::Array - generic class accessor for arrays

=head1 VERSION

Version 0.016

=head1 DESCRIPTION

See L<EntityModel::Class>.

=head1 METHODS

=cut

=head2 method_list

Returns the method definition to add to the class.

=cut

sub method_list {
	my ($class, %opt) = @_;
	my $k = $opt{k};
	if(my $pre = $opt{pre}) {
		return sub {
			my $self = shift;
			die "Options not supported for Array" if @_;
			$opt{pre}->($self, @_) or return;
			unless($self->{$k}) {
				my @watchers = map { @{ $watcher{$_}->{$k} // [] } } Class::ISA::self_and_super_path(ref $self);
				logDebug("Watcher for [%s] method [%s] has %d entries", ref $self, $k, scalar @watchers);
				$self->{$k} = EntityModel::Array->new($self->{$k},
					  (@watchers)
					? (onchange => [ sub {
						logDebug("Check [%s] for [%s]", ref $self, $k);
						# Pass value only
						$_->($self, @_) foreach @watchers;
					} ]) : ()
				);
			}
			return $self->{$k};
		};
	} else {
		return sub {
			my $self = shift;
			die "Options not supported for Array" if @_;
			unless($self->{$k}) {
				my @watchers = map {
					@{ $watcher{$_}->{$k} // [] }
				} Class::ISA::self_and_super_path(ref $self);

				logDebug("Watcher for [%s] method [%s] has %d entries", ref $self, $k, scalar @watchers);
				$self->{$k} = EntityModel::Array->new($self->{$k},
					  (@watchers)
					? (onchange => [ $self->sap(sub {
						my $self = shift;
						logDebug("Check [%s] for [%s]", ref $self, $k);
						# Pass value only
						$_->($self, @_) foreach @watchers;
					}) ]) : ()
				);
			}
			return $self->{$k};
		};
	}
}

=head2 add_watcher

Add this to the list of watchers for the class.

=cut

sub add_watcher {
	my ($class, $pkg, $meth, @sub) = @_;
	logDebug("Watching [%s] for [%s]", $meth, $pkg);
	push @{$watcher{$pkg}->{$meth}}, @sub;
	return 1;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2014. Licensed under the same terms as Perl itself.
