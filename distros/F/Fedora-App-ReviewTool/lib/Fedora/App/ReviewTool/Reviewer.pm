#############################################################################
#
# Role providing methods to work with reviews others have submitted
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/01/2009 02:01:39 AM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::ReviewTool::Reviewer;

use Moose::Role;

use MooseX::Types::Path::Class qw{ Dir File };
use MooseX::Types::URI qw{ Uri };

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

use Fedora::App::ReviewTool::KojiTask;

use namespace::clean -except => 'meta';

has basedir => (
    is     => 'rw',
    isa    => Dir,
    coerce => 1,

    lazy_build    => 1,
    documentation => 'Base dir where all reviews are kept',
);

sub _build_basedir { "$ENV{HOME}/reviews" }

##
## Reviewing methods! 
##

sub do_review {
    my ($self, $bug) = @_;

    my $id   = $bug->id;
    my $name = $bug->package_name;

    $self->log->info("Working on RHBZ#$id");

    # find likely srpm links in the bug tix
    my @uris = $bug->grep_uris(sub {/\.src\.rpm$/});

    my $srpm_uri;
    if    (@uris == 1) { $srpm_uri = $uris[0] }
    elsif (@uris > 1)  { $srpm_uri = $self->_pick_srpm_uri(@uris) }
    else               { die "no srpm uris in $name?!\n" }

    $self->log->info("Using $srpm_uri");

    # fetch uri
    my $resp = URI::Fetch->fetch($srpm_uri)
        or die 'Cannot fetch srpm?! ' . URI::Fetch->errstr;

    # FIXME this is probably the wrong way to do it
    # ## filename: $resp->http_response->filename
    my $pkg_dir = $self->basedir->subdir($name);
    (-d "$pkg_dir") || $pkg_dir->mkpath;
    my $srpm = file $pkg_dir, $resp->http_response->filename;
    $self->log->debug("Writing out $srpm");
    write_file "$srpm", $resp->content;

    # access the header
    my $srpm_pkg = Archive::RPM->new($srpm);

    my $koji_task = $self->find_koji_task($bug, $srpm_pkg);

    if (!$koji_task && !$self->no_koji) {

        #if ($self->yes || prompt "Launch koji build?")
        $self->log->info('No koji task link found; running scratch');
        print "No koji task link found; running scratch\n";
        $self->koji_run_scratch($srpm);

        # hokey, yes.
        $koji_task = 
            Fedora::App::ReviewTool::KojiTask->new(uri => $self->_koji_uri);

        if (!$self->_koji_success) {

            print "Koji build failed!\n";
            $bug->add_comment("Koji (FAILURE) $koji_task")
                if $self->yes || prompt 'Post failure? ', -YyNn1;

            next PKG_LOOP;
        }

        $bug->add_comment("Koji (success) $koji_task");
    }

    # FIXME make optional?
    if ($koji_task) {

        # bring up the interesting bits
        system "firefox $koji_task";
        system "firefox '" . $koji_task->build_log . "'";
    }

    $self->run_rpm($pkg_dir, "-ivh $srpm", 'rpm');

    # find source info -- FIXME hack!
    my $spec = file $pkg_dir, "$name.spec";
    my @sources
        = map { s/^.+: //; URI->new($_) } `spectool --lf --sources $spec`;
    my $spec_license = $self->get_license_from_spec($spec);

    ### @sources

    my %sha1sum;

    for my $source (@sources) {

        $self->log->debug("Source: $source");

        # rename

        # fetch - I'd rather use URI::Fetch, but it tends to decompress...
        #$resp = URI::Fetch->fetch($source)
        #    or die "Cannot fetch $source : " . URI::Fetch->errstr;
        #my $filename        = $resp->http_response->filename;

        my $filename = ($source->path_segments)[-1];
        my $content  = LWP::Simple::get($source);
        my $srpm     = file $pkg_dir, "$filename.srpm";
        my $upstream = file $pkg_dir, $filename;

        # mv the srpm source to where it should be and write out upstream
        rename $upstream, $srpm;
        write_file "$upstream", $content;

        # generate our sha1sums
        my $s = $sha1sum{ $srpm->basename }     = sha1_hex($srpm->slurp);
        my $u = $sha1sum{ $upstream->basename } = sha1_hex($upstream->slurp);

        if ($s ne $u) {

            die "Still need to fail sha1 check properly";
        }
    }

    ### %sha1sum

    my $stuff;

    if ($koji_task && ($self->yes || prompt 'Use prebuilt rpms? ', -YyNn1)) {

        print "Pulling down koji-built rpms...\n";    
        my $prebuilt_dir = 
            dir $self->basedir, $name, 'koji.' . $koji_task->task_id;
        $prebuilt_dir->mkpath unless $prebuilt_dir->stat;

        for my $uri ($koji_task->rpms) {
        
            print "Fetching $uri...\n";
            my $resp = URI::Fetch->fetch($uri)
                or die 'Cannot fetch srpm?! ' . URI::Fetch->errstr;

            (my $file = "$uri") =~ s/^.*=//;
            $file = file $prebuilt_dir, $file;
            write_file "$file", $resp->content;
        }

        # FIXME
        $stuff  = `cd $pkg_dir && rpmlint *.spec`;
        $stuff .= `cd $prebuilt_dir  && rpmcheck`;
    }
    else {

        print "Building locally...\n";
        my $build_output_fn = $self->run_rpm($pkg_dir, "-ba $spec");
        # FIXME make optional?
        system "firefox file://$build_output_fn";

        # FIXME
        $stuff
            = `cd $pkg_dir && rpmlint *.spec && rpmcheck && cd noarch && rpmcheck`;
    }

    #my ($fh, $fn) = tempfile;
    my $fn = file $pkg_dir, "$name.review";

    $fn->remove
        if $fn->stat && !prompt 'Use existing review file? ', -YyNn1;

    if (not $fn->stat) {

        # writing out a new review file from the template
        my $tt2 = Template->new;
        $tt2->process(
            $self->app->section_data('review'),
            {   
                sha1sum  => \%sha1sum,
                koji_url => $koji_task->uri,
                license  => $spec_license,
                rpmcheck => $stuff,
            },
            "$fn"
        );
    }

    #print "$output\n";

    system "vi $fn";

    if ($self->yes || prompt 'Post text of review? ', -YyNn1) {

        my $review_file = file $fn;
        $bug->add_comment(scalar $review_file->slurp)
            if not $self->test;
    }

    if (prompt 'APPROVE? ', -YyNn1) {

        $bug->set_flag('fedora-review' => '+');
        $bug->update;
    }

    return;
}

=head2 run_rpm("...")

Magic to wrap rpm with the right --xxxxdir options to keep everything in the
directory we expect.

=cut

sub run_rpm {
    my ($self, $dir, $cmd_suffix, $rpm) = @_;

    $rpm ||= 'rpmbuild';

    my $cmd
        = "$rpm "
        . qq{--define '_sourcedir $dir' }
        . qq{--define '_builddir  $dir' }
        . qq{--define '_srcrpmdir $dir' }
        . qq{--define '_specdir   $dir' }
        . qq{--define '_rpmdir    $dir' }
        . $cmd_suffix;

    $self->log->debug("running $cmd");

    # FIXME capture output?
    #system $cmd;
    my $output = `$cmd 2>&1`;

    if ($?) {

        die "
Error!

cmd:    $cmd
error:  $?
Output: 

$output
";
    }

    my (undef, $fn) = tempfile('rt.XXXXXXX', TMPDIR => 1);
    write_file $fn, \$output; 

    return file $fn;
}

1;

=head2 find_koji_task($bug, $srpm_pkg)

Looks for a koji scratch build link in any koji uris in the bug.  Prompts if
necessary; returns undef if we can't find one.

=cut

sub find_koji_task {
    my ($self, $bug, $srpm_pkg) = @_;

    print "\nSearching for koji tasks...\n\n";
    do { print "No koji tasks found!\n"; return } unless $bug->has_koji_tasks;
    print 'Found ' . $bug->num_koji_tasks . ".\n\n";

    my $fn = $srpm_pkg->rpm->basename;

    for my $ktask ($bug->koji_tasks) {

        ### ktask: "$ktask"
        print 'Checking task #' . $ktask->task_id . "...\n";

        if ($ktask->for_srpm eq $fn) {

            my $task_num = $ktask->task_id;
            print "Found build for $fn at task $task_num.\n\n";
            return $ktask;
        }
    }

    return;
}

=head2 get_license_from_spec($spec)

Passed a spec file, get the license tag from it and validate.

=cut

sub get_license_from_spec {
    my ($self, $spec) = @_;

    my ($lic) = grep { /^License:/i } $spec->slurp;
    $lic =~ s/^License:\s+//i;
    chomp $lic;

    # FIXME ought to do validation?
    return $lic;
}

#*#*#*#

# FIXME needed?

sub pack   { shift; join '!%!', @_                      }
sub unpack { shift; split /\|/, map { chomp; $_ } @_    }
sub repack { shift; my $l = shift; $l =~ s/!%!/\n/g; $l }

1;

__END__

=head1 NAME

Fedora::App::ReviewTool::Reviewer - methods to work with reviews

=head1 SYNOPSIS

    # ta-da!
    with 'Fedora::App::ReviewTool::Reviewer';

=head1 DESCRIPTION

This role provides common functions, attributes, when reviewing a package.

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

