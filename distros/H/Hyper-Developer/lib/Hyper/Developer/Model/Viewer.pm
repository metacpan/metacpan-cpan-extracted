package Hyper::Developer::Model::Viewer;

use strict;
use warnings;
use version; our $VERSION = qv(0.1);

use Class::Std;
use Graph::Easy;
use Hyper::Functions;

my %for_class_of :ATTR(:name<for_class>);

sub _get_config :PRIVATE {
    my $self         = shift;
    my $for_class    = $self->get_for_class();
    my ($type)       = $for_class =~ m{\A[^:]+::Control::([^:]+)::}xms;
    my $config_class = "Hyper\::Config\::Reader\::$type";
    eval "use $config_class; 1;" or die $@;

    return $config_class->new({
        config_for => $for_class,
    });
}

sub create_graph {
    my $self        = shift;
    my $graph       = Graph::Easy->new();
    my $config      = $self->_get_config();
    my $step_ref    = $config->get_steps();
    my $control_ref = $config->get_controls();
    my $i           = 0;

    for my $name ( keys %{$step_ref} ) {
        my $step = $graph->add_node($name);
        $step->set_attributes({
            fill  => '#CCFF66',
        });

        # Check for embedded controls
        #my @embedded_controls = map {
        #    my $class = Hyper::Functions::fix_class_name(
        #        $control_ref->{$_}->get_class()
        #    );
        #    $class =~ m{\A[^:]+::Control::(?: Flow|Container)::}xms
        #        ? $class
        #        : ();
        #} @{$step_ref->{$name}->get_controls() || []};
        #for my $class ( @embedded_controls ) {
        #    warn $class;
        #    $graph->add_edge(
        #        $step,
        #           Hyper::Developer::Model::Viewer->new({
        #            for_class => $class,
        #        })->create_graph($graph),
        #    );
        #}

        my $transition_counter;
        for my $transition ( @{$step_ref->{$name}->get_transitions()} ) {
            my $source      = $transition->get_source();
            my $destination = $transition->get_destination();
            my $condition   = $transition->get_condition();

            # fix transition names
            s{=}{_}xmsg for ($source, $destination);

            if ( $condition ) {
                my $decision = $graph->add_node("$source $destination");
                $decision->set_attributes({
                    shape  => 'diamond',
                    label  => ++$transition_counter,
                    fill   => '#FFB2B2',
                });
                $graph->add_edge($source, $decision)->set_attribute(flow => 'down');
                $graph->add_edge(
                    $decision,
                    $destination,
                    $condition,
                )->set_attributes({
                    flow => 'left',
                });
            }
            else {
                $graph->add_edge(
                    $source,
                    $destination,
                )->set_attribute(flow => 'down');
            }
        }
    }

    REMOVE_BROKEN_NODES:
    for my $node ( $graph->nodes() ) {
        $node->edges() and next REMOVE_BROKEN_NODES;
        $graph->del_node($node);
    }
    return $graph;
}

1;

# ToDo: add pod
