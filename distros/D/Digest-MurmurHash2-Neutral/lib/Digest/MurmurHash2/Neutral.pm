package Digest::MurmurHash2::Neutral;
$Digest::MurmurHash2::Neutral::VERSION = '0.001000';
# ABSTRACT: Perl XS interface to the endian neutral MurmurHash2 algorithm

use strict;
use warnings;
use base 'Exporter';

our @EXPORT_OK = ('murmur_hash2_neutral');

require XSLoader;
XSLoader::load('Digest::MurmurHash2::Neutral');

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Digest::MurmurHash2::Neutral - Perl XS interface to the endian neutral MurmurHash2 algorithm

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

  use Digest::MurmurHash2::Neutral qw(murmur_hash2_neutral);
  murmur_hash2_neutral($data_to_hash);

OR

  use Digest::MurmurHash2::Neutral;
  Digest::MurmurHash2::murmur_hash2_neutral($data_to_hash);

=head1 DESCRIPTION

This is an implementation of the endian neutral MurmurHash2 algorithm by Austin
Appleby.  This module was originally written for
L<ZipRecruiter|https://www.ziprecruiter.com/hiring/technology> using L<code from
nginx|https://github.com/nginx/nginx/blob/42f1e1cb96b510d1fa1abad99a5294a37b750d99/src/core/ngx_murmurhash.c>.
I used L<Digest::MurmurHash> as a template.

=head1 WHY

As stated above, this module is implemented to compatible with C<nginx>'s
MurmurHash2 implementation, used in the C<split_clients> directive.
C<MurmurHash3> would be faster, but compatibility is the goal here.

=head1 SEE ALSO

=over

=item * L<Digest::MurmurHash>

=item * L<Digest::MurmurHash3>

=item * L<Austin Appleby's algorithm description page|http://murmurhash.googlepages.com/>

=back

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
