=head1 NAME

Devel::CoverX::Covered - Collect and report caller (test file) and
covered (source file) statistics from the cover_db



=head1 DESCRIPTION

=head2 Dealing with large code bases and large test suites

When a test suite grows as a team of developers implement new
features, knowing exactly which test files provide test coverage for
which parts of the application becomes less and less obvious.

This is especially true for tests on the acceptance / integration /
system level (rather than on the unit level where the tests are more
concentrated and easily deduced).

This is also extra difficult for developers new to the code base who
have no clue what types of code may need extra testing, or about
common idioms for testing certain parts of the application.



=head2 Enter Devel::CoverX::Covered

Devel::CoverX::Covered extracts and stores the relationship between
covering test files and covered source files from a L<Devel::Cover>
cover_db.

This makes it possible to

=over 4

=item *

Given a source file, list the test files that provide coverage to that
source file. This can be done on a file, sub routine and row level.

=item *

Given a test file, list the source files and subs covered by that test
file.


=item *

Given a source file, report efficiently on the coverage details per
row, or sub.

=back



=head2 Usage Scenarios

Using this module it should be possible to implement e.g.

=over 4

=item *

From within the editor, list or open interesting source / test files,
depending on the editor context (current file, sub, line).


=item *

When a source file is saved or changed on disk, look up which tests
correspond to that source file and run only those, thereby providing a
quicker feedback loop than running the entire test suite.


=item *

In the editor, highlight source code with code coverage details.


=item *

Determine how "unity" a unit test is. That is, how much of the code
base does the unit test touch? A focused unit test would not reach too
many parts of the source code.


=back



=head2 OUTPUT FORMAT

The general output format is one record per line. When there are may
columns per record, they are tab separated.



=head2 Development Status

Moderately mature, but incomplete feature-wise. Solid, but somewhat
prone to change as a result of feedback.



=head1 SYNOPSIS

=head2 Nightly / automatic run

  #Clean up from previous test run (optional)
  cover -delete

  #Test run with coverage instrumentation
  PERL5OPT=-MDevel::Cover prove -r t

  #Collect covered and caller information
  #  Run this _before_ running "cover"
  #  Don't run with Devel::Cover enabled
  covered runs
    - or e.g. -
  covered runs --rex_skip_test_file='/your-prove-file.pl$/' \
          --rex_skip_source_file='{app_cpan_deps/}'

  #Post process to generate covered database
  cover -report Html_basic  # Needs Template installed


=head2 During development

  #List version, and all known files
  covered info


  #Query the covered database per source file
  covered covering --source_file=lib/MyApp/DoStuff.pm
  t/myapp-do_stuff.t
  t/myapp-do_stuff/edge_case1.t
  t/myapp-do_stuff/edge_case2.t

  #Query the covered database per source file and a specific sub
  covered covering --source_file=lib/MyApp/DoStuff.pm --sub=get_odd_values
  t/myapp-do_stuff/edge_case1.t


  #Query the covered database per test file
  covered by --test_file=t/myapp-do_stuff.t
  lib/MyApp/DoStuff.pm
  lib/MyApp/DoStuff/DoOtherStuff.pm


  #Query the covered database for coverage details of a source file
  #sub_name \t coverage count (0 is red, >= 1 is green)
  covered subs --source_file=lib/MyApp/DoStuff.pm
  new       4
  as_string 32
  as_xml    0
  do_stuff  4


-- not implemented --

  #Query the covered database per source file and row
  covered covering --source_file=lib/MyApp/DoStuff.pm --row=37
  t/myapp-do_stuff/edge_case1.t

  covered covering --source_file=lib/MyApp/DoStuff.pm --row=142
  t/myapp-do_stuff.t
  t/myapp-do_stuff/edge_case2.t


  #Query the covered database per test file, but also show covered
  #subroutines (\t separated)
  covered subs_by --test_file=t/myapp-do_stuff.t
  lib/MyApp/DoStuff.pm       as_xml
  lib/MyApp/DoStuff.pm       do_stuff
  lib/MyApp/DoStuff.pm       new
  lib/MyApp/DoStuff/DoOtherStuff.pm   new
  lib/MyApp/DoStuff/DoOtherStuff.pm   do_other_stuff


  #Query the covered database for details of a source file
  covered lines --source_file=lib/MyApp/DoStuff.pm --metric=statement
  11   1
  17   0
  26   0
  32   1
  77   3
  80   1
  99   2
  102  2
  104  1



=head1 THE COVERED DATABASE

The Devel::CoverX::Covered database is the "covered" directory located
next to the "cover_db" directory. It is created by running the
"covered runs" command (see the SYNOPSIS above).



=head1 EDITOR SUPPORT

=head2 Emacs

L<Devel::PerlySense> has a feature "Go to Tests - Other Files" for
navigating to related files. Limit the list of test files when point
is on a "sub name" line.

PerlySense can also highlight subroutine coverage in the source code.



=head2 Vim

There is a vim plugin at L<https://github.com/omega/vim-covered>, which
provides functions for re-running tests covering the current subroutine, or if
you are in a test file, re-run that testfile. It can also show files covering
the current file, and what modules are covered by the current test file. It
shows TAP output syntax highlighten in a seperate buffer that updates when you
re-run the tests, making the feedback cycle (if your tests are quick) quite
nice.

Ovid provides similar key bindings here:
L<http://use.perl.org/~Ovid/journal/36280>.



=head1 PLAYING WITH OTHERS

=head2 Test::Aggregate

Tests run by L<Test::Aggregate> won't be reported properly. That's
because the single .t file running all the aggregate tests will be
reported as the covering test file.

The workaround is to perform the Devel::Cover test run without
Test::Aggregate, i.e. do something like (assuming "aggtest" contains
your aggregate tests):

  PERL5OPT=-MDevel::Cover prove -r t aggtest

The extra time taken to do this is probably not a problem since
running tests with Devel::Cover enabled is so very slow anyway. The
startup time is simply less significant here.

Another clear benefit is that it will result in smaller individual
Devel::Cover run files, which may otherwise be too large to handle
efficiently.

=cut

use strict;
package Devel::CoverX::Covered;
$Devel::CoverX::Covered::VERSION = '0.016';



1;



__END__

=head1 SEE ALSO

L<Devel::Cover>



=head1 AUTHOR

Johan Lindstrom, C<< <johanl [AT] cpan.org> >>



=head1 BUGS AND CAVEATS

=head2 BUG REPORTS

Please report any bugs or feature requests to
C<bug-devel-coverx-covered@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-CoverX-Covered>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head2 CAVEATS

The Devel::Cover db version is hard coded since it's not exposed by
Devel::Cover. So that's a bit fragile.


=head2 KNOWN BUGS

If you delete a .t file, running the test suite again won't
de-register it from the covered database. To get rid of it you need to
delete the "covered" directory and re-run the entire coverage test
suite.



=head1 COPYRIGHT & LICENSE

Copyright 2007 Johan Lindstrom, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
