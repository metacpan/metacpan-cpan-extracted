package Finance::Bank::SentinelBenefits::Csv401kConverter::Types;
$Finance::Bank::SentinelBenefits::Csv401kConverter::Types::VERSION = '1.3';
use Modern::Perl;

use Moose::Util::TypeConstraints;

=head1 NAME

Types - contains some custom types used in other parts of the module

=head1 VERSION

version 1.3

=cut

enum 'ContributionSource' => [ qw(Deferral Match) ];
enum 'TradeSide' => [ qw(Buy Sell ShtSell ReinvDiv) ];

no Moose::Util::TypeConstraints;

1;

=head1 LICENSE AND COPYRIGHT
Copyright 2009-2023 David Solimano
This file is part of Finance::Bank::SentinelBenefits::Csv401kConverter

Finance::Bank::SentinelBenefits::Csv401kConverter is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Finance::Bank::SentinelBenefits::Csv401kConverter is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Finance::Bank::SentinelBenefits::Csv401kConverter.  If not, see <http://www.gnu.org/licenses/>.
=cut
