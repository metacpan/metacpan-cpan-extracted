use Test::More tests => 9;
use Modern::Perl;
use lib './lib';
use IO::File;

use_ok( 'Finance::Bank::SentinelBenefits::Csv401kConverter::SymbolMap' );

{
    diag( 'Testing symbol map');
    my %symbolMap = (
	'FooFund' => 'FUBAR',
	'SNA Fund' => 'SNAFU',
	'PerlCo' => 'PEARL',
	);

    my $f = Finance::Bank::SentinelBenefits::Csv401kConverter::SymbolMap->new('symbol_map' => \%symbolMap);

    is( $f->get_symbol('FooFund'), 'FUBAR', 'Map One Symbol' );
    is( $f->get_symbol('SNA Fund'), 'SNAFU', 'Map Another Symbol' );
    is( $f->get_symbol('SNA Fund type c-FUBAR'), 'SNAFU', 'Extra description on non-match' );
    is( $f->get_symbol('Nothing fund'), undef, 'No Match' );
}

{
    diag( 'Symbol map load from file');

    my $fh = new IO::File "< t/symmap.testfile" or die 'Unable to open symmap test dat file';

    my $f = Finance::Bank::SentinelBenefits::Csv401kConverter::SymbolMap->new('symbol_map' => $fh);

    $fh->close();

    is( $f->get_symbol('FooFund'), 'FUBAR', 'Map One Symbol' );
    is( $f->get_symbol('SNA Fund'), 'SNAFU', 'Map Another Symbol' );
    is( $f->get_symbol('SNA Fund type c-FUBAR'), 'SNAFU', 'Extra description on non-match' );
    is( $f->get_symbol('Nothing fund'), undef, 'No Match' );
}

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
