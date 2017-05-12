#############################################################################
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
#
# Copyright (c) 2010 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::MaintainerTools::LocalRepo;

use 5.010;

use Moose;
use MooseX::Types::Moose ':all';
use MooseX::Types::Path::Class ':all';
use MooseX::Types::URI ':all';

use autodie 'system';
use namespace::autoclean;

#use Fedora::App::MaintainerTools::Types ':all';

with 'MooseX::Log::Log4perl';
with 'MooseX::Traits';

use File::Copy 'cp';
use Path::Class;

our $VERSION = '0.006';

# debugging
use Smart::Comments '###', '####';

#############################################################################
# required

has name 		  => (is => 'ro', required => 1, isa => Str);
has comment       => (is => 'ro', required => 0, isa => Str);
has url 		  => (is => 'ro', required => 1, isa => Uri, coerce => 1);
has remote_target => (is => 'ro', required => 1, isa => Str);
has local_dir	  => (is => 'ro', required => 1, isa => Dir, coerce => 1);

#############################################################################
# File (and old and new) tracking

# hmm.
my $arrayref_files_type = 'ArrayRef[' . File . ']';

has _files => (
	#traits => [ 'Array' ], is => 'ro', isa => 'ArrayRef[File]', lazy_build => 1,
	traits => [ 'Array' ], is => 'ro', isa => $arrayref_files_type, lazy_build => 1,
	handles => {
		files	   => 'elements',
		has_files  => 'is_empty',
		file_count => 'count',
		srpm_files => [ grep => sub {  /\.src\.rpm$/ } ],
		rpm_files  => [ grep => sub { !/\.src\.rpm$/ } ],
	},
);

has _new_files => (
	#traits => [ 'Array' ], is => 'ro', isa => 'ArrayRef[File]', lazy_build => 1,
	traits => [ 'Array' ], is => 'ro', isa => $arrayref_files_type, lazy_build => 1,
	handles => {
		new_files => 'elements',
		has_new_files => 'count',
		no_new_files => 'is_empty',
		add_files => 'push',
	},
);

has is_local_updated  => (
	traits => ['Bool'], is => 'ro', isa => Bool, lazy_build => 1,
	handles => { _local_is_updated => 'set' },
);

has is_remote_updated => (
	traits => ['Bool'], is => 'ro', isa => Bool, lazy_build => 1,
	handles => { _remote_is_updated => 'set' },
);

sub _build__files { grep { !$_->is_dir && /\.rpm$/ } shift->local_dir->children }
sub _build__new_files { [ ] }

sub _build_is_local_updated  { 0 }
sub _build_is_remote_updated { 0 }

#############################################################################
#

sub update_local {
	my $self = shift @_;
	my %opts = @_;

	my $x = $self->_new_files;
	### $x

	return unless $self->has_new_files;

	$self->log->info('Regenerating local metadata');

	# get our dir, creating if needed
	my $dir = $self->local_dir;
	$dir->mkpath unless $dir->stat;

	# copy files over...
	cp "$_" => "$dir" for $self->new_files;

	# regenerate local metadata
	my $cmd = "cd $dir && createrepo --update .";
	$self->log->debug("Executing: $cmd");
    system $cmd;

	return;
}

sub update_remote {
	my $self = shift @_;
	my %opts = @_;

	$self->log->info('Updating local repo and pushing...');

	$self->update_local;
	$self->_push_new_files;
	$self->_push_new_metadata;

	# now, reset ourself...
	$self->_clear_files;
	$self->_clear_new_files;

	my $dir = $self->local_dir;
	return;
}

sub _push_new_files {
    my $self = shift @_;

    # push to reviewspace...
    #my $cmd = 'scp ' . join(q{ }, $self->files) . ' ' . $self->hostname . ":public_html/repo"; # $self->remote_loc;
    my $cmd = 'scp ' . join(q{ }, $self->new_files) . ' ' . $self->remote_target;

    say $cmd;
	$self->log->debug("Executing: $cmd");
    system $cmd;

	return;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Fedora::App::MaintainerTools::LocalRepo - Maintain and work with a local YUM repo

=head1 DESCRIPTION



=head1 ATTRIBUTES

...

=head1 SEE ALSO

L<Fedora::App::MaintainerTools>

=head1 AUTHOR

Chris Weyl  <cweyl@alumni.drew.edu>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 Chris Weyl <cweyl@alumni.drew.edu>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the

    Free Software Foundation, Inc.
    59 Temple Place, Suite 330
    Boston, MA  02111-1307  USA

=cut



