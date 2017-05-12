#!/usr/bin/perl

package Directory::Transactional::TXN;
BEGIN {
  $Directory::Transactional::TXN::VERSION = '0.09';
}
use Moose;

use Set::Object;
use File::Spec;
use File::Path qw(make_path remove_tree);

use Data::GUID;

use namespace::clean -except => 'meta';

has manager => (
	isa => "Directory::Transactional",
	is  => "ro",
	required => 1,
	weak_ref => 1,
);

has id => (
	isa => "Str",
	is  => "ro",
	lazy_build => 1,
);

sub _build_id { Data::GUID->new->as_string };

has work => (
	isa => "Str",
	is  => "ro",
	lazy_build => 1,
);

sub _build_work {
	my $self = shift;
	my $dir = File::Spec->catdir( $self->manager->_txns, $self->id );
	make_path($dir);
	return $dir;
}

has _locks => (
	isa => "HashRef",
	is  => "ro",
	default => sub { {} },
);

has changed => (
	isa => "Set::Object",
	is  => "ro",
	default => sub { Set::Object->new },
);

has [qw(downgrade)] => (
	isa => "ArrayRef",
	is  => "ro",
	default => sub { [] },
);

sub propagate {
	my $self = shift;

	my $p = $self->parent;

	foreach my $field ( qw(_locks) ) {
		my $h = $self->$field;
		@{ $self->parent->$field }{ keys %$h } = values %$h;
	}

	$self->parent->changed->insert($self->changed->members);

	return;
}

sub set_lock {
	my ( $self, $path, $lock ) = @_;
	$self->_locks->{$path} = $lock;
}

sub get_lock {
	my ( $self, $path ) = @_;
	$self->_locks->{$path};
}

sub is_changed_in_head {
	my ( $self, $path ) = @_;

	$self->changed->includes($path);
}

sub is_changed {
	my $self = shift;
}

sub DEMOLISH {
	my $self = shift;

	if ( $self->has_work ) {
		remove_tree($self->work, {});
	}

	if ( $self->has_backup ) {
		remove_tree($self->backup, {});
	}
}

sub mark_changed {
	my ( $self, @args ) = @_;
	$self->clear_all_changed;
	$self->changed->insert(@args);
}

sub auto_handle {}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

