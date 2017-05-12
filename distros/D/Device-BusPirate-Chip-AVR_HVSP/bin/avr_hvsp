#!/usr/bin/perl

use strict;
use warnings;

use Device::BusPirate;
use Getopt::Long;
use List::Util 1.29 qw( pairs pairkeys );
use Time::HiRes qw( sleep );

use Future::Utils qw( repeat );

my %FORMATS = (
   i => "main::Fileformat::IntelHex",
   m => "main::Fileformat::Immediate",
   d => "main::Fileformat::Decimal",
   h => "main::Fileformat::Hex",
   o => "main::Fileformat::Octal",
);

my @MEMOPS;
GetOptions(
   'P|port=s' => \my $PIRATE,
   'b|baud=i' => \my $BAUD,
   'U|memop=s' => sub {
      my ( $memory, $op, $filename, $format ) = split /:/, $_[1];
      $format //= 'a';

      $op =~ m/^[rwv]$/ or
         die "Unrecognised file operation '$op'\n";
      $FORMATS{$format} or
         die "Unrecognised file format specifier '$format'\n";

      my $dir = ( $op eq "r" ) ? "out" : "in";
      my $handler = $FORMATS{$format}->${\"open_$dir"}( $filename );

      push @MEMOPS, [ $memory, $op, $handler ];
   },
   'v|verbose+'     => \my $VERBOSE,
   'e|erase'        => \my $CHIP_ERASE,
   'n|no-write'     => \my $NO_WRITE,
   'D|no-autoerase' => \my $NO_AUTOERASE,
   'backup-all=s'   => \my $BACKUP_ALL,
   'restore-all=s'  => \my $RESTORE_ALL,
) or exit 1;

$SIG{INT} = $SIG{TERM} = sub { exit };

my $pirate = Device::BusPirate->new(
   serial => $PIRATE,
   baud   => $BAUD,
);

my $avr = $pirate->mount_chip( "AVR_HVSP" )->get;

$avr->start->get;

print "Recognised part: $avr->{part}\n";

if( $VERBOSE ) {
   print "Memories:\n";
   printf "%-20s | %6s | %5s | %5s\n", "Name", "bits/w", "words", "bytes";

   foreach ( pairs $avr->memory_infos ) {
      my ( $name, $mem ) = @$_;

      printf "  %-16s%2s | %6s | %5s | %5s\n",
         $name, $mem->can_write ? "WR" : "RO", $mem->wordsize, $mem->words, $mem->wordsize * $mem->words / 8;
   }
}

if( $BACKUP_ALL ) {
   my $outfile = main::Fileformat::IntelHex->open_out( $BACKUP_ALL );

   # Lock has to be restored last
   foreach my $memory ( ( grep { $_ ne "lock" } pairkeys $avr->memory_infos ), "lock" ) {
      next unless $avr->memory_info( $memory )->can_write;

      $outfile->print( "#MEM $memory\n" );
      read_memory( $memory, $outfile );
   }
}

my $erased;

if( $CHIP_ERASE ) {
   die "Cannot erase chip in no-write mode\n" if $NO_WRITE;

   print "Erasing chip...\n";
   $avr->chip_erase->get;
   $erased++;
}

if( $RESTORE_ALL ) {
   my $infile = main::Fileformat::IntelHex->open_in( $RESTORE_ALL );

   while( !eof $infile ) {
      my $line = <$infile>;
      $line =~ m/^#MEM (.*)/ or next;

      write_memory( $1, $infile );
   }
}

my $exitcode = 0;

foreach ( @MEMOPS ) {
   my ( $memory, $op, $handler ) = @$_;

   if( $op eq "r" ) {
      read_memory( $memory, $handler );
   }
   elsif( $op eq "w" ) {
      write_memory( $memory, $handler ) or
         $exitcode = 1;
   }
   else {
      verify_memory( $memory, $handler ) or
         $exitcode = 1;
   }
}

print "Done\n";
exit $exitcode;

END {
   $avr and $avr->stop->get;
   $pirate and $pirate->stop;
}

sub read_memory
{
   my ( $memory, $handler ) = @_;

   my $info = $avr->memory_info( $memory );
   my $bytes = $info->words * $info->wordsize / 8;

   print "Reading $memory ($bytes bytes)...\n";
   my $data = $avr->${\"read_$memory"}->get;

   $handler->output( $data );
}

sub write_memory
{
   my ( $memory, $handler ) = @_;
   die "Cannot write $memory when in no-write mode\n" if $NO_WRITE;

   my $info = $avr->memory_info( $memory );
   my $bytes = $info->words * $info->wordsize / 8;

   my $data = $handler->input;

   if( $memory eq "eeprom" || $memory eq "flash" and !$erased and !$NO_AUTOERASE ) {
      print "Erasing chip...\n";
      $avr->chip_erase->get;
      $erased++;
   }

   print "Writing $memory ($bytes bytes)...\n";
   $avr->${\"write_$memory"}( $data )->get;

   return verify_memory( $memory, undef, $data );
}

sub verify_memory
{
   my ( $memory, $handler, $exp ) = @_;
   $exp //= $handler->input;

   print "Verifying $memory...\n";
   my $got = $avr->${\"read_$memory"}( bytes => length $exp )->get;

   $got eq $exp and return 1;

   my $addr = 0;
   $addr++ while substr( $got, $addr, 1 ) eq substr( $exp, $addr, 1 );
   print STDERR "Verify failed for $memory\n";
   printf STDERR "  at address [%04x]: read %02x vs expected %02x\n",
      $addr, ord substr( $got, $addr, 1 ), ord substr( $exp, $addr, 1 );
   return 0;
}

# IO formats
package main::Fileformat {
   use base 'IO::Handle';
   sub open_out {
      my $class = shift;
      my $fh;
      if( $_[0] eq "-" ) {
         $fh = IO::Handle->new_from_fd( STDOUT->fileno, "w" );
      }
      else {
         open $fh, ">", $_[0] or die "Cannot write $_[0] - $!\n";
      }
      return bless $fh, $class;
   }
   sub open_in {
      my $class = shift;
      my $fh;
      if( $_[0] eq "-" ) {
         $fh = IO::Handle->new_from_fd( STDIN->fileno, "r" );
      }
      else {
         open $fh, "<", $_[0] or die "Cannot read $_[0] - $!\n";
      }
      return bless $fh, $class;
   }
}
package main::Fileformat::out {
   use base 'main::Fileformat';
   sub open_in { die "This format does not support being read\n" }
}

package main::Fileformat::IntelHex {
   use base 'main::Fileformat';
   sub output {
      my $self = shift;
      my ( $bytes ) = @_;
      my $addr = 0;
      foreach my $chunk ( $bytes =~ m/(.{1,16})/gs ) {
         my $clen = length $chunk;
         my $cksum = $clen + ( $addr & 0xff ) + ( $addr >> 8 );
         $self->printf( ":%02X%04X%02X", $clen, $addr, 0 );
         foreach my $byte ( split //, $chunk ) {
            $byte = ord $byte;
            $cksum += $byte;
            $self->printf( "%02X", $byte );
         }
         $self->printf( "%02X\n", ( -$cksum ) & 0xff );
         $addr += $clen;
      }
      $self->print( ":00000001FF\n" );
   }
   sub input {
      my $self = shift;
      my $bytes = "";
      while( my $line = <$self> ) {
         chomp $line;
         next unless my ( $clen, $addr, $type, $data, $cksum ) =
            $line =~ m/^:([0-9a-f]{2})([0-9a-f]{4})([0-9a-f]{2})([0-9a-f]*)([0-9a-f]{2})$/i;
         # TODO: check checksum
         $type = hex $type;
         last if $type == 1; # EOF
         next if $type != 0; # unrecognised record
         warn "Bad record length on line $.\n" and next if
            length $data != 2 * hex $clen;
         $data = pack "H*", $data;
         substr( $bytes, hex $addr, length $data ) = $data;
      }
      return $bytes;
   }
}

package main::Fileformat::Immediate {
   use base 'main::Fileformat';
   sub open_out { die "This format does not support being written\n" }
   sub open_in {
      my $class = shift;
      my $bytes = join "", map { chr( m/^0/ ? hex : $_ ) } split m/[ ,]+/, $_[0];
      return bless \$bytes, $class;
   }
   sub input {
      return ${+shift};
   }
}

package main::Fileformat::Decimal {
   use base 'main::Fileformat::out';
   sub output {
      my $self = shift;
      my ( $bytes ) = @_;
      $self->print( join ",", unpack "C*", $bytes );
      $self->print( "\n" );
   }
}

package main::Fileformat::Hex {
   use base 'main::Fileformat::out';
   sub output {
      my $self = shift;
      my ( $bytes ) = @_;
      $self->print( join ",", map { sprintf "0x%x", $_ } unpack "C*", $bytes );
      $self->print( "\n" );
   }
}

package main::Fileformat::Octal {
   use base 'main::Fileformat::out';
   sub output {
      my $self = shift;
      my ( $bytes ) = @_;
      # Annoyingly, the avrdude octal format only prepends leading 0's if the
      # value actually requires it; there isn't a sprintf() format for that
      $self->print( join ",", map { $_ > 7 ? sprintf "%#o", $_ : $_ } unpack "C*", $bytes );
      $self->print( "\n" );
   }
}

=head1 NAME

C<avr_hvsp.pl> - an F<avrdude> clone to talk HVSP to AVR chips

=head1 SYNOPSIS

 avr_hvsp.pl [-e] [-n] [-D] [-U MEMORY:OP:FILE:FORMAT] ...

=head1 DESCRIPTION

This script implements a command that behaves somewhat like F<avrdude>, using
L<Device::BusPirate::Chip::AVR_HVSP> to talk to an F<AVR> chip in HVSP mode
via a suitable circuit attached to a F<Bus Pirate>. The module provides a
detailed description of a suitable circuit.

=head1 OPTIONS

The following options are designed to be compatible with F<avrdude>

=head2 -b, --baud RATE

Overrides the default baud rate of 115200, in case for some reason the
F<Bus Pirate> has been reconfigured. Normally it should not be necessary to
alter this.

=head2 -D, --no-autoerase

Skips the implied chip erase operation before writing the C<eeprom> or
C<flash> memories.

=head2 -e, --erase

Perform a full chip erase before other operations. Normally this is not
required because the memory writes that would require it (C<eeprom> and
C<flash>) normally do this automatically.

=head2 -n, --no-write

Do not perform any writes to the chip; restrict operation only to read and
verify.

=head2 -P, --port PORT

Device node where the F<Bus Pirate> can be found. If not supplied, the value
of the C<BUS_PIRATE> environment variable will be used, or F</dev/ttyUSB0> if
that is not defined.

=head2 -U, --memop MEMORY:OP:FILE:FORMAT

Performs a memory transfer operation of the C<OP> type (which may be C<r> for
read, C<w> for write, or C<v> for verify) with a chip memory. This is
transferred to or from a file whose name and format are given.

The types of memory and file formats are listed below. As a special extension,
the filename C<-> may be given, to read from standard input, or write to
standard output.

=head2 --backup-all FILE

Reads all of the chip memories that are writable (i.e. not the signature or
calibration) and writes their entire contents to the given file, in an
extension of the Intel Hex format, where each memory starts with a comment
giving its name.

=head2 --restore-all FILE

Writes memories to the chip from the given file in a format written by
C<backup-all>.

=head1 MEMORIES

The following memories are recognised

=over 4

=item * signature (read-only)

=item * calibration (read-only)

=item * lock

=item * lfuse, hfuse, efuse

=item * flash

=item * eeprom

=back

=head1 FILE FORMATS

The following file formats are recognised

=over 4

=item * Intel Hex (type C<i>)

=item * Decimal (type C<d>), Hexadecimal (type C<h>), Octal (type C<o>)

Output-only; writes a string of text, containing comma-separated integers for
each byte individually.

=item * Immediate (type C<m>)

Input-only; interprets the filename directly as a comma- or space-separated
list of integers in any of decimal, hexadecimal or octal form. Most useful for
setting fuses or lock bits.

=back

=head1 INCOMPATIBILITES

=over 4

=item *

This program only works with a F<Bus Pirate>, and only with those F<ATtiny>
devices that support HVSP mode.

=item *

Does not support other file formats - Motorola S-record, raw binary, ELF, or
binary textual encoding.

=item *

Does not implement F<avrdude> telnet mode, nor many of the other commandline
options.

=back

=head1 AUTHOR

Paul Evans <leonerd@leonerd.org.uk>

=cut
