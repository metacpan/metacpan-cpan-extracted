use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Finance::MICR::GOCR::Check;
use Finance::MICR::LineParser;

use Smart::Comments '###';
use Cwd;
use File::Which;
use File::Path;
use File::Copy;




# if you want to se details.. turn this to 1
# and from the base dir of this package run
# perl t/0_gocr.t
$Finance::MICR::GOCR::Check::DEBUG=0;


# these are prepped
my $abs_checks = cwd().'/t/checks_easy';

opendir(DIR,$abs_checks);
my @checks = grep { /\.png$/ } readdir DIR;
closedir DIR;
ok(scalar @checks) or die;






for (@checks){


	my $check = new Finance::MICR::GOCR::Check({ 
      abs_check => "$abs_checks/$_", 
      abs_path_gocrdb => cwd.'/t/micrdb/' 
      
      });

		
	ok( $check->f,'f');

	my $prepped = $check->is_prepped;
	ok($prepped, "is prepped should return true for these");


	ok($check->parser->micr_pretty,  "parser returns micr pretty" );

	unless ($check->parser->micr_pretty){
		$check->save_report;
		print STDERR "report saved\n";
	}
	
	my $mp = $check->parser->micr_pretty;
	

	ok( $check->f->filename_only eq $mp,
      'micr_pretty from parser is same as check filename (control) '.$check->f->filename_only.' == '.$mp);
	print STDERR $check->abs_micr ."\n\n";

	

}






