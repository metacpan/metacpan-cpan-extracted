package HPC::Runner::Command::stats::Logger::JSON::Long;

use Moose::Role;
use namespace::autoclean;

with 'HPC::Runner::Command::stats::Logger::JSON::Utils';

use JSON;
use File::Glob;
use File::Slurp;

sub get_tasks {
    my $self          = shift;
    my $submission_id = shift;
    my $jobname       = shift;

    my $running = $self->read_json_files($submission_id, $jobname);

    my $total_tasks = [];
    foreach ( sort { $a <=> $b } keys( %{$running} ) ) {
        push( @{$total_tasks}, $running->{$_} );
    }

    return $total_tasks;
}


1;
