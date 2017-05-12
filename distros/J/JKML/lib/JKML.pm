package JKML;
use 5.008005;
use strict;
use warnings;
use parent qw(Exporter);
use Encode ();
use MIME::Base64 ();
use Types::Serialiser;
use B ();
use Scalar::Util ();

our @EXPORT = qw(decode_jkml encode_jkml);

our $VERSION = "0.01";

our @HERE_QUEUE;
our $SELF;

# JKML is based on JSON::Tiny.
# JSON::Tiny was "Adapted from Mojo::JSON and Mojo::Util".

# Licensed under the Artistic 2.0 license.
# http://www.perlfoundation.org/artistic_license_2_0.

sub new {
  my $class = shift;
  bless {
    functions => {
      base64 => \&MIME::Base64::decode_base64,
    }
  }, $class;
}

sub call {
  my ($self, $name, $vref) = @_;
  my $code = $self->{functions}->{$name};
  unless ($code) {
    _exception("Unknown function: $name");
  }
  $code->($vref);
}

my $TRUE  = $Types::Serialiser::true;
my $FALSE = $Types::Serialiser::false;

# Escaped special character map (with u2028 and u2029)
my %ESCAPE = (
  '"'     => '"',
  '\\'    => '\\',
  '/'     => '/',
  'b'     => "\x08",
  'f'     => "\x0c",
  'n'     => "\x0a",
  'r'     => "\x0d",
  't'     => "\x09",
  'u2028' => "\x{2028}",
  'u2029' => "\x{2029}"
);
my %REVERSE = map { $ESCAPE{$_} => "\\$_" } keys %ESCAPE;

for( 0x00 .. 0x1f, 0x7f ) {
  my $packed = pack 'C', $_;
  $REVERSE{$packed} = sprintf '\u%.4X', $_
    if ! defined( $REVERSE{$packed} );
}

my $WHITESPACE_RE = qr/[\x20\x09]/;
my $COMMENT_RE = qr!#[^\n]*(?:\n|\z)!;
my $IGNORABLE_RE = qr!(?:$WHITESPACE_RE|$COMMENT_RE)*!;
my $LEFTOVER_RE = qr!(?:$WHITESPACE_RE|$COMMENT_RE|[\x0d\x0a])*!;

sub decode_jkml { JKML->new->decode(shift) }
sub encode_jkml { JKML->new->encode(shift) }


sub decode {
  my ($self, $bytes) = @_;

  local $SELF = $self;
  local @HERE_QUEUE;

  # Missing input
  die 'Missing or empty input' unless $bytes;

  # Wide characters
  die 'Wide character in input'
    unless utf8::downgrade($bytes, 1);

  # Object or array
  my $res = eval {
    local $_ = $bytes;

    # Leading whitespace
    _skip_space();

    # value
    my $ref;
    _decode_value(\$ref);

    # Leftover data
    _skip_space();
    unless (pos() == length($_)) {
      my $got = ref $ref ? lc(ref($ref)) : 'scalar';
      _exception("Unexpected data after $got");
    }

    $ref;
  };

  # Exception
  if (!$res && (my $e = $@)) {
    chomp $e;
    die $e;
  }

  return $res;
}

sub false {$FALSE}

sub true {$TRUE}

sub _decode_array {
  my @array;
  _skip_space();
  until (m/\G\]/gc) {

    # Value
    _decode_value(\($array[0+@array]));

    # Separator
    my $found_separator = 0;
    _skip_space();
    if (m/\G,/gc) {
        $found_separator++;
    }

    # End
    _skip_space();
    last if m/\G\]/gc;

    _skip_space();
    redo if $found_separator;

    # Invalid character
    _exception('Expected comma or right square bracket while parsing array');
  }

  return \@array;
}

sub _decode_object {
  my %hash;
  _skip_space();
  until (m/\G\}/gc) {
    # Key
    my $key = do {
      _skip_space();
      if (m/\G([A-Za-z][a-zA-Z0-9_]*)/gc) {
        $1;
      } else {
        # Quote
        m/\G"/gc
            or _exception('Expected string while parsing object');

        _decode_string();
      }
    };

    # Colon
    _skip_space();
    m/\G=>/gc
      or _exception('Expected "=>" while parsing object');

    # Value
    _decode_value(\$hash{$key});

    # Separator
    _skip_space();
    my $found_separator = 0;
    $found_separator++ if m/\G,/gc;

    # End
    _skip_space();
    last if m/\G\}/gc;

    _skip_space();
    redo if $found_separator;

    # Invalid character
    _exception('Expected comma or right curly bracket while parsing object');
  }

  return \%hash;
}

sub _decode_string {
  my $quote = shift;
  my $pos = pos;
  # Extract string with escaped characters
  m!\G((?:(?:[^\x00-\x1f\\${quote}]|\\(?:[${quote}\\/bfnrt]|u[0-9a-fA-F]{4})){0,32766})*)!gc; # segfault on 5.8.x in t/20-mojo-json.t #83
  my $str = $1;

  # Invalid character
  unless (m/\G${quote}/gc) {
    _exception('Unexpected character or invalid escape while parsing string')
      if m/\G[\x00-\x1f\\]/;
    _exception('Unterminated string');
  }

  # Unescape popular characters
  if (index($str, '\\u') < 0) {
    $str =~ s!\\(["\\/bfnrt])!$ESCAPE{$1}!gs;
    return $str;
  }

  # Unescape everything else
  my $buffer = '';
  while ($str =~ m/\G([^\\]*)\\(?:([^u])|u(.{4}))/gc) {
    $buffer .= $1;

    # Popular character
    if ($2) { $buffer .= $ESCAPE{$2} }

    # Escaped
    else {
      my $ord = hex $3;

      # Surrogate pair
      if (($ord & 0xf800) == 0xd800) {

        # High surrogate
        ($ord & 0xfc00) == 0xd800
          or pos($_) = $pos + pos($str), _exception('Missing high-surrogate');

        # Low surrogate
        $str =~ m/\G\\u([Dd][C-Fc-f]..)/gc
          or pos($_) = $pos + pos($str), _exception('Missing low-surrogate');

        # Pair
        $ord = 0x10000 + ($ord - 0xd800) * 0x400 + (hex($1) - 0xdc00);
      }

      # Character
      $buffer .= pack 'U', $ord;
    }
  }

  # The rest
  return $buffer . substr $str, pos($str), length($str);
}

sub _skip_space {
  while (m/\G$IGNORABLE_RE/gc) {
    if (m/\G\x0d?\x0a/gc) {
      if (@HERE_QUEUE) {
        my ($v, $terminator) = @{pop @HERE_QUEUE};
        if (m/\G(.*?)^([ \t]*)$terminator$/gcsm) {
          my $buf = $1;
          my $dedent = $2;
          $buf =~ s/^$dedent//mg;
          $buf =~ s/\n\z//;
          $$v = $buf;
        } else {
          _exception("Unexpected EOF in heredoc: '$terminator'");
        }
      }
    }
  }
}

sub _decode_value {
  my $r = shift;

  # Leading whitespace
  _skip_space();

  # funcall
  if (m/\G([a-zA-Z][a-zA-Z0-9_]*)\(/gc) {
    my $func = $1;
    _decode_value(\my $v);
    m/\G\)/gc or _exception("Missing ) after funcall");
    return $$r = $SELF->call($func, $v);
  }

  # heredoc
  if (m/\G<<-([A-Za-z.]+)/gc) {
    push @HERE_QUEUE, [$r, $1];
    return;
  }

  # Raw string
  return $$r = $2 if m/\Gr('''|""""|'|")(.*?)\1/gc;

  # String
  return $$r = _decode_string($1) if m/\G(["'])/gc;

  # Array
  return $$r = _decode_array() if m/\G\[/gc;

  # Object
  return $$r = _decode_object() if m/\G\{/gc;

  # Number
  return $$r = 0 + $1
    if m/\G([-]?(?:0|[1-9][0-9]*)(?:\.[0-9]*)?(?:[eE][+-]?[0-9]+)?)/gc;

  # True
  return $$r = $TRUE if m/\Gtrue/gc;

  # False
  return $$r = $FALSE if m/\Gfalse/gc;

  # Null
  return $$r = undef if m/\Gnull/gc;  ## no critic (return)

  # Invalid character
  _exception('Expected string, array, object, number, boolean or null');
}

sub _exception {

  # Leading whitespace
  _skip_space();

  # Context
  my $context = 'Malformed JKML: ' . shift;
  if (m/\G\z/gc) { $context .= ' before end of data' }
  else {
    my @lines = split /\n/, substr($_, 0, pos);
    $context .= ' at line ' . @lines . ', offset ' . length(pop @lines || '');
  }

  die "$context\n";
}

# -------------------------------------------------------------------------

sub encode {
  my ($self, $ref) = @_;
  return Encode::encode 'UTF-8', _encode_value($ref);
}

sub _encode_array {
  my $array = shift;
  return '[' . join(',', map { _encode_value($_) } @$array) . ']';
}

sub _encode_object {
  my $object = shift;
  my @pairs = map { _encode_string($_) . '=>' . _encode_value($object->{$_}) }
    keys %$object;
  return '{' . join(',', @pairs) . '}';
}

sub _encode_string {
  my $str = shift;
  $str =~ s!([\x00-\x1f\x7f\x{2028}\x{2029}\\"/\b\f\n\r\t])!$REVERSE{$1}!gs;
  return "\"$str\"";
}

sub _encode_value {
  my $value = shift;

  # Reference
  if (my $ref = ref $value) {

    # Array
    return _encode_array($value) if $ref eq 'ARRAY';

    # Object
    return _encode_object($value) if $ref eq 'HASH';

    # True or false
    return Types::Serialiser::is_true($value)  ? 'true' : 'false' if Types::Serialiser::is_bool($ref);

    # References to scalars (including blessed) will be encoded as Booleans.
    return $$value ? 'true' : 'false' if $ref =~ /SCALAR/;

  }

  # Null
  return 'null' unless defined $value;

  # Number
  my $flags = B::svref_2object(\$value)->FLAGS;
  return 0 + $value if $flags & (B::SVp_IOK | B::SVp_NOK) && $value * 0 == 0;

  # String
  return _encode_string($value);
}

1;
__END__

=encoding utf-8

=head1 NAME

JKML - Just K markup language

=head1 SYNOPSIS

    use JKML;

    decode_jkml(<<'...');
    [
      {
        # heh.
        input => "hoghoge",
        expected => "hogehoge",
        description => <<-EOF,
        This markup language is human writable.
        
        JKML supports following features:

          * heredoc
          * raw string.
          * comments
        EOF
        regexp => r" ^^ \s+ ",
      }
    ]
    ...

=head1 DESCRIPTION

JKML is parser library for JKML. JKML is yet another markup language.

B<This module is alpha state. Any API will change without notice.>

=head2 What's difference between JSON?

JKML extends following features:

=over 4

=item Raw strings

=item Comments

=back

These features are very useful for writing test data.

=head1 JKML and encoding

You MUST use UTF-8 for every JKML data.

=head1 JKML Grammar

=over 4

=item Raw strings

JKML allows raw strings. Such as following:

    raw_string =
          "r'" .*? "'"
        | 'r"' .*? '"'
        | 'r"""' .*? '"""'
        | "r'''" .*? "'''"

Every raw string literals does not care about non terminater characters.

  r'hoge'
  r"hoge"
  r"""hoge"""
  r'''hoge'''

=item Comments

Perl5 style comemnt is allowed.

    # comment

=item String

String literal is compatible with JSON.

        string = sqstring | dqstring

         dqstring = '"' dqchar* '"'
         sqstring = "'" sqchar* "'"

         dqchar = unescaped | "'" | escaped
         sqchar = unescaped | '"' | escaped

         escaped = escape (
                    %x22 /          ; "    quotation mark  U+0022
                    %x5C /          ; \    reverse solidus U+005C
                    %x2F /          ; /    solidus         U+002F
                    %x62 /          ; b    backspace       U+0008
                    %x66 /          ; f    form feed       U+000C
                    %x6E /          ; n    line feed       U+000A
                    %x72 /          ; r    carriage return U+000D
                    %x74 /          ; t    tab             U+0009
                    %x75 4HEXDIG )  ; uXXXX                U+XXXX

         escape = %x5C              ; \

         quotation-mark = %x22      ; "

         unescaped = [^"'\]

=item Number

Number literal is compatible with JSON. See JSON RFC.

    3
    3.14
    3e14

=item Map

Map literal's grammar is:

    pair = string "=>" value
    map = "{" "}"
        | "{" pair ( "," pair )* ","?  "}"

You can omit quotes for keys, if you don't want to type it.

You can use trailing comma unlike JS.

Examples:

    {
        a => 3,
        "b" => 4,
    }

=item Array

    array = "[" "]"
          | "[" value ( "," value )* ","? "]"

Examples:

    [1,2,3]
    [1,2,3,]

=item heredoc

Ruby style heredoc.

    <<-TOC
    hoghoge
    TOC

=item Value

    value = map | array | string | raw_string | number | funcall

=item Boolean

    bool = "true" | "false"

=item NULL

    null = "null"

Will decode to C<undef>.

=item Function call

  funcall = ident "(" value ")"
  ident = [a-zA-Z_] [a-zA-Z0-9_]*

JKML supports some builtin functions.

=back

=head1 Builtin functions

=over 4

=item base64

Decode base64 string.

    base64(string)

=back

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=head1 LICENSE

Copyright (C) tokuhirom

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head2 JSON::Tiny LICENSE

This library uses JSON::Tiny's code. JSON::Tiny's license term is following:

Copyright 2012-2013 David Oswald.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.
See http://www.perlfoundation.org/artistic_license_2_0 for more information.


=cut

