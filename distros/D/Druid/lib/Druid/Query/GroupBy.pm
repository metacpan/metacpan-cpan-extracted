package Druid::Query::GroupBy;
use Moo;

extends 'Druid::Query';
use Hash::Merge qw( merge );

sub query_type { 'groupBy' }

around 'gen_query' => sub {
    my $orig = shift;
    my $self = shift;
    my $request_hash =  $self->$orig(@_);

    my %groupby_request_hash = (
        'dimensions' => $self->{_group_by_dimensions},
        'limitSpec'  => $self->{_limit_spec},
    );

    return merge($request_hash, \%groupby_request_hash);

};

1;
