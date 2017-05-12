use strict;
use Test::More;

$ENV{PATH} = "./bin:../bin:$ENV{PATH}";

plan tests => 14;

use_ok('Event::ExecFlow');
use_ok('Event::ExecFlow::Frontend::Term');
use_ok('Event::ExecFlow::Scheduler::SimpleMax;');

run_test();

exit;

sub run_test {
    my $scheduler = Event::ExecFlow::Scheduler::SimpleMax->new(
        max => 5
    );

    my $sleeps1 = build_sleeps($scheduler, 1);
    my $sleeps2 = build_sleeps($scheduler, 2);
    
    my $code_was_executed;
    my $code = Event::ExecFlow::Job::Code->new (
        name    => "code",
        title   => "Some code",
        code    => sub {
            $code_was_executed = 1;
            print "CODE WAS EXECUTED\n";
        },
        depends_on  => [ "sleeps_1" ],
    );

    my $job = Event::ExecFlow::Job::Group->new (
        name        => "all",
        title       => "All jobs under the hood",
        jobs        => [
            $sleeps1, $code, $sleeps2
        ],
        parallel    => 1,
        scheduler   => $scheduler,
    );

    my $frontend = Event::ExecFlow::Frontend::Term->new;
    $frontend->set_quiet(1);
    $frontend->start_job($job);

    ok($code_was_executed, "Job succesfully finished");
}

sub build_sleeps {
    my ($scheduler, $nr) = @_;

    my @jobs;

    my $max = 5;
    my $dur = 2;

    for my $i ( 1..$max ) {
        push @jobs, Event::ExecFlow::Job::Command->new (
            name            => "sleep_${nr}_$i",
            title           => "Take a sleep ($i/$max)",
            command         => "perl -e'\$|=1;for(1..$dur){print qq(\$_\\n);sleep 1}'",
            progress_max    => $dur,
            progress_parser => qr/(\d+)/,
            post_callbacks  => sub {
                my ($job) = @_;
                ok($job->get_state eq 'finished',"Job $i executed Ok");
            },
        );
    }
    
    return Event::ExecFlow::Job::Group->new (
        name        => "sleeps_$nr",
        title       => "A bunch of sleeps",
        jobs        => \@jobs,
        parallel    => 1,
        scheduler   => $scheduler,
    );
}

