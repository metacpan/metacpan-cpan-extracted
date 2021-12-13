package Decode::ARGV;

use strict;
use warnings;
use Encode::Simple qw(decode decode_lax decode_utf8 decode_utf8_lax);

our $VERSION = '1.001';

sub import {
  my ($class, $mode, $encoding) = @_;
  if (defined $mode and !defined $encoding and $mode ne 'strict' and $mode ne 'lax') {
    $encoding = $mode;
  }
  my @args;
  if (defined $mode and $mode eq 'lax') {
    if (!defined $encoding or lc($encoding) eq 'utf-8') {
      @args = map { decode_utf8_lax $_ } @ARGV;
    } else {
      @args = map { decode_lax $encoding, $_ } @ARGV;
    }
  } else {
    if (!defined $encoding or lc($encoding) eq 'utf-8') {
      @args = map { decode_utf8 $_ } @ARGV;
    } else {
      @args = map { decode $encoding, $_ } @ARGV;
    }
  }
  # only munge @ARGV if we got this far
  @ARGV = @args;
  1;
}

1;

=encoding UTF-8

=head1 NAME

Decode::ARGV - Decode the command-line arguments to characters

=head1 SYNOPSIS

  use Decode::ARGV; # decodes from UTF-8

  use Decode::ARGV 'cp1252';

  $ perl -MDecode::ARGV -E'say "Argument contains only word characters" unless $ARGV[0] =~ m/\W/' 'слово'

=head1 DESCRIPTION

This module provides simple in-place decoding of command-line arguments in the global array
L<@ARGV|perlvar/"@ARGV">. As with most input and output, command-line arguments are provided to the
script in bytes, and must be decoded to characters before performing string operations like
C<length> or regex matches.

The C<-CA> switch for Perl performs a similar function, but this has some deficiencies. It assumes
via the C<:utf8> internal layer that the arguments are valid UTF-8 bytes, ignoring invalid Unicode,
and even resulting in malformed strings if the bytes do not happen to be well-formed UTF-8. This
switch is also difficult to use in a script and cannot decode the arguments from other encodings.

=head1 PARAMETERS

  use Decode::ARGV;
  use Decode::ARGV 'lax';
  use Decode::ARGV 'Shift_JIS';
  use Decode::ARGV lax => 'Shift_JIS';

  $ perl -MDecode::ARGV ...
  $ perl -MDecode::ARGV=lax ...
  $ perl -MDecode::ARGV=Shift_JIS ...
  $ perl -MDecode::ARGV=lax,Shift_JIS ...

By default, C<Decode::ARGV> will decode C<@ARGV> in-place using L<Encode::Simple/decode_utf8>,
which will throw an exception if any argument doesn't contain valid well-formed UTF-8 bytes.

C<lax> can be specified as the first (optional) import parameter to instead use
L<Encode::Simple/decode_utf8_lax>, leaving replacement characters in the resulting strings instead
of throwing an exception.

The next optional import parameter specifies an alternate encoding to expect from the command-line,
in which case L<Encode::Simple/decode> or L<Encode::Simple/decode_lax> will be used to decode the
arguments from that encoding.

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Encode::Simple>
