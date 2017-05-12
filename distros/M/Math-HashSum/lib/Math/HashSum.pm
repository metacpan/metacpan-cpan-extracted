package Math::HashSum;

@EXPORT_OK = qw(hashsum);
$VERSION = 0.02;
use base 'Exporter';
use strict;

# hashsum: Sum a list of key-value pairs on a per-key basis
sub hashsum {
    my %sum;
    while (@_) {
        my $key = shift;
        $sum{$key} += shift;
    }
    %sum;
}

=head1 NAME

Math::HashSum - Sum a list of key-value pairs on a per-key basis

=head1 SYNOPSIS

  use Math::HashSum qw(hashsum);
  
  my %hash1 = (a=>.1, b=>.4); 
  my %hash2 = (a=>.2, b=>.5);
  my %sum = hashsum(%hash1,%hash2);
  
  print "$sum{a}\n"; # Prints .3
  print "$sum{b}\n"; # Prints .9

=head1 DESCRIPTION

This module allows you to sum a list of key-value pairs on a per-key basis.
It adds up all the values associated with each key in the given list and
returns a hash containing the sum associated with each key.

The example in the synopsis should explain usage of the module effectively.

=head1 AUTHORS

David James <david@jamesgang.com>

=head1 SEE ALSO

L<Math::VecStat>, L<Lingua::EN::Segmenter::TextTiling> for an example of this module in use

=head1 LICENSE

  Copyright (c) 2002 David James
  All rights reserved.
  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.
  
=cut
