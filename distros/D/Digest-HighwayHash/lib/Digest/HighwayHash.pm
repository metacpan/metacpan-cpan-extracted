package Digest::HighwayHash;

use 5.014000;
use strict;
use warnings;
use parent qw/Exporter/;

our @EXPORT_OK = qw/highway_hash64 highway_hash128 highway_hash256/;
our @EXPORT = @EXPORT_OK;

our $VERSION = '0.001001';

use Math::Int64;

require XSLoader;
XSLoader::load('Digest::HighwayHash', $VERSION);

1;
__END__

=encoding utf-8

=head1 NAME

Digest::HighwayHash - XS fast strong keyed hash function

=head1 SYNOPSIS

  use Digest::HighwayHash;
  say highway_hash64 [1, 2, 3, 4], 'hello';
  # 11956820856122239241
  say join ' ', @{highway_hash128([1, 2, 3, 4], 'hello')};
  # 3048112761216189476 13900443277579286659
  say join ' ', @{highway_hash256([1, 2, 3, 4], 'hello')};
  # 8099666330974151427 17027479935588128037 4015249936799013189 10027181291351549853

=head1 DESCRIPTION

HighwayHash is a fast and strong keyed hash function, documented at
L<https://github.com/google/highwayhash>.

Three functions are exported by this module, all by default:

=over

=item B<highway_hash64> I<\@key>, I<$input>

Compute the 64-bit HighwayHash of I<$input>, using I<\@key> as a key.
The key must be a 4-element arrayref, with each element either a
number or (on Perls without 64-bit numbers) a L<Math::Int64> object. The result is a single number or (on Perls without 64-bit numbers) a L<Math::Int64> object.

=item B<highway_hash128> I<\@key>, I<$input>

Compute the 128-bit HighwayHash of I<$input>, using I<\@key> as a key.
The key must be a 4-element arrayref, with each element either a
number or (on Perls without 64-bit numbers) a L<Math::Int64> object. The result is an array of exactly two numbers or (on Perls without 64-bit numbers) L<Math::Int64> objects.

=item B<highway_hash256> I<\@key>, I<$input>

Compute the 256-bit HighwayHash of I<$input>, using I<\@key> as a key.
The key must be a 4-element arrayref, with each element either a
number or (on Perls without 64-bit numbers) a L<Math::Int64> object. The result is an array of exactly four numbers or (on Perls without 64-bit numbers) L<Math::Int64> objects.


=back

=head1 SEE ALSO

L<https://github.com/google/highwayhash>

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2018 by Marius Gavrilescu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
