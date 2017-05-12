=head1 NAME

File::Rdiff -- generate remote signatures and patch files using librsync

=head1 SYNOPSIS

 use File::Rdiff

=head1 DESCRIPTION

A more-or-less direct interface to librsync (L<http://librsync.sourceforge.net/>).

For usage examples (better than this very sparse documentation), see the
two example scripts below.

=over 4

=cut

package File::Rdiff;

require DynaLoader;
require Exporter;

$VERSION = '1.0';
@ISA = qw/DynaLoader Exporter/;

bootstrap File::Rdiff $VERSION;

{
   my @loglevels = qw(LOG_EMERG LOG_ALERT LOG_CRIT LOG_ERR LOG_WARNING LOG_NOTICE LOG_INFO LOG_DEBUG);
   my @result = qw(DONE BLOCKED RUNNING TEST_SKIPPED IO_ERROR SYNTAX_ERROR MEM_ERROR INPUT_ENDED BAD_MAGIC UNIMPLEMENTED CORRUPT INTERNAL_ERROR PARAM_ERROR);

   %EXPORT_TAGS = (
           loglevels   => [@loglevels],
           trace       => [@loglevels, qw(trace_level trace_to)],
           result      => [@result],
           error       => [@result, qw(strerror)],
           file        => [@result, qw(md4_file sig_file loadsig_file delta_file patch_file)],
           nonblocking => [@result],
   );

   my %export_ok;
   @export_ok{map @$_, values %EXPORT_TAGS} = ();
   @EXPORT_OK = keys %export_ok;
}

=item LIBRSYNC_VERSION

A constant describing the version of the rsync library used in this
module. My version claimed to be "0.9.5 librsync" when I wrote this
document ;)

=item $oldlevel = trace_level [$newlevel]

Return the current tracelevel and optionally set a new one.

=item $oldcb = trace_to [$newcb]

Return the current trace callback and optionally set a new one. The callback will be
called with the log level as the first argument and the log message as the second one.

Calling C<trace_to> with C<undef> will restore the default handler (which
currently prints the message to standard error).

=item supports_trace

Returns wether debugging traces are supported in this version of the library.

=item $msg = strerror $rcode

Returns a string representation of the given error code. You usually
just "exit(1)" or something when a function/method fails, as all (most?)
librsync functions log the error properly, so there is rarely a need to
call this function.

=item $md4 = md4_file $fh

=item sig_file $old_fh, $sig_fh[, $block_len[, $strong_len]]

=item $sig = loadsig_file $fh

=item delta_file $signature, $new_fh, $delta_fh

=item patch_file $base_fh, $delta_fh, $new_fh

=back

=head2 The File::Rdiff::Job class

=head2 The File::Rdiff::Buffers class

This class contains the input and output buffers for the non-blocking interface. It is slightly unusual
in that it allows direct manipulation of (some) of it's internal variables.

=over 4

=item new File::Rdiff::Buffers [$outsize]

Creates and initializes a new buffers structure. C<$outsize> specifies
the maximum number of bytes to be read into the output scalar until it is
considered full. The default is 64k.

=item $buffers->in($in)

Set the next block of input to consume. Data will be read from this scalar
(no copy will be made!) until all bytes have been consumed or a new input
scalar is set.

=item $out = $buffers->out

Return the current output data and create a new buffer. Returns C<undef> if no data has been accumulated.

=item $buffers->eof

Set the eof flag to true. This indicates that no data is following the current input scalar.

=item $buffers->avail_in

Returns the numer of bytes still available for input. If there are no
input bytes available but the eof flag is set, returns -1 (to make boolean
tests easy to check wether to supply more data easier).

=item $buffers->avail_out

Returns the number of bytes still available in the output buffer.

=item $buffers->size

The number of bytes that have been accumulated in the current buffer so far.

=back

=head2 The File::Rdiff::Job class

It is possible to have multiple jobs running at the same time. The idea
is to create job objects and then drive them incrementally with input or
output data until all date has been processed.

=over 4

=item new_sig File::Rdiff::Job [$new_block_len[, $strong_sum_len]]

Create a job that converts a base stream into a signature stream (i.e. creates signatures).

=item new_loadsig File::Rdiff::Job

Create a job that converts the input stream into a in-memory
File::Rdiff::Signature object. The signature object can be fetched anytime
with the C<signature>-method.

=item new_delta File::Rdiff::Job $signature

Creates a job that creates (outputs) a delta between the input stream (the
newer file) and the file represented by the given signature.

=item new_patch File::Rdiff::Job $callback_or_filehandle

Creates a job that patches a file according to the input stream (a delta
stream). The single argument is used to read the base file contents. If it
is a filehandle, it must be a seekable handle to the base file.

If it is a coderef, it will be called whenever base file data must be
read. Two arguments will be passed: the file offset and the length. The
callback should eithe return the data read (must be a string, not a
number!) or an error code.

=item $job->iter($buffers)

Do as much work as possible given the input and/or output data in the
File::Rdiff::Buffers structure and return either C<DONE> when the job is
finished, C<BLOCKED> if there aren't enough bytes available in the input
or output buffers (in which case you should deplete the output buffer
and/or fill the input buffer and loop), or some error code indicating that
the operation failed.

=item $job->signature

Only valid for C<new_loadsig>, so look there.

=back

=head1 EXAMPLE PROGRAM ONE

Very simple program that mimics librsync's rdiff, using the simple file
utility functions. see example below for the same program, written using
the nonblocking API.

   #!/usr/bin/perl

   use File::Rdiff qw(:trace :file);

   trace_level(LOG_INFO);

   if ($ARGV[0] eq "signature") {
      open $base, "<$ARGV[1]" or die "$ARGV[1]: $!";
      open $sig,  ">$ARGV[2]" or die "$ARGV[2]: $!";

      File::Rdiff::sig_file $base, $sig;
   } elsif ($ARGV[0] eq "delta") {
      open $sig,   "<$ARGV[1]" or die "$ARGV[1]: $!";
      open $new,   "<$ARGV[2]" or die "$ARGV[2]: $!";
      open $delta, ">$ARGV[3]" or die "$ARGV[3]: $!";

      $sig = loadsig_file $sig;

      ref $sig or exit 1;

      $sig->build_hash_table;

      File::Rdiff::delta_file $sig, $new, $delta;
   } elsif ($ARGV[0] eq "patch") {
      open $base,  "<$ARGV[1]" or die "$ARGV[1]: $!";
      open $delta, "<$ARGV[2]" or die "$ARGV[2]: $!";
      open $new,   ">$ARGV[3]" or die "$ARGV[3]: $!";

      File::Rdiff::patch_file $base, $delta, $new;
   } else {
      print <<EOF;
   $0 signature BASE SIGNATURE
   $0 delta SIGNATURE NEW DELTA
   $0 patch BASE DELTA NEW
   EOF
      exit (1);
   }

=head1 EXAMPLE PROGRAM TWO

Same as above, but written using the callback-based, "nonblocking", API.

   #!/usr/bin/perl

   use File::Rdiff qw(:trace :nonblocking);

   trace_level(LOG_INFO);

   if ($ARGV[0] eq "signature") {
      open $basis, "<", $ARGV[1]
         or die "$ARGV[1]: $!";
      open $sig, ">", $ARGV[2]
         or die "$ARGV[2]: $!";

      my $job = new_sig File::Rdiff::Job 128;
      my $buf = new File::Rdiff::Buffers 4096;

      while ($job->iter($buf) == BLOCKED) {
         # fetch more input data
         $buf->avail_in or do {
            my $in;
            65536 == sysread $basis, $in, 65536 or $buf->eof;
            $buf->in($in);
         };
         print $sig $buf->out;
      }
      print $sig $buf->out;

   } elsif ($ARGV[0] eq "delta") {
      open $sig,   "<$ARGV[1]" or die "$ARGV[1]: $!";
      open $new,   "<$ARGV[2]" or die "$ARGV[2]: $!";
      open $delta, ">$ARGV[3]" or die "$ARGV[3]: $!";

      # first load the signature into memory
      my $job = new_loadsig File::Rdiff::Job;
      my $buf = new File::Rdiff::Buffers 0;

      do {
         $buf->avail_in or do {
            my $in;
            65536 == sysread $sig, $in, 65536 or $buf->eof;
            $buf->in($in);
         };
      } while $job->iter($buf) == BLOCKED;

      $sig = $job->signature;

      $sig->build_hash_table;

      # now create the delta file
      my $job = new_delta File::Rdiff::Job $sig;
      my $buf = new File::Rdiff::Buffers 65536;

      do {
         $buf->avail_in or do {
            my $in;
            65536 == sysread $new, $in, 65536 or $buf->eof;
            $buf->in($in);
         };
         print $delta $buf->out;
      } while $job->iter($buf) == BLOCKED;
      print $delta $buf->out;

   } elsif ($ARGV[0] eq "patch") {
      open $base,  "<$ARGV[1]" or die "$ARGV[1]: $!";
      open $delta, "<$ARGV[2]" or die "$ARGV[2]: $!";
      open $new,   ">$ARGV[3]" or die "$ARGV[3]: $!";

      # NYI
      File::Rdiff::patch_file $base, $delta, $new;
   } else {
      print <<EOF;
   $0 signature BASIS SIGNATURE
   $0 delta SIGNATURE NEW DELTA
   $0 patch BASE DELTA NEW
   EOF
      exit (1);
   }

=head1 SEE ALSO

L<File::Rsync>, L<rdiff1> (usage example using simple file API), L<rdiff2> (example using nonblocking API).

=head1 BUGS

- not well-tested so far.

- low memory will result in segfaults rather than croaks.

- no access to statistics yet

- documentation leaves much to be deserved.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1;

