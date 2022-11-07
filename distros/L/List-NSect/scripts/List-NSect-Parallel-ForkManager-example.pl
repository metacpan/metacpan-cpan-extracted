#!/usr/bin/perl
use strict;
use warnings;
use Parallel::ForkManager;
use Time::HiRes qw{sleep};
use List::NSect;
use DateTime;

=head1 NAME

List-NSect-Parallel-ForkManager-example.pl - List::NSect Example with Parallel::ForkManager

=head1 DESCRIPTION 

=head2 Group your tasks!

The concept is that forking is fairly expensive and if your tasks are short then you do not want to spend more processing power forking than actually performing tasks.  

=cut

printf "%s: Start\n", DateTime->now;

$|                = 1;
my $MAX_PROCESSES = shift || 5; #try running this with 1 process and see how it performs
my $pm            = Parallel::ForkManager->new($MAX_PROCESSES);
my $tasks         = shift || 100;
#use a hash or an object as the task so you can grow!
my @tasks         = map { {id=>$_, data=>"something", isHashRef=>1} } (1 .. $tasks);
my @sections      = nsect($MAX_PROCESSES => @tasks);

foreach my $section (@sections) {
  $pm->start and next;
  my $i=1;
  foreach my $task (@$section) {
    printf "%s: I'm child %s and I'm working on parent task %3d (child task %2d of %2d)\n", 
             DateTime->now, $$, $task->{"id"}, $i++, scalar(@$section);
    sleep rand 1;
  }
  $pm->finish; 
}

$pm->wait_all_children;

printf "%s: Finished\n", DateTime->now;
