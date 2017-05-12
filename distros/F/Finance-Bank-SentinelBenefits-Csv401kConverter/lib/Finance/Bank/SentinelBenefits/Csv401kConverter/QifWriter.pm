package Finance::Bank::SentinelBenefits::Csv401kConverter::QifWriter;
$Finance::Bank::SentinelBenefits::Csv401kConverter::QifWriter::VERSION = '1.0';
use Modern::Perl;

=head1 NAME

Finance::Bank::SentinelBenefits::Csv401kConverter::QifWriter -
Takes C<Finance::Bank::SentinelBenefits::Csv401kConverter::Line> objects
and writes them out to a QIF file

=head1 VERSION

version 1.0

=head1 SYNOPSIS

This class is responsible for taking a set of Lines and writing them out
to QIF format.  We use the class C<Finance::QIF> to do the acutal writing to disk.  If you pass it a secondary set of account information, it will also take any company matches, reverse their values, and write them to a secondary file.  This is to allow you to keep track of your unvested balance.

=cut

use Moose;
use MooseX::Method::Signatures;

use Finance::QIF;
use Finance::Bank::SentinelBenefits::Csv401kConverter::Line;

=head1 Constructor

=head2 new()

    my $l = Finance::Bank::SentinelBenefits::Csv401kConverter::QifWrite->new( {
    main_output_filename => $main_output_filename,
    flip_output_filename => $flip_output_filename, ( optional )
    account           => $account,
    trade_date        => $trade_date,
    } );

  Constructs a new QifWriter for the given trade date and account.  Each qif writer can only generate to one trade date and account, and one main file.

=cut

####
# BUILDARGS initializes the QIF reader based on the passed in filename
####
around BUILDARGS => sub {
      my $orig = shift;
      my $class = shift;

      my $hashref = $class->$orig(@_);

      if(exists $hashref->{output_file}){
	  my $qif_output = Finance::QIF->new( file => $hashref->{output_file} );

	  $hashref->{qif_output} = $qif_output;
      }

      return $hashref;
};

####
# BUILD sets up the QIF reader by writing out the header
####
sub BUILD {
    my $self = shift;

    $self->_get_qif_output()->header ( 'Account' );

    my %init = (
    	name => $self->account(),
    	type => 'Type:Invst',
    	header=> 'Account',
    );

    $self->_get_qif_output()->write(\%init);

    $self->_get_qif_output()->header ( 'Type:Invst' );
};

=head1 Accessors

=head2 $l->account()

The account of the transactions

=cut

has 'account'=> (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

=head2 $l->output_file()

The output file name that the QIF lines are written to.

=cut

has 'output_file' => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

has 'qif_output' => (
    is        => 'ro',
    isa       => 'Finance::QIF',
    required  => 1,
    reader    => '_get_qif_output',
);

=head1 Methods

=head2 $l->output_line($line)

Writes one line out to the QIF file.  Line is of type
C<Finance::Bank::SentinelBenefits::Csv401kConverter::Line>

=cut

method output_line(Finance::Bank::SentinelBenefits::Csv401kConverter::Line $line){

    # my %security_transaction = ( header => 'Type:Invst',
    # 				 date => $date,
    # 				 action => 'Buy',
    # 				 security => 'IBM',
    # 				 price => 101.1,
    # 				 quantity => 20,
    # 				 memo => 'Purchased some stock',
    # 				 transaction => 101.1 * 20,
    # 	);

  my $date_string = sprintf("%u/%u/%4d", $line->date()->mon(), $line->date()->day(), $line->date()->year());

  my $price = sprintf("%.6f", $line->total() / $line->quantity());#recalc price to avoid bad quantities
  $price =~ s/0+$//;


  my %transaction = (
		     header => 'Type:Invst',
		     date => $date_string,
		     action => $line->side(),
		     security => $line->symbol(),
		     #price => $line->price(),
                     price => $price,
		     quantity => $line->quantity(),
		     memo => $line->memo(),
		     transaction => $line->total(),
		    );
  $self->_get_qif_output()->write(\%transaction);
}

=head $l->close()

Closes the writer, ensuring that data is flushed to disk.  Calling output_line
after this is an error.

=cut

method close(){
    $self->_get_qif_output()->close();
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
