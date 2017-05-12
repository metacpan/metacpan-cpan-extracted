#############################################################################
#
# Work with updates (typically Bodhi)
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

package Fedora::App::MaintainerTools::Command::ftbfs;

use 5.010;

use Moose;
use namespace::autoclean;
use IO::Prompt;

extends 'MooseX::App::Cmd::Command';
with 'Fedora::App::MaintainerTools::Role::Bugzilla';

# debugging
#use Smart::Comments '###', '####';

our $VERSION = '0.006';

sub execute {
    my ($self, $opt, $args) = @_;

    my $bugs = $self->find_my_ftbfs_bugs;
    $bugs->aggressive(0);
    print to_table($bugs);

    return;
}

# https://bugzilla.redhat.com/buglist.cgi?emailtype2=notequals&emailreporter1=1&classification=Fedora&emailtype1=exact&query_format=advanced&bug_status=NEW&bug_status=ASSIGNED&email2=ftbfs%40fedoraproject.org&email1=ftbfs%40fedoraproject.org&emailassigned_to2=1&product=Fedora

sub find_my_ftbfs_bugs {
    my $self = shift @_;

    my $bugs = $self->_bz->search(
        product    => 'Fedora',
        version    => 'rawhide',
        bug_status => 'NEW,ASSIGNED',
        # FIXME
        #assigned_to   => $self->userid,
        assigned_to   => $self->_bz->userid,
        reporter => 'ftbfs@fedoraproject.org',
    );

    ### $bugs
    return $bugs;
}

sub to_table {
    my $bugs = shift @_;

    my $t = Text::SimpleTable->new(
        [ 6, 'ID' ],
        [ 40, 'Component' ],
        [ 20, 'Date Filed' ],
    );

    $t->row("$_", $_->component, $_->creation_time) for $bugs->bugs;
    return $t->draw;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Fedora::App::MaintainerTools::Command::ftbfs - work with FTBFS bugs

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

