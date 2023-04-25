#!/usr/bin/env perl

package File::MagicPP;

use strict;
use warnings;
use Data::Dumper;
use version 0.77;
use List::Util qw/min max/;

use Exporter qw/import/;

our @EXPORT_OK = qw(
  file
  $VERSION
  %magicLiteral
);

=pod

=head1 NAME

File::MagicPP

=head1 SYNOPSIS

This module provides file magic through pure perl and does not rely on
libraries external to Perl.

    use File::MagicPP qw/file/;
    my $type = file($0);
    # $type now holds "script"

=cut

=pod

=head1 VARIABLES

=head2 $VERSION

Describes the library version

=cut

our $VERSION = '0.2.1';

=pod

=head2 %magicLiteral

Provides a hash of magic bits to file type, e.g.,
BZh => "bz"

=cut

my %magicLiteral = (
  '@'            => "fastq",
  'BZh'          => "bz",
  '\x1f\x8b'     => "gz",
  #'\x1f\x8b\x08' => "gz",
  '>'            => "fasta",
  '\x5c\x67\x31' => "bam",
  '#!'           => "script",
  'GIF87a'       => "gif",
  'GIF89a'       => "gif",
  '\x49\x49\x2a\x00' => 'tif',
  '\x4d\x4d\x00\x2a' => 'tiff',
  '\xff\xd8\xff\xe0\x00\x10\x4a\x46' => 'jpg',
  '\x89\x50\x4e\x47\x0d\x0a\x1a\x0a' => 'png',
  '<svg'         => 'svg',
  '%PDF'         => 'pdf',
  'BM'           => 'bmp',
  '\xfd\x37\x7a\x58\x5a\x00' => 'xz',

);

my $maxMagicLength = max(map{length($_)} keys(%magicLiteral));

=pod

=head1 FUNCTIONS

=head2 file()

Give it a file path and it will tell you the file type.

=cut

sub file{
    my ($file_path) = @_;
    open(my $fh, '<:raw', $file_path) or die "Could not open file '$file_path': $!";
    my $header = <$fh>;
    chomp($header);
    close($fh);

    my $maxLength = min(length($header), $maxMagicLength);

    # For each possible length, look for keys that match the
    # header, longest to shortest.
    for(my $length=$maxLength; $length > 0; $length--){
      my $headerSubstr = substr($header, 0, $length);
      if($magicLiteral{$headerSubstr}){
        return $magicLiteral{$headerSubstr};
      }
    }

    # If we haven't found anything yet, see if it's just
    # letters and numbers for plaintext.
    if($header =~ /^[\w\d]+\s*/){
      return "plaintext";
    }

    # At this point, we just don't know
    return "UNKNOWN";
}

