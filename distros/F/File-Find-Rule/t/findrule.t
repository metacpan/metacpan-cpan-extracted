#!perl -w
use strict;
use Test::More tests => 6;

# extra tests for findrule.  these are more for testing the parsing code.

sub run ($) {
    my $expr = shift;
    [ sort split /\n/, `$^X -Iblib/lib -Iblib/arch findrule $expr 2>&1` ];
}

is_deeply(run 'testdir -file -name foobar', [ 'testdir/foobar' ],
          '-file -name foobar');

is_deeply(run 'testdir -maxdepth 0 -directory',
          [ 'testdir'  ], 'last clause has no args');


{
    local $TODO = "Win32 cmd.exe hurts my brane"
      if ($^O =~ m/Win32/ || $^O eq 'dos');

    is_deeply(run 'testdir -file -name \( foobar \*.t \)',
              [ qw( testdir/File-Find-Rule.t testdir/findrule.t testdir/foobar ) ],
              'grouping ()');

    is_deeply(run 'testdir -name \( -foo foobar \)',
              [ 'testdir/foobar' ], 'grouping ( -literal )');
}

is_deeply(run 'testdir -file -name foobar baz',
          [ "unknown option 'baz'" ], 'no implicit grouping');

is_deeply(run 'testdir -maxdepth 0 -name -file',
          [], 'terminate at next -');
