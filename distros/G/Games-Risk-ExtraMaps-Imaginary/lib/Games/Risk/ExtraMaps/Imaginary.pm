#
# This file is part of Games-Risk-ExtraMaps-Imaginary
#
# This software is Copyright (c) 2011 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#
use 5.010;
use strict;
use warnings;

package Games::Risk::ExtraMaps::Imaginary;
{
  $Games::Risk::ExtraMaps::Imaginary::VERSION = '3.113460';
}
# ABSTRACT: a set of imaginary maps for Games::Risk

use Moose;
extends 'Games::Risk::ExtraMaps';

sub extra_category { "Imaginary" }

__PACKAGE__->meta->make_immutable;
1;


=pod

=head1 NAME

Games::Risk::ExtraMaps::Imaginary - a set of imaginary maps for Games::Risk

=head1 VERSION

version 3.113460

=head1 DESCRIPTION

This distribution holds a few imaginary maps.

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut


__END__

