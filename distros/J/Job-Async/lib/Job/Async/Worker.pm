package Job::Async::Worker;

use strict;
use warnings;

use parent qw(IO::Async::Notifier);

our $VERSION = '0.003'; # VERSION

=head1 NAME

Job::Async::Worker - worker API for L<Job::Async>

=head1 DESCRIPTION

This is the thing that receives jobs, does the work, and sends
back a result.

=cut

use Ryu::Async;

use Job::Async::Job;

=head1 METHODS

=cut

sub jobs {
    my ($self) = @_;
    $self->{jobs} ||= do {
        $self->ryu->source(
            label => 'jobs'
        )
    };
}

sub id { shift->{id} //= Job::Async::Utils::uuid() }
sub timeout { shift->{timeout} }

sub configure {
    my ($self, %args) = @_;
    for my $k (qw(id timeout)) {
        $self->{$k} = delete $args{$k} if exists $args{$k};
    }
    return $self->next::method(%args);
}

sub stop {
    my ($self) = @_;
    my $f = $self->jobs->completed;
    $f->done unless $f->is_ready;
}

sub ryu {
    my ($self) = @_;
    $self->{ryu} ||= do {
        $self->add_child(
            my $ryu = Ryu::Async->new
        );
        $ryu;
    };
}

1;

=head1 AUTHOR

Tom Molesworth <TEAM@cpan.org>

=head1 LICENSE

Copyright Tom Molesworth 2016-2017. Licensed under the same terms as Perl itself.

