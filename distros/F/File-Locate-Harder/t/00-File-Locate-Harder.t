# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl File-Locate-Harder.t'

#########################

my $DEBUG = 1; # TODO zero before shipping
use Test::More;
my $total_count;
BEGIN { $total_count = 30;
        plan tests => $total_count };

use Test::Trap qw( trap $trap );

use Data::Dumper;

use FindBin qw($Bin);
use lib ("$Bin/../lib");

BEGIN {
  use_ok( 'File::Locate::Harder' );
}

ok(1, "Traditional: If we made it this far, we're ok.");

# skip all tests if there is no locate installation
SKIP:
{
  { #3
    my $class = 'File::Locate::Harder';
    my $test_name = "Testing creation of object of expected type: $class";

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

    my $created_class = ref $obj;
    is( $created_class, $class, $test_name );
  }

  { #4-#8
    my $test_name = 'Testing build_opts_for_locate_via_shell';

    { #4
      my $testcase = "empty string when all unset";
      my $flh = File::Locate::Harder->new(
                                          db => undef, # suppress system probe
                                          'case_insensitive' => undef,
                                          'posix_extended'   => undef,
                                          'regexp'           => undef,
                                         );

      my $result = $flh->build_opts_for_locate_via_shell();
      ($DEBUG) && print STDERR "$result\n";
      is( $result, '', "$test_name: $testcase" );
    }

    { #5
      my $testcase = "only case_insensitive set";

      my $flh = File::Locate::Harder->new(
                                          db => undef, # suppress system probe
                                          'case_insensitive' => 1,
                                          'posix_extended'   => undef,
                                          'regexp'           => undef,
                                         );

      my $result = $flh->build_opts_for_locate_via_shell();
      ($DEBUG) && print STDERR "$result\n";
      is( $result, '-i', "$test_name: $testcase" );
    }

    { #6
      my $testcase = "only regexp set";
      my $flh = File::Locate::Harder->new(
                                          db => undef, # suppress system probe
                                          'case_insensitive' => undef,
                                          'posix_extended'   => undef,
                                          'regexp'           => 1,
                                         );

      my $result = $flh->build_opts_for_locate_via_shell();
      ($DEBUG) && print STDERR "$result\n";
      is( $result, '-r', "$test_name: $testcase" );
    }

    { #7
      my $testcase = "case-insensitive and regexp set";
      my $flh = File::Locate::Harder->new(
                                          db => undef, # suppress system probe
                                          'case_insensitive' => 1,
                                          'posix_extended'   => undef,
                                          'regexp'           => 1,
                                         );

      my $result = $flh->build_opts_for_locate_via_shell();
      ($DEBUG) && print STDERR "$result\n";
      like( $result, qr{ ^ - [ir]{2,2} $ }x, "$test_name: $testcase" );
    }


    { #8
      my $testcase = "errors out correctly with posix_extended set";

      my @r = trap {
        my $flh = File::Locate::Harder->new(
                                            db => undef, # suppress system probe
                                            'case_insensitive' => undef,
                                            'posix_extended'   => 1,
                                            'regexp'           => 1,
                                           );
        $flh->build_opts_for_locate_via_shell()
      };
      ($DEBUG) && print STDERR "return from trap: ", Dumper(\@r), "\n";
      like ( $trap->stderr,
             qr{Can't use posix extended regexps with locate via the shell},
             "$test_name: errors correctly with posix_extended option " );

    }
  }

  { #9, #10, #11, #12
    my $test_name = 'Testing build_opts_for_locate_via_module';
    my $class = 'File::Locate::Harder';
    my $obj = $class->new( db => undef, # suppress system probe
                         );

    my (@result, $expected_result);

    @result = $obj->build_opts_for_locate_via_module();
    ($DEBUG) && print STDERR Dumper(\@result), "\n";
    $expected_result = [ ];
    is_deeply( \@result, $expected_result, "$test_name: all three params unset");

    $obj->set_case_insensitive(1);

    @result = $obj->build_opts_for_locate_via_module();
    ($DEBUG) && print STDERR Dumper(\@result), "\n";
    $expected_result = [
                        '-rex',
                        1,
                        '-rexopt',
                        'i'
                       ];
    is_deeply( \@result, $expected_result, "$test_name: case-insensitive" );

    $obj->set_case_insensitive(0);
    $obj->set_regexp(1);
    @result = $obj->build_opts_for_locate_via_module();
    ($DEBUG) && print STDERR Dumper(\@result), "\n";
    $expected_result = [
                        '-rex',
                        1
                       ];
    is_deeply( \@result, $expected_result, "$test_name: case-insensitive" );

    $obj->set_case_insensitive(1);
    @result = $obj->build_opts_for_locate_via_module();
    ($DEBUG) && print STDERR Dumper(\@result), "\n";
    $expected_result = [
                        '-rex',
                        1,
                        '-rexopt',
                        'i'
                       ];
    is_deeply( \@result, $expected_result, "$test_name: case-insensitive" );

    $obj->set_posix_extended(1);
    @result = $obj->build_opts_for_locate_via_module();
    ($DEBUG) && print STDERR Dumper(\@result), "\n";
    $expected_result = [
                        '-rex',
                        1,
                        '-rexopt',
                        'ie'
                       ];
    is_deeply( \@result, $expected_result, "$test_name: case-insensitive" );
  }

  { #13, #14, #15
    my $test_name = "Testing creation and probes of locate db";

    my $db_loc = "$Bin/dat/easy_hits/locate";
    my $db     = "$db_loc/locate.db";
    my $tree   = "$Bin/dat/easy_hits/tree";
    my $loc    = $tree;

    # erase db file from previous runs
    unlink $db if -e $db;

    my $flh = File::Locate::Harder->new( { db => $db } );
    $flh->debugging(1) if $DEBUG;
    $flh->create_database( $tree, $db );

    my $db_creation_status = -e $db;
    ok( $db_creation_status, "$test_name: db creation" );

    $test_name = "Testing probes of locate dbs";
  SKIP:
    {
      my $how_many = 2;
      my $testcase = "probe_db_via_module_locate";
      skip "can't create locate db, so can't test $testcase", $how_many
        unless ($db_creation_status);

      # The allowed return values for this test are
      #   $db or undef

      my $via_module_status = $flh->probe_db_via_module_locate;
      $flh->debug("The locate via module status: $via_module_status\n");

      ok( (not( defined($via_module_status)) || ($via_module_status eq $db) ),
          "$test_name: $testcase: returns db name or undef");

      # The allowed return values for this test are
      #   $db or undef or 1

      $testcase = "probe_db_via_shell_locate";
      my $via_shell_status  = $flh->probe_db_via_shell_locate;
      $flh->debug("Just FYI: the locate via shell status: $via_shell_status\n");

      ok( (not( defined($via_module_status)) ||
           ($via_module_status eq $db) ||
           ($via_module_status == 1) ),
          "$test_name: $testcase: returns db name or undef or 1");

    } # end skip db creation failed
  }

 SKIP:
  { #16, #17
    my $test_name = "Testing that probes of a bad locate db fail";
    my $how_many = 2;

    my $db_loc = "$Bin/dat/bad_dbs/locate";
    my $db     = "$db_loc/locate.db";

    # erase db file from previous runs
    unlink $db if -e $db;

    open my $fh, ">", $db or
      skip "Can't open file to create bogus db: $db", $how_many;
    print {$fh} "I am not really a locate db\n" ;
    print {$fh} "I just play one for this test series.\n" ;
    close $fh;

    my $flh = File::Locate::Harder->new( { db => $db } );
    $flh->debugging(1) if $DEBUG;

    my $testcase = "probe_db_via_module_locate";
    my $via_module_status = $flh->probe_db_via_module_locate;

    ok( (not( defined( $via_module_status ) ) ),
        "$test_name: $testcase: empty db file");

    $testcase = "probe_db_via_shell_locate";
    my $via_shell_status  = $flh->probe_db_via_shell_locate;

    ok( (not( defined( $via_shell_status ) ) ),
        "$test_name: $testcase: empty db file" );
  } # end skip, can't open "bad_db" for write

  { #18, #19, #20, #21, #22, #23
    my $test_name = "Testing creation of locate db";

    my $db_loc = "$Bin/dat/locate";
    my $db     = "$db_loc/locate.db";
    my $tree   = "$Bin/dat/tree";
    my $loc    = $tree;

    # erase db file from previous runs
    unlink $db if -e $db;

    my $flh = File::Locate::Harder->new( { db => $db } );
    $flh->debugging(1) if $DEBUG;
    $flh->create_database( $tree, $db );

    my $db_creation_looks_good = -e $db;
    ok( $db_creation_looks_good, "$test_name: db creation" );

    # if this fails, we'll skip the corresponding access tests
    my $via_shell_looks_good  = $flh->probe_db_via_shell_locate;
    if ($DEBUG) {
      print "Just FYI: the locate via shell status:\n$via_shell_looks_good\n";
    }

    $test_name = "Testing access of locate db";
    # skip the block of tests if we can't create a local locate db
  SKIP:
    {
      my $testcase = "locate_via_shell";
      my $how_many = 5;

      my $looks_good = $db_creation_looks_good && $via_shell_looks_good;
      my @message;
      if ( not( $db_creation_looks_good) ) {
        push @message, "can't create locate db, so can't test $testcase";
      }
      ;
      if ( not( $via_shell_looks_good ) ) {
        push @message, "can't do $testcase";
      }
      my $message = join(' & ', @message);

      skip $message, $how_many unless $looks_good;

      # TODO -- two skips were giving me trouble in the debugger (I think)
      #       skip "can't create locate db, so can't test $testcase", $how_many
      #         unless ($db_creation_looks_good);
      #       skip "can't do $testcase", $how_many
      #         unless ($via_shell_looks_good );

      # skip each test if it conflicts with this system's absolute path
    SKIP:
      {
        my @terms = qw(Barcelona NewYork SanFrancisco);
        my $how_many = 1;
        foreach my $term (@terms) {
          if ($loc =~ m/$term/i) {
            skip "tests invalid because $term matches the path, $loc", $how_many;
            last;
          }
        }

        foreach my $term (@terms) {
          my $matches = $flh->locate_via_shell( $term );
          my @expected = sort( (
                                "$tree/$term",
                                "$tree/$term/description.txt",
                                "$tree/$term/review.txt",
                               ) );
          my $matches_sorted = [ sort( @{ $matches } ) ];
          is_deeply( $matches_sorted, \@expected, "$test_name: $testcase: $term");
        }
      } # end skip -- $term matches path

      $testcase = "searching for what isn't there (shell)";

      # skip each test if it conflicts with this system's absolute path
    SKIP:
      {
        my @terms = qw( Niffleheim Aptor);
        my $how_many = 1;
        foreach my $term (@terms) {
          if ($loc =~ m/$term/i) {
            skip "tests invalid because $term matches the path, $loc", $how_many;
            last;
          }
        }

        foreach my $term (@terms) {
          my $matches = $flh->locate_via_shell( $term );
          my @expected = ();
          my $matches_sorted = [ sort( @{ $matches } ) ];
          is_deeply( $matches_sorted, \@expected, "$test_name: $testcase: $term");
        }

      } # end skip -- $term matches path
    } # end skip -- can't create locate db
  }

  # The following is a clone of the above block using
  # locate_via_module for access.

  { #23, #24, #25, #26, #27, #28
    my $test_name = "Testing creation of locate db";

    my $db_loc = "$Bin/dat/locate";
    my $db     = "$db_loc/locate.db";
    my $tree   = "$Bin/dat/tree";
    my $loc    = $tree;

    # erase db file from previous runs
    unlink $db if -e $db;

    my $flh = File::Locate::Harder->new( { db => $db } );
    $flh->debugging(1) if $DEBUG;
    $flh->create_database( $tree, $db );

    my $db_creation_looks_good = -e $db;
    ok( $db_creation_looks_good, "$test_name: db creation" );

    # if this fails, we'll skip the corresponding access tests
    my $via_module_looks_good = $flh->probe_db_via_module_locate;
    if ($DEBUG) {
      print "Just FYI: the locate via module status:\n$via_module_looks_good\n";
    }

    $test_name = "Testing access of locate db";
    # skip the block of tests if we can't create a local locate db
  SKIP:
    {
      my $testcase = "locate_via_module";
      my $how_many = 5;

      my $looks_good = $db_creation_looks_good && $via_module_looks_good;
      my @message;
      if ( not( $db_creation_looks_good) ) {
        push @message, "can't create locate db, so can't test $testcase";
      }
      ;
      if ( not( $via_module_looks_good ) ) {
        push @message, "can't do $testcase";
      }
      my $message = join(' & ', @message);

      skip $message, $how_many unless $looks_good;

      # TODO -- two skips were giving me trouble in the debugger (I think)
      #       skip "can't create locate db, so can't test $testcase", $how_many
      #         unless ($db_creation_status);
      #       skip "can't do $testcase", $how_many
      #         unless ($via_module_status );

      # skip each test if it conflicts with this system's absolute path
    SKIP:
      {
        my @terms = qw(Barcelona NewYork SanFrancisco);
        my $how_many = 1;
        foreach my $term (@terms) {
          if ($loc =~ m/$term/i) {
            skip "tests invalid because $term matches the path, $loc", $how_many;
            last;
          }
        }

        foreach my $term (@terms) {
          my $matches = $flh->locate_via_module( $term );
          my @expected = sort( (
                                "$tree/$term",
                                "$tree/$term/description.txt",
                                "$tree/$term/review.txt",
                               ) );
          my $matches_sorted = [ sort( @{ $matches } ) ];
          is_deeply( $matches_sorted, \@expected, "$test_name: $testcase: $term");
        }
      } # end skip -- $term matches path

      $testcase = "searching for what isn't there (module)";

      # skip each test if it conflicts with this system's absolute path
    SKIP:
      {
        my @terms = qw( Niffleheim Aptor);
        my $how_many = 1;
        foreach my $term (@terms) {
          if ($loc =~ m/$term/i) {
            skip "tests invalid because $term matches the path, $loc", $how_many;
            last;
          }
        }

        foreach my $term (@terms) {
          my $matches = $flh->locate_via_module( $term );
          my @expected = ();
          my $matches_sorted = [ sort( @{ $matches } ) ];
          is_deeply( $matches_sorted, \@expected, "$test_name: $testcase: $term");
        }

      } # end skip -- $term matches path
    } # end skip -- can't create locate db
  }
} # end skip -- problem with installation of locate
### end of 00-File-Locate-Harder.t
