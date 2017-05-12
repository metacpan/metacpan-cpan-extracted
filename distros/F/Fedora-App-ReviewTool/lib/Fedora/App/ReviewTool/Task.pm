#############################################################################
#
# Represent a task
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 05/01/2009 06:37:58 PM PDT
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::ReviewTool::Task;

use Moose;

use overload '""' => sub { shift->desc }, fallback => 1;

our $VERSION = '0.10';

has job  => (isa => 'CodeRef', is => 'ro', required => 1);
has desc => (isa => 'Str',     is => 'ro', required => 1);

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Fedora::App::ReviewTool::Task - describe a task

=head1 SYNOPSIS

    use Fedora::App::ReviewTool::Task;

    my $task = Fedora::App::ReviewTool::Task->new(
        job  => sub { warn 'why, hello there' },
        desc => q{Warn that... you're there},
    );

=head1 DESCRIPTION

A very simple class, keeping track of some task and its metadata.  We only
have two attributes (job and desc), and both are required.  job must be a
CodeRef; desc a Str.

=head1 SEE ALSO

L<Fedora::App::ReviewTool::Command::import>

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

