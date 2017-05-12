package JS::Test::Simple;

use 5.006;

our $VERSION = '0.29';

1;

=encoding utf8

=head1 Name

Test.Simple - Basic utilities for writing JavaScript tests.

=head1 Synopsis

  <script type="text/javascript">
    plan({ tests: 1 });
    ok( foo == bar, 'foo is bar' );
  </script>

=head1 Description

This is an extremely simple, extremely basic module for writing tests suitable
for JavaScript classes and other pursuits. If you wish to do more complicated
testing, use Test.More (a drop-in replacement for this one).

The basic unit of testing is the ok. For each thing you want to test your
program will print out an "ok" or "not ok" to indicate pass or fail. You do
this with the ok() function (see below).

The only other constraint is that you must pre-declare how many tests you
plan to run. This is in case something goes horribly wrong during the test and
your test program aborts, or skips a test or whatever. You do this like so:

  <script type="text/javascript">
    plan({ tests: 23 });
  </script>

You B<must> have a plan.

=over

=item B<ok>

  ok( foo == bar, description );
  ok( foo == bar );

ok() is given an expression (in this case C<foo == bar>). If it's true, the
test passed. If it's false, it didn't. That's about it.

ok() prints out either "ok" or "not ok" along with a test number (it keeps
track of that for you).

  // This produces "ok 1 - Hell not yet frozen over" (or not ok)
  ok( getTemperature(hell) > 0, 'Hell not yet frozen over' );

If you provide a C<description>, that will be printed along with the "ok/not
ok" to make it easier to find your test when if fails (just search for the
name). It also makes it easier for the next guy to understand what your test
is for. It's highly recommended you use test names.

=back

Test.Simple will start by printing number of tests run in the form "1..M" (so
"1..5" means you're going to run 5 tests). This strange format lets
Test.Harness know how many tests you plan on running in case something goes
horribly wrong.

If all your tests passed, Test.Simple will exit with zero (which is normal). If
anything failed it will exit with how many failed. If you run less (or more)
tests than you planned, the missing (or extras) will be considered failures.
If no tests were ever run, Test.Simple will throw a warning and exit with 255.
If the test died, even after having successfully completed all its tests, it
will still be considered a failure and will exit with 255.

This module is by no means trying to be a complete testing system. It's just
to get you started. Once you're off the ground, we recommended that you look
at L<Test.More>.

=head1 Example

Here's an example of a simple test file for the fictional JavaScript Film
class:

  <head>
    <script type="text/javascript" src="Test.Builder.js"></script>
    <script type="text/javascript" src="Test.Simple.js"></script>
    <script type="text/javascript" src="Film.js"></script>
  </head>
  <body>
    <script type="text/javascript">
      var btaste = new Film('Bad Taste');
      btaste.director('Peter Jackson');
      btaste.rating('R');
      btaste.numExplodingSheep('1');

      ok( btaste && typeof btaste == 'object', 'Constructor works' );
      ok( btaste.title()    == 'Bad Taste',     'title() get'       );
      ok( btaste.director() == 'Peter Jackson', 'director() get' );
      ok( btaste.rating()   == 'R',             'rating() get'   );
      ok( btaste.numExplodingSheep() == 1,      'numExplodingSheep() get' );
    </script>
  </body>

It will produce output like this:

    1..5
    ok 1 - Constructor works
    ok 2 - title() get
    ok 3 - director() get
    not ok 4 - rating() get
    #    Failed test (t/film.html at line 14)
    ok 5 - numExplodingSheep() get
    # Looks like you failed 1 tests of 5

Indicating that the C<Film.rating()> method is broken.

=head1 History

This module was conceived by Michael Schwern while talking with Tony Bowden in
his kitchen one night about the problems he was having writing some really
complicated feature into the new Testing module. Tony observed that the main
problem is not dealing with these edge cases but that people hate to write
tests B<at all>. What was needed was a dead simple module that took all the
hard work out of testing and was really, really easy to learn. Paul Johnson
simultaneously had this idea (unfortunately, he wasn't in Tony's kitchen).
This is it...ported to JavaScript.

=head1 See Also

=over

=item L<Test.More>

More testing functions! Once you outgrow Test.Simple, look at Test.More.
Test.Simple is 100% forward compatible with Test.More (i.e. you can just use
Test.More instead of Test.Simple in your programs and things will still work).

=begin _unimplemented

=item L<Test.Harness>

Interprets the output of your test program.

=end _unimplemented

=item L<http://www.edwardh.com/jsunit/>

JSUnit: elaborate xUnit-style testing framework.

=back

=head1 Authors

Idea by Tony Bowden and Paul Johnson. Original Perl implementation by Michael
G Schwern <schwern@pobox.com>. JavaScript implementation by David Wheeler
<david@kineticode.com>. JavaScript implementation packaged for CPAN by Ingy
döt Net <ingy@ingy.net>. Wardrobe by Calvin Klein.

=head1 Copyright

Copyright 2001, 2002, 2004 by Michael G Schwern <schwern@pobox.com>, 2005,
2008 by David Wheeler.

This program is free software; you can redistribute it and/or modify it under
the terms of the Perl Artistic License or the GNU GPL.

See L<http://www.perl.com/perl/misc/Artistic.html> and
L<http://www.gnu.org/copyleft/gpl.html>.

=cut
