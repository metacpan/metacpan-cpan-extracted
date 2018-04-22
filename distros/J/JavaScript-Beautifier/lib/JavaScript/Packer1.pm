package  # hidden from PAUSE
  JavaScript::Packer1;

use warnings;
use strict;

our $VERSION   = '0.24';
# our $AUTHORITY = 'cpan:FAYLAND'; # from eleonora45

use base 'Exporter';
use vars qw/@EXPORT_OK/;
@EXPORT_OK = qw/js_packer/;

my (@lines);
my ($payload, $symtab, $radix, $count, $splitchar, $before, $after);
my (@alfa_values, @symbols);
my $ALPHABET = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
my ($decoded);

sub check_packer($) {
    my ($line) = @_;
    if ($line =~ /eval\(function\(p,a,c,k,e,([d|r])\)\{/) {
        return 1;
    } else {
        return 0;
    }
}

sub get_table_elements($) {
    my ($line) = @_;
    $before = '';
    $after  = '';
    # caret2.js miatt
    if ($line =~ /eval\(function\(p,a,c,k,e,[d|r]\)\{.*?\}?\}?return \w+\}\('(.*?)(\}?\)?;?)?',(\d+),(\d+),'(.*?)'\.split\('(.*?)'\).*?\)\)/) {
        if (defined($2)) {
            $payload = $1 . $2;
        } else {
            $payload = $1;
        }
        $radix     = $3;
        $count     = $4;
        $symtab    = $5;
        $splitchar = $6;
        $after     = $';
        $before    = $`;
        if ($splitchar eq '\\u005e') { $splitchar = '^'; }
        return 1;
    } else {
        return 0;
    }
}

sub get_index($) {
    my ($ix) = @_;
    my @values = split('', $ix);
    my $size = @values;
    my ($idx) = grep { $alfa_values[$_] eq $values[$size - 1] } 0 .. $#alfa_values;
    if ($size == 2) { $idx += $values[0] * $radix; }
    return $idx;
}

sub do_decode() {
    my ($rest, $ix);
    my ($ix1, $ix2, $ix3, $ix4, $muv, $muv1);
    $decoded     = '';
    @alfa_values = split('', $ALPHABET);
    @symbols     = split('\\' . $splitchar, $symtab);
    for (my $i = 0; $i < $#symbols; $i++) {
        if ($symbols[$i] eq '') {
            $symbols[$i] = $i;
        }
    }
    $rest = $payload;
    while ($rest =~ /(\W+)?(\w+)(\W+)?/) {
        $rest = $';
        $ix1  = get_index($2);
        if (defined($1)) {
            $decoded .= "$1$symbols[$ix1]$3";
        } else {
            $decoded .= "$symbols[$ix1]$3";
        }
    }
    $decoded .= $rest;
}

sub js_packer {
    my ($js_source_code) = @_;
    if (check_packer($js_source_code)) {
        if (get_table_elements($js_source_code)) {
            do_decode();
        }
        my $retval = join('', $before, $decoded, $after);
        if ($retval eq '') {
            $retval = $js_source_code;
        }
        return $retval;
    } else {
      return $js_source_code;
    }
}

1;
