use strict;
use warnings;
package Device::CurrentCost::Constants;
$Device::CurrentCost::Constants::VERSION = '1.142240';
# ABSTRACT: Module to export constants for Current Cost devices


my %constants =
  (
   CURRENT_COST_CLASSIC => 0x1,
   CURRENT_COST_ENVY => 0x2,
  );
my %names =
  (
   $constants{CURRENT_COST_ENVY} => 'Envy',
   $constants{CURRENT_COST_CLASSIC} => 'Classic',
  );

sub import {
  no strict qw/refs/; ## no critic
  my $pkg = caller(0);
  foreach (keys %constants) {
    my $v = $constants{$_};
    *{$pkg.'::'.$_} = sub () { $v };
  }
  foreach (qw/current_cost_type_string/) {
    *{$pkg.'::'.$_} = \&{$_};
  }
}


sub current_cost_type_string {
  $names{$_[0]}
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Device::CurrentCost::Constants - Module to export constants for Current Cost devices

=head1 VERSION

version 1.142240

=head1 SYNOPSIS

  use Device::CurrentCost::Constants;

=head1 DESCRIPTION

Module to export constants for Current Cost devices

=head1 C<FUNCTIONS>

=head2 C<current_cost_type_string( $type )>

Returns a string describing the given Current Cost device type.

=head1 AUTHOR

Mark Hindess <soft-cpan@temporalanomaly.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Mark Hindess.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
