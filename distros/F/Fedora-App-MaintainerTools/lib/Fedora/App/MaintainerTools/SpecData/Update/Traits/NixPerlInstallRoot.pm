#############################################################################
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 02/16/2010
#
# Copyright (c) 2010  <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::MaintainerTools::SpecData::Update::Traits::NixPerlInstallRoot;

use Moose::Role;
use namespace::autoclean;

around _build_middle => sub {
    my $orig = shift @_;
    my $self = shift @_;

    my @middle = @{ $self->$orig(@_) };

    for (@middle) {

        if ($_ eq 'make pure_install PERL_INSTALL_ROOT=%{buildroot}') {

            $_ = 'make pure_install DESTDIR=%{buildroot}';
            $self->add_changelog('- PERL_INSTALL_ROOT => DESTDIR');
            last;
        }
    }

    return \@middle;
};

1;

__END__

=head1 NAME

Fedora::App::MaintainerTools::SpecData::Update::Traits::NixPerlInstallRoot -
spec update trait

=head1 DESCRIPTION

This trait wraps the _build_middle() method to check for the existence of
PERL_INSTALL_ROOT, and to replace it with DESTDIR if so.

This could really be handled in
L<Fedora::App::MaintainerTools::SpecData::Update> itself, but it seemed like a
nice demo of how to create/use these types of plugins.

=head1 AUTHOR

Chris Weyl  <cweyl@alumni.drew.edu>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010  <cweyl@alumni.drew.edu>

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


