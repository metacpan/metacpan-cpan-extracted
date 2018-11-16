# Perl test file, can be run like so:
#   `perl 07-Graphics-Skullplot-ClassifyColumns-classify_columns_simple.t'
#         doom@kzsu.stanford.edu     2018/11/13 23:04:50

use 5.10.0;
use warnings;
use strict;
$|=1;
my $DEBUG = 0;
use Data::Dumper;
use File::Path      qw( mkpath );
use File::Basename  qw( fileparse basename dirname );
use File::Copy      qw( copy move );
use Fatal           qw( open close mkpath copy move );
use Cwd             qw( cwd abs_path );
use Env             qw( HOME );

use Test::More;

BEGIN {
  use FindBin qw($Bin);
  use lib ("$Bin/../lib/");
  use_ok( 'Graphics::Skullplot::ClassifyColumns' , )
}

ok(1, "Traditional: If we made it this far, we're ok.");

# $DB::single = 1;
# Insert your test code below.  Consult perldoc Test::More for help.

{  my $subname = "classify_columns_simple";
   my $test_name = "Testing $subname";
   my $case_name = "first and last cols numeric, others strings";
   my $data = [ ['age',      'name',     'color', 'montrousness'],
                [  999,   'ghidora',     'green',             99],
                [   66,  'godzilla',     'green',             75],  
                [  6.5,   'mothera',     'multi',              3],
                [   33,     'rodan',     'brown',             55],
                ];

   my $cc = Graphics::Skullplot::ClassifyColumns->new( data => $data );  
   $cc->classify_columns_simple();

   my $opt = { indie_count => 1, };
   my $plot_cols = 
       $cc->classify_columns_simple( $opt ); 

   my $expected_plot_cols = {
          'dependents_y' => [
                             'montrousness'
                           ],
          'indie_x' => 'age',
          'y' => 'montrousness',
          'gb_cats' => [
                         'name',
                         'color'
                       ]
        };
   is_deeply( $plot_cols, $expected_plot_cols,
              "$test_name: $case_name")
     or die Dumper( $plot_cols );
 }

{  my $subname = "classify_columns_simple";
   my $test_name = "Testing $subname";
   my $case_name = "Two first cols numeric";

   my $data = [ ['age',  'height',         'name',     'color', 'montrousness'],
                [  6.5,        25,      'mothera',     'multi',              3],                       
                [  999,       110,      'ghidora',     'green',             99],
                [   66,       137,     'godzilla',     'green',             75],
                [   33,        98,        'rodan',     'brown',             55],                       
                ];


   my $cc = Graphics::Skullplot::ClassifyColumns->new( data => $data );  
   $cc->classify_columns_simple();

   my $opt = { indie_count => 1, };
   my $plot_cols = 
       $cc->classify_columns_simple( $opt ); 

   my $expected_plot_cols = {
          'dependents_y' => [
                            'montrousness'
                           ],
          'indie_x' => 'age',
          'y' => 'montrousness',
          'gb_cats' => [
                            'height',
                            'name',
                            'color'
                       ]
        };
 
   is_deeply( $plot_cols, $expected_plot_cols,
              "$test_name: $case_name")
     or die Dumper( $plot_cols );
 }

{  my $subname = "classify_columns_simple";
   my $test_name = "Testing $subname";
   my $case_name = "Two last columns numeric, indie_count 2";

   my $data = [ ['age',      'name',   'color',  'height', 'montrousness'],   
                [  999,   'ghidora',   'green',       110,             99],   
                [   66,  'godzilla',   'green',       137,             75],   
                [  6.5,   'mothera',   'multi',        25,              3],   
                [   33,     'rodan',   'brown',        98,             55],   
                ];                                                         

   my $cc = Graphics::Skullplot::ClassifyColumns->new( data => $data );  
   $cc->classify_columns_simple();

   my $opt = { indie_count => 2, };
   my $plot_cols = 
       $cc->classify_columns_simple( $opt ); 

   my $expected_plot_cols = {
          'dependents_y' => [
                            'height',
                            'montrousness'
                           ],
          'indie_x' => 'age',
          'y' => '',  # empty when there's more than one
          'gb_cats' => [
                            'name',
                            'color'
                       ]
        };

   is_deeply( $plot_cols, $expected_plot_cols,
              "$test_name: $case_name")
     or die Dumper( $plot_cols );

 }

done_testing();
