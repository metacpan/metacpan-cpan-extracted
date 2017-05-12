package Finance::Bank::SentinelBenefits::Csv401kConverter::SideReverser;
$Finance::Bank::SentinelBenefits::Csv401kConverter::SideReverser::VERSION = '1.0';
use Modern::Perl;

=head1 NAME

Finance::Bank::SentinelBenefits::Csv401kConverter::SideReverser - Reveses sides on lines

=head1 VERSION

version 1.0

=head1 SYNOPSIS

my $reverser = Finance::Bank::SentinelBenefits::Csv401kConverter::SideReverser->new();

my $side = $reverser->flip('Buy');

#$side eq 'Sell'

This class represents one transaction, whether a contribution or
a company match, and tells you the security, the price, quantity,
total money, etc.  It doesn't have any smarts, but serves as an
immutable internal data structure.

=cut

use Moose;
use MooseX::Method::Signatures;

use Finance::Bank::SentinelBenefits::Csv401kConverter::Types;

method flip(TradeSide $side){

#   $line->side() eq 'Buy' ? 'ShtSell' : 'Buy'

    return $side eq 'Buy' ? 'ShtSell' 
	: $side eq 'ReinvDiv' ? 'ShtSell'
	: 'Buy';
}

no Moose;

__PACKAGE__->meta->make_immutable;

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
