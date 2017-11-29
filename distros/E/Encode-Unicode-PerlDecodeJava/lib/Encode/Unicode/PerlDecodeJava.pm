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

our $VERSION = '20171127';

sub encode93($)                                                                 # Return the encoded version of a string
 {my ($i) = @_;                                                                 # String to encode
  my $s = '';
  my $n = length($i);
  for(split //, $i)                                                             # Letters are passed straight through
   {$s .=  /[abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ '\(\)\[\]\{\}<>`!@#\$%^&*_\-+=,;:|.?\/]/ ? $_ : ord($_).'~';
   }
  $s =~ s/([0123456789])(~)([^0123456789]|\Z)/$1$3/gsr;                         # Remove redundant ~
 }

sub decode93($)                                                                 # Return the decode version of an encoded string
 {my ($i) = @_;                                                                 # String to decode
  my $s = '';
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
# Export
#-------------------------------------------------------------------------------

require Exporter;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw(decode93 encode93);
@EXPORT_OK    = qw();
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation

=pod

=encoding utf-8

=head1 Name

Encode::Unicode::PerlDecodeJava - Encode a Unicode string in Perl and decode it in Java

=head1 Synopsis

 use Encode::Unicode::PerlDecodeJava;

 ok $_ eq decode93(encode93($_)) for(qw(aaa (𝝰𝝱𝝲) aaa𝝰𝝱𝝲aaa yüz))

=head1 Description


=head1 Index


=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read, use,
modify and install.

Standard Module::Build process for building and installing modules:

  perl Build.PL
  ./Build
  ./Build test
  ./Build install

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2017 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut


# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
 }

test unless caller;

1;
__DATA__
use Test::More tests=>22;

my @t =                                                                         # Tests
 ([qw(𝝰                     120688)],
  [qw(~~~~~~~1~    126~126~126~126~126~126~126~49~126)],
  [  'aaa(𝝰𝝱𝝲)',  'aaa(120688~120689~120690)'],
  [  'aaa𝝰𝝱𝝲aaa', 'aaa120688~120689~120690aaa'],
  [qw(yüz          y252z)],
  [  'aa,,;;𝝰""', 'aa,,;;120688~34~34'],
  [  '',   ''],
  [  ' ',  ' '],
  [  '  ', '  '],
  [  '0',   '48'],
  [  '00',  '48~48'],
 );

if (0)                                                                          # Intermediate results
 {binmode STDERR, ":utf8";
  say STDERR "AAAA =", encode93($$_[0]), "=" for @t;
 }

ok $$_[1] eq          encode93($$_[0])  for @t;                                 # Encode
ok $$_[0] eq decode93(encode93($$_[0])) for @t;                                 # Decode

1
