#############################################################################
#
# Submit an updated srpm to an existing review tix.
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/10/2009 11:06:53 PM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::ReviewTool::Command::update;

use Moose;

use MooseX::Types::Path::Class qw{ File };

use Archive::RPM;
use IO::Prompt;
use Path::Class;

use namespace::clean -except => 'meta';

our $VERSION = '0.10';

extends qw{ MooseX::App::Cmd::Command };

with 'Fedora::App::ReviewTool::Config';
with 'Fedora::App::ReviewTool::Bugzilla';
with 'Fedora::App::ReviewTool::Koji';
with 'Fedora::App::ReviewTool::Submitter';

sub _sections { qw{ base bugzilla koji submit } }

sub run {
    my ($self, $opts, $args) = @_;
    
    # first things first.
    $self->enable_logging;
    $self->app->startup_checks;

    my $total = scalar @$args;
    my $i     = 0;

    SRPM_LOOP:
    for my $srpm_file (@$args) {

        $srpm_file = file $srpm_file;
        my $srpm = Archive::RPM->new($srpm_file);
        $i++;

        my $info = $self->get_pkg_info_from_srpm($srpm);

        print "Working on: ($i of $total) " . $srpm_file->basename . "\n";

        my $spec = $self->build_spec($srpm, $info);

        my $name = $info->{name};
        my $test = $self->test;
        my $url  = $info->{url};

        # make sure we were passed a srpm
        die "$srpm_file must exist, be readable and be a srpm!\n"
            unless -r "$srpm_file" && "$srpm_file" =~ /\.src\.rpm$/;

        print "Searching bugzilla; this may take some time...\n";

        my $bug = $self->find_bug_for_pkg($name); 

        do { warn "No existing review bug for $name.\n"; next SRPM_LOOP } 
            unless $bug;

        print "Found bug $bug for $name.\n";

        if ($self->no_koji) {

            # koji scratch build (unless no_koji)
            print "Skipping koji scratch build\n";
        }
        else {

            # kick off build and capture -- just let die if not success!
            my $start = DateTime->now;
            print "Starting koji scratch build.\n";
            print "...this may take some time.  We started at $start\n";

            # FIXME the koji stuff all needs to be refactored!
            
            $self->koji_run_scratch($srpm_file);

            $info->{koji_uri}     = $self->_koji_uri;
            $info->{koji_success} = $self->_koji_success;

            my $end = DateTime->now;
            my $dur = $start - $end;

            # FIXME we should probably use DateTime::Format::Duration here
            my ($min, $sec) = ($dur->minutes, $dur->seconds);
            print "Koji build done; we took $min minutes, $sec seconds.\n\n";
        }

        my $baseuri = $self->baseuri;
        my $comment = $self->app->update(
            srpm        => "$baseuri" . $srpm_file->basename,
            spec        => "$baseuri" . $spec->basename,
            koji        => $self->_koji_uri,
        );

        my $sum = $info->{summary};
        print $self->app->verbose_submit(
            bug  => $info,
            body => $comment,
        );

        die "\nCalled with --test, exiting...\n" if $self->test;

        unless ($self->yes || prompt "Post update to $bug? ", -YyNn1) {

            print "Not posting update.\n";
            next SRPM_LOOP;
        }

        # push to fedorapeople space
        # FIXME yeah, I'd rather use Net::SSH2, but ssh-agent is easy...
        print "Pushing package and spec to fedorapeople...\n";
        $self->push_to_reviewspace($srpm_file, $spec);
        print "...done.\n\n";

        # updating
        $bug->add_comment($comment);
        print "\nAdded comment to bug $bug.\n";

        my $new_summary = $self->gen_summary($srpm);
        if ($srpm->summary ne $new_summary) {
            
            $bug->summary($new_summary);
            print "Updating with new summary...\n";
            $bug->update;
        }
    }

    print "\nfin.\n";
}

1;

__END__

=head1 NAME

Fedora::App::ReviewTool::Command::update - [submitter] update a review tix

=head1 DESCRIPTION

This class provides an update command to L<Fedora::App::ReviewTool>, allowing
one to run a koji scratch build, push the new spec and srpm to public
reviewspace, and update the review ticket.

=head1 SEE ALSO

L<Fedora::App::ReviewTool>, L<reviewtool>.

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

