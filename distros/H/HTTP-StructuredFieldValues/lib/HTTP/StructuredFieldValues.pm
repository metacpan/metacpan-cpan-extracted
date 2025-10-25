package HTTP::StructuredFieldValues;

use strict;
use warnings;

use Encode qw(decode_utf8 encode_utf8);
use Math::BigFloat;
use MIME::Base64;
use Tie::IxHash;

use Exporter 'import';

our $VERSION = '0.01';
our @EXPORT_OK = qw(encode decode_dictionary decode_list decode_item);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub encode {
    my ($data) = @_;
    
    if (ref($data) eq 'HASH') {
        if (!exists $data->{_type} || ref($data->{_type}) eq 'HASH') {
            # Dictionary
            return _encode_dictionary($data);
        } else {
            # Item
            return _encode_item($data);
        }
    } elsif (ref($data) eq 'ARRAY') {
        # List
        return _encode_list($data);
    } else {
        die "Invalid data type for encoding";
    }
}

# Encode List (RFC 9651 Section 4.1.1)
sub _encode_list {
    my ($list) = @_;
    my @parts;
    
    for my $item (@$list) {
        if (!_valid_data_type($item)) {
            die "Invalid item in list";
        }
        if ($item->{_type} eq 'inner_list') {
            my $items = $item->{value};
            my $params = $item->{params} || {};
            my $inner = _encode_inner_list($items);
            $inner .= _encode_parameters($params);
            push @parts, $inner;
        } else {
            push @parts, _encode_item($item);
        }
    }
    
    return join(', ', @parts);
}

# Encode Inner list (RFC 9651 Section 4.1.1.1)
sub _encode_inner_list {
    my ($list) = @_;
    my @parts;

    for my $item (@$list) {
        if (!_valid_data_type($item)) {
            die "Invalid item in inner list";
        }
        push @parts, _encode_item($item);
    }
    return'(' . join(' ', @parts) . ')';
}

# Encode parameters (RFC 9651 Section 4.1.1.2)
sub _encode_parameters {
    my ($params) = @_;
    my @parts;
    my $ret = '';
    
    for my $key (keys %$params) {
        $ret .= ';';
        my $encoded_key = _encode_key($key);
        $ret .= $encoded_key;
        my $value = $params->{$key};
        if (!_valid_data_type($value)) {
            die "Invalid parameter value";
        }
        if ($value->{_type} eq 'boolean' && $value->{value}) {
            # Boolean true parameter
        } else {
            $ret .= "=" . _encode_bare_item($value);
        }
    }
    return $ret;
}

# Encode key (RFC 9651 Section 4.1.1.3)
sub _encode_key {
    my ($key) = @_;
    die "Invalid key: $key" unless $key =~ /^[a-z*][a-z0-9_\-.*]*$/;
    return $key;
}

# Encode Dictionary (RFC 9651 Section 4.1.2)
sub _encode_dictionary {
    my ($dict) = @_;
    my @parts;
    
    for my $key (keys %$dict) {
        my $value = $dict->{$key};
        if (!_valid_data_type($value)) {
            die "Invalid value in dictionary for key: $key";
        }
        my $encoded_key = _encode_key($key);
        my $item;
        
        if ($value->{_type} eq 'boolean' && $value->{value}) {
            # Boolean true
            $item = $encoded_key;
            $item .= _encode_parameters($value->{params}) if exists $value->{params};
        } else {
            $item = $encoded_key . '=';
            if ($value->{_type} eq 'inner_list') {
                my $items = $value->{value};
                my $params = $value->{params} || {};
                $item .= _encode_inner_list($items);
                $item .= _encode_parameters($params);
            } else {
                $item .= _encode_item($value);
            }
        }
        push @parts, $item;
    }
    
    return join(', ', @parts);
}

# Encode item (RFC 9651 Section 4.1.3)
sub _encode_item {
    my ($item) = @_;

    my $params = $item->{params} || {};
    
    my $result = _encode_bare_item($item);
    $result .= _encode_parameters($params);
    
    return $result;
}

# Encode bare item (RFC 9651 Section 4.1.3.1)
sub _encode_bare_item {
    my ($item) = @_;

    my $type = $item->{_type};
    my $value = $item->{value};
    
    if ($type eq 'integer') {
        return _encode_integer($value);
    } elsif ($type eq 'decimal') {
        return _encode_decimal($value);
    } elsif ($type eq 'string') {
        return _encode_string($value);
    } elsif ($type eq 'date') {
        return _encode_date($value);
    } elsif ($type eq 'displaystring') {
        return _encode_displaystring($value);
    } elsif ($type eq 'token') {
        return _encode_token($value);
    } elsif ($type eq 'binary') {
        return ':' . encode_base64($value, '') . ':';
    } elsif ($type eq 'boolean') {
        return $value ? '?1' : '?0';
    } else {
        die "Unknown type: $type";
    }
}

# Encode integer (RFC 9651 Section 4.1.4)
sub _encode_integer {
    my ($value) = @_;
    $value .= '';
    if ($value =~ /^-?\d{1,15}$/) {
        return $value;
    } else {
        die "Invalid integer value: $value";
    }
}

# Encode decimal (RFC 9651 Section 4.1.5)
sub _encode_decimal {
    my $value = Math::BigFloat->new($_[0]);
    $value->bfround(-3);
    my ($d, $f) = split /\./, $value->bstr;
    $d =~ s/^-//;
    if (length $d > 12) {
        die "Decimal value out of range: $value : " . length $d;
    }
    my $ret = $value->bstr;
    $ret =~ s/(.+\.\d+?)0+$/$1/;

    return $ret;
}

# Encode string (RFC 9651 Section 4.1.6)
sub _encode_string {
    my ($str) = @_;
    if ($str =~ /[^\x20-\x7E]/) {
        die "Invalid character in string: " . $str;
    }
    $str =~ s/\\/\\\\/g;
    $str =~ s/"/\\"/g;
    return '"' . $str . '"';
}

# Encode token (RFC 9651 Section 4.1.7)
sub _encode_token {
    my ($token) = @_;
    die "Invalid key: $token" unless $token =~ /^([a-zA-Z*][a-zA-Z0-9:\/!#\$%&'*+\-.^_`|~]*)$/;
    return $token;
}

# Encode date (RFC 9651 Section 4.1.10)
sub _encode_date {
    my ($value) = @_;
    
    if ($value !~ /^-?\d+$/) {
        die "Invalid date value: $value";
    }
    
    return '@' . $value;
}

# Encode displaystring (RFC 9651 Section 4.1.11)
sub _encode_displaystring {
    my ($str) = @_;
    
    my $bytes = encode_utf8($str);
    
    my $output = '%"';
    
    for (my $i = 0; $i < length($bytes); $i++) {
        my $byte = substr($bytes, $i, 1);
        my $ord = ord($byte);
        
        if ($ord == 0x22 || $ord == 0x25 || $ord <= 0x1F || $ord >= 0x7F) {
            $output .= sprintf('%%%02x', $ord);
        } else {
            $output .= $byte;
        }
    }
    
    $output .= '"';
    return $output;
}

sub _valid_data_type {
    my ($data) = @_;
    return ref($data) eq 'HASH' 
        && exists $data->{_type} 
        && exists $data->{value};
}

sub decode_item {
    my ($string) = @_;
    if (!defined $string) {
        die "Undefined argument";
    }
    
    $string =~ s/^ +//;
    $string =~ s/ +$//;
    
    # Empty string
    return {} if $string eq '';

    my ($item, $rest) = _decode_item($string);
    if ($rest ne '') {
        die "Unexpected characters after item: $rest";
    }
    return $item;
}

# Decode List (RFC 9651 Section 4.2.1)
sub decode_list {
    my ($string) = @_;
    my @list;
    if (!defined $string) {
        die "Undefined argument";
    }
    
    while ($string =~ /\S/) {
        $string =~ s/^\s*//;
        
        my ($decoded, $rest) = _decode_item_or_inner_list($string);
        push @list, $decoded;
        $string = $rest;
        
        $string =~ s/^\s*//;
        last if $string eq '';
        if ($string !~ /^,/) {
            die "Expected comma after dictionary item: $string";
        }
        $string =~ s/^,\s*//;
        if ($string eq '') {
            die "Unexpected end of string after comma in dictionary: $string";
        }
    }
    
    return \@list;
}

# Decode Inner list or item (4.2.1.1)
sub _decode_item_or_inner_list {
    my ($string) = @_;
    
    if ($string =~ /^\(/) {
        # Inner list
        return _decode_inner_list($string);
    } else {
        # Regular item
        return _decode_item($string);
    }
}

# Decode Inner list (RFC 9651 Section 4.2.1.2)
sub _decode_inner_list {
    my ($string) = @_;
    my @inner;
    $string =~ s/^\(\s*//;

    while ($string !~ /^\)/) {
        my ($item, $rest) = _decode_item($string);
        push @inner, $item;
        $string = $rest;
        
        if ($string =~ /^ *\)/) {
            $string =~ s/^ *//;
            last;
        }
        
        if ($string =~ /^ +/) {
            $string =~ s/^ +//;
        } else {
            die "Expected space or ) in inner list";
        }
    }
    
    $string =~ s/^\)//;
    
    my $params = {};
    ($params, $string) = _decode_parameters($string);
    
    my $inner_list;
    if (keys %$params) {
        $inner_list = {
            _type => 'inner_list',
            value => \@inner,
            params => $params
        };
    } else {
        $inner_list = {
            _type => 'inner_list',
            value => \@inner,
        };
    }
    return ($inner_list, $string);
}

# Decode Dictionary (RFC 9651 Section 4.2.2)
sub decode_dictionary {
    my ($string) = @_;
    if (!defined $string) {
        die "Undefined argument";
    }

    tie my %dict, 'Tie::IxHash';
    
    $string =~ s/^ *//;
    while ($string =~ /^[^ ]/) {
        if ($string !~ /^([a-z*][a-z0-9_\-.*]*)/) {
            die "Invalid dictionary key format: $string";
        }
        my $key = $1;
        $string =~ s/^[a-z*][a-z0-9_\-.*]*//;
        
        if ($string =~ /^=/) {
            $string =~ s/^=//;
            my ($value, $rest) = _decode_item_or_inner_list($string);
            $dict{$key} = $value;
            $string = $rest;
        } else {
            my $item = { _type => 'boolean', value => 1 };  # Boolean true
            my ($params, $rest) = _decode_parameters($string);
            if (keys %$params) {
                $item->{params} = $params;
            }
            $dict{$key} = $item;
            $string = $rest;
        }
        
        $string =~ s/^\s*//;
        last if $string eq '';
        if ($string !~ /^,/) {
            die "Expected comma after dictionary item: $string";
        }
        $string =~ s/^,\s*//;
        if ($string eq '') {
            die "Unexpected end of string after comma in dictionary: $string";
        }
    }
    return \%dict;
}

# Decode item (RFC 9651 Section 4.2.3)
sub _decode_item {
    my ($string) = @_;
    
    my ($bare_item, $rest) = _decode_bare_item($string);
    
    my $params;
    ($params, $rest) = _decode_parameters($rest);
    
    if (keys %$params) {
        $bare_item->{params} = $params;
    }
    
    return ($bare_item, $rest);
}

# Decode bare item (RFC 9841 Section 4.2.3.1)
sub _decode_bare_item {
    my ($string) = @_;
    
    if ($string =~ /^[-\d]/) {
        return _decode_number($string);
    }
    elsif ($string =~ /^"/) {
        return _decode_string($string);
    }
    elsif ($string =~ /^[a-zA-Z*]/) {
        return _decode_token($string);
    }
    elsif ($string =~ /^:/) {
        return _decode_binary($string);
    }
    elsif ($string =~ /^\?/) {
        return _decode_boolean($string);
    }
    elsif ($string =~ /^@/) {
        return _decode_date($string);
    }
    elsif ($string =~ /^%"/) {
        return _decode_displaystring($string);
    }
    
    die "Unable to parse bare item: $string";
}

# Decode parameters (RFC 9651 Section 4.2.3.2)
sub _decode_parameters {
    my ($string) = @_;
    my $params = {};
    
    while ($string =~ /^;/) {
        $string =~ s/^; *//;
        if ($string !~ /^([a-z*][a-z0-9_\-.*]*)/) {
            die "Invalid parameter format: $string";
        }
        my $key = $1;
        $string =~ s/^([a-z*][a-z0-9_\-.*]*)//;
        
        if ($string =~ /^=/) {
            $string =~ s/^=//;
            my ($value, $rest) = _decode_bare_item($string);
            $params->{$key} = $value;
            $string = $rest;
        } else {
            # Boolean true parameter
            $params->{$key} = { _type => 'boolean', value => 1 };
        }
    }
    
    return ($params, $string);
}

# Decode Number (RFC 9841 Section 4.2.4)
sub _decode_number {
    my ($string) = @_;
    my $v = $string;
    my $sign = '';
    my $i = '';
    my $f = '';

    if ($string =~ /^-/) {
        $sign = '-';
        $string =~ s/^-?//;
    }

    if ($string !~ /^(\d+)/) {
        die "Invalid decimal: $v";
    }

    $i = $1;
    $string =~ s/^\d+//;
    if ($string !~ /^\./) {
        if (length($i) > 15) {
            die "Integer too long: $i";
        }
        return ({ _type => 'integer', value => int($sign . $i) }, $string);
    }

    if (length($i) > 12) {
        die "Integer part too long: $i";
    }

    $string =~ s/^\.//;

    if ($string !~ /^(\d+)/) {
        die "Point without decimal: $v";
    }

    $f = $1;
    $string =~ s/^\d+//;

    if (length($f) > 3) {
        die "Decimal part too long: $f";
    }
    if ($string =~ /^\./) {
        die "Double point: $v";
    }

    return ({ _type => 'decimal', value => ($sign . $i . '.' . $f) + 0 }, $string);
}

# Decode String (RFC 9841 Section 4.2.5)
sub _decode_string {
    my ($string) = @_;
    
    $string =~ s/^"//;
    my $value = '';

    while ($string ne '') {
        my $c = substr($string, 0, 1, '');
        if ($c eq '\\') {
            if ($string eq '') {
                die "Unterminated string";
            }
            my $c2 = substr($string, 0, 1, '');
            if ($c2 eq '"' || $c2 eq '\\') {
                $value .= $c2;  # エスケープされた文字
            } else {
                die "Invalid escape sequence in string: \\$c2";
            }
            next;
        } elsif ($c eq '"') {
            return ({ _type => 'string', value => $value }, $string);
        } elsif (ord($c) < 0x20 || ord($c) > 0x7E) {
            die "Invalid character in string: " . ord($c);
        }
        $value .= $c;
    }
    die "Unterminated string";
}

# Decode Token (RFC 9841 Section 4.2.6)
sub _decode_token {
    my ($string) = @_;
    
    $string =~ /^([a-zA-Z*][a-zA-Z0-9:\/!#\$%&'*+\-.^_`|~]*)/;
    my $token = $1;
    $string =~ s/^[a-zA-Z*][a-zA-Z0-9:\/!#\$%&'*+\-.^_`|~]*//;
    return ({ _type => 'token', value => $token }, $string);
}

# Decode Binary (RFC 9841 Section 4.2.7)
sub _decode_binary {
    my ($string) = @_;
    
    $string =~ s/^://;
    if ($string =~ /^([A-Za-z0-9+\/=]*)\:/) {
        my $b64 = $1;
        $string =~ s/^[A-Za-z0-9+\/=]*://;
        if ($b64 !~ m@^(?:[A-Za-z0-9+/]{4})*(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?$@) {
            die "Invalid Base64 string: $b64";
        }
        return ({ _type => 'binary', value => decode_base64($b64) }, $string);
    }
    
    die "Expected binary value, got: " . $string;
}

# Decode Boolean (RFC 9841 Section 4.2.8)
sub _decode_boolean {
    my ($string) = @_;
    
    if ($string =~ /^\?([01])/) {
        my $bool = $1;
        $string =~ s/^\?[01]//;
        return ({ _type => 'boolean', value => $bool ? 1 : 0 }, $string);
    }
    
    die "Expected boolean value, got: $string";
}

# Decode Date (RFC 9841 Section 4.2.9)
sub _decode_date {
    my ($string) = @_;

    $string =~ s/^@//;
    my ($value, $rest) = _decode_number($string);
    if ($value->{_type} ne 'integer') {
        die "Date value must be an integer: $value->{_type}";
    }
    return ({ _type => 'date', value => $value->{value} }, $rest);
}

# Display String (RFC 9651 Section 4.2.10)
sub _decode_displaystring {
    my ($string) = @_;
    
    $string =~ s/^%"//;
    my @bytes;
    
    while ($string !~ /^"/) {
        if (length($string) == 0) {
            die "Unterminated display string";
        }
        
        if ($string =~ /^%([0-9a-f]{2})/) {
            my $hex = $1;
            push @bytes, hex($hex);
            $string =~ s/^%[0-9a-f]{2}//;
        } else {
            my $c = substr($string, 0, 1);
            my $ord = ord($c);
            if ($ord >= 0x20 && $ord <= 0x7E && $ord != 0x25) {
                push @bytes, $ord;
                $string =~ s/^.//;
            } else {
                die "Invalid character in display string: $c (ord=$ord)";
            }
        }
    }
    
    $string =~ s/^"//;
    
    my $byte_string = pack('C*', @bytes);
    my $decoded;
    eval {
        $decoded = decode_utf8($byte_string, Encode::FB_CROAK);
    };
    if ($@) {
        die "Invalid UTF-8 sequence in display string";
    }
    
    return ({ _type => 'displaystring', value => $decoded }, $string);
}

1;

__END__

=head1 NAME

HTTP::StructuredFieldValues - Encode and decode HTTP Structured Field Values (RFC 9651) in Perl

=head1 SYNOPSIS

  use HTTP::StructuredFieldValues qw(:all);

  # Encode a Perl data structure into a Structured Field string
  my $dict = {
      foo => { _type => 'integer', value => 42 },
      bar => { _type => 'boolean', value => 1 }
  };
  my $encoded = encode($dict);
  print $encoded;   # foo=42, bar

  # Decode a Structured Field string into a Perl data structure
  my $decoded = decode_dictionary('foo=42, bar');
  print $decoded->{foo}->{value};  # 42

  # Encode a list
  my $list = [
      { _type => 'string', value => 'hello' },
      { _type => 'decimal', value => 3.14 }
  ];
  my $encoded_list = encode($list);

  # Decode a list
  my $decoded_list = decode_list('"hello", 3.14');

  # Decode a single item
  my $item = decode_item('?1');   # boolean true

=head1 DESCRIPTION

This module provides support for encoding and decoding
B<Structured Field Values for HTTP> as defined in RFC 9651.

Structured Field Values define well-typed, constrained data structures
for use in HTTP fields, improving interoperability, consistency,
and correctness.

This implementation allows you to round-trip Perl data structures into
well-formed Structured Field Value strings and back again.

This is an alpha release. The API may be subject to change.

=head1 FUNCTIONS

The following functions can be imported individually or via the C<:all> tag.

=head2 encode($data)

Encodes a Perl data structure into a valid Structured Field string.
Supported data structures include:

=over 4

=item * Dictionary (Perl hash)

=item * List (Perl array)

=item * Item (hash with C<_type> and C<value>)

=back

=head2 decode_dictionary($string)

Decodes a Structured Field dictionary string into a Perl hash
(tied to C<Tie::IxHash> to preserve order).

=head2 decode_list($string)

Decodes a Structured Field list string into a Perl array reference.

=head2 decode_item($string)

Decodes a single Structured Field item string into its corresponding
Perl representation.

=head1 DATA MODEL

Each Structured Field Item is represented as a Perl hashref
with the following form:

  {
    _type => 'string' | 'integer' | 'decimal' | 'boolean' |
             'token' | 'binary' | 'date' | 'inner_list' | 'displaystring',
    value => ...,
    params => { optional parameters hash }
  }

Lists are represented as array references, possibly containing such items
or "inner lists". Dictionaries are hash references mapping keys to items.

=head1 ERROR HANDLING

Invalid or malformed Structured Field strings will cause the decoding
functions to C<die> with an error message. Similarly, attempts to encode
invalid data (such as invalid tokens, strings with forbidden characters,
or out-of-range numbers) will result in exceptions.

=head1 SEE ALSO

C<Tie::IxHash>

=head1 AUTHOR

SHIRAKATA Kentaro <argrath@ub32.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
