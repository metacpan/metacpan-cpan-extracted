# Perl test file, can be run like so:
#    perl 10-Graphics-Skullplot-plot_tsv_to_png.t
#         doom@kzsu.stanford.edu     2018/11/13 16:27:43

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
  use_ok( 'Graphics::Skullplot' , )
}

ok(1, "Traditional: If we made it this far, we're ok.");

# $DB::single = 1;

{  my $subname = "plot_tsv_to_png";
   my $test_name = "Testing $subname";
   my $case_name = "basic case";

   my $dat_loc = "$Bin/dat";
   my $tmp_loc = "$Bin/tmp";
   my $working_area = "$tmp_loc/working";
   mkpath $working_area unless -d $working_area;

   # clean-up from previous runs
   my @stale = glob("$working_area/*");
   unlink( @stale );

   my $dbox_file = "$dat_loc/expensoids_date_type_sum.dbox"; 
   my $indie_count = 1;
   my $plot_hints = { indie_count      => $indie_count,
                    };
   my %gsp_args = 
     ( input_file   => $dbox_file,
       plot_hints   => $plot_hints, );
   $gsp_args{ working_area } = $working_area if $working_area;

   my $gsp = Graphics::Skullplot->new( %gsp_args );

   my $naming = $gsp->naming;
   my $png_file  = $naming->{ png };
   my $tsv_file  = $naming->{ tsv };

   # the input from the dbox file output directly to a tsv file 
   my $dbx = Table::BoxFormat->new( input_file  => $dbox_file ); 
   my $data = $dbx->output_to_tsv( $tsv_file ); # also returns a ref to an array of arrays

   my $plot_cols = $gsp->classify_columns( $data );

   $gsp->plot_tsv_to_png( $plot_cols );
   
   ok( -e $png_file, "$test_name $case_name: png file created" );

   my $size = -s $png_file;

   cmp_ok( $size, '>', 10000, "$test_name $case_name: png file is of reasonable size." );
   # TODO once behavior has been firmed-up, add more fine-grained examination of the image file.
 }

{  my $subname = "plot_tsv_to_png";
   my $test_name = "Testing $subname";
   my $case_name = "using 'requested' hints";

   my $dat_loc = "$Bin/dat";
   my $tmp_loc = "$Bin/tmp";
   my $working_area = "$tmp_loc/working";
   mkpath $working_area unless -d $working_area;

   # clean-up from previous runs
   my @stale = glob("$working_area/*");
   unlink( @stale );

   my $dbox_file = "$dat_loc/silver_governors_race.dbox"; 
               # silver_governors_race.dbox
               # silver_governors_race-2col.dbox
   my $indie_count = 1;
   my $dependent_requested    = 'bias';
   my $independent_requested  = 'number_polls';

   my $plot_hints = { indie_count      => $indie_count,
                      dependent_requested   => $dependent_requested,
                      independent_requested => $independent_requested,
                    };
   my %gsp_args = 
     ( input_file   => $dbox_file,
       plot_hints   => $plot_hints, );
   $gsp_args{ working_area } = $working_area if $working_area;

   my $gsp = Graphics::Skullplot->new( %gsp_args );

   my $naming = $gsp->naming;
   my $png_file  = $naming->{ png };
   my $tsv_file  = $naming->{ tsv };

   # the input from the dbox file output directly to a tsv file 
   my $dbx = Table::BoxFormat->new( input_file  => $dbox_file ); 
   my $data = $dbx->output_to_tsv( $tsv_file ); # also returns a ref to an array of arrays

   my $plot_cols = $gsp->classify_columns( $data );

   $gsp->plot_tsv_to_png( $plot_cols );

   ok( -e $png_file, "$test_name $case_name: png file created" );

   my $size = -s $png_file;

   cmp_ok( $size, '>', 5000, "$test_name $case_name: png file is of reasonable size." );

 }

done_testing();
