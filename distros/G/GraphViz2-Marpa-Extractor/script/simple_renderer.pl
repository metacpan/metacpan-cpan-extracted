
package SimpleRenderer;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    my $self = {
        out => $args{out} || \*STDOUT,
    };
    return bless $self, $class;
}

sub render {
    my ($self, $graph) = @_;
    $self->_enter_graph($graph);
    $self->_walk_graph($graph);
    $self->_leave_graph($graph);
}

sub _walk_graph {
    my ($self, $g) = @_;

    # nodes
    for my $n (@{$g->{nodes}}) {
        $self->_visit_node($n);
    }

    # edges
    for my $e (@{$g->{edges}}) {
        $self->_visit_edge($e);
    }

    # subgraphs
    for my $sg (@{$g->{subgraphs}}) {
        $self->_enter_subgraph($sg);
        $self->_walk_graph($sg);
        $self->_leave_subgraph($sg);
    }
}

sub _enter_graph {
    my ($self, $g) = @_;
    $self->_print("enter_graph($g->{id})");
}

sub _leave_graph {
    my ($self, $g) = @_;
    $self->_print("leave_graph($g->{id})");
}

sub _enter_subgraph {
    my ($self, $sg) = @_;
    $self->_print("enter_subgraph($sg->{id})");
}

sub _leave_subgraph {
    my ($self, $sg) = @_;
    $self->_print("leave_subgraph($sg->{id})");
}

sub _visit_node {
    my ($self, $n) = @_;
    $self->_print("visit_node($n->{id})");
}

sub _visit_edge {
    my ($self, $e) = @_;
    $self->_print("visit_edge($e->{from},$e->{to})");
}

sub _print {
    my ($self, $msg) = @_;
    my $fh = $self->{out};
    print $fh "$msg\n";
}

1;
package SimpleRenderer;

use strict;
use warnings;

sub new {
    my ($class, %args) = @_;
    my $self = {
        out => $args{out} || \*STDOUT,
    };
    return bless $self, $class;
}

sub render {
    my ($self, $graph) = @_;
    $self->_print("enter_graph($graph->{id})");
    $self->_walk($graph);
    $self->_print("leave_graph($graph->{id})");
}

sub _walk {
    my ($self, $g) = @_;

    for my $n (@{$g->{nodes}}) {
        $self->_print("visit_node($n->{id})");
    }

    for my $e (@{$g->{edges}}) {
        $self->_print("visit_edge($e->{from},$e->{to})");
    }

    for my $sg (@{$g->{subgraphs}}) {
        $self->_print("enter_subgraph($sg->{id})");
        $self->_walk($sg);
        $self->_print("leave_subgraph($sg->{id})");
    }
}

sub _print {
    my ($self, $msg) = @_;
    my $fh = $self->{out};
    print $fh "$msg\n";
}

1;
