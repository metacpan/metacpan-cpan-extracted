package Encode::Simple;

use strict;
use warnings;
use Carp ();
use Encode ();
use Exporter 'import';

our $VERSION = '1.002';

our @EXPORT = qw(encode encode_utf8 decode decode_utf8);
our @EXPORT_OK = qw(encode_lax encode_utf8_lax decode_lax decode_utf8_lax);
our %EXPORT_TAGS = (
  all => [@EXPORT, @EXPORT_OK],
  strict => [qw(encode encode_utf8 decode decode_utf8)],
  lax => [qw(encode_lax encode_utf8_lax decode_lax decode_utf8_lax)],
  utf8 => [qw(encode_utf8 encode_utf8_lax decode_utf8 decode_utf8_lax)],
);

use constant HAS_UNICODE_UTF8 => do { local $@; !!eval { require Unicode::UTF8; 1 } };
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

sub encode_utf8 {
  my ($input) = @_;
  return undef unless defined $input;
  my ($output, $error);
  if (HAS_UNICODE_UTF8) {
    local $@; use warnings FATAL => 'utf8'; # Unicode::UTF8 throws warnings in this category
    unless (eval { $output = Unicode::UTF8::encode_utf8($input); 1 }) { $error = $@ || 'Error' }
  } else {
    my $obj = $ENCODINGS{'UTF-8'} || _find_encoding('UTF-8');
    local $@;
    unless (eval { $output = $obj->encode("$input", MASK_STRICT); 1 }) { $error = $@ || 'Error' }
  }
  _rethrow($error) if defined $error;
  return $output;
}

sub encode_utf8_lax {
  my ($input) = @_;
  return undef unless defined $input;
  my ($output, $error);
  if (HAS_UNICODE_UTF8) {
    local $@; no warnings 'utf8'; # Unicode::UTF8 throws warnings in this category
    unless (eval { $output = Unicode::UTF8::encode_utf8($input); 1 }) { $error = $@ || 'Error' }
  } else {
    my $obj = $ENCODINGS{'UTF-8'} || _find_encoding('UTF-8');
    local $@;
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

sub decode_utf8 {
  my ($input) = @_;
  return undef unless defined $input;
  my ($output, $error);
  if (HAS_UNICODE_UTF8) {
    local $@; use warnings FATAL => 'utf8'; # Unicode::UTF8 throws warnings in this category
    unless (eval { $output = Unicode::UTF8::decode_utf8($input); 1 }) { $error = $@ || 'Error' }
  } else {
    my $obj = $ENCODINGS{'UTF-8'} || _find_encoding('UTF-8');
    local $@;
    unless (eval { $output = $obj->decode("$input", MASK_STRICT); 1 }) { $error = $@ || 'Error' }
  }
  _rethrow($error) if defined $error;
  return $output;
}

sub decode_utf8_lax {
  my ($input) = @_;
  return undef unless defined $input;
  my ($output, $error);
  if (HAS_UNICODE_UTF8) {
    local $@; no warnings 'utf8'; # Unicode::UTF8 throws warnings in this category
    unless (eval { $output = Unicode::UTF8::decode_utf8($input); 1 }) { $error = $@ || 'Error' }
  } else {
    my $obj = $ENCODINGS{'UTF-8'} || _find_encoding('UTF-8');
    local $@;
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

  use Encode::Simple qw(encode encode_lax encode_utf8 decode decode_lax decode_utf8);
  my $bytes = encode 'Shift_JIS', $characters;
  my $bytes = encode_lax 'ASCII', $characters;
  my $bytes = encode_utf8 $characters;
  my $characters = decode 'cp1252', $bytes;
  my $characters = decode_lax 'UTF-8', $bytes;
  my $characters = decode_utf8 $bytes;

=head1 DESCRIPTION

This module is a simple wrapper around L<Encode> that presents L</"encode"> and
L</"decode"> functions with straightforward behavior and error handling. See
L<Encode::Supported> for a list of supported encodings.

=head1 FUNCTIONS

All functions are exported by name, as well as via the tags C<:all>,
C<:strict>, C<:lax>, and C<:utf8>. By default, L</"encode">, L</"encode_utf8">,
L</"decode">, and L</"decode_utf8"> are exported as in L<Encode>.

=head2 encode

  my $bytes = encode $encoding, $characters;

Encodes the input string of characters into a byte string using C<$encoding>.
Throws an exception if the input string contains characters that are not valid
or possible to represent in C<$encoding>.

=head2 encode_lax

  my $bytes = encode_lax $encoding, $characters;

Encodes the input string of characters into a byte string using C<$encoding>,
encoding any invalid characters as a substitution character (the substitution
character used depends on the encoding). Note that some encoders do not respect
this option and may throw an exception anyway, this notably includes
L<Encode::Unicode> (but not UTF-8).

=head2 encode_utf8

  my $bytes = encode_utf8 $characters;

I<Since version 1.000.>

Encodes the input string of characters into a UTF-8 byte string. Throws an
exception if the input string contains characters that are not valid or
possible to represent in UTF-8.

This function will use the more consistent and efficient
L<Unicode::UTF8/"encode_utf8"> if installed, and is otherwise equivalent to
L</"encode"> with an encoding of C<UTF-8>. It is B<not> equivalent to
L<Encode/"encode_utf8">, which should be avoided.

=head2 encode_utf8_lax

  my $bytes = encode_utf8_lax $characters;

I<Since version 1.000.>

Encodes the input string of characters into a UTF-8 byte string, encoding any
invalid characters as the Unicode replacement character C<U+FFFD>, represented
in UTF-8 as the three bytes C<0xEFBFBD>.

This function will use the more consistent and efficient
L<Unicode::UTF8/"encode_utf8"> if installed, and is otherwise equivalent to
L</"encode_lax"> with an encoding of C<UTF-8>. It is B<not> equivalent to
L<Encode/"encode_utf8">, which should be avoided.

=head2 decode

  my $characters = decode $encoding, $bytes;

Decodes the input byte string into a string of characters using C<$encoding>.
Throws an exception if the input bytes are not valid for C<$encoding>.

=head2 decode_lax

  my $characters = decode_lax $encoding, $bytes;

Decodes the input byte string into a string of characters using C<$encoding>,
decoding any malformed bytes to the Unicode replacement character (U+FFFD).
Note that some encoders do not respect this option and may throw an exception
anyway, this notably includes L<Encode::Unicode> (but not UTF-8).

=head2 decode_utf8

  my $characters = decode_utf8 $bytes;

I<Since version 1.000.>

Decodes the input UTF-8 byte string into a string of characters. Throws an
exception if the input bytes are not valid for UTF-8.

This function will use the more consistent and efficient
L<Unicode::UTF8/"decode_utf8"> if installed, and is otherwise equivalent to
L</"decode"> with an encoding of C<UTF-8>. It is B<not> equivalent to
L<Encode/"decode_utf8">, which should be avoided.

=head2 decode_utf8_lax

  my $characters = decode_utf8_lax $bytes;

I<Since version 1.000.>

Decodes the input UTF-8 byte string into a string of characters, decoding any
malformed bytes to the Unicode replacement character C<U+FFFD>.

This function will use the more consistent and efficient
L<Unicode::UTF8/"decode_utf8"> if installed, and is otherwise equivalent to
L</"decode_lax"> with an encoding of C<UTF-8>. It is B<not> equivalent to
L<Encode/"decode_utf8">, which should be avoided.

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
