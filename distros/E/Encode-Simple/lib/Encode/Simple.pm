package Encode::Simple;

use strict;
use warnings;
use Carp ();
use Encode ();
use Exporter 'import';

our $VERSION = '0.002';

our @EXPORT = qw(encode decode);
our @EXPORT_OK = qw(encode_lax decode_lax);
our %EXPORT_TAGS = (all => [@EXPORT, @EXPORT_OK], strict => \@EXPORT, lax => \@EXPORT_OK);

use constant MASK_STRICT => Encode::FB_CROAK | Encode::LEAVE_SRC;
use constant MASK_LAX => Encode::FB_DEFAULT | Encode::LEAVE_SRC;

my %ENCODINGS;

sub encode {
  my ($encoding, $input) = @_;
  return undef unless defined $input;
  my $obj = $ENCODINGS{$encoding} || _find_encoding($encoding);
  my ($output, $error);
  { local $@; use warnings FATAL => 'utf8'; # Encode::Unicode throws warnings in this category
    unless (eval { $output = $obj->encode("$input", MASK_STRICT); 1 }) { $error = $@ || 'Error' }
  }
  _rethrow($error) if defined $error;
  return $output;
}

sub encode_lax {
  my ($encoding, $input) = @_;
  return undef unless defined $input;
  my $obj = $ENCODINGS{$encoding} || _find_encoding($encoding);
  my ($output, $error);
  { local $@; no warnings 'utf8'; # Encode::Unicode throws warnings in this category
    unless (eval { $output = $obj->encode("$input", MASK_LAX); 1 }) { $error = $@ || 'Error' }
  }
  _rethrow($error) if defined $error;
  return $output;
}

sub decode {
  my ($encoding, $input) = @_;
  return undef unless defined $input;
  my $obj = $ENCODINGS{$encoding} || _find_encoding($encoding);
  my ($output, $error);
  { local $@; use warnings FATAL => 'utf8'; # Encode::Unicode throws warnings in this category
    unless (eval { $output = $obj->decode("$input", MASK_STRICT); 1 }) { $error = $@ || 'Error' }
  }
  _rethrow($error) if defined $error;
  return $output;
}

sub decode_lax {
  my ($encoding, $input) = @_;
  return undef unless defined $input;
  my $obj = $ENCODINGS{$encoding} || _find_encoding($encoding);
  my ($output, $error);
  { local $@; no warnings 'utf8'; # Encode::Unicode throws warnings in this category
    unless (eval { $output = $obj->decode("$input", MASK_LAX); 1 }) { $error = $@ || 'Error' }
  }
  _rethrow($error) if defined $error;
  return $output;
}

sub _find_encoding {
  my ($encoding) = @_;
  Carp::croak('Encoding name should not be undef') unless defined $encoding;
  my $obj = Encode::find_encoding($encoding);
  Carp::croak("Unknown encoding '$encoding'") unless defined $obj;
  return $ENCODINGS{$encoding} = $obj;
}

sub _rethrow {
  my ($error) = @_;
  die $error if ref $error or $error =~ m/\n(?!\z)/;
  $error =~ s/ at .+? line [0-9]+\.\n\z//;
  Carp::croak($error);
}

1;

=head1 NAME

Encode::Simple - Encode and decode text, simply

=head1 SYNOPSIS

  use Encode::Simple qw(encode decode encode_lax decode_lax);
  my $characters = decode 'cp1252', $bytes;
  my $characters = decode_lax 'UTF-8', $bytes;
  my $bytes = encode 'Shift_JIS', $characters;
  my $bytes = encode_lax 'ASCII', $characters;

=head1 DESCRIPTION

This module is a simple wrapper around L<Encode> that presents L</"encode"> and
L</"decode"> functions with straightforward behavior and error handling. See
L<Encode::Supported> for a list of supported encodings.

=head1 FUNCTIONS

All functions are exported by name, as well as via the tags C<:all>,
C<:strict>, and C<:lax>. By default, L</"encode"> and L</"decode"> are
exported.

=head2 encode

  my $bytes = encode $encoding, $characters;

Encodes the input string of characters into a byte string using C<$encoding>.
Throws an exception if the input string contains characters that are not valid
or possible to represent in C<$encoding>.

=head2 encode_lax

  my $bytes = encode_lax $encoding, $characters;

Encodes the input string of characters as in L</"encode">, but instead of
throwing an exception on invalid input, any invalid characters are encoded as a
substitution character (the substitution character used depends on the
encoding). Note that some encoders do not respect this option and may throw an
exception anyway, this notably includes L<Encode::Unicode> (but not UTF-8).

=head2 decode

  my $characters = decode $encoding, $bytes;

Decodes the input byte string into a string of characters using C<$encoding>.
Throws an exception if the input bytes are not valid for C<$encoding>.

=head2 decode_lax

  my $characters = decode_lax $encoding, $bytes;

Decodes the input byte string as in L</"decode">, but instead of throwing an
exception on invalid input, any malformed bytes will be decoded to the Unicode
replacement character (U+FFFD). Note that some encoders do not respect this
option and may throw an exception anyway, this notably includes
L<Encode::Unicode> (but not UTF-8).

=head1 BUGS

Report any issues on the public bugtracker.

=head1 AUTHOR

Dan Book <dbook@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Dan Book.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=head1 SEE ALSO

L<Unicode::UTF8>
