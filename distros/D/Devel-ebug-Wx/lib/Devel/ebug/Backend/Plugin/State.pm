package Devel::ebug::Backend::Plugin::State;

use strict;
use Devel::ebug::Backend::Plugin::ActionPoints;

sub register_commands {
  return ( get_state => { sub => \&get_state },
           set_state => { sub => \&set_state, record => 1 },
           );
}

# FIXME breaks encapsulation
*all_break_points_with_condition = \&Devel::ebug::Backend::Plugin::ActionPoints::all_break_points_with_condition;
*break_point = \&Devel::ebug::Backend::Plugin::ActionPoints::break_point;

# FIXME likely does not scale with more ebug plugins... needs registration
#       interface
sub get_state {
    my( $req, $context ) = @_;
    my $res = {};

    my $bpres = all_break_points_with_condition( $req, $context );
    $res->{break_points} = $bpres->{break_points};
    return $res;
}

sub set_state {
    my( $req, $context ) = @_;
    my $state = $req->{state};
    foreach my $bp ( @{$state->{break_points} || []} ) {
        break_point( $bp, $context );
    }
    return {};
}

1;
