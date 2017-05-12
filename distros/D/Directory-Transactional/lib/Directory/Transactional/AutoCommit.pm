#!/usr/bin/perl

package Directory::Transactional::AutoCommit;
BEGIN {
  $Directory::Transactional::AutoCommit::VERSION = '0.09';
}
use Moose;

use Scope::Guard;

use namespace::clean -except => 'meta';

use Hash::Util::FieldHash::Compat qw(fieldhash);

has manager => (
	isa => "Directory::Transactional",
	is  => "ro",
	required => 1,
);

has finished => (
	isa => "Bool",
	is  => "rw",
);

has resources => (
	isa => "HashRef",
	is  => "ro",
	default => sub { fieldhash my %h },
);

sub register {
	my ( $self, @resources ) = @_;

	die "blah" if $self->finished;

	my $guard = Scope::Guard->new(sub { $self->resource_expired });

	@{ $self->resources }{ @resources } = ( ($guard) x @resources );
}

sub resource_expired {
	my $self = shift;

	if ( keys %{ $self->resources } == 0 ) {
		$self->commit;
	}
}

sub commit {
	my $self = shift;

	unless ( $self->finished ) {
		$self->manager->txn_commit;
		$self->finished(1);
	}
}

sub DEMOLISH {
	my $self = shift;
	$self->finished(1); # don't commit, we're being destroyed because the txn was rolled back or comitted
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__
