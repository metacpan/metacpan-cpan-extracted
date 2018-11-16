# Perl test file, can be run like so:
#   `perl 09-Graphics-Skullplot-ClassifyColumns-define_regxeps.t'
#         doom@kzsu.stanford.edu     2018/11/14 13:20:28

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

{  my $subname   = "define_regxeps";
   my $test_name = "Testing $subname";

   my $cc = Graphics::Skullplot::ClassifyColumns->new();
   my $patterns = $cc->define_regxeps();

   my $pattern_key = 'yyyymmdd';
   my $pat = $patterns->{ $pattern_key };
   my @cases = ( [ 'simple date',       '2018-03-25', 1 ],
                 [ 'not really valid',  '2018-03-33', 1 ],                 
                 [ 'older date',        '1872-01-12', 1 ],                 
                 [ 'not at all a date', 'now, baby',  0 ],                 
               );

   foreach my $case ( @cases ) { 
     my ($case_name, $input, $expected) = @{ $case };

     my $result = 0;
     if( $input =~ m{ $pat }x ){  # pinned at both ends
       $result = 1;
     }
     is( $result, $expected, "$test_name: $pattern_key: $case_name" );
   }
 }

{  my $subname   = "define_regxeps";
   my $test_name = "Testing $subname";

   my $cc = Graphics::Skullplot::ClassifyColumns->new();
   my $patterns = $cc->define_regxeps();

   my $pattern_key = 'datetime';
   my $pat = $patterns->{ $pattern_key };
   my @cases = ( [ 'simple date and time',           '2018-03-25 12:00',    1 ],
                 [ 'not really valid date or time',  '2018-03-33 06:00',    1 ],                 
                 [ 'date with time in hh::mm::ss',   '1872-01-12 01:01:01', 1 ],                 
                 [ 'not at all a date time',         'now, baby',           0 ],                 
                 [ 'date wtihout a time',            '1970:07:17',          0 ],                 
               );

   foreach my $case ( @cases ) { 
     my ($case_name, $input, $expected) = @{ $case };

     my $result = 0;
     if( $input =~ m{ $pat }x ){  # pinned at both ends
       $result = 1;
     }
     is( $result, $expected, "$test_name: $pattern_key: $case_name" );
   }
 }

done_testing();
