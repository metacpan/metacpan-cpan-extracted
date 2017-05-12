package Font::BDF::Reader;

use 5.008;
use strict;
use warnings;

use IO::File;
use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Font::BDF::Reader ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
);

our $VERSION = '0.01';

# Preloaded methods go here.

sub new {
  my $type	= shift;
  my $self	= { STARTCHAR	=> {},
		    ENCODING	=> {},
		  };

  bless $self, $type;

  my $bdf_file	= shift || "";
  if( $bdf_file ) {
    if( $self->open_bdf_file( $bdf_file ) ) {
      $self->read_bdf_file;
    }
  }
  return $self;
}

sub get_all_STARTCHAR {
  my $self		= shift;

  return sort keys %{$self->{STARTCHAR}};
}

sub get_all_ENCODING {
  my $self		= shift;

  return sort keys %{$self->{ENCODING}};
}

sub get_font_info_by_STARTCHAR {
  my $self		= shift;
  my $key		= shift;

  return $self->{STARTCHAR}{$key};
}

sub get_font_info_by_ENCODING {
  my $self		= shift;
  my $key		= shift;

  return $self->{ENCODING}{$key};
}

sub clear_cache {
  my $self		= shift;
  $self->{ENCODING}	= {};
  $self->{STARTCHAR}	= {};
}

sub clear_font_info_by_STARTCHAR {
  my $self		= shift;
  my $key		= shift;
  delete $self->{STARTCHAR}{$key};
}

sub clear_font_info_by_ENCODING {
  my $self		= shift;
  my $key		= shift;
  delete $self->{ENCODING}{$key};
}

sub open_bdf_file {
  my $self		= shift;
  my $bdf_file		= shift || die "No bdf file specified!";
  if( ! -f $bdf_file ) {
    die "bdf file '$bdf_file' not found!";
  }
  $self->{BDF_FILE}	= $bdf_file;
  my $FH		= IO::File->new( $bdf_file )
    || die "Can't open bdf file '$bdf_file'!";
  $self->{FH}		= $FH;

  return $self;
}

sub read_bdf_file {
  my $self		= shift;
  $self->read_bdf_metadata( @_ );

  $self->read_bdf_chars( @_ );
}

sub read_bdf_metadata {
  my $self		= shift;
  my $FH		= shift || $self->{FH} || die "No FH!";

  # Read in the metadata
  my $last_line		= "";
  my %METADATA	= ();
  while( <$FH> ) {
    chomp; chomp;
    my( $key, $val )	= split /\s+/, $_, 2;
    $METADATA{$key}	= $val;
    if( $key =~ /^CHARS$/i ) {
      $self->{METADATA}	= \%METADATA;
      last;
    }
  }
}

sub get_bdf_metadata {
  my $self		= shift;

  return $self->{METADATA};
}


sub read_bdf_chars {
  my $self		= shift;
  my $FH		= shift || $self->{FH} || die "No FH!";

  my $chars		= $self->{METADATA}{CHARS};
  my $chars_read	= 0;
  while( $self->read_bdf_char ) {
    $chars_read++;
  }

  if( $chars_read != $chars ) {
    warn "Chars read is $chars_read, expected $chars.\n";
  }
  return $self;
}


sub read_bdf_char {
  my $self		= shift;
  my $FH		= shift || $self->{FH} || die "No FH!";

  # Now, read in the character data:
  # STARTCHAR 7f56
  # ENCODING 32598
  # SWIDTH 150 0
  # DWIDTH 48 0
  # BBX 48 48 0 -2
  # BITMAP
  # 000000000000
  # ...
  # ENDCHAR

  my %char_data		= ();
  while( <$FH> ) {
    chomp; chomp;
    return 0	if( /ENDFONT/ or /^$/ );
    if( /^BITMAP/ ) {
      # Read the bitmap data
      my @bitmap_data	= ();
      while( <$FH> ) {
	chomp; chomp;
	last		if( /^ENDCHAR/ );
	push @bitmap_data, $_;			# Otherwise, store the line of data
      }
      $char_data{BITMAP}	= \@bitmap_data;
      last;
    }
    last		if( /^ENDCHAR/ );

    # Read metadata
    my($key,$val)	= split /\s+/, $_, 2;
    if( $key eq "STARTCHAR" or $val eq "ENCODING" ) {
      $char_data{$key}	= $val;
    }
    else {
      my @array_data	= split /\s+/, $val;
      $char_data{$key}	= \@array_data;
    }
  }
#  print Dumper( \%char_data );
  my $STARTCHAR	= $char_data{STARTCHAR};
  my $ENCODING	= $char_data{ENCODING};
  $self->{STARTCHAR}{$STARTCHAR}	= \%char_data;
  $self->{ENCODING}{$ENCODING}		= \%char_data;

  return $char_data{STARTCHAR};
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Font::BDF::Reader - Module for reading in BDF files

=head1 SYNOPSIS

  use Font::BDF::Reader;
  my $BDF		= Font::BDF::Reader->new( $bdf_filename );

  my @starchars		= $BDF->get_all_STARTCHAR;
  sub font_to_png {
    ...
  }
  foreach my $starchar (@starchars) {
    my $png_data	= font_to_png( $BDF->get_font_info_by_STARTCHAR( $starchar ) );
    my $png_file	= "$bdf_base.$starchar.png";
    my $FH		= IO::File->new( ">$png_file" )
      || die "Error opening file for write: '$png_file'";
    binmode $FH;
    print $FH $png_data;
  }

=head1 ABSTRACT

  This module supports importing data from BDF files.  A BDF file is
  an ASCII file that defines a font.  The fonts are bitmap fonts, and
  are easily converted to other formats.

=head1 DESCRIPTION

This module imports data from a BDF file.  Have a look at the BDF file
spec at http://partners.adobe.com/asn/developer/PDFS/TN/5005.BDF_Spec.pdf.

=head1 CONSTRUCTOR

=over 4

=item new ( [ BDF_FILE ] )

Creates a Font::BDF object.  If BDF_FILE is specified, it attempts to read
in the entire file.  (which can eat up a lot of memory, depending on the size
of the file)

=back

=head1 METHODS

=over 4

=item open_bdf_file ( BDF_FILE )

Opens a BDF file without doing anything.  Will die() if it can't find
or open BDF_FILE.

=item read_bdf_file

Assumes open_bdf_file() has been called.  It reads in the BDF metadata,
using read_bdf_metadata(), and then reads in ALL of the characters in
the BDF file using read_bdf_chars().  Will die() if the BDF file has not
been opened yet.

=item read_bdf_metadata

Attempts to read in the metadata block of the BDF file, which occurs
before any character data.  Assumes open_bdf_file() has been called.

=item get_bdf_metadata

Returns a HASHREF containing the metadata for the BDF file.  Each attribute
consists of a key-value pair.  The value is always one scalar.  Here's an
example of the metadata from a font file:

          'SIZE' => '48 100 100',
          'STARTFONT' => '2.1',
          'FONT_ASCENT' => '46',
          'FONT' => '-watanabe-fixed-medium-r-normal--48-450-75-75-c-480-jisx0208.1983-0',
          'COMMENT' => undef,
          'ENDPROPERTIES' => undef,
          'STARTPROPERTIES' => '4',
          'DEFAULT_CHAR' => '41377',
          'COPYRIGHT' => '"Public Domain"',
          'CHARS' => '8890',
          'FONTBOUNDINGBOX' => '48 48 0 -2',
          'FONT_DESCENT' => '2'

=item read_bdf_chars

Reads in ALL of the characters.  For a file containing 8000 characters,
each 48 by 48 pixels, approximately 16MB of memory is used.  Non-asian
character sets will have significantly smaller memory requirements.

This procedure also keeps track of the number of characters read, issuing
a warning if the number of characters does not equal the expected number
of characters as specified in the metadata section.

=item read_bdf_char

Reads in the next character.  Returns 0 if there are no more characters.

=item get_all_STARTCHAR

Returns all of the STARTCHAR keys in a list ordered alphabetically.
Each font has a unique STARTCHAR and ENCODING that it is indexed on.

=item get_all_ENCODING

Returns all of the ENCODING keys in a list ordered alphabetically.

=item get_font_info_by_STARTCHAR ( STARTCHAR )

Returns the font info for a particular STARTCHAR.  Returns undef if
no information exists for STARTCHAR.

The following is an example of font information returned by this
routine:
  {
          'BITMAP' => [
                        '000000000000',
                        <SNIP, SNIP>
                        '000000000000'
                      ],
          'ENCODING' => [
                          '8481'
                        ],
          'DWIDTH' => [
                        '48',
                        '0'
                      ],
          'BBX' => [
                     '48',
                     '48',
                     '0',
                     '-2'
                   ],
          'SWIDTH' => [
                        '150',
                        '0'
                      ],
          'STARTCHAR' => '2121'
  }

This is basically the most direct conversion from the BDF file
to a Perl hash.

=item get_font_info_by_ENCODING ( ENCODING )

Returns the font info for a particular ENCODING.  Returns undef if
no information exists for ENCODING

=item clear_cache

Clears the entire font cache.

=item clear_font_info_by_STARTCHAR ( STARTCHAR )

Clears the information for a font by STARTCHAR.

=item clear_font_info_by_ENCODING ( ENCODING )

Clears the information for a font by ENCODING.

=back

=head1 EXPORTS

Nothing.

=head1 SEE ALSO

See the script bdf2png for example usage of this module.

The specifications for the BDF format can be found here:
http://partners.adobe.com/asn/developer/PDFS/TN/5005.BDF_Spec.pdf.

=head1 AUTHOR

Desmond Lee, E<lt>dclee@shaw.ca<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Desmond Lee

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
