use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Finance::MICR::GOCR;
use Finance::MICR::LineParser;

use Smart::Comments '###';
use Cwd;
use File::Which;
use File::Path;
use File::Copy;

ok(File::Which::which('gocr'),'gocr binary found with which') or die('which does not find path to gocr binary. Is gocr installed?');

File::Path::rmtree(cwd().'/t/micrdb');
mkdir cwd().'/t/micrdb';
opendir(DOR,cwd().'/micrdb') or die;
my @f = grep { /\.\w{3}$/ } readdir DOR;
closedir DOR;
map { File::Copy::cp(cwd().'/micrdb/'.$_, cwd().'/t/micrdb/'.$_) } @f;
my $abs_path_gocrdb = cwd().'/t/micrdb';


print STDERR "$0 tests Finance::MICR::GOCR\n";


# if you want to se details.. turn this to 1
# and from the base dir of this package run
# perl t/0_gocr.t
$Finance::MICR::GOCR::DEBUG=0;


# this tests on micr extracts only

opendir(DIR,cwd().'/t/micrs');
my @micrs = grep { /\.pgm$/ } readdir DIR;
closedir DIR;
ok(scalar @micrs) or die;




my $symbol = {
	transit=> 'Aa',
	on_us=> 'CCc',
};

my $control = {};

for (@micrs){
	my $filename = $_;
	
	my $data = {	
		filename => $filename,
		abs_path => cwd()."/t/micrs/$filename",		
	};	

	my $micr = $filename;
	$micr=~s/\.\w{3}$//;
	$data->{micr} = $micr;		
	$control->{$filename} = $data;

}



for (keys %{$control}){
	my $c = $control->{$_};

	my $gocr = new Finance::MICR::GOCR({
		abs_path => $c->{abs_path},
		abs_path_gocrdb => $abs_path_gocrdb,
	});
	
	my $micr_g = $gocr->out;
	my $micr_c = $c->{micr};
	


	ok($micr_g,"Finance::MICR::GOCR::out() = $micr_g");
	
	my $parser_out = new Finance::MICR::LineParser({
		string => $micr_g,
		on_us_symbol => 'CCc',
		transit_symbol => 'Aa',
		dash_symbol => 'DDd',
		ammount_symbol => 'XxX',	
	});
	my $parser_out_micr_pretty = $parser_out->micr_pretty;
	ok($parser_out_micr_pretty) or die("Finance::MICR::LineParser should be able to produce micr pretty for $micr_g");
	
	
	my $parser_control = new Finance::MICR::LineParser({ 
		string => $micr_g,
		on_us_symbol => 'CCc',
		transit_symbol => 'Aa',
		dash_symbol => 'DDd',
		ammount_symbol => 'XxX',	
	});
	
	my $parser_control_micr_pretty = $parser_control->micr_pretty;
	

	
	ok(
	$parser_out_micr_pretty eq
	$parser_control_micr_pretty, 
	"a LineParser for test and crontrol should both output same micr pretty
	test is $parser_out_micr_pretty
	control $parser_control_micr_pretty");

#	ok($micr_g eq $micr_c) or print STDERR " $micr_g ne\n $micr_c\n\n";

}

















