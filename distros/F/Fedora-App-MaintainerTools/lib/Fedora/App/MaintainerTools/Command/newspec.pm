#############################################################################
#
# Update a Perl RPM spec with the latest GA in the CPAN
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

package Fedora::App::MaintainerTools::Command::newspec;

use Moose;
use MooseX::Types::Moose ':all';
use MooseX::Types::Path::Class ':all';
use namespace::autoclean;
use File::Copy 'cp';
use List::MoreUtils 'uniq';
use Path::Class;

use autodie 'system';

use Fedora::App::MaintainerTools::Types ':all';

extends 'MooseX::App::Cmd::Command';
with 'Fedora::App::MaintainerTools::Role::Logger';
with 'Fedora::App::MaintainerTools::Role::Template';
with 'Fedora::App::MaintainerTools::Role::SpecUtils';

# debugging
#use Smart::Comments '###';

# classes we need but don't want to load a compile-time
my @CLASSES = qw{
    CPANPLUS::Backend
    DateTime
    Data::TreeDumper
    Fedora::App::MaintainerTools::SpecData::New
    Module::CoreList
    RPM2
};

our $VERSION = '0.006';

sub command_names { 'new-spec' }

has recursive => (is => 'ro', isa => Bool, default => 0);

has _new_pkgs => (
    traits => ['Hash'],
    is => 'ro', isa => 'HashRef', default => sub { {} },
    handles => {
        new_pkgs     => 'keys',
        has_new_pkgs => 'count',
        no_new_pkgs  => 'is_empty',
        num_new_pkgs => 'count',
        has_new_pkg  => 'exists',
        add_new_pkg  => 'set',
    },
);

has _corelist => (
    traits => ['Hash'],
    is => 'ro', isa => 'HashRef', lazy_build => 1,
    handles => { has_as_core => 'exists' },
);

sub _build__corelist { $Module::CoreList::version{$]} }

has _cpanp => (is => 'ro', isa => CPBackend, lazy_build => 1);
has _rpmdb => (is => 'ro', isa => Object, lazy_build => 1);

sub _build__cpanp { CPANPLUS::Backend->new }
sub _build__rpmdb { RPM2->open_rpm_db()    }

sub execute {
    my ($self, $opt, $args) = @_;

    $self->log->info('Beginning new-spec run.');
    Class::MOP::load_class($_) for @CLASSES;

    for my $pkg (@$args) {

        my ($dist, $rpm_name) = $self->_pkg_to_dist($pkg);
        my $ret = $self->_new_spec($pkg);

        my @new = $self->new_pkgs;

        next unless $self->recursive;

        ### $ret
        ### @new

        my $tree = $self->_pretty_dep_tree($rpm_name, $ret);
        print "For $pkg ($dist), we generated " . @new . " new srpms.\n\n";

        print "These packages are dependent on each other as:\n\n$tree\n\n";
    }

    return;
}

sub _new_spec {
    my ($self, $pkg) = @_;

    # build what our rpm name would be
    my ($dist, $rpm_name) = $self->_pkg_to_dist($pkg);
    return if $self->_check_if_satisfied($rpm_name, $pkg);

    $self->log->info("Working on $dist.");
    my $data = $self
        ->_new_spec_class
        ->new(dist => $dist, cpanp => $self->_cpanp)
        ;
    $self->build_srpm($data);
    $self->add_new_pkg($rpm_name);

    return unless $self->recursive;

    my @deps = uniq sort ($data->build_requires, $data->requires);

    my %children = ();
    $self->_strip_rpm_deps(@deps);
    for my $dep (@deps) {

        $self->log->trace("Checking $dep (for $rpm_name)");
        my ($child_dist, $child_rpm_name) = $self->_pkg_to_dist($dep);
        my $ret = $self->_new_spec($dep);
        $children{$child_rpm_name} = $ret if $ret;
    }

    ### %children
    return keys %children ? \%children : 1;
}

sub _strip_rpm_deps { shift; map { s/^perl\(//; s/\)$//; $_ } @_ }

sub _pkg_to_dist {
    my ($self, $pkg) = @_;

    $pkg =~ s/::/-/g;
    $pkg =~ s/^perl\(//;
    $pkg =~ s/\)$//;

    my $module = $self->_cpanp->parse_module(module => $pkg);
    my $dist = $module->package_name;
    my $rpm_name = "perl-$dist";
    $self->log->trace("Found dist $dist for $pkg => $rpm_name");

    return ($dist, $rpm_name);
}

sub _check_if_satisfied {
    my ($self, $rpm_name, $pkg) = @_;

    $pkg =~ s/-/::/g; # ugh.

    # first (easiest), check to see if we've built it already
    # then if it's core (no need to build srpm)
    # then, check local system
    # then, check yum

    return 1 if $self->has_new_pkg($rpm_name);
    return 1 if $self->has_as_core($pkg);
    return 1 if $self->_rpmdb->find_by_name($rpm_name);
    return `repoquery $rpm_name` ? 1 : 0;
}

sub _pretty_dep_tree {
    my ($self, $rpm_name, $tree) = @_;

    my $printable = Data::TreeDumper::DumpTree(
        $tree, $rpm_name,
        USE_ASCII => 1,
        DISPLAY_ADDRESS => 0,
    );
    $printable =~ s/= 1//g;

    return $printable;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Fedora::App::MaintainerTools::Command::newspec - Generate a srpm/spec

=head1 DESCRIPTION

Generates a spec file with metadata from the CPAN.


=head1 SEE ALSO

L<maintainertool>, L<Fedora::App::MaintainerTools>

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



