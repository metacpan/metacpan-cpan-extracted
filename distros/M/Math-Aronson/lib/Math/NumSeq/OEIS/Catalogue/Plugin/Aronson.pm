# Copyright 2011, 2012 Kevin Ryde

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

package Math::NumSeq::OEIS::Catalogue::Plugin::Aronson;
use 5.004;
use strict;

use vars '$VERSION', '@ISA';
$VERSION = 9;
use Math::NumSeq::OEIS::Catalogue::Plugin;
@ISA = ('Math::NumSeq::OEIS::Catalogue::Plugin');

use constant info_arrayref =>
  [
   {
    anum  => 'A005224',
    class => 'Math::NumSeq::Aronson',
    parameters => [ conjunctions=>0 ],
   },
   {
    anum  => 'A055508',
    class => 'Math::NumSeq::Aronson',
    parameters => [ letter=>'H', conjunctions=>0 ],
   },
   {
    anum  => 'A049525',
    class => 'Math::NumSeq::Aronson',
    parameters => [ letter=>'I', conjunctions=>0 ],
   },

   {
    anum  => 'A081023',
    class => 'Math::NumSeq::Aronson',
    parameters => [ lying=>1, conjunctions=>0 ],
   },

   {
    anum  => 'A080520',
    class => 'Math::NumSeq::Aronson',
    parameters => [ lang=>'fr' ],  # with conjunctions
   },
  ];

1;
__END__
