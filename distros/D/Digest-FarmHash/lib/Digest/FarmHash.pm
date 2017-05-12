package Digest::FarmHash;
use 5.008005;
use strict;
use warnings;
use Exporter 'import';

our $VERSION = "0.01";

require XSLoader;
XSLoader::load('Digest::FarmHash', $VERSION);

our @EXPORT_OK = qw(
    farmhash32
    farmhash64
    farmhash128
    farmhash_fingerprint32
    farmhash_fingerprint64
    farmhash_fingerprint128
);

1;
__END__

=encoding utf-8

=head1 NAME

Digest::FarmHash - FarmHash Implementation For Perl

=head1 SYNOPSIS

  use Digest::FarmHash qw(
      farmhash32 farmhash64 farmhash128
      farmhash_fingerprint32 farmhash_fingerprint64 farmhash_fingerprint128
  );

  my $hash = farmhash32($data_to_hash);
  my $hash = farmhash64($data_to_hash);
  my ($lo, $hi) = farmhash128($data_to_hash);

  my $fingerprint = farmhash_fingerprint32($data_to_hash);
  my $fingerprint = farmhash_fingerprint64($data_to_hash);
  my ($lo, $hi) = farmhash_fingerprint128($data_to_hash);

=head1 DESCRIPTION

This module provides an interface to FarmHash functions.

L<https://github.com/google/farmhash>

Note that this module works only in the environment which supported a 64-bit integer.

=head1 FUNCTIONS

=over 4

=item $h = farmhash32($data [, $seed])

=item $h = farmhash64($data [, $seed1, $seed2])

=item ($lo, $hi) = farmhash128($data [, $seed_lo, $seed_hi])

=item $f = farmhash_fingerprint32($data)

=item $f = farmhash_fingerprint64($data)

=item ($lo, $hi) = farmhash_fingerprint128($data)

=back

=head1 SEE ALSO

L<https://github.com/google/farmhash>

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

FarmHash by Google, Inc.

=cut
