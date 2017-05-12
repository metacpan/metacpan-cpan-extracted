#!perl -w
use strict;
use Test::More tests => 13;
use HTTP::ServerEvent;

# Check the synopsis
my $res= HTTP::ServerEvent->as_string(
    event => "ping",
    data => 12345678, # time(),
    retry => 5000, # retry in 5 seconds
    id => 1,
  );

my @res= split /\x{0D}\x{0A}?/, $res, -1;
is_deeply \@res, [
'event: ping',
'id: 1',
'retry: 5000',
'data: 12345678',
"",
"",
], "The synopsis works as expected";

for my $nl ("\x{0d}", "\x{0a}", "\x{0d}\x{0a}") {
    # Check that embedded newlines still get prefixed with "data:"
       $res= HTTP::ServerEvent->as_string(
        data => ["123${nl}456"],
      );
    my @res= split /\x{0D}\x{0A}?/, $res, -1;
    is_deeply \@res, [
    'data: 123',
    'data: 456',
    "",
    "",
    ], "Embedded newlines don't escape from the data prefixes"
    or diag $res;

    # Check that embedded newlines still get prefixed with "data:"
    my $lived= eval {
       $res= HTTP::ServerEvent->as_string(
        event => "123${nl}456",
      );
      1;
    };
    ok !$lived, "Embedded newline is fatal in the 'event' parameter"
        or diag $res;
    # Check that embedded newlines still get prefixed with "data:"
       $lived= eval {
       $res= HTTP::ServerEvent->as_string(
        event => 'test',
        retry => "123${nl}456",
      );
      1;
    };
    ok !$lived, "Embedded newline is fatal in the 'retry' parameter";
    # Check that embedded newlines still get prefixed with "data:"
       $lived= eval {
       $res= HTTP::ServerEvent->as_string(
        event => 'test',
        id => "123${nl}456",
      );
      1;
    };
    ok !$lived, "Embedded newline is fatal in the 'id' parameter";
};
