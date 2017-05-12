package    # hide from PAUSE
  Gearman::Driver::Test::Live::Spread;

use base qw(Gearman::Driver::Test::Base::All);
use Moose;
use Gearman::Driver::Test;

has 'gc' => ( is => 'ro' );

sub BUILD {
    my ($self) = @_;
    my ( $host, $port ) = split /:/, $self->server;
    my $test = Gearman::Driver::Test->new();
    $self->{gc} = $test->gearman_client( $host, $port );
}

sub main : Job {
    my ( $self, $job, $workload ) = @_;
    my $result = '';
    for ( 1 .. 5 ) {
        my $res = $self->gc->do_task( "Gearman::Driver::Test::Live::Spread::some_job_$_" => '' );
        $result .= $$res;
    }
    return $result;
}

sub some_job_1 : Job : ProcessGroup(group1) {
    return 1;
}

sub some_job_2 : Job : ProcessGroup(group1) {
    return 2;
}

sub some_job_3 : Job : ProcessGroup(group1) {
    return 3;
}

sub some_job_4 : Job : ProcessGroup(group1) {
    return 4;
}

sub some_job_5 : Job : ProcessGroup(group1) {
    return 5;
}

1;
