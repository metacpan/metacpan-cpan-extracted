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

package Games::RailRoad::Node::Cross;
BEGIN {
  $Games::RailRoad::Node::Cross::VERSION = '1.101330';
}
# ABSTRACT: a node object with 4 branches

use Moose;
extends qw{ Games::RailRoad::Node };

__PACKAGE__->meta->make_immutable;
1;


=pod

=head1 NAME

Games::RailRoad::Node::Cross - a node object with 4 branches

=head1 VERSION

version 1.101330

=head1 DESCRIPTION

This package is a virtual class representing a node object with four
branches. This corresponds to 2 straight lines crossing each-other.

Refer to L<Games::RailRoad::Node> for a description of the various
node types.

=head1 AUTHOR

  Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

