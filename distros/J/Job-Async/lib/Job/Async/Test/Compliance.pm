package Job::Async::Test::Compliance;

use strict;
use warnings;

our $VERSION = '0.003'; # VERSION

use parent qw(IO::Async::Notifier);

=head1 NAME

Job::Async::Test::Compliance - verify whether a client+worker pair conform
to the current API.

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Job::Async::Test::Compliance;
 my $loop = IO::Async::Loop->new;
 $loop->add(
  my $compliance = Job::Async::Test::Compliance->new
 );
 eval {
  print "Test result: " . $compliance->test(
   'memory',
   worker => { },
   client => { },
  )->get;
 } or do {
  warn "Compliance test failed: $@\n";
 };

=head1 DESCRIPTION

Provides a compliance test. Might be of use when writing

=cut

use Job::Async;
use Future::Utils qw(fmap0);
use Log::Any qw($log);

sub jobman {
    my ($self) = @_;
    $self->{jobman} //= do {
        $self->add_child(
            my $jobman = Job::Async->new
        );
        $jobman
    };
}

sub test {
    my ($self, $type, %args) = @_;
    my $worker = $self->jobman->worker(
        $type => $args{worker},
    );
    my $client = $self->jobman->client(
        $type => $args{client},
    );
    Future->needs_all(
        $worker->start,
        $client->start,
    )->then($self->curry::weak::start(
        $worker,
        $client
    ))
}

sub start {
    my ($self, $worker, $client) = @_;
    my $start = Time::HiRes::time;
    my $count = 0;
    my @seq = (
        [  0,  1 =>  1 ],
        [  1,  1 =>  2 ],
        [  1,  0 =>  1 ],
        [  1,  1 =>  2 ],
        [  0,  0 =>  0 ],
        [ 10, 11 => 21 ],
        (map [ 0, $_ => $_ ], 1..100),
        (map [ 2, $_ => 2 + $_ ], 1..100),
        (map [ 4, $_ => 4 + $_ ], 1..100),
        (map [ 5, $_ => 5 + $_ ], 1..100),
        (map [ 7, $_ => 7 + $_ ], 1..100),
    );
    $worker->jobs->each(sub {
        $_->done($_->data('first') + $_->data('second'));
    });
    $worker->trigger;
    $client->submit(
        first  => 8,
        second => 2,
    )->then(sub {
        return Future->fail('Unable to perform initial job') unless shift eq 10;

        (fmap0 {
            my $concurrent = shift;
            (fmap0 {
                my ($x, $y, $expected) = @{shift()};
                ++$self->{jobs};
                $client->submit(
                    first  => $x,
                    second => $y,
                )->on_done(sub {
                    ++$self->{responses};
                    ++$self->{shift eq $expected ? 'success' : 'fail'};
                })->on_fail(sub {
                    ++$self->{errors}{shift()};
                })
            } concurrent => $concurrent, foreach => [ @seq ])
        } foreach => [1, 2, 4, 8, 50])
    })->then(sub {
        my $elapsed = Time::HiRes::time - $start;
        $log->debugf("Took $elapsed sec, which would be %.2f/sec", $self->{jobs} / $elapsed);
        return Future->fail('response count did not match job count') unless $self->{jobs} == $self->{responses};
        return Future->fail('had failed results') if $self->{fail};
        return Future->fail('had errors') if $self->{errors};
        return Future->done($elapsed) if $self->{success} == $self->{responses};
        return Future->fail('unexpected inconsistency');
    })
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2017. Licensed under the same terms as Perl itself.

