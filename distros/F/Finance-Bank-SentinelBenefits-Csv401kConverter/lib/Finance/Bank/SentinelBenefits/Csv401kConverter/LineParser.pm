package Finance::Bank::SentinelBenefits::Csv401kConverter::LineParser;
$Finance::Bank::SentinelBenefits::Csv401kConverter::LineParser::VERSION = '1.0';
use Modern::Perl;
=head1 NAME

Finance::Bank::SentinelBenefits::Csv401kConverter::LineParser - turns
CSV lines into standardized Line objects

=head1 VERSION

version 1.0

=head1 SYNOPSIS

This class takes raw lines from the Sentinel website's CSV files and a map
of security names to symbols, and returns parsed C<Finance::Bank::SentinelBenefits::Csv401kConverter::Line>
objects

=cut

use Moose;

use Finance::Bank::SentinelBenefits::Csv401kConverter::SymbolMap;
use Finance::Bank::SentinelBenefits::Csv401kConverter::Line;

use constant {
    NUMBER_OF_FIELDS => 7,
};

=head1 Constructor

=head2 new()

    my $f = Finance::Bank::SentinelBenefits::Csv401kConverter::LineParser->new( {
        symbol_map => $symbol_map,
    } );

Construct a new LineParser with the given symbol map

=head1 Accessors

=head2 $p->symbol_map()

Accesses the passed in symbol map.  This is only really for internal
use, as the symbol map is immutable.

=cut

has 'symbol_map' => (
    is       => 'ro',
    isa      => 'Finance::Bank::SentinelBenefits::Csv401kConverter::SymbolMap',
    required => 1,
);

=head1 Methods

=head2 $f->parse_line($line);

This method takes the line to be parsed as an argument.

If it is a valid security line, it returns a C<Finance::Bank::SentinelBenefits::Csv401kConverter::Line>.

If it is not a valid security line, it returns C<undef>.

=cut

sub parse_line {
    my $self = shift;
    my $line = shift;
    my $date = shift;

    my @line_parts = split /,/, $line;

     if(NUMBER_OF_FIELDS() == @line_parts
        && $line_parts[0] =~ m/Employe. .+ Contribution/){
	 
	 my ($contribution_type, $status, $memo, $quantity, $price, $total, $redemption_fee) = @line_parts;

	 $total =~ s/\$//;

	 my $parsed_line = Finance::Bank::SentinelBenefits::Csv401kConverter::Line->new( {
	    date     => $date,
	    symbol   => $self->symbol_map()->get_symbol($memo),
	    memo     => $memo,
	    quantity => abs($quantity),
	    price    => $price,
	    total    => abs($total),
	    side     => $memo =~ m/^Sell/       ? 'Sell' 
		      : $memo =~ m/^Gain\/Loss/ ? 'ReinvDiv'
		      : $memo =~ m/^Dividend/   ? 'ReinvDiv'
		      : 'Buy',
	    source   => $contribution_type =~ m/Employer Matching Contribution/ ? 'Match' : 'Deferral',
											} );
	return $parsed_line;
    }

    return;
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
