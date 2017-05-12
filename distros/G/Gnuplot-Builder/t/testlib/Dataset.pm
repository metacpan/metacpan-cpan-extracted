package testlib::Dataset;
use strict;
use warnings FATAL => "all";
use Test::More;

sub new {
    my ($class, $params, $data_provider) = @_;
    my $self = bless {
        params => $params,
        data_provider => $data_provider,
    }, $class;
    return $self;
}

sub params_string {
    ok wantarray, "params_string() is called in list context";
    return $_[0]->{params};
}

sub write_data_to {
    my ($self, $writer) = @_;
    $self->{data_provider}->($writer);
}

1;

