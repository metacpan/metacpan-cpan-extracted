package Finance::Bank::SentinelBenefits::Csv401kConverter::Line;
$Finance::Bank::SentinelBenefits::Csv401kConverter::Line::VERSION = '1.0';
use Modern::Perl;

=head1 NAME

Finance::Bank::SentinelBenefits::Csv401kConverter::Line - stores
one line of data from a Sentinel Benefits spreadsheet.

=head1 VERSION

version 1.0

=head1 SYNOPSIS

This class represents one transaction, whether a contribution or
a company match, and tells you the security, the price, quantity,
total money, etc.  It doesn't have any smarts, but serves as an
immutable internal data structure.

=cut

use Moose;

use Finance::Bank::SentinelBenefits::Csv401kConverter::Types;

=head1 Constructor

=head2 new()

    my $l = Finance::Bank::SentinelBenefits::Csv401kConverter::Line->new(
        date     => $date,
        symbol   => $symbol,
        memo     => $memo,
        quantity => $quantity,
        price    => $price,
        total    => $total,
        source   => $source,
        side     => $side,
     );

=cut

=head1 Accessors

=head2 $l->date()

The date of the transaction

=cut

has 'date' => (
    is        => 'ro',
    isa       => 'DateTime',
    required  => 1,
);

=head2 $l->symbol()

The symbol of the transaction

=cut

has 'symbol' => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

=head2 $l->memo()

The memo of the transaction

=cut

has 'memo' => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

=head2 $l->quantity()

The quantity of the transaction, can be franctional

=cut

has 'quantity' => (
    is        => 'ro',
    isa       => 'Num',
    required  => 1,
);

=head2 $l->price()

The price of the transaction

=cut

has 'price' => (
    is        => 'ro',
    isa       => 'Num',
    required  => 1,
);

=head2 $l->total()

The total of the transaction

=cut

has 'total' => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);

=head2 $l->source()

The source of the transaction

=cut

has 'source' => (
    is       => 'ro',
    isa      => 'ContributionSource',
    required => 1,
);

has 'side' => (
    is       => 'ro',
    isa      => 'TradeSide',
    required => 1,
);

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
