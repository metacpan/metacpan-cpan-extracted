package Druid::Query;

use Moo;

use Druid::Interval;
use Druid::Aggregation;
use Druid::PostAggregator;
use Druid::LimitSpec;

has query_type     => (is => 'ro');
has data_source => (is => 'ro');

sub granularity {
    my $self = shift;
    $self->{_granularity} = shift;

    return $self;
}

sub descending {
    my $self = shift;
    $self->{_descending} = 'true';
    return $self;
}

sub ascending {
    my $self = shift;
    $self->{_descending} = 'false';
    return $self;
}

sub aggregation {
    my $self = shift;
    my ($type, $name, $fieldName) = @_;

    my $aggregation = Druid::Aggregation->new(
       type        =>    $type,
       name        =>    $name,
       fieldName   =>    $fieldName
    );

    $self->{_aggregations} //= [];
    push(@{ $self->{_aggregations} }, $aggregation->build);

    return $self;
}

sub post_aggregation {
    my $self = shift;
    my $post_aggregator = shift;

    $self->{_post_aggregations} //= [];
    push(@{ $self->{_post_aggregations} }, $post_aggregator->build);

    return $self;
}

sub filter {
    my $self = shift;
    my $filter = shift;

    $self->{_filters} = $filter->build;

    return $self;
}


sub interval {
    my $self = shift;
    my ($start, $end) = @_;

    my $interval = Druid::Interval->new(start => $start, end => $end);

    $self->{_intervals} //= [];
    push(@{ $self->{_intervals} }, $interval->build);

    return $self;
}

sub context {
    my $self = shift;
    my ($key, $value) = @_;

    $self->{_context} //= {};
    $self->{_context}->{$key} = $value;

    return $self;
}

sub dimension {
    my $self = shift;
    $self->{_dimension} = shift;

    return $self;
}

sub group_by_dimensions {
    my $self = shift;
    $self->{_group_by_dimensions} = shift;

    return $self;
}

sub limit_spec {
    my $self = shift;
    my ($limit, $columns) = @_;

    my $limit_spec = Druid::LimitSpec->new(
        limit   => $limit,
        columns => $columns
    );
    $self->{_limit_spec} = $limit_spec->build;

    return $self;
}

sub threshold {
    my $self = shift;
    $self->{_threshold} = shift;

    return $self;
}

sub metric {
    my $self = shift;
    $self->{_metric} = shift;

    return $self;
}

sub gen_query {
    my $self = shift;

    my %request_hash = (
        'queryType'         => $self->query_type,
        'dataSource'        => $self->data_source,
        'granularity'       => $self->{_granularity},
        'aggregations'      => $self->{_aggregations},
        'postAggregations'  => $self->{_post_aggregations},
        'intervals'         => $self->{_intervals},
        'filter'            => $self->{_filters},
        'context'           => $self->{_context}
    );

    return \%request_hash;
}

1;
