package HPC::Runner::Command::submit_jobs::Utils::Scheduler::ResolveDeps;
use 5.010;

use Moose::Role;
use List::MoreUtils qw(natatime);
use List::Util qw(first);
use Storable qw(dclone);
use Data::Dumper;
use Algorithm::Dependency::Source::HoA;
use Algorithm::Dependency::Ordered;
use HPC::Runner::Command::submit_jobs::Utils::Scheduler::Batch;
use POSIX;
use String::Approx qw(amatch);
use Text::ASCIITable;
use Try::Tiny;
use Memoize;
use Array::Compare;

with
'HPC::Runner::Command::submit_jobs::Utils::Scheduler::ResolveDeps::BuildTaskDeps';

=head1 HPC::Runner::Command::submit_jobs::Utils::Scheduler::ResolveDeps;

Once we have parsed the input file parse each job_type for job_batches

=head2 Attributes

=cut

=head3 schedule

Schedule our jobs

=cut

has 'schedule' => (
    traits  => ['Array'],
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { [] },
    handles => {
        all_schedules    => 'elements',
        add_schedule     => 'push',
        has_schedules    => 'count',
        clear_schedule   => 'clear',
        has_no_schedules => 'is_empty',
    },
);

has 'batch_tags' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        return {};
    }
);

=head2 Subroutines

=cut

#Just putting this here
#scontrol update job=9314_2 Dependency=afterok:9320_1

=head3 schedule_jobs

Use Algorithm::Dependency to schedule the jobs

Catch any scheduling errors not caught by the sanity check

=cut

sub schedule_jobs {
    my $self = shift;

    my $source =
      Algorithm::Dependency::Source::HoA->new( $self->graph_job_deps );

    my $dep = Algorithm::Dependency::Ordered->new(
        source   => $source,
        selected => []
    );

    try {
        $self->schedule( $dep->schedule_all );
    }
    catch {
        # $DB::single=2;
        $self->app_log->fatal( 'There was a problem creating your schedule.'
              . ' Please ensure there are no cyclic dependencies. '
              . 'Aborting mission!' );
        $self->app_log->fatal($@);
        exit 1;
    }

}

=head3 sanity_check_schedule

Run a sanity check on the schedule. All the job deps should have existing job names

=cut

sub sanity_check_schedule {
    my $self = shift;

    # $DB::single = 2;

    my @jobnames = keys %{ $self->graph_job_deps };
    @jobnames = sort(@jobnames);
    my $search = 1;
    my $t      = Text::ASCIITable->new();

    my $x = 0;

    my @rows = ();

    #Search the dependencies for matching jobs
    foreach my $job (@jobnames) {
        # $DB::single = 2;
        my $row = [];
        my $ref = $self->graph_job_deps->{$job};
        push( @$row, $job );

        my $y = 0;
        my $depstring;

        #TODO This should be a proper error
        foreach my $r (@$ref) {
            # $DB::single = 2;

            if ( !exists $self->graph_job_deps->{$r} ) {
                $ref->[$y] = "**$r**";

                $self->app_log->fatal("Job dep $r is not in joblist.");
                $search = 0;

                my @matches = amatch( $r, @jobnames );
                if (@matches) {
                    push( @$row, join( ", ", @matches ) );
                    $self->app_log->warn( "Did you mean ( "
                          . join( ", ", @matches )
                          . "  ) instead of $r?" );
                }
                else {
                    $self->app_log->fatal(
                        "No potential matches were found for dependency $r");
                }
            }
            elsif ( "$r" eq "$job" ) {
                $self->app_log->fatal(
"Job dep $r deps upon itself. This schedule is not possible."
                );
            }

            $y++;
        }

        $depstring = join( ", ", @{$ref} );
        push( @$row, $depstring );

        my $count_cmd = $self->jobs->{$job}->cmd_counter;
        push( @$row, $count_cmd );

        push( @rows, $row );
        $x++;
    }

    #IF there are no broken dependencies - return
    return $search if $search;

    $t->setCols( [ "JobName", "Deps", "Suggested" ] );
    map { $t->addRow($_) } @rows;
    $self->app_log->fatal(
        'There were one or more problems with your job schedule.');
    $self->app_log->warn(
        "Here is your tabular dependency list in alphabetical order");
    $self->app_log->info( "\n\n" . $t );

    return $search;
}

=head3 chunk_commands

Chunk commands per job into batches

#TODO Clean this up

=cut

sub chunk_commands {
    my $self = shift;

    $self->reset_cmd_counter;
    $self->reset_batch_counter;

    return if $self->has_no_schedules;

    $self->clear_scheduler_ids();

    $self->chunk_commands_jobs;

    $self->reset_job_counter;
    $self->reset_cmd_counter;
    $self->reset_batch_counter;

}

sub chunk_commands_jobs {
    my $self = shift;

    foreach my $job ( $self->all_schedules ) {

        $self->current_job($job);

        next unless $self->jobs->{ $self->current_job };

        $self->reset_cmd_counter;
        $self->reset_batch_counter;

        # $self->jobs->{ $self->current_job }->{batch_index_start} =
        #   $self->batch_counter;

        $self->chunk_commands_jobs_check;
        next unless $self->jobs->{ $self->current_job }->cmd_counter;

        my $commands_per_node =
          $self->jobs->{ $self->current_job }->commands_per_node;

        my @cmds = @{ $self->parse_cmd_file };

        if($commands_per_node > scalar @cmds){
          $commands_per_node = scalar @cmds;
          $self->jobs->{$self->current_job}->commands_per_node($commands_per_node);
        }

        my $iter = natatime $commands_per_node, @cmds;

        $self->assign_batches($iter);
        $self->assign_batch_stats( scalar @cmds );

        $self->inc_job_counter;

        my $batch_index_start =
          $self->jobs->{ $self->current_job }->{batch_index_start};

        my $batch_index_end =
             $self->jobs->{ $self->current_job }->{batch_index_end}
          || $self->jobs->{ $self->current_job }->{batch_index_start};

        my $number_of_batches =
          $self->jobs->{ $self->current_job }->{num_job_arrays};

        $self->return_ranges( $batch_index_start, $batch_index_end,
            $number_of_batches );
    }
}

sub chunk_commands_jobs_check {
    my $self = shift;

    if ( !$self->jobs->{ $self->current_job }->can('count_cmds') ) {
        warn
"You seem to be mixing and matching job dependency declaration types! Here there be dragons! We are dying now.\n";
        exit 1;
    }
}

sub assign_num_max_array {
    my $self = shift;
    my $job  = shift;

    my $commands_per_node = $self->jobs->{$job}->commands_per_node;

    $self->max_array_size(1) if $self->use_batches;

    my $number_of_batches =
      resolve_max_array_size( $self->max_array_size, $commands_per_node,
        $self->jobs->{$job}->cmd_counter );

    $self->jobs->{$job}->{num_job_arrays} = $number_of_batches;
}

sub parse_cmd_file {
    my $self = shift;

    my $fh = $self->job_files->{ $self->current_job };
    seek( $fh, 0, 0 );

    my @cmds = ();
    my $cmd  = '';
    while (<$fh>) {
        my $line = $_;

        next unless $line;

        $cmd .= $line;
        next if $line =~ m/\\$/;
        next if $line =~ m/^#/;
        push( @cmds, $cmd );
        $cmd = '';
    }
    return \@cmds;
}

#TODO put arrays in oen place, batches in another

=head3 resolve_max_array_size

Arrays should not be greater than the max_array_size variable

If it is they need to be chunked up into various arrays

Each array becomes its own 'batch'

=cut

memoize('resolve_max_array_size');

sub resolve_max_array_size {
    my $max_array_size    = shift;
    my $commands_per_node = shift;
    my $cmd_size          = shift;

    my $num_arrays = $cmd_size / $max_array_size;
    $num_arrays = $num_arrays / $commands_per_node;

    my $ceil = POSIX::ceil($num_arrays);

    return POSIX::ceil($num_arrays);
}

#TODO get rid of this
sub return_ranges {
    my $self = shift;

    my $batch_start = shift;
    my $batch_end   = shift;
    my $num_arrays  = shift;

    my $new_array;
    if ( $num_arrays == 1 ) {
        $new_array = {
            'batch_index_start' => $batch_start,
            'batch_index_end'   => $batch_end
        };
        $self->jobs->{ $self->current_job }->add_batch_indexes($new_array);
        return;
    }

    my $x = $batch_start;

    my $array_ref = [];
    while ( $x <= $batch_end ) {
        my $t_batch_end = $x + $self->max_array_size - 1;
        if ( $t_batch_end < $batch_end ) {
            $new_array = {
                'batch_index_start' => $x,
                'batch_index_end'   => $t_batch_end,
            };
        }
        else {
            $new_array = {
                'batch_index_start' => $x,
                'batch_index_end'   => $batch_end,
            };
        }
        $x += $self->max_array_size;
        $self->jobs->{ $self->current_job }->add_batch_indexes($new_array);
    }

    return;
}

=head3 assign_batch_stats

Iterate through the batches to assign stats (number of batches per job, number of tasks per command, etc)

=cut

sub assign_batch_stats {
    my $self      = shift;
    my $cmd_count = shift;

    $self->jobs->{ $self->current_job }->{cmd_start} = $self->total_cmd_counter;
    foreach my $batch ( @{ $self->jobs->{ $self->current_job }->batches } ) {
        $self->current_batch($batch);

        #Counter per job
        $self->inc_cmd_counter(
            $self->jobs->{ $self->current_job }->commands_per_node );

        #Total counter
        $self->inc_total_cmd_counter(
            $self->jobs->{ $self->current_job }->commands_per_node );

        $self->job_stats->collect_stats( $self->batch_counter,
            $self->cmd_counter, $self->current_job );

        $self->inc_batch_counter;
        $self->reset_cmd_counter;
    }
}

=head3 assign_batches

Each jobtype has one or more batches
iterate over the the batches to get some data and assign s

For batches - each HPC::Runner::Command::submit_jobs::Utils::Scheduler::Batch

is an element in the array
Each element could has commands_per_node tasks

=cut

sub assign_batches {
    my $self = shift;
    my $iter = shift;

    my $x = 0;
    my $y = 1;
    $self->jobs->{ $self->current_job }->{batch_index_start} = 1;
    while ( my @vals = $iter->() ) {

        my $batch_cmds = \@vals;
        my $batch_tags = $self->assign_batch_tags($batch_cmds);
        push(
            @{ $self->batch_tags->{ $self->current_job } },
            dclone($batch_tags)
        );

        ##TODO Possibly get rid of this in next release?
        my $batch_ref =
          HPC::Runner::Command::submit_jobs::Utils::Scheduler::Batch->new(
            batch_tags => $batch_tags,
            job        => $self->current_job,
            cmd_count  => scalar @vals,
            cmd_start  => $y,
          );

        $self->jobs->{ $self->current_job }->add_batches($batch_ref);
        $self->jobs->{ $self->current_job }->submit_by_tags(1)
          if @{$batch_tags};

        $x++;
        $y = $y + $self->jobs->{ $self->current_job }->commands_per_node;
    }

    $self->jobs->{ $self->current_job }->{batch_index_end} = $x;
}

=head3 assign_batch_tags

Parse the #TASK lines to get batch_tags
#TODO We should do this while are reading in the file

=cut

sub assign_batch_tags {
    my $self       = shift;
    my $batch_cmds = shift;

    my @batch_tags = ();

    foreach my $lines ( @{$batch_cmds} ) {

        my @lines = split( "\n", $lines );

        foreach my $line (@lines) {

            #TODO Change this to TASK
            next unless $line =~ m/^#TASK/;
            chomp($line);
            my ( $t1, $t2 ) = parse_meta($line);

            next unless $t2;
            my @tags = split( ",", $t2 );

            if ( $t1 eq 'tags' ) {
                map { push( @batch_tags, $_ ) if $_ } @tags;
            }
            else {
                $self->app_log->warn(
                        'You are using an unknown directive with #TASK '
                      . "\n$line\nDirectives should be one of 'tags' or 'deps'"
                );
            }
        }
    }

    return \@batch_tags;
}

memoize('parse_meta');

sub parse_meta {
    my $line = shift;
    my ( @match, $t1, $t2 );

    @match = $line =~ m/ (\w+)=(.+)$/;
    ( $t1, $t2 ) = ( $match[0], $match[1] );

    return ( $t1, $2 );
}

1;
