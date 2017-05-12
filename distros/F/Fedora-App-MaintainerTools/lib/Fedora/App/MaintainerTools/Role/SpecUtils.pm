#############################################################################
#
# Simple role to provide access to Bugzilla
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 06/16/2009
#
# Copyright (c) 2009-2010  <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::MaintainerTools::Role::SpecUtils;

use Moose::Role;
use namespace::autoclean;
use MooseX::Types::Moose ':all';
use File::Copy 'cp';
use Path::Class;

use MooseX::Traits::Util 'new_class_with_traits';

# debugging
#use Smart::Comments '###', '####';

our $VERSION = '0.006';

#############################################################################
# command options...

has stdout => (
    is => 'ro', isa => Bool, default => 0,
    documentation => 'write the spec to STDOUT rather than a .spec file',
);

#############################################################################
# spec class composition...

# If this grows any larger, let's refactor it out into a parameterized role.

has _new_spec_class =>  (is => 'rw', isa => Str, lazy_build => 1);
has _new_spec_traits => (is => 'rw', isa => 'ArrayRef[Str]', lazy_build => 1);
has _update_spec_class =>  (is => 'rw', isa => Str, lazy_build => 1);
has _update_spec_traits => (is => 'rw', isa => 'ArrayRef[Str]', lazy_build => 1);

sub _build__new_spec_traits { shift->_find_traits('New') }
sub _build__new_spec_class  { shift->_compose('New') }
sub _build__update_spec_traits { shift->_find_traits('Update') }
sub _build__update_spec_class  { shift->_compose('Update') }

sub _find_traits {
    my ($self, $part) = @_;

    Class::MOP::load_class('Module::Find');

    my $class = "Fedora::App::MaintainerTools::SpecData::$part";
    my @traits = Module::Find::findsubmod($class.'::Traits');

    ### $class
    ### @traits
    return \@traits;
}

sub _compose {
    my ($self, $part) = @_;

    my $att = lc "_$part" . '_spec_traits';

    return
        new_class_with_traits(
            "Fedora::App::MaintainerTools::SpecData::$part",
            @{ $self->$att },
        )
        ->name
        ;
}

#############################################################################
# rpmbuild methods

sub build_srpm { shift->_build_cmd('-bs --nodeps', @_) }
sub build_rpm  { shift->_build_cmd('-ba',          @_) }

sub _build_cmd {
	my ($self, $rpm_opts, $spec) = @_;

    my ($dir, $specfile) = (dir->absolute, $spec->to_file);
    local $ENV{$_} for qw{ PERL5LIB PERL_MM_OPT MODULEBUILDRC };

    cp $spec->tarball => "$dir";

	$rpm_opts .= " --define '$_ $dir'"
		for qw{ _sourcedir _builddir _srcrpmdir _rpmdir };

    # From Fedora CVS Makefile.common.
    $self->log->warn('running rpmbuild...');
	system "rpmbuild $rpm_opts $specfile";

    return;
}

1;

__END__

=head1 NAME

Fedora::App::MaintainerTools::Role::SpecUtils - Command role to get our data
class

=head1 DESCRIPTION

This is a L<Moose::Role> that command classes should consume in order to
properly create other classes with traits (that is, create certain classes of
ours with plugins/extensions pulled in dynamically).

=head1 AUTHOR

Chris Weyl  <cweyl@alumni.drew.edu>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 <cweyl@alumni.drew.edu>

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

