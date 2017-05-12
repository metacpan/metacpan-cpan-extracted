#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 1;
use Inline 'Lua';
use Data::Dumper;

sub bla {
    return {
        foo => sub {
            Dumper(\@_);
            1
        },
    };
}

gna({bla => \&bla});
pass('made it!');

__END__
__Lua__
function gna(t)
  x = t:bla()
  x:foo {'Test'} -- Will work
  x:foo 'Test' -- Will create a segmentation fault
end
