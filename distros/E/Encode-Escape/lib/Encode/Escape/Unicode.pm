# Encoding of Unicode Escape Sequences (or Escaped Unicode)

# $Id: Unicode.pm,v 1.13 2007-12-05 22:11:11+09 you Exp $

package Encode::Escape::Unicode;

our $VERSION  = do { q$Revision: 1.13 $ =~ /\d+\.(\d+)/; sprintf "%.2f", $1 / 100  };

use 5.008008;
use strict;
use warnings;

use Encode::Encoding;
use base qw(Encode::Encoding);

__PACKAGE__->Define(qw/unicode-escape unicode_escape/);

sub import {

    __PACKAGE__->enmode('default');
    __PACKAGE__->demode('default');

    require Encode;
    Encode->export_to_level(1, @_);
}

our $enmode;
our $demode;
sub encoder($);
sub decoder($);

#
# == encoder/decoder modes ==
#
our %encoder = (
    undef   => \&perl_encoder,
    ''      => \&perl_encoder,
    default => \&perl_encoder,
    perl    => \&perl_encoder,
    java    => \&python_encoder,
    python  => \&python_encoder,
    csharp  => \&python_encoder,
);

our %decoder = (
    undef   => \&perl_decoder,
    ''      => \&perl_decoder,
    default => \&perl_decoder,
    perl    => \&perl_decoder,
    java    => \&python_decoder,
    python  => \&python_decoder,
    csharp  => \&python_decoder,
);

#
# == encode/decode ==
#

sub encode($$;$) {
    my ($obj, $str, $chk) = @_;
    $_[1] = '' if $chk;
    return encoder $str;
}


sub decode($$;$) {
    my ($obj, $str, $chk) = @_;
    $_[1] = '' if $chk;
    return decoder $str;
}

#
# == enmode/demode ==
#

sub enmode ($$) {
   my ($class, $mode) = @_;
   $mode = 'undef' unless defined $mode;
   unless (exists $encoder{$mode}) {
        require Carp;
        Carp::croak(
            "Unknown enmode '$mode' for encoding '" . $class->name() . "'"
        );
   }
   $enmode = $mode;
}

sub demode ($$) {
   my ($class, $mode) = @_;
   $mode = 'undef' unless defined $mode;
   unless (exists $decoder{$mode}) {
        require Carp;
        Carp::croak(
            "Unknown demode '$mode' for encoding '" . $class->name() . "'"
        );
   }
   $demode = $mode;
}


#
# = DATA AND SUBROUTINES FOR INTERNAL USE =
#


#
# == encoder/decoder ==
#

sub encoder($) {
    local $_ = ( defined $_[0] ? $_[0] : '' );
    return $encoder{$enmode}->($_);
}
sub decoder($) {
    local $_ = ( defined $_[0] ? $_[0] : '' );
    return $decoder{$demode}->($_);
}

#
# == enmode_encoder / demode_decoder ==
#

# default (perl) escape sequences
#
sub perl_encoder($) {

    local $_ = ( defined $_[0] ? $_[0] : '' );

    $_ = escape($_);
    s/([\x00-\x1f\x{7f}-\x{ffff}])/"\\x\{".uc(chr2hex($1))."\}"/gse;

    return $_;
}

sub perl_decoder($) {

    local $_ = ( defined $_[0] ? $_[0] : '' );

    s/((?:\A|\G|[^\\]))\\x([\da-fA-F]{1,2})/$1.hex2chr($2)/gse;
    s/((?:\A|\G|[^\\]))\\x\{([\da-fA-F]{1,4})\}/$1.hex2chr($2)/gse;

    return unescape($_);
}

# python (or java, c#) escape sequences 
#
sub python_encoder($) {

    local $_ = ( defined $_[0] ? $_[0] : '' );

    $_ = escape($_);
    s/([\x00-\x1f\x{7f}-\x{ffff}])/'\u'.chr2hex($1)/gse;

    return $_;
}

sub python_decoder {

    local $_ = ( defined $_[0] ? $_[0] : '' );

    s/((?:\A|\G|[^\\]))\\u([\da-fA-F]{4})/$1.hex2chr($2)/gse;

    return unescape($_);
}

#
# == common data and subroutines ==
#

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

sub escape ($) {
    local $_ = ( defined $_[0] ? $_[0] : '' );
    s/([\a\b\e\f\r\n\t\"\\\$\@])/\\$ESCAPED{$1}/sg;
    return $_;
}

sub unescape ($) {
    local $_ = ( defined $_[0] ? $_[0] : '' );

    s/((?:\A|\G|[^\\]))\\([0-7]{1,3})/$1.oct2chr($2)/gse;

    s/((?:\A|\G|[^\\]))\\([^aAbBeEfFrRnNtT\\\"\$\@])/$1$2/g;

    s/((?:\A|\G|[^\\]))\\([aAbBeEfFrRnNtT\\\"\$\@])/$1.$UNESCAPED{lc($2)}/gse;

    return $_;
}



sub chr2hex {
    my($c) = @_;
    if ( ord($c) < 65536 ) {
        return sprintf("%04x", ord($c));
    }
    else {
        require Carp;
        Carp::croak (
            "'unicode-escape' codec can't encode character: ordinal " . ord($c)
        );
    }
}

sub hex2chr { 
    my($hex) = @_;
    if ( hex($hex) >= 0 and hex($hex) < 65536) {
        return chr(hex($hex));
    }
    else {
        require Carp;
        Carp::croak(
            "'unicode-escape' codec can't decode escape sequence: " 
            . "\\x$hex (ordinal " . hex($hex) . ")"
        );
    }
}

sub oct2chr {
    my($oct) = @_;
    if ( oct($oct) >= 0 and oct($oct) < 256 ) {
        return chr(oct($oct));
    }
    else {
        require Carp;
        Carp::croak (
            "'unicode-escape' codec can't decode escape sequence: " 
            . "\\$oct (ordinal " . oct($oct). ")"
        );
    }
}

$\ = "\n";


1;
__END__

=head1 NAME

Encode::Escape::Unicode - Perl extension for Encoding of Unicode Escape Sequnces

=head1 SYNOPSIS

  use Encode::Escape::Unicode;

  $escaped = "What is \\x{D384}? It's Perl!";
  $string = decode 'unicode-escape', $escaped;

  # Now, $string is equivalent "What is \x{D384}? It's Perl!"

  Encode::Escape::Unicode->demode('python');

  $python_unicode_escape = "And \\u041f\\u0435\\u0440\\u043b? It's Perl, too.";
  $string = decode 'unicode-escape', $python_unicode_escape;

  # Now, $string eq "And \x{041F}\x{0435}\x{0440}\x{043B}? It's Perl, too."

If you have a text data file 'unicode-escape.txt'. It contains a line:

  What is \x{D384}? It's Perl!\n
  And \x{041F}\x{0435}\x{0440}\x{043B}? It's Perl, too.\n

And you want to use it as if it were a normal double quote string in source 
code. Try this:

  use Encode::Escape::Unicode;

  open(FILE, 'unicode-escape.txt');

  while(<FILE>) {
    chomp;
    print encode 'utf8', decode 'unicode-escape', $_;
  }

=head1 DESCRIPTION

L<Encode::Escape::Unicode> module implements encodings of escape sequences.

Simply saying, it converts (decodes) escape sequences into Perl internal string 
(\x{0000} -- \x{ffff}) and encodes Perl strings to escape sequences.

=head2 MODES AND SUPPORTED ESCAPE SEQUENCES

=head3 default or perl mode

 Escape Sequcnes      Description
 ---------------      --------------------------
 \a                   Alarm (beep)
 \b                   Backspace
 \e                   Escape
 \f                   Formfeed
 \n                   Newline
 \r                   Carriage return
 \t                   Tab
 \000     - \377      octal ASCII value. \0, \00, and \000 are equivalent.
 \x00     - \xff      hexadecimal ASCII value. \x0 and \x00 are equivalent.
 \x{0000} - \x{ffff}  hexadecimal ASCII value. \x{0}, \x{00}, x\{000}, \x{0000}


 \\                   Backslash
 \$                   Dollar Sign
 \@                   Ampersand
 \"                   Print double quotes
 \                    Escape next character if known otherwise print

This is the default mode. You don't need to invoke it since
you haven't invoke other mode previously.

=head3 python or java mode

Python, Java, and C# languages use C<\u>I<xxxx> escape sequence for Unicode
character. 

 Escape Sequcnes      Description
 ---------------      --------------------------
 \a                   Alarm (beep)
 \b                   Backspace
 \e                   Escape
 \f                   Formfeed
 \n                   Newline
 \r                   Carriage return
 \t                   Tab
 \000   - \377        octal ASCII value. \0, \00, and \000 are equivalent.
 \x00   - \xff        hexadecimal ASCII value. \x0 and \x00 are equivalent.
 \u0000 - \uffff      hexadecimal ASCII value.

 \\                   Backslash
 \$                   Dollar Sign
 \@                   Ampersand
 \"                   Print double quotes
 \                    Escape next character if known otherwise print

If you have data which contains C<\u>I<xxxx> escape sequences,
this will translate them to utf8-encoded characters:

 use Encode::Escape;

 Encode::Escape::demode 'unicode-escape', 'python';

 while(<>) {
	chomp;
	print encode 'utf8', decode 'unicode-escape', $_;
 }

And this will translate C<\u>I<xxxx> to C<\x{>I<xxxx>C<}>.

 use Encode::Escape;

 Encode::Escape::enmode 'unicode-escape', 'perl';
 Encode::Escape::demode 'unicode-escape', 'python';

 while(<>) {
	chomp;
	print encode 'unicode-escape', decode 'unicode-escape', $_;
 }


=head1 SEEALSO

See L<Encode::Escape>.

=head1 AUTHOR

you, E<lt>you at cpan dot orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by you 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
# vi: set ts=4 sts=4 sw=4 et
