#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Math-Aronson.
#
# Math-Aronson is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-Aronson is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-Aronson.  If not, see <http://www.gnu.org/licenses/>.

use 5.010;
use strict;
use warnings;
use Math::Aronson;
use Lingua::Any::Numbers;
use Lingua::ES::Numeros;

use Smart::Comments;

{
  require Lingua::EN::Numbers;
  foreach my $i (0 .. 120) {
    say Lingua::EN::Numbers::num2en_ordinal($i);
  }
  exit 0;
}

{
  require Lingua::FR::Numbers;
  foreach my $i (0 .. 120) {
    say Lingua::FR::Numbers::ordinate_to_fr($i);
  }
  exit 0;
}

{
  { local $,=' ';
    say Lingua::Any::Numbers::available(); }
  say Lingua::Any::Numbers::to_ordinal(12345,'es');

  require Lingua::ES::Numeros;
  foreach my $gender (Lingua::ES::Numeros::MALE(),
                      Lingua::ES::Numeros::FEMALE(),
                      Lingua::ES::Numeros::NEUTRAL()) {
    my $obj = new Lingua::ES::Numeros (GENERO => $gender);
    say $obj->ordinal(12345);
  }
  exit 0;
}
