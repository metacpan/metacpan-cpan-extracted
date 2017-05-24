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

#TODO This should be split into separate modules
#ScheduleJobs
#ResolveArray

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

has batch_tags => (
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
        $self->app_log->fatal(
            'There was a problem creating your schedule. Aborting mission!');
        exit 1;
    }

}

=head3 sanity_check_schedule

Run a sanity check on the schedule. All the job deps should have existing job names

=cut

sub sanity_check_schedule {
    my $self = shift;

    #$DB::single = 2;

    my @jobnames = keys %{ $self->graph_job_deps };
    @jobnames = sort(@jobnames);
    my $search = 1;
    my $t      = Text::ASCIITable->new();

    my $x = 0;

    my @rows = ();

    #Search the dependencies for matching jobs
    foreach my $job (@jobnames) {
        my $row = [];
        my $ref = $self->graph_job_deps->{$job};
        push( @$row, $job );

        my $y = 0;
        my $depstring;

        #TODO This should be a proper error
        foreach my $r (@$ref) {

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
            else {
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

    #Format the table
    if ( !$search ) {
        $t->setCols( [ "JobName", "Deps", "Suggested" ] );
        map { $t->addRow($_) } @rows;
        $self->app_log->fatal(
            'There were one or more problems with your job schedule.');
        $self->app_log->warn(
            "Here is your tabular dependency list in alphabetical order");
    }
    else {
        $t->setCols( [ "JobName", "Deps", "Task Count" ] );
        map { $t->addRow($_) } @rows;
        $self->app_log->info(
            "Here is your tabular dependency list in alphabetical order");
    }

    $self->app_log->info( "\n\n" . $t );

    return $search;
}

=head3 chunk_commands

Chunk commands per job into batches

#TODO Clean this up

=cut

sub chunk_commands {
    my $self = shift;

    #$DB::single = 2;
    $self->reset_cmd_counter;
    $self->reset_batch_counter;

    return if $self->has_no_schedules;

    $self->clear_scheduler_ids();

    foreach my $job ( $self->all_schedules ) {

        $self->current_job($job);

        next unless $self->jobs->{ $self->current_job };

        $self->reset_cmd_counter;

        my $commands_per_node =
          $self->jobs->{ $self->current_job }->commands_per_node;

        my @cmds = @{ $self->parse_cmd_file };

        $self->jobs->{ $self->current_job }->{batch_index_start} =
          $self->batch_counter;

        if ( !$self->jobs->{ $self->current_job }->can('count_cmds') ) {
            warn
"You seem to be mixing and matching job dependency declaration types! Here there be dragons! We are dying now.\n";
            exit 1;
        }
        next unless $self->jobs->{ $self->current_job }->cmd_counter;

        #Replace this with function that will get cmds from our tmp file
        my $iter = natatime $commands_per_node, @cmds;

        $self->assign_batches($iter);
        $self->assign_batch_stats(scalar @cmds);

        $self->jobs->{ $self->current_job }->{batch_index_end} =
          $self->batch_counter - 1;
        $self->inc_job_counter;

        my $batch_index_start =
          $self->jobs->{ $self->current_job }->{batch_index_start};
        my $batch_index_end =
             $self->jobs->{ $self->current_job }->{batch_index_end}
          || $self->jobs->{ $self->current_job }->{batch_index_start};

        # TODO Update this - they should both use the same method
        my $number_of_batches;
        if ( !$self->use_batches ) {

            $number_of_batches =
              resolve_max_array_size( $self->max_array_size, $commands_per_node,
                $self->jobs->{ $self->current_job }->cmd_counter );
        }
        else {

            $self->max_array_size($commands_per_node);

            $number_of_batches =
              resolve_max_array_size( $self->max_array_size,
                $self->jobs->{ $self->current_job }->cmd_counter,
                $commands_per_node );
        }
        $self->jobs->{ $self->current_job }->{num_job_arrays} =
          $number_of_batches;

        $self->return_ranges( $batch_index_start, $batch_index_end,
            $number_of_batches );

    }

    $self->reset_job_counter;
    $self->reset_cmd_counter;
    $self->reset_batch_counter;
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
    my $number_of_batches = shift;
    my $cmd_size          = shift;

    if ( ( $cmd_size / $number_of_batches ) <= ( $max_array_size + 1 ) ) {
        return $number_of_batches;
    }

    $number_of_batches = $cmd_size / ( $max_array_size + 1 );

    return POSIX::ceil($number_of_batches);
}

sub return_ranges {
    my $self        = shift;
    my $batch_start = shift;
    my $batch_end   = shift;

    #walk is the ret value from resolve_max_array_size
    my $walk = shift;

    my $new_array;
    if ( $walk == 1 ) {
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
    my $self = shift;
    my $cmd_count = shift;

    foreach my $batch ( @{ $self->jobs->{ $self->current_job }->batches } ) {
        $self->current_batch($batch);
        #How does this work?
        $self->inc_cmd_counter( $self->commands_per_node );

        $self->job_stats->collect_stats( $self->batch_counter,
            $self->cmd_counter, $self->current_job );

        $self->inc_batch_counter;
        $self->reset_cmd_counter;
    }
}

=head3 assign_batches

Each jobtype has one or more batches
iterate over the the batches to get some data and assign s

=cut

sub assign_batches {
    my $self = shift;
    my $iter = shift;

    my $x = 0;
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
            cmd_count => scalar @vals,
          );

        $self->jobs->{ $self->current_job }->add_batches($batch_ref);
        $self->jobs->{ $self->current_job }->submit_by_tags(1)
          if @{$batch_tags};

        $x++;
    }

    $self->jobs->{ $self->current_job }->{batch_count} = $x;
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

=head3 process_all_batch_deps

=cut

sub process_all_batch_deps {
    my $self = shift;

    return unless $self->jobs->{ $self->current_job }->submit_by_tags;
    return unless $self->jobs->{ $self->current_job }->has_deps;

    my $batch_tags      = $self->batch_tags->{ $self->current_job };
    my $scheduler_index = {};

    foreach my $dep ( @{ $self->jobs->{ $self->current_job }->deps } ) {
        next unless $self->jobs->{$dep}->submit_by_tags;
        my $dep_tags = $self->batch_tags->{$dep};

#If they are the same - and they probably are - each element of the array depends upon the same index in the dep array
        if ( check_equal_batch_tags( $batch_tags, $dep_tags ) ) {
            my $sched_array = build_equal_batch_tags( scalar @{$batch_tags} );
            $scheduler_index->{$dep} = $sched_array;
        }
        else {
            my $sched_array =
              build_unequal_batch_tags( $batch_tags, $dep_tags );
            $scheduler_index->{$dep} = $sched_array;
        }
    }

    return $scheduler_index;
}

=head3 build_unequal_batch_tags

When they are not the same we have to search

=cut

sub build_unequal_batch_tags {
    my $batch_tags = shift;
    my $dep_tags   = shift;

    my @sched_array = ();

    for ( my $x = 0 ; $x < scalar @{$batch_tags} ; $x++ ) {
        my $batch_tag = $batch_tags->[$x];
        my @tarray    = ();
        for ( my $y = 0 ; $y < scalar @{$dep_tags} ; $y++ ) {
            my $dep_tag = $dep_tags->[$y];
            push( @tarray, $y ) if search_tags( $batch_tag, $dep_tag );
        }
        push( @sched_array, \@tarray );
    }

    return \@sched_array;
}

=head3 build_equal_batch_tags

If the arrays are equal, each element depends upon the same element previously

=cut

memoize('build_equal_batch_tags');

sub build_equal_batch_tags {
    my $len = shift;

    $len = $len - 1;
    my @array = map { [$_] } ( 0 .. $len );
    return \@array;
}

=head3 check_equal_batch_tags

If they are the same each element depends upon the same element from the other array

This will probably be true most of the time

=cut

memoize('check_equal_batch_tags');

sub check_equal_batch_tags {
    my $batch_tags = shift;
    my $dep_tags   = shift;

    if ( scalar @{$batch_tags} != scalar @{$dep_tags} ) {
        return 0;
    }
    my $comp = Array::Compare->new;
    for ( my $x = 0 ; $x < scalar @{$batch_tags} ; $x++ ) {
        my $tbatch_tags = $batch_tags->[$x];
        my $tdep_tags   = $dep_tags->[$x];
        if ( !$comp->compare( $tbatch_tags, $tdep_tags ) ) {
            return 0;
        }
    }
    return 1;
}

=head3 process_batch_deps

If a job has one or more job tags it is possible to fine tune dependencies

#HPC jobname=job01
#HPC commands_per_node=1
#TASK tags=Sample1
gzip Sample1
#TASK tags=Sample2
gzip Sample2

#HPC jobname=job02
#HPC jobdeps=job01
#HPC commands_per_node=1
#TASK tags=Sample1
fastqc Sample1
#TASK tags=Sample2
fastqc Sample2

job01 - Sample1 would be submitted as schedulerid 1234
job01 - Sample2 would be submitted as schedulerid 1235

job02 - Sample1 would be submitted as schedulerid 1236 - with dep on 1234 (with no job tags this would be 1234, 1235)
job02 - Sample2 would be submitted as schedulerid 1237 - with dep on 1235 (with no job tags this would be 1234, 1235)

=cut

sub process_batch_deps {
    my $self  = shift;
    my $batch = shift;

    return unless $self->jobs->{ $self->current_job }->submit_by_tags;
    return unless $self->jobs->{ $self->current_job }->has_deps;

    my $tags = $batch->batch_tags;

    return $self->search_batches( $self->jobs->{ $self->current_job }->deps,
        $tags );
}

=head3 search_batches

search the batches for a particular scheduler id

#TODO update this to search across all batches - they are usually the same
instead of per batch, create an array of array for all batches


[['Sample01'], ['Sample03']]

=cut

sub search_batches {
    my $self     = shift;
    my $job_deps = shift;
    my $tags     = shift;

    my $scheduler_ref = {};

    foreach my $dep ( @{$job_deps} ) {
        next unless $self->jobs->{$dep}->submit_by_tags;
        my $dep_batches = $self->jobs->{$dep}->batches;
        $scheduler_ref->{$dep} = search_dep_batch_tags( $dep_batches, $tags );
    }

    return $scheduler_ref;
}

=head3 search_dep_batch_tags

=cut

memoize('search_dep_batch_tags');

sub search_dep_batch_tags {
    my $dep_batches = shift;
    my $tags        = shift;

    my @scheduler_index = ();
    my $x               = 0;
    foreach my $dep_batch ( @{$dep_batches} ) {
        push( @scheduler_index, $x )
          if  search_tags( $dep_batch->batch_tags, $tags );
        $x++;
    }

    return \@scheduler_index;
}

=head3 search_tags

#TODO Update this - we shouldn't check for searches and search separately
Check for matching tags. We match against any

job02 depends on job01

job01 batch01 has tags Sample1,Sample2
job01 batch02 has tags Sample3

job02 batch01 has tags Sample1

job02 batch01 depends upon job01 batch01 - because it has an overlap
But not job01 batch02

=cut

memoize('search_tags');

sub search_tags {
    my $batch_tags  = shift;
    my $search_tags = shift;

    foreach my $batch_tag ( @{$batch_tags} ) {
        my $s = first { "$_" eq $batch_tag } @{$search_tags};
        return $s if $s;
    }

    return 0;
}

1;
