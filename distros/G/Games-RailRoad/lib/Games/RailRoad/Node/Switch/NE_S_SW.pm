# 
# This file is part of Games-RailRoad
# 
# This software is copyright (c) 2008 by Jerome Quelin.
# 
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# 
use 5.010;
use strict;
use warnings;

package Games::RailRoad::Node::Switch::NE_S_SW;
BEGIN {
  $Games::RailRoad::Node::Switch::NE_S_SW::VERSION = '1.101330';
}
# ABSTRACT: a given type of node...

use Moose;
extends qw{ Games::RailRoad::Node::Switch };


# -- private methods

sub _next_map {
    return {
        'ne' => $_[0]->_sw_exits->[ $_[0]->_switch ],
        's'  => 'ne',
        'sw' => 'ne',
    };
}


sub _sw_exits { return [ qw{ s sw } ]; }


sub _transform_map {
    my $prefix = 'Games::RailRoad::Node::';
    return {
        'n'   => $prefix . 'Cross::N_NE_S_SW',
        '-s'  => $prefix . 'Straight::NE_SW',
        '-sw' => $prefix . 'Straight::NE_S',
    };
}


__PACKAGE__->meta->make_immutable;
1;


=pod

=head1 NAME

Games::RailRoad::Node::Switch::NE_S_SW - a given type of node...

=head1 VERSION

version 1.101330

=head1 DESCRIPTION

This package provides a node object. Refer to L<Games::RailRoad::Node>
for a description of the various node types.

=head1 AUTHOR

  Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

