package File::Utils;
use Modern::Perl;
use Carp;
use PerlIO::gzip;
use Exporter;

our $VERSION = '0.0.5'; # VERSION
# ABSTRACT: Provide various of file operation

our @ISA = ('Exporter');
our @EXPORT = ();
our @EXPORT_OK = qw/read_handle write_handle file2array/;
our %EXPORT_TAGS = (
  gz    => [qw/read_handle write_handle/],
  data  => [qw/file2array/]
);



sub read_handle {
  my $file = shift;
  my $handle;
  if ($file =~/\.gz$/) {
    open $handle, "<:gzip", $file;
  } else {
    open $handle, "<", $file;
  }
  $handle->autoflush;
  return $handle;
}


sub write_handle {
  my $file = shift;
  my $handle;
  if ($file =~/\.gz$/) {
    open $handle, ">:gzip", $file;
  } else {
    open $handle, ">", $file;
  }
  $handle->autoflush;
  return $handle;
}


sub file2array {
  my ($filename, $sep) = @_;
  $sep ||= "\t";
  open my $file, "<", "$filename";
  my @out;
  while (my $line = <$file>) {
    chomp($line);
    my @cols = split $sep, $line;
    push @out, \@cols;
  }
  close($file);
  return @out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Utils - Provide various of file operation

=head1 VERSION

version 0.0.5

=head1 SYNOPSIS

  use File::Utils qw/:gz/;
  my $r_gz = read_handle("test.fastq.gz");  # get a read filehandle of *.gz file
  my $r_normal = read_handle("test.txt");   # get a normal filehandle

  # obtain content of gz file
  $r_gz->getline                            # get a line of test.fastq.gz file
  $r_gz->getlines                           # get all lines of test.fastq.gz file

  my $w_gz = write_handle("test.fastq.gz")  # get a write filehandle of *.gz file 
  my $w_normal = write_handle("test.txt")   # get a normal write filehandle

  # write content to *gz or normal file
  $w_gz->print("the first line\n")          # write a str to test.fastq.gz file
  $w_gz->printf("sum value is %.2f", 1.234) # write a formatted string to test.fastq.gz file, just like sprintf

=head1 DESCRIPTION

This module will provide various of functions, and each one would conduct a series of operations.
The aim of this module is to simplify file operations and make file operation a enjoyment process.

Currently, it only offer the read_handle and write_handle that can process different types of file according
to the ext of filename. But more and more functions will be added subsequently and maintain this module constantly.

=head1 METHODS

=head2 read_handle

Obtain a read filehandle of different types of file according to the ext of a file. It simplified the process of dealing
with different types of file and finding specific module

=head2 write_handle

Obtain a write filehandle of different types of file according to the ext of a file. It simplified the process of dealing
with different types of file and finding specific module

=head2 file2array

Convert file path to two-dimension array

=head1 AUTHOR

Yan Xueqing <yanxueqing621@163.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yan Xueqing.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
