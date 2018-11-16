# Perl test file, can be run like so:
#   `perl 08-Graphics-Skullplot-ClassifyColumns-column_types.t'
#         doom@kzsu.stanford.edu     2018/11/14 11:58:28

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

{  my $subname = "column_types";
   my $test_name = "Testing $subname";
   my $case_name = "first and last cols numeric, others strings";

   my $data = [ ['age',      'name',     'color', 'montrousness'],
                [  999,   'ghidora',     'green',             99],
                [   66,  'godzilla',     'green',             75],  
                [  6.5,   'mothera',     'multi',              3],
                [   33,     'rodan',     'brown',             55],
                ];

   my $cc = Graphics::Skullplot::ClassifyColumns->new( data => $data );  
   my $types = 
       $cc->column_types();

   my @expected_types = ( ':NUMBER:', ':STRING:', ':STRING:', ':NUMBER:' );
   is_deeply( $types, \@expected_types, "$test_name: $case_name" );
 }

{  my $subname = "column_types";
   my $test_name = "Testing $subname";
   my $case_name = "first col year, last cols numeric, others strings";

   my $data = [ ['first_sited',      'name',     'color', 'montrousness'],
                [         1964,   'ghidora',     'green',             99],
                [         1954,  'godzilla',     'green',             75],
                [         1961,   'mothera',     'multi',              3],
                [         1956,     'rodan',     'brown',             55],
                ];

   my $cc = Graphics::Skullplot::ClassifyColumns->new( data => $data );  
   my $types = 
       $cc->column_types();

   my @expected_types = ( ':NUMBER:', ':STRING:', ':STRING:', ':NUMBER:' );
   is_deeply( $types, \@expected_types, "$test_name: $case_name" );
 }

{  my $subname = "column_types";
   my $test_name = "Testing $subname";
   my $case_name = "first col yyyy-mm-dd date, last cols numeric, others strings";

   my $data = [ ['first_sighted',      'name',     'color', 'montrousness'],
                [   '1964-01-01',   'ghidora',     'green',             99],
                [   '1954-03-31',  'godzilla',     'green',             75],
                [   '1961-02-28',   'mothera',     'multi',              3],
                [   '1956-12-32',     'rodan',     'brown',             55],
                ];

   my $cc = Graphics::Skullplot::ClassifyColumns->new( data => $data );  
   my $types = 
       $cc->column_types();

   my @expected_types = ( ':DATE:', ':STRING:', ':STRING:', ':NUMBER:' );
   is_deeply( $types, \@expected_types, "$test_name: $case_name" );
 }


done_testing();
