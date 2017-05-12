#!/usr/bin/perl

use warnings; use strict;

use English qw( -no_match_vars );
use FindBin qw( $Bin );
use Test::More;

use lib $Bin .q{/../lib/};

my $tmp_output = sprintf q{/tmp/Devel-CoverReport-tout-%d/}, $PID;

my @file_checks = qw(
    cover_report.css                                                lib-Sample-Simple-Baz-pm-subroutine.html                        t-Baz-b-t-1253384586.6373.10649-branch.html
    cover_report.html                                               lib-Sample-Simple-Foo-pm-1253384591.6375.39890-branch.html      t-Baz-b-t-1253384586.6373.10649-condition.html
    lib-Sample-Simple-Bar-pm-1253384580.6371.30504-branch.html      lib-Sample-Simple-Foo-pm-1253384591.6375.39890-condition.html   t-Baz-b-t-1253384586.6373.10649.html
    lib-Sample-Simple-Bar-pm-1253384580.6371.30504-condition.html   lib-Sample-Simple-Foo-pm-1253384591.6375.39890.html             t-Baz-b-t-1253384586.6373.10649-subroutine.html
    lib-Sample-Simple-Bar-pm-1253384580.6371.30504.html             lib-Sample-Simple-Foo-pm-1253384591.6375.39890-subroutine.html  t-Baz-b-t-branch.html
    lib-Sample-Simple-Bar-pm-1253384580.6371.30504-subroutine.html  lib-Sample-Simple-Foo-pm-branch.html                            t-Baz-b-t-condition.html
    lib-Sample-Simple-Bar-pm-branch.html                            lib-Sample-Simple-Foo-pm-condition.html                         t-Baz-b-t.html
    lib-Sample-Simple-Bar-pm-condition.html                         lib-Sample-Simple-Foo-pm.html                                   t-Baz-b-t-subroutine.html
    lib-Sample-Simple-Bar-pm.html                                   lib-Sample-Simple-Foo-pm-subroutine.html                        t-Baz-t-1253384589.6374.07833-branch.html
    lib-Sample-Simple-Bar-pm-subroutine.html                        t-Bar-t-1253384580.6371.30504-branch.html                       t-Baz-t-1253384589.6374.07833-condition.html
    lib-Sample-Simple-Baz-pm-1253384583.6372.60096-branch.html      t-Bar-t-1253384580.6371.30504-condition.html                    t-Baz-t-1253384589.6374.07833.html
    lib-Sample-Simple-Baz-pm-1253384583.6372.60096-condition.html   t-Bar-t-1253384580.6371.30504.html                              t-Baz-t-1253384589.6374.07833-subroutine.html
    lib-Sample-Simple-Baz-pm-1253384583.6372.60096.html             t-Bar-t-1253384580.6371.30504-subroutine.html                   t-Baz-t-branch.html
    lib-Sample-Simple-Baz-pm-1253384583.6372.60096-subroutine.html  t-Bar-t-branch.html                                             t-Baz-t-condition.html
    lib-Sample-Simple-Baz-pm-1253384586.6373.10649-branch.html      t-Bar-t-condition.html                                          t-Baz-t.html
    lib-Sample-Simple-Baz-pm-1253384586.6373.10649-condition.html   t-Bar-t.html                                                    t-Baz-t-subroutine.html
    lib-Sample-Simple-Baz-pm-1253384586.6373.10649.html             t-Bar-t-subroutine.html                                         t-Foo-t-1253384591.6375.39890-branch.html
    lib-Sample-Simple-Baz-pm-1253384586.6373.10649-subroutine.html  t-Baz-a-t-1253384583.6372.60096-branch.html                     t-Foo-t-1253384591.6375.39890-condition.html
    lib-Sample-Simple-Baz-pm-1253384589.6374.07833-branch.html      t-Baz-a-t-1253384583.6372.60096-condition.html                  t-Foo-t-1253384591.6375.39890.html
    lib-Sample-Simple-Baz-pm-1253384589.6374.07833-condition.html   t-Baz-a-t-1253384583.6372.60096.html                            t-Foo-t-1253384591.6375.39890-subroutine.html
    lib-Sample-Simple-Baz-pm-1253384589.6374.07833.html             t-Baz-a-t-1253384583.6372.60096-subroutine.html                 t-Foo-t-branch.html
    lib-Sample-Simple-Baz-pm-1253384589.6374.07833-subroutine.html  t-Baz-a-t-branch.html                                           t-Foo-t-condition.html
    lib-Sample-Simple-Baz-pm-branch.html                            t-Baz-a-t-condition.html                                        t-Foo-t.html
    lib-Sample-Simple-Baz-pm-condition.html                         t-Baz-a-t.html                                                  t-Foo-t-subroutine.html
    lib-Sample-Simple-Baz-pm.html                                   t-Baz-a-t-subroutine.html
);

plan tests =>
    + 1 # use_ok
    + 1 # running with default
    + ( scalar @file_checks ) # file checks
;

use_ok('Devel::CoverReport::App::CoverReport');

chdir $Bin .q{/Samples/Simple/};

is(Devel::CoverReport::App::CoverReport::main( q{--cover_db}, q{cover_db-20090919}, q{--output}, $tmp_output, q{--quiet}), 0, "main() running");

foreach my $file (@file_checks) {
    ok(-s $tmp_output . $file > 0, 'Check file: ' . $file);
}

