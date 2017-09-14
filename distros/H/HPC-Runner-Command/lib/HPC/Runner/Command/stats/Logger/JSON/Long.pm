package HPC::Runner::Command::stats::Logger::JSON::Long;

use Moose::Role;
use namespace::autoclean;

use JSON;
use File::Slurp;

sub get_tasks {
    my $self          = shift;
    my $submission_id = shift;
    my $jobname       = shift;

    ##Get the running tasks
    my $running_file =
      File::Spec->catdir( $self->data_dir, $jobname, 'running.json' );

    my $running = {};
    if ( -e $running_file ) {
        my $running_json = read_file($running_file);
        $running = decode_json($running_json);
    }

    my $complete = {};
    my $complete_file =
      File::Spec->catdir( $self->data_dir, $jobname, 'complete.json' );
    if ( -e $complete_file ) {
        my $complete_json = read_file($complete_file);
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
