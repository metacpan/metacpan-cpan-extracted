package Finance::Bank::SentinelBenefits::Csv401kConverter;
$Finance::Bank::SentinelBenefits::Csv401kConverter::VERSION = '1.0';
use Modern::Perl;

use DateTime;
use DateTime::Format::Flexible;

=head1 NAME

Finance::Bank::SentinelBenefits::Csv401kConverter - Takes a series of lines in Sentinel Benefits format and writes them out as QIF files, subject to the symbol mappings specified.

=head1 VERSION

version 1.0

=head1 SYNOPSIS


=head1 DESCRIPTION

This module takes a CSV file in the format "provided" i.e. copy-pasted from the Sentinel Benefits website.  It also takes a description->symbol mapping, and one or two filenames to write out.  The first file is a list of the transactions in QIF format.  The second file, if provided, is a list of the company matches with the signs reversed, which can be useful if you want to keep unvested company contributions from showing up in your net worth calculations.

=cut

use Moose;
use MooseX::Method::Signatures;
use MooseX::StrictConstructor;

use Finance::Bank::SentinelBenefits::Csv401kConverter::SymbolMap;
use Finance::Bank::SentinelBenefits::Csv401kConverter::LineParser;
use Finance::Bank::SentinelBenefits::Csv401kConverter::QifWriter;
use Finance::Bank::SentinelBenefits::Csv401kConverter::SideReverser;


=head1 Accessors

=head2 $p->trade_input()

A file handle that supplies the trade data

=cut

has 'trade_input'  => (
    is       => 'ro',
    isa      => 'FileHandle',
    required => 1,
    );

has 'primary_output_file' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    );

has 'symbol_map' => (
    is       => 'ro',
    isa      => 'Finance::Bank::SentinelBenefits::Csv401kConverter::SymbolMap',
    required => 1,
    );

=head2 $p->trade_date()

Used if you wish to override the trade date specified in the input file, or if no trade date is available in the files.

If no dates are specified here or in the files, an exception will be thrown.

=cut

has 'trade_date' => (
    is       => 'ro',
    isa      => 'DateTime',
    required => 0,
    );

has 'account'    => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    );

has 'companymatch_account' => (
    is       => 'ro',
    isa      => 'Str',
    required => 0,
    );

has '_side_reverser' => (
    is       => 'ro',
    isa      => 'Finance::Bank::SentinelBenefits::Csv401kConverter::SideReverser',
    required => 0,
    default => sub {
	Finance::Bank::SentinelBenefits::Csv401kConverter::SideReverser->new();
    }
    );

method write_output(){
    my $parser = Finance::Bank::SentinelBenefits::Csv401kConverter::LineParser->new
	(
	 symbol_map => $self->symbol_map()
	);

    my $writer = Finance::Bank::SentinelBenefits::Csv401kConverter::QifWriter->new
	(
	 output_file => ">" . $self->primary_output_file(),
	 account     => $self->account(),
	);

    my $fh = $self->trade_input();

    my @lines;

    my $date = $self->trade_date();

    while(<$fh>){


      #this line is a date and there is no override, parse it as such
      if(9 == length && (not defined $self->trade_date()) ){
	$date = DateTime::Format::Flexible->parse_datetime($_);
#	warn "date is $date";
      }else{

	my $line = $parser->parse_line($_, $date);

	if (defined $line) {
	  $writer->output_line($line);

	  push @lines, $line;
	}
      }
    }

    $writer->close();

    if($self->companymatch_account())
    {
	my $cm_writer = Finance::Bank::SentinelBenefits::Csv401kConverter::QifWriter->new
	(
	 output_file => ">>" . $self->primary_output_file(),
	 account     => $self->companymatch_account(),
	);

	foreach my $line (@lines) {

	    if($line->source() eq 'Match'){
		my $cm_line = Finance::Bank::SentinelBenefits::Csv401kConverter::Line->new
		    (
		     date      => $line->date(),
		     symbol    => $line->symbol(),
		     memo      => $line->memo(),
		     quantity  => $line->quantity(),
		     price     => $line->price(),
		     total     => $line->total(),
		     source    => $line->source(),
		     side      => $self->_side_reverser->flip($line->side()),
		    );
		$cm_writer->output_line($cm_line);
	    }

	}

	$cm_writer->close();
	
    }
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;

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
