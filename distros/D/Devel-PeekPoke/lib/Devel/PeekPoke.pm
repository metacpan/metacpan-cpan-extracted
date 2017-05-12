package Devel::PeekPoke;
use strict;
use warnings;

our $VERSION = '0.04';

use Carp;
use Devel::PeekPoke::Constants qw/PTR_SIZE PTR_PACK_TYPE BIG_ENDIAN/;

if (
  $ENV{DEVEL_PEEK_POKE_USE_PP}
    or
  # when someone writes the XS this should just work
  ! eval { require XSLoader; XSLoader::load( __PACKAGE__, $VERSION ) }
) {
  require Devel::PeekPoke::PP;
  *peek = \&Devel::PeekPoke::PP::peek;
  *poke = \&Devel::PeekPoke::PP::poke;

  # sanity checks an address value before packing it
  *_pack_address = \&Devel::PeekPoke::PP::_pack_address;
}

use base 'Exporter';
our @EXPORT = qw/peek poke/;
our @EXPORT_OK = qw/peek poke peek_address poke_address peek_verbose describe_bytestring/;

=head1 NAME

Devel::PeekPoke - All your bytes are belong to us

=head1 DESCRIPTION

This module provides a toolset for raw memory manipulation (both reading and
writing), together with some tools making it easier to examine memory chunks.

All provided routines expect memory addresses as regular integers (not as their
packed representations). Note that you can only manipulate memory of your
current perl process, this is B<not> a general memory access tool.

=head1 PORTABILITY

The implementation is very portable, and is expected to work on all
architectures and operating systems supported by perl itself. Moreover no
compiler toolchain is required to install this module (in fact currently no
XS version is available).

In order to interpret the results, you may need to know the details of the
underlying system architecture. See L<Devel::PeekPoke::Constants> for some
useful constants related to the current system.

=head1 USE RESPONSIBLY

It is apparent with the least amount of imagination that this module can be
used for great evil and general mischief. On the other hand there are some
legitimate uses, if nothing else as a learning/debugging tool. Hence this
tool is provided ( L<with Larry Wall's blessing!
|http://groups.google.com/group/alt.hackers/msg/8ce9ba2e5554e8e6>)
in the interest of free speech and all. The authors expect a user of this
module to exercise maximum common sense.


=head1 EXPORTABLE FUNCTIONS

The following functions are provided, with L</peek> and L</poke> being
exported by default.

=head2 peek

  my $byte_string = peek( $address, $size );

Reads and returns C<$size> B<bytes> from the supplied address. Expects
C<$address> to be specified as an integer.

=head2 poke

  my $bytes_written = poke( $address, $bytes );

Writes the contents of C<$bytes> to the memory location C<$address>. Returns
the amount of bytes written. Expects C<$bytes> to be a raw byte string, throws
an exception when (possible) characters are detected.

=cut

# peek and poke come either from Devel::PeekPoke::PP or the XS implementation

=head2 peek_address

  my $address = peek_address( $pointer_address );

A convenience function to retrieve an address from a known location of a
pointer. The address is returned as an integer. Equivalent to:

  unpack (
    Devel::PeekPoke::Constants::PTR_PACK_TYPE,
    peek( $pointer_address, Devel::PeekPoke::Constants::PTR_SIZE ),
  )

=cut

sub peek_address {
  #my($location) = @_;
  croak "Peek address where?" unless defined $_[0];
  unpack PTR_PACK_TYPE, peek($_[0], PTR_SIZE);
}

=head2 poke_address

  my $addr_size = poke_address( $pointer_address, $address_value );

A convenience function to set a pointer to an arbitrary address an address
(you need to ensure that C<$pointer_address> is in fact a pointer).
Equivalent to:

  poke( $pointer_address, pack (
    Devel::PeekPoke::Constants::PTR_PACK_TYPE,
    $address_value,
  ));

=cut

sub poke_address {
  #my($location, $addr) = @_;
  croak "Poke address where and to what?"
    unless (defined $_[0]) and (defined $_[1]);
  poke( $_[0], _pack_address( $_[1]) );
}

=head2 peek_verbose

  peek_verbose( $address, $size )

A convenience wrapper around L</describe_bytestring>. Equivalent to:

  print STDERR describe_bytestring( peek($address, $size), $address);

=cut

sub peek_verbose {
  #my($location, $len) = @_;
  my $out = describe_bytestring( peek(@_), $_[0]);

  print STDERR "$out\n";
}

=head2 describe_bytestring

  my $desc = describe_bytestring( $bytes, $start_address )

A convenience aid for examination of random bytestrings. Useful for those of
us who are not skilled enough to read hex dumps directly. For example:

  describe_bytestring( "Har har\t\x13\x37\xb0\x0b\x1e\x55 !!!", 46685601519 )

 returns the following on a little-endian system (regardless of pointer size):

              Hex  Dec  Oct    Bin     ASCII      32      32+2          64
             --------------------------------  -------- -------- ----------------
 0xadeadbeef   48   72  110  01001000    H     20726148          0972616820726148
 0xadeadbef0   61   97  141  01100001    a     ___/              _______/
 0xadeadbef1   72  114  162  01110010    r     __/      61682072 ______/
 0xadeadbef2   20   32   40  00100000  (SP)    _/       ___/     _____/
 0xadeadbef3   68  104  150  01101000    h     09726168 __/      ____/
 0xadeadbef4   61   97  141  01100001    a     ___/     _/       ___/
 0xadeadbef5   72  114  162  01110010    r     __/      37130972 __/
 0xadeadbef6   09    9   11  00001001  (HT)    _/       ___/     _/
 0xadeadbef7   13   19   23  00010011  (DC3)   0BB03713 __/      2120551E0BB03713
 0xadeadbef8   37   55   67  00110111    7     ___/     _/       _______/
 0xadeadbef9   B0  176  260  10110000  "\260"  __/      551E0BB0 ______/
 0xadeadbefa   0B   11   13  00001011  (VT)    _/       ___/     _____/
 0xadeadbefb   1E   30   36  00011110  (RS)    2120551E __/      ____/
 0xadeadbefc   55   85  125  01010101    U     ___/     _/       ___/
 0xadeadbefd   20   32   40  00100000  (SP)    __/      21212120 __/
 0xadeadbefe   21   33   41  00100001    !     _/       ___/     _/
 0xadeadbeff   21   33   41  00100001    !              __/
 0xadeadbf00   21   33   41  00100001    !              _/

=cut

# compile a list of short C0 code names (why doesn't charnames.pm provide me with this?)
my $ctrl_names;
for (qw/
  NUL SOH STX ETX EOT ENQ ACK BEL BS HT LF VT FF CR SO SI DLE DC1 DC2 DC3 DC4 NAK SYN ETB CAN EM SUB ESC FS GS RS US SP
/) {
  $ctrl_names->{scalar keys %$ctrl_names} = $_;
};
$ctrl_names->{127} = 'DEL';
for (values %$ctrl_names) {
  $_ = "($_)" . ( ' ' x (4 - length $_) );
}

sub describe_bytestring {
  my ($bytes, $start_addr) = @_;

  require Devel::PeekPoke::BigInt;
  $start_addr = Devel::PeekPoke::BigInt->new($start_addr || 0);

  my $len = length($bytes);

  my $max_addr_hexsize = length ( ($start_addr + $len)->as_unmarked_hex );
  $max_addr_hexsize = 7 if $max_addr_hexsize < 7; # to match perl itself (minimum 7 digits)
  my $addr_hdr_pad = ' ' x ($max_addr_hexsize + 3);

  my @out = (
    "$addr_hdr_pad Hex  Dec  Oct    Bin     ASCII  ",
    "$addr_hdr_pad-------------------------------- ",
  );

  if ($len > 3) {
    $out[0] .= '    32   ';
    $out[1] .= ' --------';
  }

  if ($len > 5) {
    $out[0] .= '   32+2  ';
    $out[1] .= ' --------';
  }

  if ($len > 7) {
    $out[0] .= '        64       ';
    $out[1] .= ' ----------------';
  }

  for my $off (0 .. $len - 1) {
    my $byte = substr $bytes, $off, 1;
    my ($val) = unpack ('C', $byte);
    push @out, sprintf( "0x%0${max_addr_hexsize}s   %02X % 4d % 4o  %s  %s",
      ($start_addr + $off)->as_unmarked_hex,
      ($val) x 3,
      unpack('B8', $byte),
      $ctrl_names->{$val} || ( $val > 127 ? sprintf('"\%o"', $val) : "  $byte   " ),
    );

    my @ints;
    for my $col_32 (0,2) {
      my $start_off_32 = ($off - $col_32) % 4;

      if ( ($off < $col_32) or ($len - $off + $start_off_32) < 4 ) {
        push @ints, (' ' x 8);
      }
      else {
        push @ints,
            $start_off_32 == 0 ? sprintf '%08X', unpack('L', substr $bytes, $off - $start_off_32, 4)
          : sprintf '%s/%s', '_' x (4 - $start_off_32), ' ' x ($start_off_32 + 3)
        ;
      }
    }

    # print as two successive 32bit values, based on the determined endianness
    # since the machine may very well not have unpack('Q',...)
    my $start_off_64 = $off % 8;
    if ( ($len - $off + $start_off_64) >= 8) {
      push @ints,
          $start_off_64 == 0 ? sprintf '%08X%08X', unpack('LL', BIG_ENDIAN
            ? substr( $bytes, $off, 8 )
            : substr( $bytes, $off + 4, 4 ) . substr( $bytes, $off, 4 )
          )
        : sprintf '%s/%s', '_' x (8 - $start_off_64), ' ' x ($start_off_64 + 7)
      ;
    }

    $out[-1] .= join ' ', ' ', @ints
      if @ints;
  }

  s/\s+$// for @out;
  join "\n", @out, '';
}

=head1 AUTHOR

ribasushi: Peter Rabbitson <ribasushi@cpan.org>

=head1 CONTRIBUTORS

None as of yet

=head1 COPYRIGHT

Copyright (c) 2011 the Devel::PeekPoke L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut

1;
