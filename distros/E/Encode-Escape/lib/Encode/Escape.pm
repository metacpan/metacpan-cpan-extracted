# Encodings based on Escape Sequence

# $Id: Escape.pm,v 1.14 2007-12-05 22:08:33+09 you Exp $

package Encode::Escape;

use 5.008008;

use strict;
use warnings;

our $VERSION = do { q$Revision: 1.14 $ =~ /\d+\.(\d+)/; sprintf "%.2f", $1 / 100  };


sub import {
    if ( defined $_[1] and $_[1] eq ':modes') {

        require Exporter;

        our @ISA = qw(Exporter);
        our @EXPORT_OK = qw(enmode demode);

        __PACKAGE__->export_to_level(1, $_[0], 'enmode', 'demode');

        splice @_, 1, 1;
    }

    require Encode;
    Encode->export_to_level(1, @_);
}

use Encode::Escape::ASCII;
use Encode::Escape::Unicode;


sub enmode ($@) {
    my $enc = shift;
    my $obj = Encode::find_encoding($enc);

    unless (defined $obj) {

        require Carp;
        Carp::croak("Unknown encoding '$enc'");
    }

    $obj->enmode(@_);
}

sub demode ($@) {
    my $enc = shift;
    my $obj = Encode::find_encoding($enc);

    unless (defined $obj) {

        require Carp;
        Carp::croak("Unknown encoding '$enc'");
    }

    $obj->demode(@_);
}


1;
__END__

=head1 NAME

Encode::Escape - Perl extension for Encodings of various escape sequences

=head1 SYNOPSIS

  use Encode::Escape;

  $escaped_ascii = "Perl\\tPathologically Eclectic Rubbish Lister\\n";
  $ascii = decode 'ascii-escape', $escaped_ascii;
  
  
  # Now, $ascii is equivalent to 
  # double quote string "Perl\tPathologically Eclectic Rubbish Lister\n"

  $escaped_unicode = "Perl \\x{041F}\\x{0435}\\x{0440}\\x{043B} \\x{D384}" 
  $string = decode 'unicode-escape', $escaped_unicode;

  # Now, $string is equvialent to 
  # double quote string "Perl \x{041F}\x{0435}\x{0440}\x{043B} \x{D384}" 

It may looks non-sense. Here's another case.

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

L<Encode::Escape> module is a wrapper class for encodings of escape sequences.

It is NOT for an escape-based encoding (eg. ISO-2022-JP). It is for 
encoding/decoding escape sequences, generally used in source codes.

Many programming languages, markup languages, and typesetting languages 
provide methods for encoding special (or functional) characters and non-keyboard 
symbols in the form of escape sequence. That's what I concern.

Yes, you're right. There already exist many modules.
See L<String::Escape>, 
L<Unicode::Escape>, 
L<TeX::Encode>, 
L<HTML::Mason::Escape>, L<Template::Plugin::XML::Escape>, L<URI::Escape>, etc.

But for some reason I need to do it in a different way. There is more than 
one way to do it! After that, I asked myself if this module is useful. May 
be not except for me. At this time, Zhuangzi reminds me,  "L</"The useless 
has its use">".

=head2 ASCII

See L<Encode::Escape::ASCII>

=head2 Unicode

See L<Encode::Escape::Unicode>


=head1 ESCAPE SEQUENCES

=head2 Character Escape Codes

ASCII defines 128 characters: 33 non-printing control characters 
(0x00 -- 0x1f, 0x7f) and 95 printable characters (0x20 -- 0x7e).

Character Escape Codes in C programming language provide a method 
to express control characters, using only printable ones. 
These are accepted by Perl and many other languages.

 CEC    HEX     Description
 ---    ----    --------------
 \0     00      Null character
 \a     07      Bell
 \b     08      Backspace
 \t     09      Horizontal Tab
 \n     0a      Line feed
 \v     0b      Vertical Tab
 \f     0c      Form feed
 \r     0d      Carriage return

Programming languages provide escape sequences for printable characters,
which have significant meaning in that language. Otherwise, it would be
harder to print them literally.

 ESC    HEX     Description
 ---    ----    ---------------
 \"     22      double quote 
\\     52      backslash

Refer to ASCII, Escape character, Escape sequence at <http://en.wikipedia.org>, for more
details.

=head2 Perl Escape Sequences

Perl use backslash as an escape character. 

These work in normal strings and regular expressions except \b.

 ESC       Description
 ---       --------------------------
 \a        Alarm (beep)
 \b        Backspace
 \e        Escape
 \f        Formfeed
 \n        Newline
 \r        Carriage return
 \t        Tab
 \037      Any octal ASCII value
 \x7f      Any hexadecimal ASCII value
 \x{263a}  A wide hexadecimal value
 \cx       Control-x
 \N{name}  name is a name for the Unicode character (use charnames)
 
The following escape sequences are available in constructs that interpolate.

 \l        Lowercase next character
 \u        Titlecase next character
 \L        Lowercase until \E
 \U        Uppercase until \E
 \E        End case modification
 
In regular expresssions:

 \b        An assetion, not backspace, except in a character class
 \Q        Disable pattern metacharacters until \E

Unlike C and other languages, Perl has no \v escape sequence for the vertical tab 
(VT - ASCII 11).

For constructs that do interpolate, variable begining with "$" or "@" are interpolated.

 \$        Dollar Sign
 \@        Ampersand
 \"        Print double quotes
 \         Escape next character if know otherwise print

See L<perlreref>, L<perlop>

=head2 Python Escape Sequences

 \newline   Ignored
 \\         Backslash (\)
 \'         Single quote (')
 \"         Double quote (")
 \a         ASCII Bell (BEL)
 \b         ASCII Backspace (BA)
 \f         ASCII Formfeed (FF)
 \n         ASCII Linefeed (LF)
 \N{name}   Character named 'name' in the Unicode database
 \r         ASCII Carriage Return (CR)
 \t         ASCII Horizontal Tab (TAB)
 \uxxxx     Character with 16-bit hex value xxxx (Unicode only)
 \Uxxxxxxxx Character with 32-bit hex value xxxxxxxx (Unicode only)
 \v         ASCII Vertical Tab (VT)
 \ooo       Character with octal value ooo
 \xhh       Character with hex value hh

See L<http://docs.python.org/ref/strings.html>

Unicode escape sequences in the form of C<\u>I<xxxx> are used in Java, Python,
C#, JavaScript. L<Unicode::Escape> module implements it.

=head2 LaTeX Escapes

L<TeX::Encode> implements encodings of LaTeX escapes. It converts (encodes)
utf8 string to LaTeX escapes.

=head2 HTML Escapes

See L<HTML::Mason::Escapes>

=head1 SEE ALSO

=head1 The useless has its use 

Hui Tzu said to Chuang Tzu, "Your words are useless!"

Chuang Tzu said, "A man has to understand the useless before you can talk to 
him about the useful. The earth is certainly vast and broad, though a man 
uses no more of it than the area he puts his feet on. If, however, you were 
to dig away all the earth from around his feet until you reached the Yellow 
Springs, then would the man still be able to make use of it?"

"No, it would be useless," said Hui Tzu.

"It is obvious, then," said Chuang Tzu, "that the useless has its use."

=begin html

--- from <a href="http://www.terebess.hu/english/chuangtzu3.html"><em>External 
Things, Chuang Tzu translated by Burton Watson</em></a>

=end html

=head1 AUTHOR

You Hyun Jo, E<lt>you at cpan dot orgE<gt>

=head1 ACKNOWLEDGEMENTS

Matthew Simon Cavlletto for L<String::Escape>. It worked as good reference 
when writing the first working version of L<Encode::Escape::ASCII>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by You Hyun Jo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
#set ts=4 sts=4 sw=4 et
