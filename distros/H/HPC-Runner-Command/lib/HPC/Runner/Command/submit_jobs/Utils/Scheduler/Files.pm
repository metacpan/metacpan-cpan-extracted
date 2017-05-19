package HPC::Runner::Command::submit_jobs::Utils::Scheduler::Files;

use Moose::Role;
use IO::File;
#Travis test fails without this
use IO::Interactive;
use File::Path qw(make_path remove_tree);
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

=head2 Subroutines

=cut

=head3 resolve_project

=cut

sub resolve_project {
    my $self    = shift;
    my $counter = shift;

    my $jobname;

    if ( $self->has_project ) {
        $jobname
            = $self->project . "_" . $counter . "_" . $self->current_job;
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

    $DB::single = 2;

    my ( $batch_counter, $job_counter ) = $self->prepare_counter;

    make_path( $self->outdir ) unless -d $self->outdir;

    #If we are using job arrays there will only be one per batch

    my $jobname = $self->resolve_project($job_counter);

    if ( $self->use_batches ) {
        $self->slurmfile(
            $self->outdir . "/$jobname" . "_" . $batch_counter . ".sh" );
    }
    else {
        $self->slurmfile( $self->outdir . "/$jobname" . ".sh" );
    }
}

=head3 prepare_batch_files_array

Write out the batch files

For job arrays this is 1 per array element

For (legacy) batches 1 file per batch

=cut

sub prepare_batch_files_array {
    my $self              = shift;
    my $batch_index_start = shift;
    my $batch_index_end   = shift;

    #Each jobtype has 1 or more batches based on max_array_size
    $DB::single = 2;
    my $job_start = $self->jobs->{ $self->current_job }->{batch_index_start};

    #Get batch index as array
    #BatchIndexStart 11 BatchIndexEnd 20    (size 10)
    #Range 0, 9                             (size 10)

    my @batch_indexes = ( $batch_index_start .. $batch_index_end );
    my $len           = scalar @batch_indexes;

    for ( my $x = 0; $x < $len; $x++ ) {

        #Get the current batch/array element
        my $real_batch_index = $batch_indexes[$x] - $job_start;
        $self->current_batch(
            $self->jobs->{ $self->current_job }->batches->[$real_batch_index]
        );

        #TODO counters are messed up somewhere...
        next unless $self->current_batch;
        
        #Assign the counters
        my $job_counter   = sprintf( "%03d", $self->job_counter );
        my $array_counter = sprintf( "%03d", $self->array_counter );

        my $jobname = $self->resolve_project($job_counter);

        $self->cmdfile(
            $self->outdir . "/$jobname" . "_" . $array_counter . ".in" );

        #Write the files
        $self->write_batch_file($self->current_batch->batch_str);

        $self->inc_array_counter;
    }
}

sub write_batch_file {
    my $self = shift;
    my $command  = shift;

    make_path( $self->outdir ) unless -d $self->outdir;

    my $fh = IO::File->new( $self->cmdfile, q{>} )
        or die print "Error opening file  "
        . $self->cmdfile . "  "
        . $! . "\n";

    print $fh $command if defined $fh && defined $command;
    $fh->close;
}

1;
