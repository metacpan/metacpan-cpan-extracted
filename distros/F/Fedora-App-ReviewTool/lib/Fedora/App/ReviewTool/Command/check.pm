#############################################################################
#
# Check to see if a review already exists 
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/07/2009 03:10:20 PM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::ReviewTool::Command::check;

use Moose;

use MooseX::Types::Path::Class qw{ File };

use Archive::RPM;
use DateTime;
use IO::Prompt;
use Path::Class;
use Template;

use namespace::clean -except => 'meta';

extends qw{ MooseX::App::Cmd::Command };

with 'Fedora::App::ReviewTool::Config';
with 'Fedora::App::ReviewTool::Bugzilla';
with 'Fedora::App::ReviewTool::Submitter';

# debugging
#use Smart::Comments '###', '####';

our $VERSION = '0.10';

sub _sections { qw{ base bugzilla koji submit } }

sub _usage_format { 'usage: %c check <package1> [<package2> ...] %o' } 

sub run {
    my ($self, $opts, $args) = @_;
    
    # first things first.
    $self->enable_logging;

    $self->app->startup_checks;

    my $total = scalar @$args;
    my $i     = 0;

    die "Pass packages to check for on the command line.\n"
        unless @$args;

    my @bug_ids;

    PACKAGE_LOOP:
    for my $pkg (@$args) {

        $i++;
        print "Working on: ($i of $total) $pkg\n"; 

        print "Searching bugzilla; this may take some time...\n";

        # check to ensure we haven't done this already
        my @ids = $self->find_bug_for_pkg($pkg);

        print "No existing review bug for $pkg.\n"
            unless @ids;

        push(@bug_ids, @ids)
            if @ids;
    }
    
    ### @bug_ids
    print $self->bug_table($self->_bz->bugs(sort @bug_ids))
        if @bug_ids;

    return;
}

1;

__END__

=head1 NAME

Fedora::App::ReviewTool::Command::submit - [submitter] submit a srpm for review

=head1 DESCRIPTION

Handles the various routine parts of submitting a package for review.

=over 4

=item B<koji scratch build>

=item B<push to publicly-accessible fedorapeople.org>

=item B<create a review bug on bugzilla>

=back

=head1 SUBROUTINES/METHODS

TODO/FIXME!

=head1 SEE ALSO

L<reviewtool>, L<Fedora::App::ReviewTool>.

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



