package Digest::SpookyHash;
use strict;
use warnings;
use 5.008008;
use base qw(Exporter);
use XSLoader;

BEGIN {
    our $VERSION = '1.05';
    XSLoader::load __PACKAGE__, $VERSION;
}

our @EXPORT_OK = qw(
    spooky32
    spooky64
    spooky128
);

1;
__END__

=pod

=encoding utf8

=head1 NAME

Digest::SpookyHash - SpookyHash implementation for Perl

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Digest::SpookyHash qw(spooky32 spooky64 spooky128);
  
  my $key = 'spooky';
  
  my $hash32  = spooky32($key, 0);
  my $hash64  = spooky64($key, 0);
  my ($hash64_1, $hash64_2) = spooky128($key, 0);

=head1 DESCRIPTION

This module provides an interface to SpookyHash(SpookyHash V2) functions.

B<This module works only in the environment which supported a 64-bit integer>.

B<This module works only in little endian machine>.

=head1 FUNCTIONS

=head2 spooky32($key [, $seed = 0])

Calculates a 32 bit hash.

=head2 spooky64($key [, $seed = 0])

Calculates a 64 bit hash.

=head2 ($v1, $v2) = spooky128($key [, $seed1 = 0, $seed2 =0])

Calculates a 128 bit hash. The result is returned as a two element list of 64 bit integers.

=head1 SEE ALSO

L<http://burtleburtle.net/bob/hash/spooky.html>

=head1 AUTHOR

Hideaki Ohno E<lt>hide.o.j55 {at} gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
