# Perl test file, can be run like so:
#   perl 01-Graphics-Skullplot-new.t
#         doom@kzsu.stanford.edu     2018/11/13 19:52:06

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
# Insert your test code below.  Consult perldoc Test::More for help.

{  my $subname = "new";
   my $test_name = "Testing $subname";

   my $dat_loc = "$Bin/dat";
   my $dbox_file = "$dat_loc/silver_governors_race-2col.dbox";

   my $gsp = 
       Graphics::Skullplot->new( {
           input_file   => $dbox_file,
           plot_hints   => {
               indie_count      => 1,
               dependent_spec   => '',
               independent_spec => '',
           },
         });

   my $class = ref $gsp;
   is( $class, 'Graphics::Skullplot', "$test_name: created object");

   is( $gsp->working_area, '/tmp', "$test_name: expected working area default");

   is( $gsp->image_viewer, 'display', "$test_name: expected image viewer setting");

   my $naming = $gsp->naming;
   print "naming: ", Dumper( $naming ), "\n";

   my $expected_naming = {
          'base'          => 'silver_governors_race-2col.dbox',
          'ext'           => 'dbox',
          'rscript'       => '/tmp/silver_governors_race-2col.r',
          'tsv'           => '/tmp/silver_governors_race-2col.tsv',
          'base_sans_ext' => 'silver_governors_race-2col',
          'png'           => '/tmp/silver_governors_race-2col.png'
        };

   is_deeply( $naming, $expected_naming, "$test_name: expected names for tsv, png, etc." );

 }

done_testing();
