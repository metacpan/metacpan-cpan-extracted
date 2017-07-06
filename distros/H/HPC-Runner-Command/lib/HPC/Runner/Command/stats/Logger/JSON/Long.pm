use strict;
use warnings;

package HPC::Runner::Command::stats::Logger::JSON::Long;

use Moose::Role;
use namespace::autoclean;

use JSON;
use Data::Dumper;

sub get_tasks {
    my $self          = shift;
    my $submission_id = shift;
    my $jobname       = shift;

    ##Get the running tasks
    my $basename = $self->data_tar->basename('.tar.gz');
    my $running_file =
      File::Spec->catdir( $basename, $jobname, 'running.json' );

    my $running = {};
    if ( $self->archive->contains_file($running_file) ) {
        my $running_json = $self->archive->get_content($running_file);
        $running = decode_json($running_json);
    }

    my $complete = {};
    my $complete_file =
      File::Spec->catdir( $basename, $jobname, 'complete.json' );
    if ( $self->archive->contains_file($complete_file) ) {
        my $complete_json = $self->archive->get_content($complete_file);
        $complete = decode_json($complete_json);
    }

    my $total_tasks = [];
    foreach ( sort { $a <=> $b } keys(%{$running}) ) {
      push(@{$total_tasks}, $running->{$_});
    }
    foreach ( sort { $a <=> $b } keys(%{$complete}) ) {
      push(@{$total_tasks}, $complete->{$_});
    }

    return $total_tasks;
}

1;
