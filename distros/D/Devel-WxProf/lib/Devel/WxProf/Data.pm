package Devel::WxProf::Data;
use strict; use warnings;
use Class::Std::Fast;
use Time::HiRes qw(tv_interval);
use version; our $VERSION = qv(0.0.1);

my %child_nodes_of  :ATTR(:name<child_nodes>    :default<[]>);
my %calls_of        :ATTR(:name<calls>          :default<()>);
my %function_of     :ATTR(:name<function>       :default<()>);
my %package_of      :ATTR(:name<package>        :default<()>);
my %start_of        :ATTR(:name<start>          :default<()>);
my %end_of          :ATTR(:name<end>            :default<0>);

sub add_child_node {
    push @{ $child_nodes_of{ ${ $_[0] } } }, $_[1];
}

sub add_end {
    $end_of{ ${ $_[0] } } += $_[1];
    $calls_of{ ${ $_[0] } }++;
}

sub get_elapsed {
    return 0 if not defined($start_of{ ${ $_[0] }});
    return 0 if not $end_of{ ${ $_[0] }};
    return 0 if $start_of{ ${ $_[0] }} > $end_of{ ${ $_[0] }};
    return ($end_of{ ${ $_[0] }} - $start_of{ ${ $_[0] }});
}

my @colour_from = (
    '#AA5555',
    '#55AA55',
    '#5555AA',
    '#AAAA55',
    '#55AAAA',
    '#AA55AA',
    '#FFAA55',
    '#55FFAA',
    '#AA55FF',
    '#775555',
    '#557755',
    '#555577',
);

sub treedata {
    my $depth = $_[1] || 0;
    return if $depth > 10;
    $depth++;
    my $colour_index = ${ $_[0]} % scalar(@colour_from);
    my $colour = $colour_from[ $colour_index ];
    if (defined($_[2]) && $_[2] eq $colour) {
        $colour = $colour_from[ --$colour_index ];
    }

    return {
        name => "$package_of{ ${ $_[0] } }::$function_of{ ${ $_[0] } }",
        size => $_[0]->get_elapsed(),
        colour => $colour,
        children => [
                map { $_->treedata($depth, $colour) } @{ $child_nodes_of{ ${ $_[0] } } }
        ]
    }
}

1;