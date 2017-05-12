#############################################################################
#
# Provides a 'import' command to Fedora::App::ReviewTool.
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/07/2009 11:02:10 AM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::App::ReviewTool::Command::import;

use autodie 'system';

use Moose;

use MooseX::Types::Path::Class ':all';

use Archive::RPM;
use File::Slurp;
use IO::Prompt;
use Term::Completion::Path 'Complete';
use IPC::System::Simple;
use Path::Class;
use URI::Fetch;

use Log::Log4perl ':easy';

use Fedora::App::ReviewTool::Task;

# debugging...
#use Smart::Comments;

use namespace::clean -except => 'meta';

extends qw{ MooseX::App::Cmd::Command }; 

with 'Fedora::App::ReviewTool::Config';
with 'Fedora::App::ReviewTool::Bugzilla';
with 'Fedora::App::ReviewTool::Bodhi';
with 'Fedora::App::ReviewTool::Submitter';

with 'MooseX::Workers';

our $VERSION = '0.10';

sub _sections { qw{ bugzilla fas } }

has _jobs => (
    metaclass => 'Collection::Array',
    traits   => [ 'NoGetopt' ],
    is       => 'ro',
    isa      => 'ArrayRef[Fedora::App::ReviewTool::Task]',
    default  => sub { [] },
    provides => {
        'elements' => 'jobs',
        'push'     => 'enqueue_job',
        'shift'    => 'dequeue_job',
        'count'    => 'num_jobs',
        'empty'    => 'has_jobs',
    },
);

has tmpdir => (is => 'ro', isa => Dir, coerce => 1, lazy_build => 1);
sub _build_tmpdir { File::Temp::tempdir }

has cvs_root => (is => 'ro', isa => 'Str', lazy_build => 1);

sub _build_cvs_root 
    { ':ext:' . shift->app->cn . '@cvs.fedora.redhat.com:/cvs/extras' }

sub run {
    my ($self, $opts, $args) = @_;
   
    $self->enable_logging;
    $self->app->startup_checks;

    my $bugs;
    
    if (@$args == 0) {

        print "Finding our submitted bugs...\n";
        $bugs = $self->find_my_submissions;
    }
    else {

        # go after the ones on the command line...
        # FIXME should probably do some sanity checking here...
        $bugs = $self->_bz->bugs($args);
    }

    print "Found bugs $bugs.\n\n";

    my $dir  = $self->tmpdir;
    my $root = $self->cvs_root;

    BUG_LOOP:
    for my $bug ($bugs->bugs) {

        my $pkg = $bug->package_name;

        print "Checking $bug ($pkg)...\n";
        do { print "$pkg ($bug) not ready to be imported.\n\n"; next BUG_LOOP }
            unless $bug->ready_for_import;

        print "$bug has been approved, branched, and is ready for CVS import.\n";
        next BUG_LOOP unless ($self->yes || prompt "Import $bug? ", -YyNn1);

        my $srpm_file;
        if ($self->yes || prompt 'Look SRPM in the review tix? ', -YyNn1) {

            print "\nSearching for latest SRPM...\n";
            my @uris = $bug->grep_uris(sub { /\.src\.rpm$/ });
            my $srpm_uri;
            if    (@uris == 1) { $srpm_uri = $uris[0]                      }
            elsif (@uris  > 1) { $srpm_uri = $self->_pick_srpm_uri(@uris)  }
            else               { die "no srpm uris in $bug?!\n"           } 

            print "Using $srpm_uri.\nFetching...\n";
            my $r = URI::Fetch->fetch($srpm_uri) || die URI::Fetch->errstr;
            my @parts = $srpm_uri->path_segments;
            $srpm_file = file($dir, $parts[-1]);
            write_file "$srpm_file", $r->content;
        }
        else {

            do { $srpm_file = file Complete('SRPM filename? ') }
                until $srpm_file && $srpm_file->stat;
            
            print "Using $srpm_file.\n";
        }

        # sanity check; make sure our srpm corresponds to the correct package
        my $srpm = Archive::RPM->new($srpm_file) || die;
        die $srpm_file->basename . " does not appear to be for $pkg?!\n"
            if $srpm->name ne $pkg;

        chdir "$dir";
        $self->_run(
            "cvs -d $root co $pkg && cd $pkg && make common",
            "\nChecking out $pkg module from cvs ($dir)",
        );

        $self->enqueue_job(Fedora::App::ReviewTool::Task->new(
            job  => sub { $self->_import_devel($dir, $srpm) },
            desc => "Import $pkg on devel (rawhide)",
        ));

        # FIXME!
        for my $branch ('F-9', 'F-10', 'F-11') {

            # queue up a branch build job to run...
            $self->enqueue_job(Fedora::App::ReviewTool::Task->new(
                job  => sub { $self->_import_branch($branch, $dir, $srpm) },
                desc => "Import $pkg on $branch",
            ));
        }

        if ($self->yes || prompt "Close $bug after import? ", -YyNn1) {

            $self->enqueue_job(Fedora::App::ReviewTool::Task->new(
                job  => sub { _close($bug) }, 
                desc => "Close $bug ($pkg)",
            ));
        }
        else { print "$bug will NOT be closed.\n\n" }
    }

    # review what we're going to do, and ask OK
    print $self->app->import_task_review(jobs => [ $self->jobs ]);
    return unless $self->yes || prompt 'Execute tasks? ', -YyNn1;


    # FIXME hard limit right now
    $self->max_workers(3);
    for (1..3) { 
        #$self->spawn($self->dequeue_job) }
        my $job = $self->dequeue_job;
        INFO 'Queueing: ' . $job->desc;
        $self->spawn($job->job);
    }

    POE::Kernel->run;
    return;
}

sub _usage_format {
    return 'usage: %c close %o';
}

sub _run {
    my ($self, $cmd, $msg) = @_;

    print "$msg...\n" if $msg;

    # force a subshell so redirect works correctly for compound statements
    my $out = `($cmd) 2>&1`;

    return unless $?;

    # something Bad happened if we're here
    die "Command failed: $?\n";
}

sub _import_branch {
    my ($self, $branch, $dir, $srpm) = @_;
    my $pkg = $srpm->name;
    (my $verrel = $srpm->as_nvre) =~ s/^.*://;
    my $root = $self->cvs_root;

    warn $srpm->rpm . ", $pkg, $branch, $verrel";
    my $cvs_cmd = "echo | ./cvs-import.sh -m 'Initial import.'";
    print "Importing and building in $branch...\n\n";
    chdir "$dir/$pkg/common";
    system "$cvs_cmd -b $branch " . $srpm->rpm;
    chdir "$dir/$pkg/$branch";
    system "cvs update";
    system "make build";

    # FIXME has to be a better way
    #my $build = `make verrel`;
    #chomp $build;

    # let's see if this works...
    $self->submit_bodhi_newpackage($verrel);

    print "\n\n$branch import done.\n\n";

    return;
}

sub _import_devel {
    my ($self, $dir, $srpm) = @_;
    my $pkg = $srpm->name;
    my $root = $self->cvs_root;
        
    chdir "$dir";
    $self->_run(
        "cvs -d $root co $pkg && cd $pkg && make common",
        "\nChecking out $pkg module from cvs ($dir)",
    );

    print "\nImporting and building in devel...\n\n";
    my $cvs_cmd = "echo | ./cvs-import.sh -m 'Initial import.'";

    chdir "$dir/$pkg/common";
    ##$self->_run("$cvs_cmd -b devel " . $srpm->rpm);
    chdir "$dir/$pkg/devel";
    $self->_run("cvs update && make build");

    return;
}

sub _close { 
    shift->close_nextrelease(comment => 'Thanks for the review! :-)')
}

################## worker routines

sub worker_manager_start { INFO 'started worker manager'       }
sub worker_manager_stop  { INFO 'stopped worker manager'       }
sub max_workers_reached  { INFO 'maximum worker count reached' }

sub worker_stdout  { shift; INFO  join ' ', @_; }
sub worker_stderr  { shift; WARN  join ' ', @_; }
sub worker_error   { shift; ERROR join ' ', @_; }
sub worker_started { shift; INFO  join ' ', @_; } 
sub sig_child      { shift; INFO  join ' ', @_; }

sub worker_done    { 
    # shift; INFO  join ' ', @_; } 
    my $self = shift @_;

    INFO  join ' ', @_; 
    
    ### kick off another job if we're able to...
    while (!$self->check_worker_threashold && $self->has_jobs) {

        my $job = $self->dequeue_job;
        INFO 'Queueing: ' . $job->desc;
        $self->spawn($job->job);
    }

    return;
} 

1;

__END__

=head1 NAME

Fedora::App::ReviewTool::Command::import - [submitter] import packages

=head1 DESCRIPTION

Import packages that have been reviewed and branched.

=head1 SEE ALSO

L<reviewtool>, L<Fedora::App::ReviewTool>

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



