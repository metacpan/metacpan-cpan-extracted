#############################################################################
#
# Take a posted package review request for review
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/01/2009 11:50:00 AM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::ReviewTool::Command::take;

=head1 NAME

Fedora::App::ReviewTool::Command::take - [reviewer] take a package for review

=cut

use Moose;

use Archive::RPM;
use Digest::SHA1 qw{ sha1_hex };
use File::Slurp;
use File::Temp qw{ tempfile tempdir };
use IO::Prompt;
use LWP::Simple qw{ };
use Path::Class;
use Readonly;
use Template;
use URI::Fetch;
use URI::Find;

# debugging
#use Smart::Comments;

use namespace::clean -except => 'meta';

extends qw{ MooseX::App::Cmd::Command };

with 'Fedora::App::ReviewTool::Config';
with 'Fedora::App::ReviewTool::Bugzilla';
with 'Fedora::App::ReviewTool::Koji';
with 'Fedora::App::ReviewTool::Reviewer';
with 'Fedora::App::ReviewTool::Bodhi';

#with 'MooseX::Role::XMLRPC::Client' => {
#    name       => '_koji',
#    #uri        => 'http://koji.fedoraproject.org/kojihub',
#    login_info => 0,
#};
#sub _build__koji_uri { warn 'here'; return 'https://koji.fedoraproject.org/kojihub' }

sub _sections { qw{ bugzilla fas } }

sub run {
    my ($self, $opts, $args) = @_;
    
    # first things first.
    $self->enable_logging;

    $self->log->info('Starting take process.');

    # right now we assume we've been passed either bug ids or aliases; ideally
    # we should even search for a given review ticket from a package name

    PKG_LOOP:
    for my $id (@$args) {

        $self->log->info("Working on RHBZ#$id");
        
        # FIXME check!
        my $bug  = $self->_bz->bug($id);
        my $name = $bug->package_name;

        # FIXME basic "make sure bug is actually a review tix"

        print "\nFound: bug $bug, package $name\n\n";
        print $self->bug_table($bug) . "\n";

        # FIXME we should prompt to mark/check for FE-SPONSORNEEDED
        print "Checking to ensure packager is sponsored...\n\n";        
        print "*** WARNING *** Submitter is not in 'packager' group!\n\n"
            unless $self->has_packager($bug->reporter);

        if ($bug->has_flag('fedora-review')) {

            #if ($bug->get_flag('fedora-review') eq
            print "Bug has fedora-review set; not taking.\n\n";
        }
        elsif ($self->yes || prompt "Take review request? ", -YyNn1) {

            print "\nTaking...\n";

            $bug->assigned_to($self->userid);
            $bug->update;
            $bug->set_flags('fedora-review' => '?');

            print "$bug assigned and marked under review.\n";
        }

        next PKG_LOOP unless $self->yes || prompt 'Start review? ', -YyNn1;
        
        $self->do_review($bug) 
            if $self->yes || prompt 'Begin review? ', -YyNn1;
        
        print "\n";
        # end pkg loop...
    }

    return;
}

__END__

=head1 DESCRIPTION

This package provides a "take" command for reviewtool.

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



