package Druid::Query::Timeseries;
use Moo;

extends 'Druid::Query';
use Hash::Merge qw( merge );

sub query_type { 'timeseries' }

around 'gen_query' => sub {
    my $orig = shift;
    my $self = shift;
    my $request_hash =  $self->$orig(@_);

    my %timeseries_request_hash = (
        'descending' => $self->{_descending},
    );

    return merge($request_hash, \%timeseries_request_hash);
};

1;
