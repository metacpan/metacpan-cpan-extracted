#############################################################################
#
# Generate a pretty table showing the status of our open review bugs.
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/06/2009 11:06:18 PM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::ReviewTool::Command::status;

use Moose;

use MooseX::Types::Path::Class qw{ File };

use DateTime::TimeZone::Local;
use Path::Class;
use Term::ProgressBar;
use Term::Size;
use Text::SimpleTable;

# debugging
#use Smart::Comments '###', '####';

use namespace::clean -except => 'meta';

extends qw{ MooseX::App::Cmd::Command };

with 'Fedora::App::ReviewTool::Config';
with 'Fedora::App::ReviewTool::Bugzilla';
with 'Fedora::App::ReviewTool::Koji';
with 'Fedora::App::ReviewTool::Submitter';

our $VERSION = '0.10';

has just_reviews => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => 'Only list reviews',
);

has just_submissions=> (
    is            => 'rw',
    isa           => 'Bool', 
    default       => 0,
    documentation => 'Only list submissions',
);

sub _sections { qw{ base bugzilla koji status } }

sub _usage_format {
    return 'usage: %c status %o';
}

sub run {
    my ($self, $opts, $args) = @_;
    
    # first things first.
    $self->enable_logging;
    $self->app->startup_checks;

    unless ($self->just_reviews) {

        print "Retrieving submissions status from bugzilla....\n\n";
        my $bugs = $self->find_my_submissions;
        print $bugs->num_ids . " bugs found.\n\n";
        print $self->bug_table($bugs) if $bugs->num_ids;
    }

    unless ($self->just_submissions) {

        print "Retrieving reviews status from bugzilla....\n\n";
        my $bugs = $self->find_my_active_reviews;
        print $bugs->num_ids . " bugs found.\n\n";
        print $self->bug_table($bugs) if $bugs->num_ids;
    }

    return;
}

1;

__END__

=head1 NAME

Fedora::App::ReviewTool::Command::status - [submitter] submit a srpm for review

=head1 SYNOPSIS

This package provides a "status" command for reviewtool.

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head1 SEE ALSO

L<Fedora::App::ReviewTool>

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



