package Graphviz::DSL::Edge;
use strict;
use warnings;

use parent qw/Graphviz::DSL::Component/;

use Carp ();
use Scalar::Util qw/blessed/;
use Graphviz::DSL::Util qw/parse_id/;

sub new {
    my ($class, %args) = @_;

    for my $key (qw/start end/) {
        unless (exists $args{$key}) {
            Carp::croak("missing mandatory parameter '$key'");
        }

        my $param = $args{$key};
        unless (blessed $param && $param->isa('Graphviz::DSL::Component')) {
            Carp::croak("'$key' parameter should isa 'Graphviz::DSL::Component'");
        }
    }

    my $attrs = delete $args{attributes} || {};

    my $self = bless {
        start      => $args{start},
        end        => $args{end},
        attributes => $attrs,
    }, $class;

    return $self;
}

sub as_string {
    my ($self, $id_directed) = @_;

    my $edgeop = $id_directed ? '->' : '--';
    my ($start, $end) = ($self->{start}, $self->{end});

    for my $obj ($start, $end) {
        if (blessed $obj && blessed $obj eq 'Graphviz::DSL::Graph') {
            $start->{delayd} = 0;
        }
    }

    sprintf "%s %s %s", $start->as_string, $edgeop, $end->as_string;
}

sub equal_to {
    my ($self, $edge) = @_;
    my ($start, $end) = ($self->{start}, $self->{end});

    return $start->equal_to($edge->start) && $end->equal_to($edge->end);
}

# accessor
sub start { $_[0]->{start} }
sub end   { $_[0]->{end}   }

1;
