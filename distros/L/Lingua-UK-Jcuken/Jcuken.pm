# Lingua/UK/Jcuken.pm
#
# Copyright (c) 2006-2008 Serguei Trouchelle. All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# History:
#  1.04  2008/02/26 use Encode instead of Text::Iconv
#  1.02  2007/02/04 Quality update (Test::Pod, Test::Pod::Coverage)
#  1.01  2006/11/15 Initial revision

=head1 NAME

Lingua::UK::Jcuken -- Conversion between QWERTY and JCUKEN keys in Ukrainian

=head1 SYNOPSIS

 use Lingua::UK::Jcuken qw/ jcu2qwe qwe2jcu /;

 print qwe2jcu('qwerty', 'koi8-r'); # prints "jcuken" in koi8-r

=head1 DESCRIPTION

Lingua::UK::Jcuken can be used for conversion between two layouts on Ukrainian keyboards.

=head1 METHODS

=cut

package Lingua::UK::Jcuken;

require Exporter;
use Config;

use strict;
use warnings;

use Encode;

our @EXPORT      = qw/ /;
our @EXPORT_OK   = qw/ jcu2qwe qwe2jcu /;
our %EXPORT_TAGS = qw / /;
our @ISA = qw/Exporter/;

our $VERSION = "1.04";

my $table = q!1 1
q é
w ö
e ó
r ê
t å
y í
u ã
i ø
o ù
p ç
[ õ
] ¿
a ô
s ³
d â
f à
g ï
h ð
j î
k ë
l ä 
; æ
' º
z ÿ
x ÷
c ñ
v ì
b è
n ò
m ü
, á
. þ
/ .
` ¸
Q É
W Ö
E Ó
R Ê
T Å
Y Í
U Ã
I Ø
O Ù
P Ç
{ Õ
} ¯
A Ô
S ²
D Â
F À
G Ï
H Ð
J Î
K Ë
L Ä
: Æ
" ª
Z ß
X ×
C Ñ
V Ì
B È
N Ò
M Ü
< Á
> Þ
? .
~ ¨
2 2!;

our %qwe2jcu = split /\s+/, $table;
our %jcu2qwe = reverse split /\s+/, $table;

=head2 jcu2qwe ( $string, [ $encoding ])

This method converts $string from Jcuken to Qwerty.

Optional $encoding parameter allows to specify $string's encoding (default is 'windows-1251')

=cut

sub jcu2qwe {
  my $val = shift;
  my $enc = shift;
  Encode::from_to($val, $enc, 'windows-1251') if $enc;
  my $res = '';
  foreach (split //, $val) {
    $_ = $jcu2qwe{$_} if $jcu2qwe{$_};
    $res .= $_;
  }
  return $res;
}

=head2 qwe2jcu ( $string, [ $encoding ])

This method converts $string from Qwerty to Jcuken.

Optional $encoding parameter allows to specify result encoding (default is 'windows-1251'). 
It is also used as $string encoding if you have cyrillic in it.

=cut

sub qwe2jcu {
  my $val = shift;
  my $enc = shift;
  Encode::from_to($val, $enc, 'windows-1251') if $enc;
  $enc = 'windows-1251' unless $enc;
  my $res = '';
  foreach (split //, $val) {
    $_ = $qwe2jcu{$_} if $qwe2jcu{$_};
    Encode::from_to($_, 'windows-1251', $enc);
    $res .= $_;
  }
  return $res;
}

1;

=head1 AUTHORS

Serguei Trouchelle E<lt>F<stro@railways.dp.ua>E<gt>

=head1 COPYRIGHT

Copyright (c) 2006-2008 Serguei Trouchelle. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
