# Test file created outside of h2xs framework.
# Run this like so: `perl 01-File-Locate-Harder.t'
#   doom@kzsu.stanford.edu     2007/06/09 04:26:48

# Testing:
# (1) the locate method with options specified late, not at object creation time
# (2) the case_insensitive and regexp options

use warnings;
use strict;
$|=1;
use Data::Dumper;

my $DEBUG = 0; # TODO zero before shipping
use Test::More;
my $total_count;
BEGIN { $total_count = 15;
        plan tests => $total_count };

use Test::Trap qw( trap $trap );

use FindBin qw($Bin);
use lib ("$Bin/../lib");

BEGIN {
  use_ok( 'File::Locate::Harder' );
}

ok(1, "Traditional: If we made it this far, we're ok.");

# skip all tests if there is no locate installation
SKIP:
{
  {
    my $class = 'File::Locate::Harder';
    my $obj;
    my @r = trap {
      $obj = $class->new();
    };

    if ( my $err_mess = $trap->die ) {
      my $expected_err_mess =
        "File::Locate::Harder is not working. " .
          "Problem with 'locate' installation?";
      $expected_err_mess =~ s{ \s+? }{ \\s+ }gx;

      unless( $err_mess =~ qr{ $expected_err_mess }x) {
        die "$err_mess";
      }
      my $how_many = $total_count - 2; # all remaining tests
      skip "Problem with installation of 'locate'", $how_many;
    }
  }

  { #3 ...
    my $test_name = "Testing creation of locate db";

    my $db_loc = "$Bin/dat/for01/locate";
    my $db     = "$db_loc/locate.db";
    my $tree   = "$Bin/dat/for01/tree";

    # erase db file from previous runs
    unlink $db if -e $db;

    my $flh = File::Locate::Harder->new( { db => $db } );
    $flh->debugging(1) if $DEBUG;
    $flh->create_database( $tree, $db );

    my $db_creation_looks_good = -e $db;
    ok( $db_creation_looks_good, "$test_name: db creation" );   #3

    # if both fail, we'll skip the access tests
    my $via_module_looks_good = $flh->probe_db_via_module_locate;
    my $via_shell_looks_good = $flh->probe_db_via_shell_locate;
    if ($DEBUG) {
      print "Just FYI: the locate via module status:\n$via_module_looks_good\n";
      print "Just FYI: the locate via shell status:\n$via_shell_looks_good\n";
    }
    my $lfh_access_looks_good = $via_module_looks_good || $via_shell_looks_good;

    $test_name = "Testing toggling case sensitivity";
    # skip all the tests if we can't create a local locate db
  SKIP:
    {
      my $how_many = 12;

      my $looks_good = $db_creation_looks_good && $lfh_access_looks_good;
      my @message;
      if ( not( $db_creation_looks_good) ) {
        push @message, "Can't create locate db";
      }
      ;
      if ( not( $lfh_access_looks_good ) ) {
        push @message, "List::Filter::Harder locate isn't working";
      }
      my $message = join(' & ', @message);
      $message .= ", so can't do test $test_name";

      skip $message, $how_many unless $looks_good;

      # skip all tests if some search terms conflict with this system's absolute paths
    SKIP:
      {
        # checking all the terms we're going to use at once
        my @terms = qw(on_the_rhine_castle bogojpegyouknow htmlnotreally bogoext);
        my $how_many = 12;
        foreach my $term (@terms) {
          if ($tree =~ m/$term/i) {
            skip "tests invalid because $term matches the path, $tree", $how_many;
            next;
          }
        }

        { #4, #5, #6
          my $term = 'on_the_rhine_castle';
          my $test_case = "initial case sensitive default: $term";
          my $flh = File::Locate::Harder->new( db => $db );
          # $flh->debugging(1) if $DEBUG;
          my $results_1_aref = $flh->locate( $term );
          my $expected_1_aref =
            [ sort @{ [
                       "$tree/Dir2/Misc/on_the_rhine_castle_skull.txt",
                       "$tree/Dir2/Misc/on_the_rhine_castle_skull.htmlnotreally"
                      ] } ];
          is_deeply( [ sort( @{ $results_1_aref } ) ], [ sort( @{ $expected_1_aref} ) ],
                     "$test_name: $test_case");
          ($DEBUG) && print STDERR "results_1_aref: ", Dumper($results_1_aref), "\n";


          $test_case = "same handle, case-insensitive: $term";
          my $results_2_aref = $flh->locate( $term,
                                             { case_insensitive => 1,
                                             } );
          my $expected_2_aref =
            [ sort @{ [
                       "$tree/Dir2/Misc/on_the_rhine_castle_skull.txt",
                       "$tree/Dir2/Misc/on_the_rhine_castle_skull.htmlnotreally",
                       "$tree/Dir1/On_the_Rhine_Castle",
                       "$tree/Dir1/On_the_Rhine_Castle/Skull",
                       "$tree/Dir1/On_the_Rhine_Castle/Skull/synopsis.txt",
                       "$tree/Dir1/On_the_Rhine_Castle/Skull/cover.BOGOJPEGYOUKNOW"
                      ] } ];
          is_deeply( [ sort( @{ $results_2_aref } ) ], [ sort( @{ $expected_2_aref} ) ],
                     "$test_name: $test_case");
          ($DEBUG) && print STDERR "results_2_aref: ", Dumper($results_2_aref), "\n";

          $test_case = "repeat initial case sensitive: $term";
          my $results_3_aref = $flh->locate( $term ); # still case sensitive, right?
          my $expected_3_aref = $expected_1_aref;
          is_deeply( [ sort( @{ $results_3_aref } ) ], [ sort( @{ $expected_3_aref} ) ],
                     "$test_name: $test_case");
          ($DEBUG) && print STDERR "results_3_aref: ", Dumper($results_3_aref), "\n";
        }

        { #7, #8, #9
          my $term = 'bogojpegyouknow';
          my $flh = File::Locate::Harder->new( db => $db );
          # $flh->debugging(1) if $DEBUG;
          my $test_case = "initial case sensitive default: $term";
          my $results_1_aref = $flh->locate( $term );
          my $expected_1_aref =
            [ sort @{ [
                       "$tree/Dir3/images/cover.bogojpegyouknow"
                      ] } ];
          is_deeply( [ sort( @{ $results_1_aref } ) ], [ sort( @{ $expected_1_aref} ) ],
                     "$test_name: $test_case");
          ($DEBUG) && print STDERR "results_1_aref: ", Dumper($results_1_aref), "\n";

          $test_case = "same handle, case-insensitive: $term";
          my $results_2_aref = $flh->locate( $term,
                                             { case_insensitive => 1,
                                             } );
          my $expected_2_aref =
            [ sort @{ [
                       "$tree/Dir1/On_the_Rhine_Castle/Skull/cover.BOGOJPEGYOUKNOW",
                       "$tree/Dir3/images/cover.bogojpegyouknow"
                      ] } ];
          is_deeply( [ sort( @{ $results_2_aref } ) ], [ sort( @{ $expected_2_aref} ) ],
                     "$test_name: $test_case");
          ($DEBUG) && print STDERR "results_2_aref: ", Dumper($results_2_aref), "\n";

          $test_case = "repeat initial case sensitive: $term";
          my $results_3_aref = $flh->locate( $term ); # still case sensitive, right?
          my $expected_3_aref = $expected_1_aref;
          is_deeply( [ sort( @{ $results_3_aref } ) ], [ sort( @{ $expected_3_aref} ) ],
                     "$test_name: $test_case");
          ($DEBUG) && print STDERR "results_3_aref: ", Dumper($results_3_aref), "\n";
        }

        { #10, #11, #12
          my $test_name = "Testing toggling regexp use";
          my $term = '.htmlnotreally';  # matches more as regexp than as string
          my $flh = File::Locate::Harder->new( db => $db );
          $flh->debugging(1) if $DEBUG;
          my $test_case = "initial string search default: $term";
          my $results_1_aref = $flh->locate( $term );
          my $expected_1_aref =
            [ sort @{ [
                       "$tree/Dir2/Misc/on_the_rhine_castle_skull.htmlnotreally",
                       "$tree/Dir2/Misc/skull_island.htmlnotreally",
                       "$tree/Dir2/Misc/zero_zero_island.htmlnotreally",
                       "$tree/Dir5/not_too_bad.htmlnotreally",
                       "$tree/Dir5/one_more.htmlnotreally",
                      ] } ];
          is_deeply( [ sort( @{ $results_1_aref } ) ], [ sort( @{ $expected_1_aref} ) ],
                     "$test_name: $test_case");

          ($DEBUG) && print STDERR "results_1_aref: ", Dumper($results_1_aref), "\n";

          $test_case = "same handle, regexp search: $term";

          my $results_2_aref = $flh->locate( $term,
                                             { regexp           => 1,
                                             } );

          my $expected_2_aref =
            [ sort @{ [
                       "$tree/Dir2/Misc/on_the_rhine_castle_skull.htmlnotreally",
                       "$tree/Dir2/Misc/skull_island.htmlnotreally",
                       "$tree/Dir2/Misc/zero_zero_island.htmlnotreally",
                       "$tree/Dir5/bad_htmlnotreally.lst",
                       "$tree/Dir5/bad_htmlnotreally.lst~",
                       "$tree/Dir5/not_too_bad.htmlnotreally",
                       "$tree/Dir5/one_more.htmlnotreally",
                      ] } ];

          is_deeply( [ sort( @{ $results_2_aref } ) ], [ sort( @{ $expected_2_aref} ) ],
                     "$test_name: $test_case");

          ($DEBUG) && print STDERR "results_2_aref: ", Dumper($results_2_aref), "\n";

          $test_case = "repeat initial string search: $term";

          my $results_3_aref = $flh->locate( $term ); # still case sensitive, right?

          my $expected_3_aref = $expected_1_aref;

          is_deeply( [ sort( @{ $results_3_aref } ) ], [ sort( @{ $expected_3_aref} ) ],
                     "$test_name: $test_case");

          ($DEBUG) && print STDERR "results_3_aref: ", Dumper($results_3_aref), "\n";
        }

        { #13, #14, #15
          my $test_name = "Testing toggling case-insensitive and regexp use";
          my $term = '.bogoext';  # matches more as regexp than as string
          my $flh = File::Locate::Harder->new( db => $db );
          $flh->debugging(1) if $DEBUG;
          my $test_case = "initial case sens. string search default: $term";
          my $results_1_aref = $flh->locate( $term );
          my $expected_1_aref =
            [ sort @{ [
                       "$tree/Dir6/stuff/stashola.bogoext",
                       "$tree/Dir6/stuff/storissimo.bogoext",
                      ] } ];
          is_deeply( [ sort( @{ $results_1_aref } ) ], [ sort( @{ $expected_1_aref} ) ],
                     "$test_name: $test_case");

          ($DEBUG) && print STDERR "results_1_aref: ", Dumper($results_1_aref), "\n";

          $test_case = "same handle, case-insensitive, regexp search: $term";

          my $results_2_aref = $flh->locate( $term,
                                             { case_insensitive => 1,
                                               regexp           => 1,
                                             } );

          my $expected_2_aref =
            [ sort @{ [
                       "$tree/Dir6/stuff/stashola.bogoext",
                       "$tree/Dir6/stuff/stasharino.BOGOEXT",
                       "$tree/Dir6/stuff/stashola_bogoext.listsky",
                       "$tree/Dir6/stuff/STASHOLA_BOGOEXT.listsky",
                       "$tree/Dir6/stuff/storissimo.bogoext",
                       "$tree/Dir6/stuff/stuffsack.BOGOEXT",
                       "$tree/Dir6/stuff/STORKNEST_BOGOEXT.LISTSKY",
                      ] } ];

          is_deeply( [ sort( @{ $results_2_aref } ) ], [ sort( @{ $expected_2_aref} ) ],
                     "$test_name: $test_case");

          ($DEBUG) && print STDERR "results_2_aref: ", Dumper($results_2_aref), "\n";

          $test_case = "repeat initial default-style: $term";

          my $results_3_aref = $flh->locate( $term ); # still case sensitive, right?

          my $expected_3_aref = $expected_1_aref;

          is_deeply( [ sort( @{ $results_3_aref } ) ], [ sort( @{ $expected_3_aref} ) ],
                     "$test_name: $test_case");

          ($DEBUG) && print STDERR "results_3_aref: ", Dumper($results_3_aref), "\n";
        }

      } # end skip -- $term matches path
    } # end skip -- can't create locate db
  }
} # end skip -- problem with installation of locate
### end of 01-File-Locate-Harder.t


