#!/usr/bin/perl -w

package File::GetLineMaxLength;

=head1 NAME

File::GetLineMaxLength - Get lines from a file, up to a maximum line length

=head1 SYNOPSIS

  use File::GetLineMaxLength;

  $FML = File::GetLineMaxLength->new(STDIN);

  # Read lines, up to 1024 chars
  while (my $Line = $FML->getline(1024, $Excess)) {
  }

=head1 DESCRIPTION

While generally reading lines of data is easy in perl (eg C<E<lt>$FhE<gt>>),
there's apparently no easy way to limit the read line to a maximum length
(as in the C call C<fgets(char *s, int size, FILE *stream)>). This can
lead to potential DOS situations in your code where an attacker can send
an arbitrarily large line and use up all your memory. Of course you can
use things like BSD::Resource to stop your program using all memory,
but that just kills off the process and gives you no more information
about what was causing the problem.

This question was raised on perlmonks, and the general
response seemed to be "roll your own using the C<read()>
call." L<http://www.perlmonks.org/index.pl?node_id=238980>

This module basically does that, but makes it reusable, so you can wrap
any handle and get line length limited IO.

=head1 IMPLEMENTATION

It basically creates an internal buffer, and uses C<read()> to read up to
4096 bytes at a time, looking for the appropriate EOL marker. When found,
it returns the line and leaves the remaining data in the internal buffer
for the next call.

Because of this internal buffering, you should NOT mix calling
C<getline()> via this class and any other standard IO calls on the file
handle you passed to C<new()>, you'll get surprising results.

=head1 PERFORMANCE

The code tries to be pretty careful performance wise (single buffer,
no copying, use index to find EOL), but because it's
perl, a tight loop is still an order of magnitude slower.

For instance, just a loop reading a file with 10,000 50 char or so
lines, 100 times:

  read: 0.588507
  glml read: 4.654946

However, if you do any work in the loop at all, that time difference
becomes quite a bit less.

Same as above, but do C<@_ = split / /> in the loop

  read: 8.688189
  glml read: 12.529909

So basically any "work" you do will probably easily swamp the read time

=cut

# Use modules {{{
our $VERSION = '1.01';

use strict;
# }}}

=head1 METHODS

=over 4
=cut

=item I<new($Handle)>

Wrap handle and return object which you can call C<getline($max_len)> on.

Note: See above about not calling any other IO calls on the passed handle
after you pass it to this C<new()> call.

=cut
sub new {
  my $Proto = shift;
  my $Class = ref($Proto) || $Proto;

  @_ >= 1 && @_ <= 2
    || die "Must call $Class->new(HANDLE)";

  my $Self = bless { }, $Class;

  # Save file handle
  my $Fd = $Self->{Fd} = shift;
  # Get current EOL chars for this file handle
  my $ofh = select($Fd); $Self->{EOL} = $/; select ($ofh);
  # Initialise empty read buffer
  $Self->{Buffer} = '';

  $Self->{ReadSize} = int(shift || 0) || 4096;

  return $Self;
}

=item I<getline([ $max_length, $was_long_line ])>

Get a line of data from the file handle, up to $max_length
bytes long. If no $max_length passed, works just like
standard perl <$fh>. If the $was_long_line variable is passed,
it's set to 0 or 1 depending on whether the line was
very long and has been truncated.

Note: Actually this might return up to $maxlength + length(EOL)
chars as the EOL chars are not considered part of the line
length. The current EOL chars for the file handle are gotten
via $/ when you called C<new()> above

=cut
sub getline {
  my ($Self, $MaxLength) = (shift, shift);

  # Get EOL char and reference to current line buffer
  my $EOL = $Self->{EOL};
  my $Buffer = \$Self->{Buffer};

  # Reset "line was long" marker if passed
  $_[0] = 0 if @_;

  while (1) {
    # Search for EOL chars in current buffer
    my $FoundLineLen = index($$Buffer, $EOL);

    # If EOL found...
    if ($FoundLineLen != -1) {

      # If no maxlen, or line is <= max length, just rip from buffer and return it
      if (!$MaxLength || $FoundLineLen <= $MaxLength) {
        return substr($$Buffer, 0, $FoundLineLen + length($EOL), '');

      # Otherwise, set $was_long_line param, and return up to max length chars
      } else {
        $_[0] = 1 if @_;
        return substr($$Buffer, 0, $MaxLength, '');
      }

    # No EOL found...
    } else {

      # Already > max length chars available, just return it
      if ($MaxLength && length($$Buffer) > $MaxLength + length($EOL)) {
        $_[0] = 1 if @_;
        return substr($$Buffer, 0, $MaxLength, '');
      }
    }

    # Otherwise grab more data and add to buffer
    my $BytesRead = read($Self->{Fd}, $$Buffer, $Self->{ReadSize}, length($$Buffer));
    defined($BytesRead) || die "getline failed: $!";

    # Reached EOF? Just return remnants from buffer
    if ($BytesRead == 0) {
      return substr($$Buffer, 0, length($$Buffer), '');
    }

  }

  die "Unexpected exit from loop";
}

=back
=cut

=head1 SEE ALSO

L<PerlIO::via>, L<IO::Handle>

Latest news/details can also be found at:

http://cpan.robm.fastmail.fm/filegetlinemaxlength/

=cut

=head1 AUTHOR

Rob Mueller E<lt>cpan@robm.fastmail.fmE<gt>.

=cut

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2007 by FastMail IP Partners

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

