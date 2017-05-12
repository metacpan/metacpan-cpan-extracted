use Test::Simple 'no_plan';
use strict;
use lib './lib';
use Metadata::DB::WUI;
use LEOCHARRE::DBI;
use Cwd;
use File::Copy;
use Smart::Comments '###';
#$Metadata::DB::WUI::DEBUG = 1;
$CGI::Application::Plugin::MetadataDB::DEBUG = 1;


my $absdb = cwd().'/t/test.db';
-f $absdb or die("missing $absdb");
my $dbh = DBI::connect_sqlite($absdb);
ok($dbh,"got db connect to $absdb") or die;







my $wui = Metadata::DB::WUI->new( 
	PARAMS => { 
		DBH => $dbh , 
	},
);
ok($wui, 'instanced wui');


$ENV{HTML_TEMPLATE_ROOT} = './t';
$ENV{CGI_APP_RETURN_ONLY} = 1;

my $mdw_search_output;
ok( $mdw_search_output = $wui->run, 'ran search' );
save_file('./t/mdw_search_output.html',$mdw_search_output);



# try getting a record hash
#my $record = $wui->mdw_record_params(197507);
## $record


undef $wui;



$wui = Metadata::DB::WUI->new( 
	PARAMS => { 
		DBH => $dbh , 
	},
);
ok($wui, 'instanced wui again');


# RUN A SEARCH
require Metadata::DB::Search::InterfaceHTML;
my $prepend = $Metadata::DB::Search::InterfaceHTML::PREPEND_VALUE;
my $pfieldn = $Metadata::DB::Search::InterfaceHTML::PREPEND_FIELD_NAME;
### $prepend
### $pfieldn


my %query_params = (
    rm                           => 'mdw_search_results' ,
    $prepend .'_attribute'       => 'year',
    $prepend .'_year'            => '2006' ,
    $prepend .'_year_match_type' => 'exact',
    $pfieldn                     => $prepend,
);
### %query_params

for( keys %query_params ){
   $wui->query->param( $_ => $query_params{$_} );
};


ok( ($wui->query->param($pfieldn)) eq $prepend ) or die;


# change the single record display...

my $_record_html = q{
<hr>
<div>
   <p>
    <cite><TMPL_VAR LIST_INDEX></cite>
    <i><TMPL_VAR ID></i>
    <b><TMPL_VAR META_YEAR> <TMPL_VAR META_MONTH></b>
   </p>
   
   <h2><TMPL_VAR META_NAME></h2>

   <p>Stats: <TMPL_VAR META_HEIGHT> <TMPL_VAR META_WEIGHT></p>
  
<blockquote><TMPL_VAR META_AS_UL_HTML></blockquote>

</div>

};

#$wui->mdw_result_code($_record_html);

my $mdw_search_results_output = $wui->run;
ok($mdw_search_results_output, 'ran search results');

my $cr = $wui->get_current_runmode;
ok($cr eq 'mdw_search_results','rm is search results') or die;

save_file('./t/mdw_search_results_output.html', $mdw_search_results_output );



sub save_file {
   my($abs_html, $output) = @_;

   open(FILE,'>',$abs_html) or die;
   print FILE $output;
   close FILE;
   ok(-f $abs_html, "saved [$abs_html], this is a temp file");
   return $abs_html;

}

