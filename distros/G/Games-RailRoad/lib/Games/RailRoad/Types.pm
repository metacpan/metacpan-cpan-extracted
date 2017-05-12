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

package Games::RailRoad::Types;
BEGIN {
  $Games::RailRoad::Types::VERSION = '1.101330';
}
# ABSTRACT: private types for the distribution

use MooseX::Types -declare => [ qw{ Num_0_1 } ];
use MooseX::Types::Moose qw{ Num };


# -- type definition

subtype Num_0_1,
    as Num,
    where   { $_ >= 0 && $_ <= 1},
    message { 'Num should be between 0 and 1' };

1;


=pod

=head1 NAME

Games::RailRoad::Types - private types for the distribution

=head1 VERSION

version 1.101330

=head1 DESCRIPTION

This module is defining some L<Moose> subtypes to be used elsewhere in
the distribution.

Available types exported:

=over 4

=item * Num_0_1

A float between 0 and 1.

=back

=head1 AUTHOR

  Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

