use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Role::Parser::Actions;

# ABSTRACT: Grammar actions role for .class file parsing

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Moo::Role;
#
# This package is part of the core of the engine. So it is optimized
# using directly the stack (i.e. no $self)
#
use Math::BigFloat qw//;
use Bit::Vector qw//;
use Scalar::Util qw/blessed/;
use constant {
  FLOAT_POSITIVE_INF => Math::BigFloat->binf(),
  FLOAT_NEGATIVE_INF => Math::BigFloat->binf('-'),
  FLOAT_NAN => Math::BigFloat->bnan(),
  FLOAT_POSITIVE_ONE => Math::BigFloat->new('1'),
  FLOAT_NEGATIVE_ONE => Math::BigFloat->new('-1'),
};


#
# Note: we use Bit::Vector for portability, some steps could have been replaced with unpack
#
sub _bytesToVector {
  #
  # Increase bit numbers by 1 ensure to_Dec() returns the unsigned version
  # Default is to not increase the number of bits, i.e. to_Dec() returns a signed value
  #
  my $vector = Bit::Vector->new($_[2] ? (8 * length($_[1]) + 1) : (8 * length($_[1])));
  $vector->Chunk_List_Store(8, reverse unpack('C*', $_[1])), $vector
}

# sub u1       { $_[0]->_bytesToVector($_[1], 1)->to_Dec }  # Ask for an unsigned value explicitely
# sub signedU1 { $_[0]->_bytesToVector($_[1]   )->to_Dec }
# sub u2       { $_[0]->_bytesToVector($_[1], 1)->to_Dec }  # Ask for an unsigned value explicitely
sub u1       { unpack('C', $_[1]) }
sub signedU1 { unpack('c', $_[1]) }
sub u2       { unpack('n', $_[1]) }
sub signedU2 { $_[0]->_bytesToVector($_[1]   )->to_Dec }
sub u4       { $_[0]->_bytesToVector($_[1], 1)->to_Dec }  # Ask for an unsigned value explicitely
sub signedU4 { $_[0]->_bytesToVector($_[1],  )->to_Dec }

my @bitsForFloatCmp =
  (
   Bit::Vector->new_Hex( 32, '7f800000' ),
   Bit::Vector->new_Hex( 32, 'ff800000' ),
   Bit::Vector->new_Hex( 32, '7f800001' ),
   Bit::Vector->new_Hex( 32, '7fffffff' ),
   Bit::Vector->new_Hex( 32, 'ff800001' ),
   Bit::Vector->new_Hex( 32, 'ffffffff' )
  );
my @bitsForFloatMantissa =
  (
   Bit::Vector->new_Hex( 32, 'ff'     ),
   Bit::Vector->new_Hex( 32, '7fffff' ),
   Bit::Vector->new_Hex( 32, '800000' )
  );
my @mathForFloat =
  (
   Math::BigFloat->new('150'),
   Math::BigFloat->new('2'),
  );

sub floatToString { $_[0]->double($_[1], $_[2])->bstr() }
sub float {
  my $vector = $_[0]->_bytesToVector($_[1]);

  my $value;
  if ($vector->equal($bitsForFloatCmp[0])) {
    $value = FLOAT_POSITIVE_INF->copy
  }
  elsif ($vector->equal( $bitsForFloatCmp[1])) {
    $value = FLOAT_NEGATIVE_INF->copy
  }
  elsif (
         (
          $vector->Lexicompare( $bitsForFloatCmp[2] ) >= 0  &&
          $vector->Lexicompare( $bitsForFloatCmp[3] ) <= 0
         )
         ||
         (
          $vector->Lexicompare( $bitsForFloatCmp[4] ) >= 0 &&
          $vector->Lexicompare( $bitsForFloatCmp[5] ) <= 0
         )
        ) {
    $value = FLOAT_NAN->copy
  }
  else {
    #
    # int s = ((bits >> 31) == 0) ? 1 : -1;
    #
    my $s = $vector->Clone();
    $s->Move_Right(31);
    my $sf = ($s->to_Dec() == 0) ? FLOAT_POSITIVE_ONE->copy() : FLOAT_NEGATIVE_ONE->copy();
    #
    # int e = ((bits >> 23) & 0xff);
    #
    my $e = $vector->Clone();
    $e->Move_Right(23);
    $e->And( $e, $bitsForFloatMantissa[0] );
    #
    # int m = (e == 0) ? (bits & 0x7fffff) << 1 : (bits & 0x7fffff) | 0x800000;
    #                     ^^^^^^^^^^^^^^^^^^^^^    ^^^^^^^^^^^^^^^^^^^^^^^^^
    #                                       \       /
    #                                        \     /
    #                                      same things
    #
    my $m = $vector->Clone();
    $m->And( $m, $bitsForFloatMantissa[1] );
    if ( $e->to_Dec() == 0 ) {
      $m->Move_Left(1)
    } else {
      $m->Or( $m, $bitsForFloatMantissa[2] )
    }
    #
    # $value = $s * $m * (2 ** ($e - 150))
    # Note: Bit::Vector->to_Dec() returns a string
    my $mf = Math::BigFloat->new($m->to_Dec());
    my $ef = Math::BigFloat->new($e->to_Dec());

    $ef->bsub($mathForFloat[0]);              # $e - 150
    my $mantissaf = $mathForFloat[1]->copy(); # 2
    $mantissaf->bpow($ef);                    # 2 ** ($e - 150)
    $mf->bmul($mantissaf);                    # $m * (2 ** ($e - 150))
    $mf->bmul($sf);                           # $s * $m * (2 ** ($e - 150))
    $value = $mf
  }

  $value
}

sub long {
  my $vhigh = $_[0]->_bytesToVector($_[1]);
  my $vlow  = $_[0]->_bytesToVector($_[2]);
  #
  # ((long) high_bytes << 32) + low_bytes
  #
  Bit::Vector->Concat_List($vhigh, $vlow)->to_Dec()
}

my @bitsForDoubleCmp = (
                       Bit::Vector->new_Hex( 64, "7ff0000000000000" ),
                       Bit::Vector->new_Hex( 64, "fff0000000000000" ),
                       Bit::Vector->new_Hex( 64, "7ff0000000000001" ),
                       Bit::Vector->new_Hex( 64, "7fffffffffffffff" ),
                       Bit::Vector->new_Hex( 64, "fff0000000000001" ),
                       Bit::Vector->new_Hex( 64, "ffffffffffffffff" )
                      );
my @bitsForDoubleMantissa =
  (
   Bit::Vector->new_Hex( 64, '7ff'           ),
   Bit::Vector->new_Hex( 64, 'fffffffffffff' ),
   Bit::Vector->new_Hex( 64, '10000000000000' )
  );
my @mathForDouble =
  (
   Math::BigFloat->new('1075'),
   Math::BigFloat->new('2'),
  );

sub doubleToString { $_[0]->double($_[1], $_[2])->bstr() }
sub double {
  my $vhigh = $_[0]->_bytesToVector($_[1]);
  my $vlow  = $_[0]->_bytesToVector($_[2]);
  #
  # ((long) high_bytes << 32) + low_bytes
  #
  my $vector = Bit::Vector->Concat_List($vhigh, $vlow);
  #
  # Same technique as in float
  #
  my $value;
  if ($vector->equal($bitsForDoubleCmp[0])) {
    $value = FLOAT_POSITIVE_INF->copy
  }
  elsif ($vector->equal( $bitsForDoubleCmp[1])) {
    $value = FLOAT_NEGATIVE_INF->copy
  }
  elsif (
         (
          $vector->Lexicompare( $bitsForDoubleCmp[2] ) >= 0  &&
          $vector->Lexicompare( $bitsForDoubleCmp[3] ) <= 0
         )
         ||
         (
          $vector->Lexicompare( $bitsForDoubleCmp[4] ) >= 0 &&
          $vector->Lexicompare( $bitsForDoubleCmp[5] ) <= 0
         )
        ) {
    $value = FLOAT_NAN->copy
  }
  else {
    #
    # int s = ((bits >> 63) == 0) ? 1 : -1;
    #
    my $s = $vector->Clone();
    $s->Move_Right(63);
    my $sf = ($s->to_Dec() == 0) ? FLOAT_POSITIVE_ONE->copy() : FLOAT_NEGATIVE_ONE->copy();
    #
    # int e = (int)((bits >> 52) & 0x7ffL);
    #
    my $e = $vector->Clone();
    $e->Move_Right(52);
    $e->And( $e, $bitsForDoubleMantissa[0] );
    #
    # long m = (e == 0) ? (bits & 0xfffffffffffffL) << 1 : (bits & 0xfffffffffffffL) | 0x10000000000000L;
    #                     ^^^^^^^^^^^^^^^^^^^^^^^^^        ^^^^^^^^^^^^^^^^^^^^^^^^^
    #                                             \       /
    #                                              \     /
    #                                            same things
    my $m = $vector->Clone();
    $m->And( $m, $bitsForDoubleMantissa[1] );
    if ( $e->to_Dec() == 0 ) {
      $m->Move_Left(1)
    } else {
      $m->Or( $m, $bitsForDoubleMantissa[2] )
    }
    #
    # $value = $s * $m * (2 ** ($e - 1075))
    #
    my $mf = Math::BigFloat->new($m->to_Dec());
    my $ef = Math::BigFloat->new($e->to_Dec());

    $ef->bsub($mathForDouble[0]);              # $e - 1075
    my $mantissaf = $mathForDouble[1]->copy(); # 2
    $mantissaf->bpow($ef);                     # 2 ** ($e - 150)
    $mf->bmul($mantissaf);                     # $m * (2 ** ($e - 150))
    $mf->bmul($sf);                            # $s * $m * (2 ** ($e - 150))
    $value = $mf
  }

  $value
}

sub utf8 {
  #
  # Disable all conversion warnings:
  # either we know we succeed, either we abort -;
  #
  no warnings;

  my $s = undef;
  return $s unless (length($_[1]));

  my @bytes = unpack('C*', $_[1]);
  my ($val0, $val1, $val2, $val3, $val4, $val5) = '';

  while (@bytes) {
    #
    # This is to avoid a internal op with ';' : @bytes is guaranteed to be shifted
    #
    if ((($val0 = shift(@bytes)) & 0x80) == 0) {              # 0x80 == 10000000                   => 0xxxxxxx
      #
      # 1 byte
      #
      $s .= chr($val0)
    }
    elsif ((($val0 & 0xE0) == 0xC0) &&                        # 0xE0 == 11100000, 0xC0 == 11000000 => 110xxxxx
           ($#bytes >= 0) &&
           ((($val1 = $bytes[0]) & 0xC0) == 0x80)) {          # 0xC0 == 11000000, 0x80 == 10000000 => 10xxxxxx
      #
      # 2 bytes
      #
      shift(@bytes), $s .= chr((($val0 & 0x1F) << 6) + ($val1 & 0x3F))
    }
    elsif (($val0 == 0xED) &&                                 # 0xED == 11101101                   => 11101101
           ($#bytes >= 4) &&
           ((($val1 = $bytes[0]) & 0xF0) == 0xA0) &&          # 0xF0 == 11110000, 0xA0 == 10100000 => 1010xxxx
           ((($val2 = $bytes[1]) & 0xC0) == 0x80) &&          # 0xC0 == 11000000, 0x80 == 10000000 => 10xxxxxx
           ( ($val3 = $bytes[2])         == 0xED) &&          # 0xED == 11101101                   => 11101101
           ((($val4 = $bytes[3]) & 0xF0) == 0xB0) &&          # 0xF0 == 11110000, 0xB0 == 10110000 => 1011xxxx
           ((($val5 = $bytes[4]) & 0xC0) == 0x80)) {          # 0xC0 == 11000000, 0x80 == 10000000 => 10xxxxxx
      #
      # 6 bytes, for supplementary characters are tested BEFORE 3 bytes, because it is a doubled 3-bytes encoding
      #
      splice(@bytes, 0, 5), $s .= chr(0x10000 + (($val1 & 0x0F) << 16) + (($val2 & 0x3F) << 10) + (($val4 & 0x0F) <<  6) + ($val5 & 0x3F))
    }
    elsif ((($val0 & 0xF0) == 0xE0) &&                      # 0xF0 == 11110000, 0xE0 == 11100000   => 1110xxxx
           ($#bytes >= 1) &&
           ((($val1 = $bytes[0]) & 0xC0) == 0x80) &&        # 0xC0 == 11000000, 0x80 == 10000000   => 10xxxxxx
           ((($val2 = $bytes[1]) & 0xC0) == 0x80)) {        # 0xC0 == 11000000, 0x80 == 10000000   => 10xxxxxx
      #
      # 3 bytes
      #
      splice(@bytes, 0, 2), $s .= chr((($val0 & 0xF ) << 12) + (($val1 & 0x3F) << 6) + ($val2 & 0x3F))
    }
    else {
      $_[0]->fatalf('Unable to map byte with value 0x%x', $val0)
    }
  }

  $s
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Role::Parser::Actions - Grammar actions role for .class file parsing

=head1 VERSION

version 0.008

=head1 DESCRIPTION

MarpaX::Java::ClassFile::ClassFile::Common::Actions is an internal class used by L<MarpaX::Java::ClassFile::ClassFile>, please refer to the later.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
