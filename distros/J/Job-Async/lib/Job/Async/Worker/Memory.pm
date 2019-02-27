package Job::Async::Worker::Memory;

use strict;
use warnings;

use parent qw(Job::Async::Worker);

our $VERSION = '0.003'; # VERSION

=head1 NAME

Job::Async::Worker::Memory - basic in-memory job worker for L<Job::Async>

=head1 DESCRIPTION

This is intended as an example, and for testing code. It's not
very useful in a real application.

=cut

use Future::Utils qw(repeat);

sub start { Future->done }

sub trigger {
    my ($self) = @_;
    $self->{active} ||= (repeat {
        my $loop = $self->loop;
        my $f = $loop->new_future;
        $self->loop->later(sub {
            if(my $job = shift @Job::Async::Memory::PENDING_JOBS) {
                $self->process($job);
            }
            $f->done;
        });
        $f;
    } while => sub { 0+@Job::Async::Memory::PENDING_JOBS })->on_ready(sub {
        delete $self->{active}
    })
}

sub process {
    my ($self, $job) = @_;
    $self->jobs->emit($job);
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2017. Licensed under the same terms as Perl itself.

