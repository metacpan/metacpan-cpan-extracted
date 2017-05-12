# Encoding of ASCII Escape Sequences (or Escaped ASCII)

# $Id: ASCII.pm,v 1.19 2007-12-05 22:11:11+09 you Exp $

package Encode::Escape::ASCII;

our $VERSION  = do { q$Revision: 1.19 $ =~ /\d+\.(\d+)/; sprintf "%.2f", $1 / 100  };

use 5.008008;
use strict;
use warnings;

use Encode::Encoding;
use base qw(Encode::Encoding);

__PACKAGE__->Define(qw/ascii-escape ascii_escape/);

sub import {

    require Encode;
    Encode->export_to_level(1, @_);
}

sub enmode ($$) {
    my ($class, $mode) = @_;
    
}

sub demode ($$) {
    my ($class, $mode) = @_;
}


sub encode($$;$) {
    my ($obj, $str, $chk) = @_;
    my $escaped = escape($str);
    return $escaped;
}


sub decode($$;$) {
    my ($obj, $str, $chk) = @_;
    my $unescaped = unescape($str);
    return $unescaped;
}

my %ESCAPED = ( 
    "\\" => '\\', 
    "\r" => 'r', 
    "\n" => 'n', 
    "\t" => 't', 
    "\a" => 'a',
    "\b" => 'b',
    "\e" => 'e',
    "\f" => 'f',
    "\"" => '"',
    "\$" => '$',
    "\@" => '@',
);

my %UNESCAPED = ( reverse %ESCAPED );

sub chr2hex {
    my($c) = @_;
    if ( ord($c) < 128 ) {
        return sprintf("\\x%02x", ord($c));
    }
    else {
        require Carp;
        Carp::croak (
            "'ascii-escape' codec can't encode character: ordinal " . ord($c)
        );
    }
}


sub escape ($) {
    local $_ = ( defined $_[0] ? $_[0] : '' );
    s/([\a\b\e\f\r\n\t\"\\\$\@])/\\$ESCAPED{$1}/sg;
    s/([\x00-\x1f\x7f-\xff])/chr2hex($1)/gse;
    return $_;
}

sub hex2chr { 
    my($hex) = @_;
    if ( hex($hex) >= 0 and hex($hex) < 128) {
        return chr(hex($hex));
    }
    else {
        require Carp;
        Carp::croak(
            "'ascii-escape' codec can't decode escape sequence: " 
            . "\\x$hex (ordinal " . hex($hex) . ")"
        );
    }
}
sub oct2chr {
    my($oct) = @_;
    if ( oct($oct) >= 0 and oct($oct) < 128 ) {
        return chr(oct($oct));
    }
    else {
        require Carp;
        Carp::croak (
            "'ascii-escape' codec can't decode escape sequence: " 
            . "\\$oct (ordinal " . oct($oct). ")"
        );
    }
}

# $original_string = unprintable( $special_characters_escaped );
sub unescape ($) {
    local $_ = ( defined $_[0] ? $_[0] : '' );

    s/((?:\A|\G|[^\\]))\\x([\da-fA-F]{1,2})/$1.hex2chr($2)/gse;
    s/((?:\A|\G|[^\\]))\\x\{([\da-fA-F]{1,4})\}/$1.hex2chr($2)/gse;
    s/((?:\A|\G|[^\\]))\\([0-7]{1,3})/$1.oct2chr($2)/gse;

    s/((?:\A|\G|[^\\]))\\([^aAbBeEfFrRnNtT\\\"\$\@])/$1$2/g;
    s/((?:\A|\G|[^\\]))\\([aAbBeEfFrRnNtT\\\"\$\@])/$1.$UNESCAPED{lc($2)}/gse;

    return $_;
}


1;
__END__

=head1 NAME

Encode::Escape::ASCII - Perl extension for Encoding of ASCII Escape Sequnces
(or Escaped ASCII)

=head1 SYNOPSIS

  use Encode::Escape::ASCII;

  $escaped = "Perl\\tPathologically Eclectic Rubbish Lister\\n";
  $string = decode 'ascii-escape', $escaped;

  # Now, $string is equivalent to "Perl\tPathologically Eclectic Rubish Lister\n";

  $escaped = "\\x65\\x50\\x6c\\x72\\x50\\x09\\x74\\x61\\x6f\\x68\\x6f\\x6c" .
             "\\x69\\x67\\x61\\x63\\x6c\\x6c\\x20\\x79\\x63\\x45\\x65\\x6c" .
             "\\x74\\x63\\x63\\x69\\x52\\x20\\x62\\x75\\x73\\x69\\x20\\x68" .
             "\\x69\\x4c\\x74\\x73\\x72\\x65\\x0a";
  $string = decode 'ascii-escape', $escaped;

  # Now, $string is equivalent to "Perl\tPathologically Eclectic Rubish Lister\n";

If you have a text data file 'ascii-escape.txt'. It contains a line:

  Perl\tPathologically Eclectic Rubbish Lister\n

And you want to use it as if it were a normal double quote string in source 
code. Try this:

  open(FILE, 'ascii-escape.txt');
  while(<FILE>) {
    chomp;
    print decode 'ascii-escape', $_;
  }

=head1 DESCRIPTION

L<Encode::Escape::ASCII> module implements  encoding of ASCII escape sequences.

Simply saying, it converts (decodes) escape sequences into ASCII chracters 
(0x00 -- 0x7f) and converts (encodes) non-printable control characters 
into escape sequences.

It supports only ASCII character. ASCII is called as low ASCII or 7-bit ASCII 
when one distinguishes it from various extended ASCII codes, i.e. high ASCII 
or 8-bit ASCII.

=head2 Supproted Escape Sequences

 Escape Sequcnes      Description
 ---------------      --------------------------
 \a                   Alarm (beep)
 \b                   Backspace
 \e                   Escape
 \f                   Formfeed
 \n                   Newline
 \r                   Carriage return
 \t                   Tab
 \000     - \177      octal ASCII value. \0, \00, and \000 are equivalent.
 \x00     - \x7f      hexadecimal ASCII value. \x0 and \x00 are equivalent.
 \x{0000} - \x{007f}  hexadecimal ASCII value. \x{0}, \x{00}, x\{000}, \x{0000}


 \\                   Backslash
 \$                   Dollar Sign
 \@                   Ampersand
 \"                   Print double quotes
 \                    Escape next character if known otherwise print

=head1 AUTHOR

you, E<lt>you at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by you 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
# vi: set ts=4 sts=4 sw=4 et
