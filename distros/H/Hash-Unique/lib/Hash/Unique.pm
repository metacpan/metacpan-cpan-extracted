package Hash::Unique;
use strict;
use warnings;

our $VERSION = "0.06";

sub get_unique_hash {
  my $class = shift;
  my ($array_hash, $key) = @_;

  my @tmp;
  my @return_hash = ();

  foreach my $hash (@$array_hash) {
    if (!in_array($hash->{$key}, \@tmp)) {
      push (@return_hash, $hash);
      push (@tmp, $hash->{$key});
    }
  }

  return @return_hash;
}

sub in_array {
  my ($val, $array_ref) = @_;

  foreach my $elem (@$array_ref) {
    if ($val eq $elem) {
      return 1;
    }
  }

  return 0;
}

1;
__END__

=encoding utf-8

=head1 NAME

Hash::Unique - It's hash manipulation module

=head1 DESCRIPTION

=head3 get_unique_hash

This subroutine makes hash-array unique by specified key.

=head4 way to use

 use Hash::Unique;

 my @hash_array = (
   {id => 1, name => 'tanaka'},
   {id => 2, name => 'sato'},
   {id => 3, name => 'suzuki'},
   {id => 4, name => 'tanaka'}
 );

 my @unique_hash_array = Hash::Unique->get_unique_hash(\@hash_array, "name");

=head4 result

Contents of "@unique_hash_array"

 (
  {id => 1, name => 'tanaka'},
  {id => 2, name => 'sato'},
  {id => 3, name => 'suzuki'}
 )

=head1 LICENSE

Copyright (C) matsumura-taichi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

matsumura-taichi E<lt>hiroto.in.the.cromagnons@gmail.comE<gt>

=cut
