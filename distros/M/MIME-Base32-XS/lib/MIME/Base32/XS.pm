package MIME::Base32::XS;

use strict;
use warnings;
use XSLoader;
use base qw/Exporter/;

our $VERSION = '0.09';

our @EXPORT  = qw/
    encode_base32
    decode_base32
/;

XSLoader::load('MIME::Base32::XS', $VERSION);

1;

=encoding utf8

=head1 NAME

MIME::Base32::XS - Encoding and decoding Base32

=head1 SYNOPSIS
 
    use MIME::Base32::XS;
 
    $encoded = encode_base32('Foo');
    $decoded = decode_base32($encoded);

=head1 DESCRIPTION

This module provides functions to encode and decode strings into and from the
Base32 encoding specified in RFC 3548.

=head1 METHODS

=head2 encode_base32
 
    my $encoded = encode_base32('Baz');

=head2 decode_base32
 
    my $decoded = decode_base32('IJQXU===');

=head1 AUTHOR
  
Lucas Tiago de Moraes C<lucastiagodemoraes@gmail.com>

=head1 CONTRIBUTORS

Orestes Leal Rodriguez C<olealrd1981@gmail.com>
  
=head1 COPYRIGHT AND LICENSE
  
This software is copyright (c) 2020 by Lucas Tiago de Moraes.
  
This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
  
=cut
