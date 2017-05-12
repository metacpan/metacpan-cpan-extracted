#!perl -w
use strict;
use Test::More tests => 6;

# extra tests for findrule.  these are more for testing the parsing code.

sub run ($) {
    my $expr = shift;
    [ sort split /\n/, `$^X -Iblib/lib -Iblib/arch findrule $expr 2>&1` ];
}

is_deeply(run 't -file -name foobar', [ 't/foobar' ],
          '-file -name foobar');

is_deeply(run 't -maxdepth 0 -directory',
          [ 't' ], 'last clause has no args');


{
    local $TODO = "Win32 cmd.exe hurts my brane"
      if ($^O =~ m/Win32/ || $^O eq 'dos');

    is_deeply(run 't -file -name \( foobar \*.t \)',
              [ qw( t/File-Find-Rule.t t/findrule.t t/foobar ) ],
              'grouping ()');

    is_deeply(run 't -name \( -foo foobar \)',
              [ 't/foobar' ], 'grouping ( -literal )');
}

is_deeply(run 't -file -name foobar baz',
          [ "unknown option 'baz'" ], 'no implicit grouping');

is_deeply(run 't -maxdepth 0 -name -file',
          [], 'terminate at next -');
