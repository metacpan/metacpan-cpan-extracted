package Devel::PeekPoke::Constants;

use strict;
use warnings;

use Config;

BEGIN {
  my $ptr_size = $Config{ptrsize};
  eval "sub PTR_SIZE () { $ptr_size }";

  my $ptr_pack_type = do {
    if ($ptr_size == 4) {
      'L'
    }
    elsif ($ptr_size == 8) {
      'Q'
    }
    else {
      die "Unsupported \$Config{ptrsize}: $ptr_size\n";
    }
  };
  eval "sub PTR_PACK_TYPE () { $ptr_pack_type }";

  my $big_endian = do {
    my $ivnums = join '', (1 .. $Config{ivsize});
    if ($Config{byteorder} eq $ivnums ) {
      0
    }
    elsif ($Config{byteorder} eq scalar reverse $ivnums ) {
      1
    }
    else {
      die "Weird byteorder: $Config{byteorder}\n";
    }
  };
  eval "sub BIG_ENDIAN () { $big_endian }";
}

use base 'Exporter';
our @EXPORT_OK = (qw/PTR_SIZE PTR_PACK_TYPE BIG_ENDIAN/);

=head1 NAME

Devel::PeekPoke::Constants - Some convenience constants based on your machine

=head1 DESRIPTION

This module provides some convenience constants based on your machine. It
provides the following constants (exportable on request)

=head2 PTR_SIZE

The size of your pointer, equivalent to L<$Config::ptr_size|Config>.

=head2 PTR_PACK_TYPE

The L<pack|perlfunc/pack> template type suitable for L</PTR_SIZE> pointers.
Either C<L> (32 bit) or C<Q> (64 bit).

=head2 BIG_ENDIAN

An indicator whether your system is big-endian (constant is set to C<1>) or
little-endian (constant is set to C<0>).

=head1 COPYRIGHT

See L<Devel::PeekPoke/COPYRIGHT>.

=head1 LICENSE

See L<Devel::PeekPoke/LICENSE>.

=cut

1;
