package HPC::Runner::Command::stats::Logger::JSON::Utils;

use Moose::Role;
use namespace::autoclean;

use JSON;
use Try::Tiny;
use File::Slurp;

sub read_json_files {
    my $self          = shift;
    my $submission_id = shift;
    my $jobname       = shift;

    my @json_files =
      glob( File::Spec->catdir( $self->data_dir, $jobname, '*json' ) );

    my $running = {};
    foreach my $file (@json_files) {
        my $running_json = read_file($file);
        my $trun         = decode_json($running_json);
        foreach my $key ( keys %{$trun} ) {
            $running->{$key} = $trun->{$key};
        }
    }

    return $running;
}

1;
