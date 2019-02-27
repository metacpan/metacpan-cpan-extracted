package Job::Async::Job;

use strict;
use warnings;

our $VERSION = '0.003'; # VERSION

=head1 NAME

Job::Async::Job - represents a single job for L<Job::Async>

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

use Sereal;
use JSON::MaybeUTF8 qw(:v1);

use constant SEREAL_DEFAULT => 1;

my $sereal_encode = Sereal::Encoder->new;
my $sereal_decode = Sereal::Decoder->new;

sub id { shift->{id} }

sub data {
    my ($self, $key) = @_;
    return $self->{data} unless defined $key;
    return $self->{data}{$key};
}

sub flattened_data {
    my ($self, $data) = @_;
    $data //= $self->{data};
    return { map {
        !ref($data->{$_})
        ? ("text_$_" => $data->{$_})
        : SEREAL_DEFAULT
        ? ("sereal_$_" => $sereal_encode->encode($data->{$_}))
        : ("json_$_" => encode_json_utf8($data->{$_}))
    } keys %$data };
}

sub structured_data {
    my ($self, $data) = @_;
    $data //= $self->{data};
    return {
        (map {
            die "invalid format for $_" unless my ($type, $k) = /^(json|text|sereal)_(.*)$/;
            $k => (
                $type eq 'text'
                ? $data->{$_}
                : $type eq 'json'
                ? decode_json_utf8($data->{$_})
                : $sereal_decode->decode($data->{$_})
            )
        } grep /^[a-z]/, keys %$data),
        map {; $_ => $data->{$_} } grep /^_/, keys %$data
    };
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
