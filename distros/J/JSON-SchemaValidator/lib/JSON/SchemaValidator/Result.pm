package JSON::SchemaValidator::Result;

use strict;
use warnings;

use JSON;

sub new {
    my $class = shift;
    my (%params) = @_;

    my $self = {};
    bless $self, $class;

    $self->{errors} = [];
    $self->{root} = $params{root} || '#';

    return $self;
}

sub is_success {
    my $self = shift;

    return @{$self->{errors}} == 0;
}

sub errors {
    my $self = shift;

    return $self->{errors};
}

sub errors_json {
    my $self = shift;

    return JSON::encode_json($self->{errors});
}

sub add_error {
    my $self = shift;

    if (@_ == 1) {
        my ($error) = @_;
        foreach my $suberror (@{$error->errors}) {
            push @{$self->{errors}}, $suberror;
        }
    }
    else {
        my %params = @_;

        my $uri = $params{uri};
        if ($self->{root} && $self->{root} ne '#') {
            $uri =~ s{^#}{$self->{root}};
            $params{uri} = $uri;
        }

        push @{$self->{errors}}, {%params};
    }

    return $self;
}

sub merge {
    my $self = shift;
    my ($subresult) = @_;

    return $self if $subresult->is_success;

    foreach my $suberror (@{$subresult->errors}) {
        push @{$self->{errors}}, $suberror;
    }

    return $self;
}

1;
