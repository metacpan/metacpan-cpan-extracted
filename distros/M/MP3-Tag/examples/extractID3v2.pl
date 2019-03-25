#!/usr/bin/perl

my $filename = shift;
die "usage: extractID3v2 filename" unless defined $filename;
  
open FH, "<$filename" or die "Can't open $filename: $!\n";

seek(FH, 0,0);
read(FH, $header, 10);

if ($tagsize = read_header($header)) {
  read(FH, $tagdata, $tagsize);
  print $header, $tagdata;
} else {
  print "$filename: ID3v2 Tag not found\n";
}
sub read_header {
  my ($header) = @_;
  my %params;

  if (substr ($header,0,3) eq "ID3") {
    # get the tag size
    my $size=0;
    foreach (unpack("x6C4", $header)) {
      $size = ($size << 7) + $_;
    }
    return $size;
  }
  return 0; # ID3v2-Tag found
}
