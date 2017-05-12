package IO::Buffered; 
use strict;
use warnings;

our $VERSION = '1.00';

use Carp;

use IO::Buffered::Split;
use IO::Buffered::Regexp;
use IO::Buffered::Size;
use IO::Buffered::FixedSize;
use IO::Buffered::Last;
use IO::Buffered::HTTP;

=head1 NAME

IO::Buffered - A simple buffer class for dealing with different data types

=head1 SYNOPSIS

  my $buf = new IO::Buffered(Split => qr/,/);
  $buf->write("record1,reco")
  $buf->write("rd2,record3");

  my @records = $buf->read(); # @records is now ("record1", "record2")
  @records = $buf->read_last(); # @records is now ("record3")


=head1 DESCRIPTION

IO::Buffered provides a simple unified way of dealing with buffering. This is 
done by providing a set of buffering types each with an understanding of what 
they are buffering. All buffering types share a common set of function for 
working with the buffer.

=over 4

=item B<write($str,..)>

C<write()> appends more data to the buffer if the buffer type allows it.
Different types might have rules that prohibit the buffer for growing over a
certain limit or mandates that only certain types of data be written to the 
buffer.

In case of error the number of bytes written to the buffer is returned and the
function croaks. 

=item B<read($alt_size)>

C<read()> returns the number of ready records as defined by the buffer type or
returns an empty array when no records are available. Read records will be
cleared from the buffer. $alt_size defines alternative size of the next record
in the buffer if the buffer type does not know how much data to buffer before
returning the record. This is currently used by the HTTP buffer type when it is
in HeaderOnly mode and needs to return the data part of a http request.

=item B<read_last()>

C<read_last()> returns the number of ready records as defined by the buffer type and
the rest of the buffer as the last record. Or returns an empty array when no records 
are available. After C<read_last> is called the buffer will be empty.

=item B<flush($str, ...)>

C<flush()> flushes the buffer if no input or replace the buffer with the input.

=item B<buffer()>

C<buffer()> returns a copy of the buffer.

=item B<returns_last()>

C<returns_last()> tells if the buffer type knows if it's dealing with a 
complete record or not. Or a call to <read_last()> is need to get all valid 
records. An example of this is the "Split" buffer type where record delimiter
does not have to be at the end of every record:

  my $buffer = new IO::Buffered::Split(qr/\n/);
  $buffer->write("Hello\nHello");
  
  if($buffer->returns_last) {
      my @records = $buffer->read(); # @records would be ('Hello')
  } else {
      my @records = $buffer->read_last(); # @records is ('Hello', 'Hello')
  }

=cut

=back

=head1 BUFFER TYPES

=head2 Regexp

The Regexp buffer type takes a regular expression as input and splits records 
based on that. Only the match defined in the () is returned and not the 
complete match.

An example would be C<qr/^(.+)\n/> that would work as line buffing:

  my $buf = IO::Buffered(Regexp => qr/^(.+)\n/); 

Read more here: L<IO::Buffered::Regexp>

=head2 Split

Split is special case of the Regexp buffer type and is in essence just 
C</(.*?)$split/>. Here only the non matching part of $split is returned.

An example would be C<qr/\n/> that also works as line buffering or C<qr/\0/> 
for C strings.
  
  my $buf = IO::Buffered(Split => qr/\n/); 

Read more here: L<IO::Buffered::Split>

=head2 Size

The Size buffering type reads the size from the data to determine where record
boundaries are. Only the data is returned not the bytes that hold the length
information. Size buffering takes two arguments, a L<pack> template and a offset 
for the numbers of bytes to add to the length that was unpacked with the 
template.

An example would be a template of "n" and a offset of 0 that could be used to
handle DNS tcp requests. Offset defaults to 0 if not set.

  my $buf = IO::Buffered(Size => ["n", 0]); 

Read more here: L<IO::Buffered::Size>

=head2 FixedSize

FixedSize buffering returns records in fixed size chunks.

An example would to return 100 bytes at a time:

  my $buf = IO::Buffered(FixedSize => 100);

Read more here: L<IO::Buffered::FixedSize>

=head2 Last

Last buffering simple only returns one record when read_last is called. All
calls to read will return an empty array.

An example would be:

  my $buf = IO::Buffered(Last => 1);

Read more here: L<IO::Buffered::Last>

=head2 HTTP

HTTP buffering provides a simple buffering for HTTP traffic by looking for 
"Content-Length:" in the HTTP header. If one is found this will be used to 
split records. If not only the header will be returned. 

An example would be:

  my $buf = IO::Buffered(HTTP => 1);

Read more here: L<IO::Buffered::HTTP>

=head1 GENERIC OPTIONS

=head2 MaxSize

MaxSize provides a limit on how big a buffer can grow, when the limit is hit an
exception is thrown.

The default value for MaxSize is 0, meaning that there is no size limit on the 
buffer.

=head1 METHODS

=over

=cut

use base "Exporter";

our @EXPORT_OK = qw(recroak);

=item new()

IO::Buffered simple provides a wrapper for the different buffering types. The 
argument given to the buffer type is simply given as first argument to the 
constructor of the buffer type, as show below:

  $buf = Buffered::IO(Split => qr/\n/);

  # is the same as

  $buf = Buffered::IO::Split(qr/\n/);

Extra options are passed along as an array after first argument, as show below:

  $buf = Buffered::IO(Split => qr/\n/, MaxSize => 1000_000);

  # is the same as

  $buf = Buffered::IO::Split(qr/\n/, MaxSize => 1000_000);

Buffered::IO recasts exceptions so there is no differences in using either
interface. 

=cut

sub new {
    my ($class, %args) = @_;

    my ($type) = grep { exists $args{$_} }  
        qw(Split Regexp Size FixedSize Last HTTP); # Find buffer type 
    croak "Unknown or no buffer type defined" if !defined $type; 

    my %opts = map { $_ => $args{$_} } 
        grep { $_ ne $type } keys %args; # Get options for buffer type

    my $package = "IO::Buffered::$type";
    if($type =~ /HTTP|Last/) {
        return (eval { new $package(%opts); }
            or recroak($@));
    } else {
        return (eval { new $package($args{$type}, %opts); }
            or recroak($@));
    }
}

=item recroak()

Helper function to rethrow croaks

=cut

sub recroak {
  $_[0] =~ s/ at \S+ line \d+.*$//s;
  croak $_[0];
}

=back

=head1 AUTHOR

Troels Liebe Bentsen <tlb@rapanden.dk> 

=head1 COPYRIGHT

Copyright(C) 2008 Troels Liebe Bentsen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
