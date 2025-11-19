#!/usr/bin/env perl
# HARNESS-NO-PRELOAD
# HARNESS-CAT-LONG
# THIS IS A GENERATED YATH RUNNER TEST - amended

# This test file will run the test suite with yath
# it will fall back to prove if yath is unavailable
# and finally it will fall back to regular test if
# prove is unavailable

use strict;
use warnings;

use lib 'lib';
use FindBin qw($Bin);

if (
      eval {
          require App::Yath;
          import App::Yath::Util qw/find_yath/;
          1;
      }
   )
{
    # tests performed with yath
    system(
            $^X, find_yath(), '-D', 'test',
            '--default-search' => './t',
            '--default-search' => './xt',
            @ARGV
          );
    my $exit = $?;

    # This makes sure it works with prove.
    print "1..1\n";
    print "not " if $exit;
    print "ok 1 - Passed tests when run by yath\n";
    print STDERR "yath exited with $exit" if $exit;

    exit( $exit ? 255 : 0 );
}
elsif (
        eval {
            require App::Prove;
            import App::Prove;
            1;
        }
      )
{
    # tests performed with prove
    my $prove_file = "$Bin/.prove";
    if ( -e $prove_file ) {
        system('prove');
    }
    else {
        system('prove --norc -l --state=all,save t/*.t');
    }
}
else {
    1;    # tests preformed normally
}

