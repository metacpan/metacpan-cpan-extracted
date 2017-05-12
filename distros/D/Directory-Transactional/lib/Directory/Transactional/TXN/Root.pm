#!/usr/bin/perl

package Directory::Transactional::TXN::Root;
BEGIN {
  $Directory::Transactional::TXN::Root::VERSION = '0.09';
}
use Moose;

use File::Spec;
use File::Path qw(make_path remove_tree);

use namespace::clean -except => 'meta';

extends qw(Directory::Transactional::TXN);

# optional lock attr, used in NFS mode when no fine grained locking is
# available
has global_lock => (
	is  => "ro",
);

# used for auto commit
has auto_handle => (
	is  => "ro",
);

has backup => (
	isa => "Str",
	is  => "ro",
	lazy_build => 1,
);

sub _build_backup {
	my $self = shift;
	File::Spec->catdir( $self->manager->_backups, $self->id );
}

sub create_backup_dir {
	my $self = shift;
	make_path($self->backup);
}

sub find_lock {
	my ( $self, $path ) = @_;
	$self->get_lock($path);
}

sub clear_all_changed {}

sub all_changed {
	shift->changed;
}

sub DEMOLISH {
	my $self = shift;

	if ( my $ah = $self->auto_handle ) {
		# in case of rollback
		$ah->finished(1);
	}
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

