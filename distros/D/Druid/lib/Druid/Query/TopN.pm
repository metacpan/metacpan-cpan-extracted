package Druid::Query::TopN;
use Moo;

extends 'Druid::Query';
use Hash::Merge qw( merge );

sub query_type { 'topN' }

around 'gen_query' => sub {
    my $orig = shift;
    my $self = shift;
    my $request_hash =  $self->$orig(@_);

    my %topn_request_hash = (
        'dimension' => $self->{_dimension},
        'threshold' => $self->{_threshold},
        'metric'    => $self->{_metric},
    );

    return merge($request_hash, \%topn_request_hash);

};

1;
