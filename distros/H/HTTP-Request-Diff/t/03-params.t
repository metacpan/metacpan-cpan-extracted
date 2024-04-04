#!perl
use 5.020;
use experimental 'postderef';
no warnings 'experimental::postderef';
use Test2::V0 '-no_srand';
use Data::Dumper;

use HTTP::Request;
use YAML::PP 'Load';

use HTTP::Request::Diff;

# Our hacky data parser
my $tests = do { local($/); <DATA> };
my @tests = map {;
    my @pairs = /--- (\w+)\s+(.*?)\r?\n(?=---|\z)/msg
        or die "Bad line: $_";
    +{
        @pairs
    }
    } $tests =~ /(?:===\s+)(.*?)(?====|\z)/msg;

plan tests => 1 * @tests;

for my $block (@tests) {
    $block->{reference} =~ s!\r?\n!\r\n!sg;
    $block->{actual} =~ s!\r?\n!\r\n!sg;
    my $reference = $block->{reference};
    my ($name_v)  = $reference =~ m!^(.*?)$!;
    my $actual    = $block->{actual};
    my $result    = Load($block->{diff}) // [];

    for( $result->@* ) {
        $_->{actual} =~ s/\s+\z//
            if $_->{actual};
        $_->{reference} =~ s/\s+\z//
            if $_->{reference};
    }
    my $name      = $block->{name} // $name_v;

    my $todo;
    $todo = todo( $block->{todo})
        if $block->{todo};

    my @constructor;
    if( $block->{constructor} ) {
        @constructor = map { %$_ } @{ Load( $block->{constructor}) };
    }

    my @diff = HTTP::Request::Diff
                   ->new(reference => $reference, @constructor)
                   ->diff( $actual );
    is \@diff, $result, $name
        or diag Dumper \@diff;
};

done_testing();

__DATA__
===
--- name
Parameter difference
--- reference
GET /?sessionid=1 HTTP/1.1


--- actual
GET /?sessionid=2 HTTP/1.1


--- diff
- kind: value
  type: query.sessionid
  reference:
  - 1
  actual:
  - 2
===
--- name
Multiple parameters
--- reference
GET /?sessionid=1;sessionid=2 HTTP/1.1


--- actual
GET /?sessionid=2 HTTP/1.1


--- diff
- kind: missing
  type: query.sessionid
  reference:
  - 1
  - 2
  actual:
  - ~
  - 2


===
--- name
Order of multiple parameters
--- reference
GET /?sessionid=1;sessionid=2 HTTP/1.1


--- actual
GET /?sessionid=2;sessionid=1 HTTP/1.1


--- diff
- kind: missing
  type: query.sessionid
  reference:
  - 1
  - 2
  - ~
  actual:
  - ~
  - 2
  - 1


===
--- name
Query separator
--- constructor
    - mode: strict
--- reference
GET /?sessionid=1;sessionid=2 HTTP/1.1


--- actual
GET /?sessionid=1&sessionid=2 HTTP/1.1


--- diff
- kind: value
  type: meta.query_separator
  reference: "sessionid=1;sessionid=2"
  actual:    "sessionid=1&sessionid=2"


