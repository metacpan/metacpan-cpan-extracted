package Digest::MurmurHash;

use strict;
use warnings;
use base 'Exporter';

our $VERSION = '0.11';
our @EXPORT_OK = ('murmur_hash');

require XSLoader;
XSLoader::load('Digest::MurmurHash', $VERSION);

1;
__END__

=head1 NAME

Digest::MurmurHash - Perl XS interface to the MurmurHash algorithm

=head1 SYNOPSIS

  use Digest::MurmurHash qw(murmur_hash);
  murmur_hash($data_to_hash);

OR

  use Digest::MurmurHash;
  Digest::MurmurHash::murmur_hash($data_to_hash);

=head1 DESCRIPTION

The murmur hash algorithm by Austin Appleby is an exteremely fast
algorithm that combines both excellent collision resistence and
distribution characteristics.

This module requires Perl version > 5.8

=head1 BENCHMARK 

Here is a comparison of this module between common hash function
modules on an Intel Core2Duo 2.4GHz machine.

  n = 10000000

  murmur  :  ( 2.54 usr +  0.01 sys =  2.55 CPU ) @ 3921568.63/s
  jenkins :  ( 2.89 usr +  0.01 sys =  2.90 CPU ) @ 3448275.86/s
  pearson :  ( 2.99 usr +  0.01 sys =  3.00 CPU ) @ 3333333.33/s
  fowler  :  ( 3.30 usr +  0.01 sys =  3.31 CPU ) @ 3021148.04/s
  crc32   :  ( 3.86 usr +  0.00 sys =  3.86 CPU ) @ 2590673.58/s
  md5     :  ( 7.12 usr +  0.01 sys =  7.13 CPU ) @ 1402524.54/s
  sha1    :  ( 9.86 usr +  0.01 sys =  9.87 CPU ) @ 1013171.23/s

=head1 SEE ALSO

For more information on the Murmur algorithm, visit Austin Appleby's
algorithm description page:

http://murmurhash.googlepages.com/

=head1 AUTHOR

Toru Maesaka, E<lt>dev@torum.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Toru Maesaka

MurmurHash algorithm comes from Austin Appleby.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
