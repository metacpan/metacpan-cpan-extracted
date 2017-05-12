#!/usr/bin/perl
#-------------------------------------------------------------------------------
# Encode a Unicode string in Perl and decode it in Java
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------

package Encode::Unicode::PerlDecodeJava;
require v5.16.0;
use warnings FATAL => qw(all);
use strict;
use Carp;
use utf8;

our $VERSION = '2017.302';

sub encode93($)                                                                 # Encode a string
 {my ($i) = @_;
  my $s;
  my $n = length($i);
  for(split //, $i)                                                             # Letters are passed straight through
   {$s .=  /[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ '\(\)\[\]\{\}<>`!@#\$%^&*_\-+=,;:|.?\/]/ ? $_ : ord($_).'~';
   }
  $s =~ s/([0123456789])(~)([^0123456789]|\Z)/$1$3/gsr;                         # Remove redundant ~
 }

sub decode93($)                                                                 # Decode a string
 {my ($i) = @_;
  my $s;
  my $n = '';
  for(split //, $i)                                                             # Letters are passed straight through
   {if (   /[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ '\(\)\[\]\{\}<>`!@#\$%^&*_\-+=,;:|.?\/]/)
     {if (length($n)) {$s .= pack('U', $n); $n = ''}                            # Number terminated by letter not ~
      $s .= $_
     }
    elsif (/~/i)      {$s .= pack('U', $n); $n = ''}                            # Decompress number
    else              {$n .= $_}
   }
  if     (length($n)) {$s .= pack('U', $n)}                                     # Trailing number
  $s
 }

#-------------------------------------------------------------------------------
# Test
#-------------------------------------------------------------------------------

sub test
 {eval join('', <Encode::Unicode::PerlDecodeJava::DATA>) || die $@
 }

test unless caller();

# Documentation
#extractDocumentation unless caller;

#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

require Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw(decode93 encode93);
@EXPORT_OK    = qw();
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

1;

=pod

=encoding utf-8

=head1 Name

Encode::Unicode::PerlDecodeJava - Encode a Unicode string in Perl and decode it in Java

=head1 Synopsis                                                  𝝰

 use Encode::Unicode::PerlDecodeJava;

 ok $_ eq decode93(encode93($_)) for(qw(aaa (𝝰𝝱𝝲) aaa𝝰𝝱𝝲aaa yüz))

=head1 Description

 encode93($input)

encodes any Perl string given as $input, even one containing Unicode
characters, using only the 93 well known ASCII characters below:

 abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ
 0123456789 '()[]{}<>`!@#$%^&*_-+=,;:|.?\

and returns the resulting encoded string.

Such a string can be easily compressed and transported using software
restricted to ASCII data and then reconstituted as a Unicode string in Perl by
using decode93() or in Java by using the code reproduced further below.

 decode93($input)

takes an $input string encoded by encode93() and returns the decoded string.

The following Java code takes a string encoded by encode93() and returns the
decoded string to Java:

  String decode93(String input)                                                 // Decode string encoded by encode93()
   {final StringBuilder s = new StringBuilder();
    final StringBuilder n = new StringBuilder();
    final int           N = input.length();

    for(int i = 0; i < N; ++i)                                                  // Decode each character
     {char c = input.charAt(i);
      if (Character.isDigit(c)) n.append(c);                                    // Digit to accumulate
      else if (c == '~')                                                        // Decode number
       {final int p = Integer.parseInt(n.toString());
        s.appendCodePoint(p);
        n.setLength(0);
       }
      else                                                                      // Letter
       {if (n.length() > 0)                                                     // Number available for decode
         {final int p = Integer.parseInt(n.toString());
          s.appendCodePoint(p);
          n.setLength(0);
         }
        s.append(c);                                                            // Add letter
       }
     }
    if (n.length() > 0)                                                         // Trailing number available for decode
     {final int p = Integer.parseInt(n.toString());
      s.appendCodePoint(p);
      n.setLength(0);
     }
    return s.toString();                                                        // Decoded string
   }

=head1 Installation

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

philiprbrenan@gmail.com

http://www.appaapps.com

=head1 Copyright

Copyright (c) 2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut

__DATA__
use Test::More tests=>12;

my @t =                                                                         # Tests
 ([qw(𝝰                     120688)],
  [qw(~~~~~~~1~    126~126~126~126~126~126~126~49~126)],
  [  'aaa(𝝰𝝱𝝲)',  'aaa(120688~120689~120690)'],
  [  'aaa𝝰𝝱𝝲aaa', 'aaa120688~120689~120690aaa'],
  [qw(yüz          y252z)],
  [  'aa,,;;𝝰""', 'aa,,;;120688~34~34'],
 );

if (0)                                                                          # Intermediate results
 {binmode STDERR, ":utf8";
  say STDERR encode93($$_[0]) for @t;
 }

ok $$_[1] eq          encode93($$_[0])  for @t;                                 # Encode
ok $$_[0] eq decode93(encode93($$_[0])) for @t;                                 # Decode

1
