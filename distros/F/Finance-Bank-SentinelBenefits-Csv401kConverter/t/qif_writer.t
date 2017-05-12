use Test::More tests => 19;
use Modern::Perl;
use DateTime;
use lib './lib';

use File::Temp qw(tempfile);

use_ok( 'Finance::Bank::SentinelBenefits::Csv401kConverter::QifWriter' );

my $date = DateTime->new( year   => 1964,
			      month  => 10,
			      day    => 16,);


diag("Header tests");
{

  my ($temp_fh, $temp_filename) = tempfile(UNLINK=>1);

  diag("Temp file is $temp_filename, will be auto-removed");


  {#make sure that it goes out of scope, forcing the underlying writer to close
    my $writer = Finance::Bank::SentinelBenefits::Csv401kConverter::QifWriter->
      new(
	  output_file => ">$temp_filename",
	  account => 'TestAccount',
	  trade_date => $date,
	 );

    isnt($writer, undef, "Construction works");
  }

  my $fh;

  open ($fh, $temp_filename) or die "Can't open temp file";
  ok($fh, "Able to open temp file");

  matchHeader($fh);

  # my @expected = ('!Account', 'NTestAccount', 'TType:Invst');
  # my $index = 0;
  # while(<$fh>){
  #   if($index >= @expected){
  #     last;
  #   }
  #   my $item = chop($_);
  #   warn($item);
  #   is($_, $expected[$index++], "Header should match expected");
  # }

  close($fh) or die "Can't close temp file";
}

diag("Write one line tests - deferral");
{
  my ($temp_fh, $temp_filename) = tempfile(UNLINK=>0);

  diag("Temp file is $temp_filename, will be auto-removed");

  {#make sure that it goes out of scope, forcing the underlying writer to close
    my $writer = Finance::Bank::SentinelBenefits::Csv401kConverter::QifWriter->
      new(
	  output_file => ">$temp_filename",
	  account => 'TestAccount',
	  trade_date => $date,
	 );

    my $line = Finance::Bank::SentinelBenefits::Csv401kConverter::Line->new(
									    date => $date,
									    symbol => 'IBM',
									    memo => 'Purchased some stock',
									    quantity => 6.35,
									    price => 31.57,#put a wrong quantity to make sure that it gets converted correctly, should be 31.574803
									    total => 200.5,
									    source => 'Deferral',
									    side => 'Sell',
									   );

    $writer->output_line($line);
  }

  my $fh;

  open ($fh, $temp_filename) or die "Can't open temp file";
  ok($fh, "Able to open temp file");

  # my @expected = ('!Account', 'NTestAccount', 'TType:Invst', '^');
  # my $index = 0;
  # while($index < @expected){
  #   my $line = <$fh>;
  #   chomp $line;
  #   is($line, $expected[$index++], "Header should match expected");
  # }

  matchHeader($fh);

  my $headerLine = <$fh>;
  chomp $headerLine;
  is($headerLine, '^');

  #now that we've matched the header, we should be able to match the rest of the file
  #order doesn't matter, so check this using a hash;

  my %expectedTradeFields = (
			   '!' => 'Type:Invst',
			     D => '10/16/1964',
			     Q => '6.35',
			     M => 'Purchased some stock',
			     N => 'Sell',
			     Y => 'IBM',
			     T => '200.5',
			     I => '31.574803',
			    );

  my %actualTradeFields;

  while(<$fh>){
    my $line = $_;
    chomp $line;
    $actualTradeFields{substr($line, 0, 1)} = substr($line, 1);
  }

  while(my ($key, $value) = each(%expectedTradeFields)){
    is($actualTradeFields{$key}, $value, 'Actual field should match expected field');
  }

  close($fh) or die "Can't close temp file";
}

sub matchHeader{
  my $fh = shift;
  my $headerLine = <$fh>;
  chomp $headerLine;
  is($headerLine, '!Account','First line of header should be account');

  my $sawAccount = 0;
  my $sawType = 0;

  for(my $index = 0; $index < 2; $index++){
    $headerLine = <$fh>;
    chomp $headerLine;

    if('NTestAccount' eq $headerLine){
      $sawAccount = 1;
    } elsif('TType:Invst' eq $headerLine){
      $sawType = 1;
    }
  }

  is(1, $sawAccount, "Should see account in header");
  is(1, $sawType, "Should see type in header");
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
