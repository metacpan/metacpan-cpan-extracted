#!/usr/bin/perl

package Directory::Transactional::TXN::Nested;
BEGIN {
  $Directory::Transactional::TXN::Nested::VERSION = '0.09';
}
use Moose;

use namespace::clean -except => 'meta';

extends qw(Directory::Transactional::TXN);

has parent => (
	isa => "Directory::Transactional::TXN",
	is  => "ro",
	required => 1,
);

sub has_backup { return }

has _lock_cache => (
	isa => "HashRef",
	is  => "ro",
	default => sub { +{} },
);

sub find_lock {
	my ( $self, $path ) = @_;

	if ( my $lock = $self->get_lock($path) ) {
		return $lock;
	} else {
		my $c = $self->_lock_cache;

		if ( exists $c->{$path} ) {
			return $c->{$path};
		} else {
			return $c->{$path} = $self->parent->find_lock($path);
		}
	}
}

has [qw(parent_changed all_changed)] => (
	isa => "Set::Object",
	is  => "ro",
	lazy_build => 1,
);

sub _build_parent_changed {
	shift->parent->all_changed;
}

sub _build_all_changed {
	my $self = shift;

	$self->changed->union( $self->parent_changed );
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

