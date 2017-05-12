# Slackware System Tests

  [System tests](https://en.wikipedia.org/wiki/System_testing) are short programs which exercise components of your computer
  system and make sure they are running correctly.

  This module implements tests for [Slackware Linux](http://distrowatch.com/table.php?distribution=slackware) systems.

  The eventual goal is to accumulate enough tests that when Slackware updates, you can just re-run the system tests and know
  that everything works okay.

## Current status

  Pre-beta!  This project needs a lot more system tests before it will be useful.

  Please help out by writing some system tests!

## Running system tests

  If you are reading this file, it is assumed that you downloaded the zip from github or cpan.org, rather than installing with cpan(1), and
  are therefore interested in running system tests rather than developing them.

  To run all system tests, unpack the zip on your Slackware system, cd to the top-level directory and run the test harness:

    $ unzip perl-linux-slackware-systemtests.zip
    $ cd perl-linux-slackware-systemtests
    $ bin/slackware-system-test

  That will display the pathname of each system test and any failed subtests.

  To see the harness command line options, use the --help flag:

    $ bin/slackware-system-test --help

  To run specific system tests, invoke them directly.  They are located in the system_tests subdirectory:

    $ lib/Linux/Slackware/SystemTests/system_tests/001_sed.t

  That will display each subtest and its result in [Test Anything Protocol](http://testanything.org/) format.

## Developing system tests

  If you are interested in developing system tests, install the module properly:

    $ sudo cpan Linux::Slackware::SystemTests

  .. and run 'perldoc Linux::Slackware::SystemTests' for full documentation.

  Or just run 'perldoc lib/Linux/Slackware/SystemTests.pm' to see the documentation without installing the module.

  Or hop onto the ##slackware IRC channel on irc.freenode.net, chat up ttkp and email him your tests to make him do all the packaging work ;-)

## SEE ALSO

  [Linux Testing Project](https://linux-test-project.github.io/) - which does not work under Slackware and has more of a kernel focus.
