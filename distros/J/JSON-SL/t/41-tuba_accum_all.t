#!/usr/bin/perl
package MyTuba;
use strict;
use warnings;
use Data::Dumper;

use JSON::SL::Tuba;
use Test::More;
our @ISA = qw(JSON::SL::Tuba);

my $ExpResults =
#Compile a list of what we actually expect,
#in terms of events..
[
  [
    {
      Mode => "+",
      Type => "D"
    }
  ],
  [
    {
      Mode => "+",
      Type => "{"
    }
  ],
  [
    {
      Key => "a",
      Mode => ">",
      Type => '"',
    },
    "b"
  ],
  [
    {
      Key => "c",
      Mode => "+",
      Type => "{"
    }
  ],
  [
    {
      Key => "d",
      Mode => ">",
      Type => '"'
    },
    "e"
  ],
  [
    {
      Mode => "-",
      Type => "{"
    }
  ],
  [
    {
      Key => "f",
      Mode => "+",
      Type => "["
    }
  ],
  [
    {
      Index => 0,
      Mode => ">",
      Type => "\""
    },
    "g"
  ],
  [
    {
      Index => 1,
      Mode => ">",
      Type => '"',
    },
    "h"
  ],
  [
    {
      Index => 2,
      Mode => ">",
      Type => '"'
    },
    "i"
  ],
  [
    {
      Index => 3,
      Mode => ">",
      Type => '"'
    },
    "j"
  ],
  [
    {
      Mode => "-",
      Type => "["
    }
  ],
  [
    {
      Key => "a number",
      Mode => ">",
      Type => "="
    },
    "0.4444444444"
  ],
  [
    {
      Key => "a (false) boolean",
      Mode => ">",
      Type => "?"
    },
    bless( do{\(my $o = 0)}, 'JSON::SL::Boolean' )
  ],
  [
    {
      Key => "another (true) boolean",
      Mode => ">",
      Type => "?"
    },
    bless( do{\(my $o = 1)}, 'JSON::SL::Boolean' )
  ],
  [
    {
      Key => "a null value",
      Mode => ">",
      Type => "~"
    }
  ],
  [
    {
      Key => "exponential",
      Mode => ">",
      Type => "="
    },
    "13413.4"
  ],
  [
    {
      Key => "an\tescaped key",
      Mode => ">",
      Type => '"'
    },
    "a u-escaped value"
  ],
  [
    {
      Mode => "-",
      Type => "{"
    }
  ],
  [
    {
      Mode => "-",
      Type => "D"
    }
  ]
];

#this tries to replicate the tests in eg/tuba.pl
my $JSON ||= <<'EOJ';
{
    "a" : "b",
    "c" : { "d" : "e" },
    "f" : [ "g", "h", "i", "j" ],
    "a number" : 0.4444444444,
    "a (false) boolean": false,
    "another (true) boolean" : true,
    "a null value" : null,
    "exponential" : 1.3413400E4,
    "an\tescaped key" : "a u-\u0065\u0073caped value"    
}
EOJ

my @GotResults;

sub on_any {
    my ($tuba,$info,$data) = @_;
        
    my $arry = [ { %$info } ];
    if (@_ > 2) {
        push @$arry, $data;
    }
    push @GotResults, $arry;
}

my $tuba = __PACKAGE__->new();
$tuba->accum_all(1);
$tuba->accum_kv(1);
$tuba->parse($JSON);
is_deeply(\@GotResults, $ExpResults, "Got expected results..");
done_testing();