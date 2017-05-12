use Test::More tests => 83;
use lib './lib';
use DateTime;
use Modern::Perl;

diag( 'Loading line parser' );
use_ok( 'Finance::Bank::SentinelBenefits::Csv401kConverter::LineParser' );

my %symbol_hash = (
    'Micro-organism Investment Value Fund' => 'ALGAE',
    'Blue Bank Fund - Class A' => 'BLUEF',
    'Green Bank Intl Equity' => 'GREEN',
    'Red Bank Bond Fund' => 'REDFU',
    'Purple Bank LLC Fund' => 'GOPIP',
    'GNU Privacy Fund' => 'GNUPG',
    'Bank of Perl Stock Fund' => 'IAAEA',
    'Jam and Jelly Commodity Fund Class A' => 'GRAPE',
    'Legal Industry ETF' => 'IANAL',
    );

my $symbol_map = Finance::Bank::SentinelBenefits::Csv401kConverter::SymbolMap->new( symbol_map => \%symbol_hash );

####
#Sample data
####
my $header_line = 'Date & Source of Money,Status,Details,Units,Price,Dollars,Redemption Fee';
my $date_line = '11/02/09';
my $symbol_line = 'Employer Matching Contribution,Settled,Match of $8.13 to Foobar Dividend Portfolio - ALGAEMicro-organism Investment Value Fund.,2.67,4.17,11.1339,0';
my $no_symbol_line = 'Employer Matching Contribution,Settled,Match of $16.67 to Blue Bank Fund - Class A.,1.65,6.53,10.7745,0';
my $deferral_line = 'Employee 401k Contribution,Settled,Deferral of $10.83 to Foobar Dividend Portfolio - GOPIPPurple Bank LLC Fund.,2.21,1.46,3.2266,0';
my $buy_line = 'Employee 401k Contribution,Settled,Buy Foobar Portfolio - GOPIPPurple Bank LLC Fund.(Dollar certain),2.21,1.46,3.2266,0';
my $sell_line = 'Employer Matching Contribution,Settled,Sell Foobar Portfolio - GOPIPPurple Bank LLC Fund.(Unit certain),-2.21,1.46,-$3.2266,0';
my $div_line = 'Employee 401k Contribution,Settled,Gain/Loss of of $0.11 to Foobar Portfolio - GOPIPPurple Bank LLC Fund.,0.001,133.49,0.11,0';
my $div_match_line = 'Employer Matching Contribution,Settled,Gain/Loss of of $0.17 to Foobar Portfolio - GOPIPPurple Bank LLC Fund.,0.006,28.04,0.17,0';
my $div_line_true = 'Employee 401k Contribution,Settled,Dividend of of $0.11 to Foobar Portfolio - GOPIPPurple Bank LLC Fund.,0.001,133.49,0.11,0';
my $div_match_line_true = 'Employer Matching Contribution,Settled,Dividend of of $0.17 to Foobar Portfolio - GOPIPPurple Bank LLC Fund.,0.006,28.04,0.17,0';

my $line_parser = Finance::Bank::SentinelBenefits::Csv401kConverter::LineParser->new( symbol_map => $symbol_map );

my $date = DateTime->new( year   => 1964,
                          month  => 10,
                          day    => 16,
    );

diag( 'testing invalid lines' );

is( $line_parser->parse_line($header_line, $date), undef, 'Header line should return undef');

is( $line_parser->parse_line($date_line, $date), undef, 'Date line should return undef');

diag( 'testing valid lines - matching contribution, without symbol' );

{
    my $line = $line_parser->parse_line($no_symbol_line, $date);
    is( $line->date()->subtract_datetime( $date )->seconds, 0, 'Datetime on line should match input datetime' );
    is( $line->symbol(), 'BLUEF', 'Symbol should be picked up from the map' );
    is( $line->memo(), 'Match of $16.67 to Blue Bank Fund - Class A.' );
    is( $line->quantity(), 1.65 );
    is( $line->price(), 6.53 );
    is( $line->total(), 10.7745 );
    is( $line->source(), 'Match', 'This should be picked up as a match transaction' );
    is( $line->side(), 'Buy', 'We are buying here' );
}

diag( 'testing valid lines - matching contribution, with symbol' );
{
    my $line = $line_parser->parse_line($symbol_line, $date);
    is( $line->date()->subtract_datetime( $date )->seconds, 0, 'Datetime on line should match input datetime' );
    is( $line->symbol(), 'ALGAE', 'Symbol should be ALGAE' );
    is( $line->memo(), 'Match of $8.13 to Foobar Dividend Portfolio - ALGAEMicro-organism Investment Value Fund.' );
    is( $line->quantity(), 2.67 );
    is( $line->price(), 4.17 );
    is( $line->total(), 11.1339 );
    is( $line->source(), 'Match', 'This should be picked up as a match transaction' );
    is( $line->side(), 'Buy', 'We are buying here' );
}

diag( 'testing valid lines - employee contribution, with symbol' );
{
    my $line = $line_parser->parse_line($deferral_line, $date);
    is( $line->date()->subtract_datetime( $date )->seconds, 0, 'Datetime on line should match input datetime' );
    is( $line->symbol(), 'GOPIP', 'Symbol should be GOPIP' );
    is( $line->memo(), 'Deferral of $10.83 to Foobar Dividend Portfolio - GOPIPPurple Bank LLC Fund.' );
    is( $line->quantity(), 2.21 );
    is( $line->price(), 1.46 );
    is( $line->total(), 3.2266 );
    is( $line->source(), 'Deferral', 'This should be picked up as a deferral transaction' );
    is( $line->side(), 'Buy', 'We are buying here' );
}

diag( 'testing valid lines - employee contribution, with symbol' );
{
    my $line = $line_parser->parse_line($deferral_line, $date);
    is( $line->date()->subtract_datetime( $date )->seconds, 0, 'Datetime on line should match input datetime' );
    is( $line->symbol(), 'GOPIP', 'Symbol should be GOPIP' );
    is( $line->memo(), 'Deferral of $10.83 to Foobar Dividend Portfolio - GOPIPPurple Bank LLC Fund.' );
    is( $line->quantity(), 2.21 );
    is( $line->price(), 1.46 );
    is( $line->total(), 3.2266 );
    is( $line->source(), 'Deferral', 'This should be picked up as a deferral transaction' );
    is( $line->side(), 'Buy', 'We are buying here' );
}

diag( 'testing valid lines - employee buyin, with symbol' );
{
    my $line = $line_parser->parse_line($buy_line, $date);
    is( $line->date()->subtract_datetime( $date )->seconds, 0, 'Datetime on line should match input datetime' );
    is( $line->symbol(), 'GOPIP', 'Symbol should be GOPIP' );
    is( $line->memo(), 'Buy Foobar Portfolio - GOPIPPurple Bank LLC Fund.(Dollar certain)' );
    is( $line->quantity(), 2.21 );
    is( $line->price(), 1.46 );
    is( $line->total(), 3.2266 );
    is( $line->source(), 'Deferral', 'This should be picked up as a deferral transaction' );
    is( $line->side(), 'Buy', 'We are buying here' );
}

diag( 'testing valid lines - employee match sell, with symbol' );
{
    my $line = $line_parser->parse_line($sell_line, $date);
    is( $line->date()->subtract_datetime( $date )->seconds, 0, 'Datetime on line should match input datetime' );
    is( $line->symbol(), 'GOPIP', 'Symbol should be GOPIP' );
    is( $line->memo(), 'Sell Foobar Portfolio - GOPIPPurple Bank LLC Fund.(Unit certain)' );
    is( $line->quantity(), 2.21 );
    is( $line->price(), 1.46 );
    is( $line->total(), 3.2266 );
    is( $line->source(), 'Match', 'This should be picked up as a match transaction' );
    is( $line->side(), 'Sell', 'We are selling here' );
}

diag( 'testing employee contribution dividend' );
{
  my $line = $line_parser->parse_line($div_line, $date);
  is( $line->date()->subtract_datetime( $date )->seconds, 0, 'Datetime on line should match input datetime' );
  is( $line->symbol(), 'GOPIP', 'Symbol should be GOPIP' );
  is( $line->memo(), 'Gain/Loss of of $0.11 to Foobar Portfolio - GOPIPPurple Bank LLC Fund.' );
  is( $line->quantity(), 0.001 );
  is( $line->price(), 133.49 );
  is( $line->total(), 0.11 );
  is( $line->source(), 'Deferral', 'This should be picked up as a match transaction' );
  is( $line->side(), 'ReinvDiv', 'We are reinvesting a dividend here' );
}

diag( 'testing employer match dividend' );
{
  my $line = $line_parser->parse_line($div_match_line, $date);
  is( $line->date()->subtract_datetime( $date )->seconds, 0, 'Datetime on line should match input datetime' );
  is( $line->symbol(), 'GOPIP', 'Symbol should be GOPIP' );
  is( $line->memo(), 'Gain/Loss of of $0.17 to Foobar Portfolio - GOPIPPurple Bank LLC Fund.' );
  is( $line->quantity(), 0.006 );
  is( $line->price(), 28.04 );
  is( $line->total(), 0.17 );
  is( $line->source(), 'Match', 'This should be picked up as a match transaction' );
  is( $line->side(), 'ReinvDiv', 'We are reinvesting a dividend here' );
}

diag( 'testing employee contribution dividend true' );
{
  my $line = $line_parser->parse_line($div_line_true, $date);
  is( $line->date()->subtract_datetime( $date )->seconds, 0, 'Datetime on line should match input datetime' );
  is( $line->symbol(), 'GOPIP', 'Symbol should be GOPIP' );
  is( $line->memo(), 'Dividend of of $0.11 to Foobar Portfolio - GOPIPPurple Bank LLC Fund.' );
  is( $line->quantity(), 0.001 );
  is( $line->price(), 133.49 );
  is( $line->total(), 0.11 );
  is( $line->source(), 'Deferral', 'This should be picked up as a match transaction' );
  is( $line->side(), 'ReinvDiv', 'We are reinvesting a dividend here' );
}

diag( 'testing employer match dividend true' );
{
  my $line = $line_parser->parse_line($div_match_line_true, $date);
  is( $line->date()->subtract_datetime( $date )->seconds, 0, 'Datetime on line should match input datetime' );
  is( $line->symbol(), 'GOPIP', 'Symbol should be GOPIP' );
  is( $line->memo(), 'Dividend of of $0.17 to Foobar Portfolio - GOPIPPurple Bank LLC Fund.' );
  is( $line->quantity(), 0.006 );
  is( $line->price(), 28.04 );
  is( $line->total(), 0.17 );
  is( $line->source(), 'Match', 'This should be picked up as a match transaction' );
  is( $line->side(), 'ReinvDiv', 'We are reinvesting a dividend here' );
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
