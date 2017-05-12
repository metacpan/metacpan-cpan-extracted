#############################################################################
#
# A submit command for Fedora::App::ReviewTool
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

package Fedora::App::ReviewTool::Command::submit;

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
with 'Fedora::App::ReviewTool::Koji';
with 'Fedora::App::ReviewTool::Submitter';

our $VERSION = '0.10';

sub _sections { qw{ base bugzilla koji submit } }

# FIXME I'm pretty sure this is the wrong way to do it :)
has '+logger' => ( traits => [ 'NoGetopt' ] );

has depends_on => (
    traits        => [ 'Getopt' ],
    is            => 'rw',
    isa           => 'Str',
    default       => q{},
    cmd_flag      => 'depends-on',
    cmd_aliases   => [ 'depends' ],
    documentation => 'bugs this review depends on',
);

has blocks => (
    is            => 'rw',
    isa           => 'Str',
    default       => q{},
    documentation => 'bugs this review blocks',
);

has additional_comment => (
    traits        => [ 'Getopt' ],
    is            => 'rw',
    isa           => 'Str',
    cmd_flag      => 'additional-comment',
    cmd_aliases   => [ 'c' ],
    documentation => 'Additional comment to append to tix',
);

has force => (
    traits => [ 'Getopt' ],
    is => 'rw', 
    isa => 'Bool',
    documentation => 'Force operation',
    default => 0,
);

# death to aliases > 20! (not factorial, sadly)
sub _alias { length $_[1] < 21 ? $_[1] : undef }

sub _usage_format {
    return "usage: %c submit <srpm1> [<srpm2> ...] %o";
}

sub run {
    my ($self, $opts, $args) = @_;
    
    # first things first.
    $self->enable_logging;

    $self->app->startup_checks;

    my $total = scalar @$args;
    my $i     = 0;

    die "Pass srpms on the command line to submit.\n"
        unless @$args;

    SRPM_LOOP:
    for my $srpm_file (@$args) {

        $srpm_file = file $srpm_file;

        # make sure we were passed a srpm
        die "$srpm_file must exist, be readable and be a srpm!\n"
            unless -r "$srpm_file" && "$srpm_file" =~ /\.src\.rpm$/;

        my $srpm = Archive::RPM->new($srpm_file);
        $i++;

        my $info = $self->get_pkg_info_from_srpm($srpm);

        print "Working on: ($i of $total) " . $srpm_file->basename . "\n";

        my $spec = $self->build_spec($srpm, $info);

        my $name = $info->{name};
        my $test = $self->test;
        my $url  = $info->{url};

        # catch cpanspec/CPANPLUS::Dist::RPM issues 
        die "$name has an invalid summary!\n" 
            if $srpm->summary =~ /no summary found/i;

        print "Searching bugzilla; this may take some time...\n";

        # check to ensure we haven't done this already
        if (my $bug = $self->find_bug_for_pkg($name))  {

            die "\n$name already has a review bug: $bug\n"
                unless $self->force;
        }

        print "No existing review bug for $name.\n";

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

            if (!$self->_koji_success) {

                die "KOJI SCRATCH FAILED! Correct and re-submit.\n\n  "
                  . $self->_koji_uri . "\n\n"
                  ;
            }
        
        }

        # push to fedorapeople space
        # FIXME yeah, I'd rather use Net::SSH2, but ssh-agent is easy...
        print "Pushing package and spec to fedorapeople...\n";
        $self->push_to_reviewspace($srpm_file, $spec);
        print "...done.\n\n";

        my $baseuri = $self->baseuri;

        my $comment = $self->app->new_tix(
            srpm        => "$baseuri" . $srpm->rpm->basename,
            spec        => "$baseuri" . $spec->basename,
            koji        => $self->_koji_uri,
            description => $self->repack($info->{description}),
            version     => $Fedora::App::ReviewTool::VERSION,

            additional_comment => $self->additional_comment,
        );

        my $sum = $info->{summary};

        print $self->app->verbose_submit(
            bug  => $info,
            body => $comment,
        );

        unless ($self->yes || prompt 'Post for review? ', -YyNn1) {

            print "Not posting $name for review.\n";
            next SRPM_LOOP;
        }

        # create bug, etc
        print "\nCreating bug...\n";
        my $bug = $self->_bz->create_bug(
            product      => $test ? 'Bugzilla' : 'Fedora',
            component    => $test ? 'test'     : 'Package Review',
            version      => $test ? 'devel'    : 'rawhide',
            assigned_to  => 'nobody@fedoraproject.org', # easier than $test
            #summary      => "Review Request: $name - $sum",
            summary      => $self->gen_summary($srpm),
            comment      => $comment,
            alias        => $self->_alias($name),
            dependson    => $self->depends_on,
            blocked      => $self->blocks,
            bug_file_loc => "$url",
        );

        print "...done.\n\nReview bug for $name is: $bug\n\n";
    }
    
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

L<Fedora::App::ReviewTool>.

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



