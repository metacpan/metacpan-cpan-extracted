package HPC::Runner::Command::submit_jobs::Utils::Scheduler::ResolveDeps::BuildTaskDeps;

use Moose::Role;

use Memoize;
use List::MoreUtils 0.428 qw(first_index);
use Array::Compare;
use List::Util qw(first);

=head1 HPC::Runner::Command::submit_jobs::Utils::Scheduler::ResolveDeps::BuildTaskDeps

Iterate over the batches and get the the matching TASK_TAGS

=cut

=head3 process_all_batch_deps

=cut

sub process_all_batch_deps {
    my $self = shift;

    return if $self->jobs->{ $self->current_job }->submission_failure;
    return unless $self->jobs->{ $self->current_job }->submit_by_tags;
    return unless $self->jobs->{ $self->current_job }->has_deps;

    my $batch_tags      = $self->batch_tags->{ $self->current_job };
    my $scheduler_index = {};

    foreach my $dep ( @{ $self->jobs->{ $self->current_job }->deps } ) {
        next unless $self->jobs->{$dep}->submit_by_tags;
        my $dep_tags = $self->batch_tags->{$dep};

        ##If they are the same AND UNIQ - and they probably are -
        ## each element of the array depends upon the same index in the dep array
        # if ( check_equal_batch_tags( $batch_tags, $dep_tags ) ) {
        #     my $sched_array = build_equal_batch_tags( scalar @{$batch_tags} );
        #     $scheduler_index->{$dep} = $sched_array;
        # }
        # else {
        #     my $sched_array =
        #       build_unequal_batch_tags( $batch_tags, $dep_tags );
        #     $scheduler_index->{$dep} = $sched_array;
        # }
            my $sched_array =
              build_unequal_batch_tags( $batch_tags, $dep_tags );
            $scheduler_index->{$dep} = $sched_array;
    }

    return $scheduler_index;
}

##TODO Task Tags should go in its own module

=head3 build_unequal_batch_tags

When they are not the same we have to search

=cut

memoize('build_unequal_batch_tags');

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

#TODO Update this - it does not work when we have groups!

=cut

memoize('build_equal_batch_tags');

sub build_equal_batch_tags {
    my $len = shift;

    $len = $len - 1;
    my @array = map { [$_] } ( 0 .. $len );
    return \@array;
}

=head3 check_equal_batch_tags

If they are the same AND unique each element depends upon the same element from
the other array

TODO - add back in this method to check for unique

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

#TODO separate out all batches vs arrays/tasks

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

##DEPRACATED  - process_all_batch_deps

=cut

sub process_batch_deps {
    my $self  = shift;
    my $batch = shift;

    return if $self->jobs->{ $self->current_job }->submission_failure;
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
          if search_tags( $dep_batch->batch_tags, $tags );
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
