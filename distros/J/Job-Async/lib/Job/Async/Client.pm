package Job::Async::Client;

use strict;
use warnings;

use parent qw(IO::Async::Notifier);

our $VERSION = '0.004'; # VERSION

=head1 NAME

Job::Async::Client - client API for L<Job::Async>

=head1 SYNOPSIS

=head1 DESCRIPTION

This is the thing that submits jobs. It sends out a job request
which hopefully a worker will pick up and process.

=cut

use Job::Async::Job;

=head1 METHODS

=head2 id

Returns this client's ID. Although one can be configured specifically, it
will default to a random (v4) UUID.

=cut

sub id { shift->{id} //= Job::Async::Utils::uuid() }

=head2 timeout

Timeout to use for any newly-created jobs. No default.

=cut

sub timeout { shift->{timeout} }

sub configure {
    my ($self, %args) = @_;
    for my $k (qw(id timeout)) {
        $self->{$k} = delete $args{$k} if exists $args{$k};
    }
    return $self->next::method(%args);
}

=head2 submit

Queue a new job for processing.

Takes zero or more C<key> => C<value> arguments to be used as
job parameters.

Returns a L<Job::Async::Job> instance.

=cut

sub submit {
    my ($self, %args) = @_;
    ...
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2017. Licensed under the same terms as Perl itself.

