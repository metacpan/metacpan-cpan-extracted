package HPC::Runner::Command::submit_jobs::Utils::Scheduler::Files;

use Moose::Role;
use namespace::autoclean;

use IO::File;

#Travis test fails without this
use IO::Interactive;
use File::Path qw(make_path remove_tree);
use File::Copy;
use File::Spec;
use Data::Dumper;

=head1 HPC::Runner::Command::submit_jobs::Utils::Scheduler::Files

Take care of all file operations

=cut

=head2 Attributes

=cut

=head3 cmdfile

File of commands for mcerunner
Is cleared at the end of each slurm submission

=cut

has 'cmdfile' => (
    traits   => ['String'],
    default  => q{},
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    handles  => { clear_cmdfile => 'clear', },
);

=head3 slurmfile

File generated from slurm template

Job submission file

=cut

has 'slurmfile' => (
    traits   => ['String'],
    default  => q{},
    is       => 'rw',
    isa      => 'Str',
    required => 0,
    handles  => { clear_slurmfile => 'clear', },
);

has job_files => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        return {};
    }
);

=head2 Subroutines

=cut

=head3 resolve_project

=cut

sub resolve_project {
    my $self    = shift;
    my $counter = shift;

    my $jobname;

    if ( $self->has_project ) {
        $jobname = $self->project . "_" . $counter . "_" . $self->current_job;
    }
    else {
        $jobname = $counter . "_" . $self->current_job;
    }

    return $jobname;
}

=head3 prepare_files

=cut

#TODO I think we will get rid of this

sub prepare_files {
    my $self = shift;

    make_path( $self->outdir ) unless -d $self->outdir;

    $self->prepare_sched_file;
}

=head3 prepare_counter

Prepare the counter. It is 001, 002, etc instead of 1, 2 etc

=cut

sub prepare_counter {
    my $self = shift;

    my $batch_counter = $self->batch_counter;
    $batch_counter = sprintf( "%03d", $batch_counter );

    my $job_counter = $self->job_counter;
    $job_counter = sprintf( "%03d", $job_counter );

    return ( $batch_counter, $job_counter );
}

=head3 prepare_sched_files

=cut

sub prepare_sched_file {
    my $self = shift;

    #$DB::single = 2;

    my ( $batch_counter, $job_counter ) = $self->prepare_counter;

    make_path( $self->outdir ) unless -d $self->outdir;

    #If we are using job arrays there will only be one per batch

    my $jobname = $self->resolve_project($job_counter);

    if ( $self->use_batches ) {
        $self->slurmfile(
            File::Spec->catdir($self->outdir , "$jobname" . "_" . $batch_counter . ".sh") );
    }
    else {
        $self->slurmfile( File::Spec->catdir($self->outdir , "$jobname" . ".sh") );
    }
}

=head3 prepare_batch_files_array

Write out the batch files

Old method

For job arrays this is 1 per array element

For (legacy) batches 1 file per batch

New method

One file per job - and we just have a counter to make sure we are on the right task

=cut

sub prepare_batch_files_array {
    my $self = shift;

    # my $job_counter = sprintf( "%03d", $self->job_counter );

    my $job_counter = "000";
    my $jobname     = $self->resolve_project($job_counter);
    my $outfile     = File::Spec->catfile( $self->outdir, $jobname . '.in' );

    if ( !-e $outfile ) {
        copy( $self->job_files->{ $self->current_job }->filename, $outfile )
          or die print "ERROR COPYING $!";
    }

    $self->cmdfile($outfile);
}

#TODO Write a file per job - not per task
# sub write_batch_file {
#     my $self    = shift;
#     my $command = shift;
#
#     make_path( $self->outdir ) unless -d $self->outdir;
#
#     my $fh = IO::File->new( $self->cmdfile, q{>} )
#       or die print "Error opening file  " . $self->cmdfile . "  " . $! . "\n";
#
#     print $fh $command if defined $fh && defined $command;
#     $fh->close;
# }

1;
