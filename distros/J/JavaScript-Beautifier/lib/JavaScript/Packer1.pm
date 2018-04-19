package # hidden from PAUSE
  JavaScript::Packer1;

use warnings;
use strict;

our $VERSION = '0.22';
# our $AUTHORITY = 'cpan:FAYLAND'; # from eleonora45

use base 'Exporter';
use vars qw/@EXPORT_OK/;
@EXPORT_OK = qw/js_packer/;

my (@lines);
my ($payload, $symtab, $radix, $count, $splitchar, $d_or_r, $before, $after);
my (@alfa_values, @symbols);
my $ALPHABET = '0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
my ($decoded);
$before  = '';
$after   = '';
$decoded = '';

sub check_packer($) {
    my ($line) = @_;
    if ($line =~ /eval\(function\(p,a,c,k,e,([d|r])\)\{/) {
        $d_or_r = $1;
        return 1;
    } else {
        return 0;
    }
}

sub get_table_elements($) {
    my ($line) = @_;

    # caret2.js miatt
    if ($line =~ /eval\(function\(p,a,c,k,e,[d|r]\)\{.*?\}?\}?return \w+\}\('(.*?)\}?\)?;?',(\d+),(\d+),'(.*?)'\.split\('(.*?)'\).*?\)\)/) {
        $payload   = $1 . ";";
        $radix     = $2;
        $count     = $3;
        $symtab    = $4;
        $splitchar = $5;
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

sub do_decode_d() {
    my ($rest, $ix);
    my ($ix1, $ix2, $ix3);
    @alfa_values = split('',                $ALPHABET);
    @symbols     = split('\\' . $splitchar, $symtab);
    $rest        = '';
    if ($payload =~ /\$\((\w+)\)\.(\w+)\((\w+)\(\)\{/) {
        $rest    = $';
        $ix1     = get_index($1);
        $ix2     = get_index($2);
        $ix3     = get_index($3);
        $decoded = "\$($symbols[$ix1])\.$symbols[$ix2]($symbols[$ix3](){";
    }
    while ($rest =~ /\$\(\\'\.(\w+)\\'\)\.(\w+)\((\w+)\);?/) {
        $rest = $';
        $ix1  = get_index($1);
        $ix2  = get_index($2);
        $ix3  = get_index($3);
        $decoded .= "\n\$('.$symbols[$ix1]')\.$symbols[$ix2]($symbols[$ix3])\;";
    }
    $decoded .= "\n});";

    # $`, $&,  $'  -- before, matching pattern, after
}

sub do_decode_r() {
    my ($rest, $ix);
    my ($ix1, $ix2, $ix3, $ix4, $muv, $muv1);
    @alfa_values = split('', $ALPHABET);
    @symbols = split('\\' . $splitchar, $symtab);
    for (my $i = 0; $i < $#symbols; $i++) {
        if ($symbols[$i] eq '') {
            $symbols[$i] = $i;
        }
    }
    $rest = $payload;
    while ($rest =~ /(\w+)=(\w+)([^a-zA-Z0-9;]+?)?(\w+)?([^a-zA-Z0-9;]+?)?(\w+)?;/) {
        $rest = $';
        $ix1  = get_index($1);
        $ix2  = get_index($2);
        my $six2 = $symbols[$ix2];
        $muv = '';
        $ix3 = '';
        if (defined($3)) { $muv = $3; }
        if (defined($4)) { $ix3 = get_index($4); }
        $muv1 = '';
        $ix4  = '';
        if (defined($5)) { $muv1 = $5; }
        if (defined($6)) { $ix4  = get_index($6); }

        my $six3 = '';
        if ($ix3 ne '') { $six3 = $symbols[$ix3]; }
        my $six4 = '';
        if ($ix4 ne '') { $six4 = $symbols[$ix4]; }

        $decoded .= "$symbols[$ix1] = $symbols[$ix2]";
        if ($muv) {
            $decoded .= " $muv $symbols[$ix3]";
        }
        if ($muv1) {
            $decoded .= " $muv1 $symbols[$ix4]";
        }
        $decoded .= ";\n";
    }    # while rest

    # $`, $&,  $'  -- before, matching pattern, after
}

sub js_packer {
    my ($js_source_code) = @_;
    if (check_packer($js_source_code)) {
        if (get_table_elements($js_source_code)) {
            if ($d_or_r eq 'd') {
                do_decode_d();
            } else {
                do_decode_r();
            }
        }
    }
    my $retval = join('', $before, $decoded, $after);
    if ($retval eq '') {
        $retval = $js_source_code;
    }
    return $retval;
}

1;
