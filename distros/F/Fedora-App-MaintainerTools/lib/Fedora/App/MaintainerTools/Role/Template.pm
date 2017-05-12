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

package Fedora::App::MaintainerTools::Role::Template;

use Moose::Role;
use MooseX::Types::Moose ':all';
use MooseX::Types::Path::Class ':all';
use namespace::autoclean;
use Path::Class;

our $VERSION = '0.006';

has share_dir => (is => 'ro', isa => Dir, coerce => 1, lazy_build => 1);
has _tt2      => (is => 'ro', isa => Object, lazy_build => 1);

sub _build__tt2 {
    Class::MOP::load_class('Template');
    return Template->new({ INCLUDE_PATH => shift->share_dir });
}

sub _build_share_dir {
    my $self = shift @_;

    my $dir = dir qw{ .. share };

    return $dir->absolute if $dir->stat;

    Class::MOP::load_class('File::ShareDir');
    return File::ShareDir::dist_dir('Fedora-App-MaintainerTools');
}

1;

__END__

=head1 NAME

Fedora::App::MaintainerTools::Role::Template - Command role to access
templates and our sharedir

=head1 DESCRIPTION

This is a L<Moose::Role> that command classes should consume in order to
access templates.

=head1 AUTHOR

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

