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

package Fedora::App::MaintainerTools::Command::updatespec; 

use Moose;
use MooseX::Types::Moose ':all';
use MooseX::Types::Path::Class ':all';
use namespace::autoclean;
use File::Copy 'cp';
use Path::Class;

extends 'MooseX::App::Cmd::Command'; 
with 'Fedora::App::MaintainerTools::Role::Logger';
with 'Fedora::App::MaintainerTools::Role::Template';
with 'Fedora::App::MaintainerTools::Role::SpecUtils';

# classes we need but don't want to load a compile-time
my @CLASSES = qw{
    DateTime
    RPM::Spec
    Fedora::App::MaintainerTools::SpecData::Update
};

our $VERSION = '0.006';

has package => (is => 'ro', isa => Bool, default => 0);

sub command_names { 'update-spec' }

sub execute {
    my ($self, $opt, $args) = @_;

    $self->log->info('Beginning update-spec run.');
    Class::MOP::load_class($_) for @CLASSES;
    my $dir = dir->absolute;

    for my $pkg (@$args) {

        my $data = $self
            ->_update_spec_class
            ->new(spec => RPM::Spec->new(specfile => "$pkg"))
            ;

        my $tarball = $data->tarball;
        cp "$tarball" => "$dir";

        if ($self->stdout) {

            print $data->output;
        }
        else {

            $data->to_file;
        }

        $self->_do_fedora_bits($data);
    }

    return;
}

sub _do_fedora_bits {
    my ($self, $data) = @_;

    # check to see if we have a sources file
    return unless -f 'sources';

    my $tarball = $data->tarball;
    system "make new-source FILES='$tarball'";
    system "cvs diff | colordiff";

    # FIXME koji build bits here...
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



