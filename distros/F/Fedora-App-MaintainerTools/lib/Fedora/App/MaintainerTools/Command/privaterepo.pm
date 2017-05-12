#############################################################################
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 05/12/2009 09:54:18 PM PDT
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::MaintainerTools::Command::privaterepo;

use 5.010;

use Moose;
use autodie 'system';
use namespace::autoclean;
use MooseX::Types::Moose ':all';
use MooseX::Types::Path::Class ':all';
use Path::Class;

use English '-no_match_vars';

extends 'MooseX::App::Cmd::Command';
with 'Fedora::App::MaintainerTools::Role::Logger';
#with 'Fedora::App::MaintainerTools::Role::Template';
#with 'Fedora::App::MaintainerTools::Role::SpecUtils';

# classes we need but don't want to load a compile-time
my @CLASSES = qw{
	Fedora::App::MaintainerTools::LocalRepo
};

our $VERSION = '0.006';

has package => (is => 'ro', isa => Bool, default => 0);
has rebuild => (is => 'ro', isa => Bool, default => 1);
has hostname => (is => 'rw', isa => Str, lazy_build => 1);
has repo => (is => 'rw', isa => Str, lazy_build => 1);

has _repo_config => (is => 'ro', isa => 'HashRef[HashRef]', lazy_build => 1);

sub command_names { 'private-repo' }

sub execute {
    my ($self, $opt, $args) = @_;

    $self->log->info('Beginning private-repo run.');
    Class::MOP::load_class($_) for @CLASSES;

	my @files = map { file $_ } @$args;
	do { die "$_ must exist!\n" if !$_->stat } for @files;

	my $reponame = $self->repo;
	#my %repocfg  = %{ $self->_repo_config->{$reponame} };
	$self->log->info("Pushing to $reponame");

	my $repo = Fedora::App::MaintainerTools::LocalRepo
		->new($self->_repo_config->{$reponame});
	my $i=0; say $i++;
	$repo->add_files(@files);
	say $i++;
	#$repo->update_local;
	$repo->update_remote;
	say $i++;

    return;
}

sub _build_repo { 'default' }

sub _build__repo_config {
	my $self = shift @_;

	{
		default => {
			comment => 'Default on fedorapeople.org',
			url => 'http://cweyl.fedorapeople.org/repo',
			remote_target => 'cweyl.fedorapeople.org:public_html/repo',
			local_dir => "$ENV{HOME}/.maintainertool/repos/default",
			name => 'default', # FIXME probably a non-optimal way
		},

	}
}

sub _build_hostname {
	my $self = shift @_;

	my $name = getpwent;
	return "$name.fedorapeople.org";
}

sub push_to_reviewspace {
    my $self = shift @_;

    # push to reviewspace...
    my $cmd = 'scp ' . join(q{ }, @_) . ' ' . $self->hostname . ":public_html/repo"; # $self->remote_loc;
	#say $cmd;
    system $cmd;

    #die "Error executing '$cmd'\n\n$?" if $?;

    return;
}

sub run_repocreate {
	my $self = shift @_;

	my $host = $self->hostname;
	my $cmd = "ssh $host ...";
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Fedora::App::MaintainerTools::Command::updatespec - Update a spec to latest GA version from the CPAN

=head1 DESCRIPTION

Updates a spec file with metadata from the CPAN.


=head1 SEE ALSO

L<Fedora::App::MaintainerTools>

=head1 AUTHOR

Chris Weyl  <cweyl@alumni.drew.edu>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>

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



