use Modern::Perl;
use DateTime;
use lib './lib';

use Finance::Bank::SentinelBenefits::Csv401kConverter;
use Finance::Bank::SentinelBenefits::Csv401kConverter::SymbolMap;

use Getopt::Long;

my $symbol_map_filename = '';
my $output_main = 'C:/programming/sbwpt/main.qif';
my $output_flip  = 'C:/programming/sbwpt/alt.qif';

my $trade_date = DateTime->new( year  => 2010 ,
			  month => 8   ,
			  day   => 16   ,);
my $main_account='LaBranche 401(k)';
my $flip_account='LaBranche 401(k) seg';


my $fh_symbol_map;
open($fh_symbol_map, 'C:/programming/sbwpt/dictionary.csv') or die "unable to open symbol map fh";
my $symbol_map = Finance::Bank::SentinelBenefits::Csv401kConverter::SymbolMap->new(symbol_map => $fh_symbol_map);
close($fh_symbol_map) or die 'Unable to close symbol map fh';

my $trade_input;
open ($trade_input, "C:/programming/sbwpt/data.csv") or die "Unable to open input file";

{
  my $parser = Finance::Bank::SentinelBenefits::Csv401kConverter->new
    (
     primary_output_file => $output_main,
     trade_input         => $trade_input,
#     trade_date          => $trade_date,
     symbol_map          => $symbol_map,
     account             => $main_account,
     companymatch_account     => $flip_account,
    );
  $parser->write_output();
}
close $trade_input or die "Unable to close input file";
