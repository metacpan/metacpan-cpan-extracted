use Test::More tests => 20;

use Modern::Perl;

use DateTime;
use lib './lib';

use_ok( 'Finance::Bank::SentinelBenefits::Csv401kConverter::Line' );

my $date = DateTime->new( year   => 1964,
                       month  => 10,
                       day    => 16,
                     );
diag( 'Testing deferral' );
{
    my $l = Finance::Bank::SentinelBenefits::Csv401kConverter::Line->new(
	'date' => $date,
	'symbol' => 'INTC',
	'memo' => 'foobar',
	'price' => 11.24,
	'quantity' => 2,
	'total' => 22.48,
	side   => 'Buy',
	'source' => 'Deferral',
);

    is( 'INTC', $l->symbol(), 'Symbol accessor works' );
    is( 1964, $l->date()->year, 'Date year works' );
    is( 'foobar', $l->memo(), 'Memo accessor works' );
    is( 2, $l->quantity(), 'Quantity accessor works' );
    is( 11.24, $l->price(), 'Price accessor works' );
    is( 22.48, $l->total(), 'Total accessor works' );
    is( 'Deferral', $l->source(), 'Source accessor works' );
    is( 'Buy', $l->side(), 'Side accessor works' );
}

{
    my $l_with_fractional_qty = Finance::Bank::SentinelBenefits::Csv401kConverter::Line->new
      (
       date => $date,
       symbol => 'INTC',
       memo => 'foobar',
       price => 11.24,
       quantity => 2.54,
       total => 22.48,
       source => 'Deferral',
       side => 'Buy'
      );

    is( 2.54, $l_with_fractional_qty->quantity(), 'Quantity accessor works' );
}

diag( 'Testing match' );
{
my $l = Finance::Bank::SentinelBenefits::Csv401kConverter::Line->new
  (
   'date' => $date,
   'symbol' => 'INTC',
   'memo' => 'foobar',
   'price' => 11.24,
   'quantity' => 2,
   'total' => 22.48,
   'source' => 'Match',
   side => 'Buy'
  );

is( 'INTC', $l->symbol(), 'Symbol accessor works' );
is( 1964, $l->date()->year, 'Date year works' );
is( 'foobar', $l->memo(), 'Memo accessor works' );
is( 2, $l->quantity(), 'Quantity accessor works' );
is( 11.24, $l->price(), 'Price accessor works' );
is( 22.48, $l->total(), 'Total accessor works' );
is( 'Match', $l->source(), 'Source accessor works' );
is( 'Buy', $l->side(), 'Side accessor works' );
}

diag ( 'Testing invalid source' );

eval{
my $l = Finance::Bank::SentinelBenefits::Csv401kConverter::Line->new
  (
    'date' => $date,
    'symbol' => 'INTC',
    'memo' => 'foobar',
    'price' => 11.24,
    'quantity' => 2,
    'total' => 22.48,
    'source' => 'NotAValidSource',
   side => 'Buy',
  );
};

ok($@, 'Invalid source should cause exception');


diag ( 'Testing invalid side' );

eval{
  my $l = Finance::Bank::SentinelBenefits::Csv401kConverter::Line->new
    (
    'date' => $date,
    'symbol' => 'INTC',
    'memo' => 'foobar',
    'price' => 11.24,
    'quantity' => 2,
    'total' => 22.48,
    'source' => 'Match',
   side => 'MadeUpSide',
  );
};

ok($@, 'Invalid side should cause exception');


# Copyright 2009-2011 David Solimano
# This file is part of Finance::Bank::SentinelBenefits::Csv401kConverter

# Finance::Bank::SentinelBenefits::Csv401kConverter is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Finance::Bank::SentinelBenefits::Csv401kConverter is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with Finance::Bank::SentinelBenefits::Csv401kConverter.  If not, see <http://www.gnu.org/licenses/>.
