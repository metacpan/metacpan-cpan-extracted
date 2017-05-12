#!perl

use strict;
use warnings;

use Test::More tests => 6;
use File::Spec;

# extra tests for findorule.  these are more for testing the parsing code.

sub run ($) {
    my $expr = shift;
    my $script = File::Spec->catfile(
        File::Spec->curdir(), "scripts", "findorule"
    );

    [ sort split /\n/, `$^X -Mblib $script $expr 2>&1` ];
}

is_deeply(run 't -file -name foobar', [ 't/foobar' ],
          '-file -name foobar');

is_deeply(run 't -maxdepth 0 -directory',
          [ 't' ], 'last clause has no args');


{
    local $TODO = "Win32 cmd.exe hurts my brane"
      if ($^O =~ m/Win32/ || $^O eq 'dos');

    is_deeply(run 't -file -name \( foobar \*.t \)',
              [ qw( t/File-Find-Rule.t t/findorule.t t/foobar ) ],
              'grouping ()');

    is_deeply(run 't -name \( -foo foobar \)',
              [ 't/foobar' ], 'grouping ( -literal )');
}

is_deeply(run 't -file -name foobar baz',
          [ "unknown option 'baz'" ], 'no implicit grouping');

is_deeply(run 't -maxdepth 0 -name -file',
          [], 'terminate at next -');
