package Job::Async::Job;

use strict;
use warnings;

our $VERSION = '0.002'; # VERSION

=head1 NAME

Job::Async::Job - represents a single job for L<Job::Async>

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use JSON::MaybeUTF8 qw(:v1);

sub id { shift->{id} }

sub data {
    my ($self, $key) = @_;
    return $self->{data} unless defined $key;
    return $self->{data}{$key};
}

sub flattened_data {
    my ($self) = @_;
    my $data = $self->{data};
    return $data unless grep ref, values %$data;
    return { map { $_ => ref($data->{$_}) ? encode_json_utf8($data->{$_}) : $_ } keys %$data };
}

sub future { shift->{future} }

for my $method (qw(then get done fail else catch on_done on_cancel on_fail on_ready is_ready is_done is_failed failure)) {
    no strict 'refs';
    *$method = sub { my $self = shift; $self->future->$method(@_) }
}

sub new {
    my ($class, %args) = @_;
    bless \%args, $class
}


1;
