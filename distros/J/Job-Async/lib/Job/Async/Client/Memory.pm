package Job::Async::Client::Memory;

use strict;
use warnings;

use parent qw(Job::Async::Client);

our $VERSION = '0.004'; # VERSION

=head1 NAME

Job::Async::Client::Memory - basic in-memory job client for L<Job::Async>

=head1 DESCRIPTION

This is intended as an example, and for testing code. It's not
very useful in a real application.

=cut

sub start { Future->done }

sub submit {
    my ($self, %args) = @_;
    push @Job::Async::Memory::PENDING_JOBS, my $job = Job::Async::Job->new(
        data => \%args,
        id => rand(1e9),
        future => $self->loop->new_future,
    );
    $job
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2017. Licensed under the same terms as Perl itself.

