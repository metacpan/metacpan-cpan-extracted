package    # hide from PAUSE
  Gearman::Driver::Test::XxX;

use base qw(Gearman::Driver::Worker);
use Moose;

sub process_name {
    my ( $self, $orig, $job_name ) = @_;
    return "$orig ($job_name)";
}

sub scale_image : Job : ProcessGroup(image_worker) {
}

sub convert_image : Job : ProcessGroup(image_worker) {
}

sub jobfoo : Job : MinProcesses(5) : MaxProcesses(5) {
}

sub jobbar : Job {
}

sub job1 : Job : ProcessGroup(jobn) : MinProcesses(5) : MaxProcesses(5) {
    return 'job1';
}

sub job2 : Job : ProcessGroup(jobn) {
    return 'job2';
}

sub job3 : Job : ProcessGroup(jobn) {
    return 'job3';
}

sub job4 : Job : ProcessGroup(jobn) {
    return 'job4';
}

sub job5 : Job : ProcessGroup(jobn) {
    return 'job5';
}

1;
