package Math::Vector::SortIndexes;

$VERSION = 0.02;
@EXPORT_OK = qw(sort_indexes_descending sort_indexes_ascending);
use base 'Exporter';

sub sort_indexes_descending {
    (sort { $_[$b] <=> $_[$a] } 0..$#_);
}

sub sort_indexes_ascending {
    (sort { $_[$a] <=> $_[$b] } 0..$#_);
}

=head1 NAME

Math::Vector::SortIndexes - Sort the indices of a numeric vector

=head1 SYNOPSIS

  use Math::Vector::SortIndexes qw(sort_indexes_descending 
                                   sort_indexes_ascending);
  
  @vector = qw(44 22 33 11);
  @indexes1 = sort_indexes_ascending @vector; 
  @indexes2 = sort_indexes_descending @vector; 

  print "@indexes1\n"; # Prints 3 1 2 0
  print "@indexes2\n"; # Prints 0 2 1 3

=head1 DESCRIPTION

This module allows you to find the sort the indices of a numeric vector. 
The subroutine names explain themselves: sort_indexes_ascending and 
sort_indexes_descending. Import them and use them as you see fit.

=head1 AUTHORS

David James <david@jamesgang.com>

=head1 SEE ALSO

L<Math::VecStat>

=head1 LICENSE

  Copyright (c) 2002 David James
  All rights reserved.
  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.
  
=cut
