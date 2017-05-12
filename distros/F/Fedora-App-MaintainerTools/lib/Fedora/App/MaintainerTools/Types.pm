#############################################################################
#
# Moose types for us to use. 
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 06/16/2009
#
# Copyright (c) 2009  <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::MaintainerTools::Types;

use MooseX::Types -declare => [ qw{ CPBackend CPModule SpecData } ];
use MooseX::Types::Moose ':all';

use namespace::clean -except => [ 'meta', 'CPBackend', 'CPModule', 'SpecData' ];

our $VERSION = '0.006';

subtype CPBackend,
    as Object,
    where   { $_->isa('CPANPLUS::Backend')   },
    message { 'Object !isa CPANPLUS::Backend' },
    ;

subtype CPModule,
    as Object,
    where { $_->isa('CPANPLUS::Module')     },
    message { 'Object !isa CPANPLUS::Module' },
    ;

subtype SpecData,
    as Object,
    where   { $_->isa('Fedora::App::MaintainerTools::SpecData')    },
    message { 'Object !isa Fedora::App::MaintainerTools::SpecData' },
    ;

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Fedora::App::MaintainerTools::Types - Moose types we need

=head1 SYNOPSIS

    use Fedora::App::MaintainerTools::Types ':all';

    has foo => (isa => CPBackend, ...);

=head1 DESCRIPTION

Two additional types we use; broken out here due to the global nature of the
Moose type system.

 =head1 SEE ALSO

L<MooseX::Types>



Chris Weyl  <cweyl@alumni.drew.edu>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009  <cweyl@alumni.drew.edu>

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

