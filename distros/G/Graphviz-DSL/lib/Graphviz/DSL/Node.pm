package Graphviz::DSL::Node;
use strict;
use warnings;

use parent qw/Graphviz::DSL::Component/;

use Carp ();
use Scalar::Util qw/blessed/;
use Graphviz::DSL::Util qw/parse_id validate_compass/;

sub new {
    my ($class, %args) = @_;

    unless (exists $args{id}) {
        Carp::croak("missing mandatory parameter 'id'");
    }

    my $id    = delete $args{id};
    my $attrs = delete $args{attributes} || [];
    unless (ref $attrs eq 'ARRAY') {
        Carp::croak("'attributes' parameter should be ArrayRef");
    }

    my $port    = delete $args{port}    || undef;
    my $compass = delete $args{compass} || undef;

    if (defined $compass) {
        validate_compass($compass);
    }

    bless {
        id         => $id,
        attributes => $attrs,
        port       => $port,
        compass    => $compass,
    }, $class;
}

sub as_string {
    my $self = shift;

    my $str = qq{"$self->{id}"};
    if ($self->{port}) {
        $str .= qq{:"$self->{port}"};
    }

    if ($self->{compass}) {
        $str .= ":$self->{compass}";
    }

    return $str;
}

sub update_attributes {
    my ($self, $attrs) = @_;

 OUTER:
    for my $attr (@{$attrs}) {
        my ($key, $val) = @{$attr};
        for my $old_attr (@{$self->{attributes}}) {
            my ($old_key, $old_val) = @{$old_attr};

            if ($key eq $old_key) {
                $old_attr->[1] = $val;
                next OUTER;
            }
        }

        push @{$self->{attributes}}, $attr;
    }
}

sub equal_to {
    my ($self, $node) = @_;

    unless (blessed $node && $node->isa('Graphviz::DSL::Node')) {
        return 0;
    }

    unless ($self->{id} eq $node->{id}) {
        return 0;
    }

    my ($port1, $port2) = map { defined $_ ? $_ : '' } ($self->{port}, $node->{port});
    unless ($port1 eq $port2) {
        return 0;
    }

    my ($comp1, $comp2) = map { defined $_ ? $_ : '' } ($self->{compass}, $node->{compass});
    unless ($comp1 eq $comp2) {
        return 0;
    }

    return 1;
}

sub update {
    my ($self, $node_id) = @_;

    my ($id, $port, $compass) = parse_id($node_id);

    # id is same
    $self->{port} = $port;
    $self->{compass} = $compass;
}

# accessor
sub id         { $_[0]->{id};         }
sub port       { $_[0]->{port};       }
sub compass    { $_[0]->{compass};    }

1;
