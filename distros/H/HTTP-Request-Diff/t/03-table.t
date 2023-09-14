#!perl
use 5.020;
no warnings;
use Test2::V0;
use Data::Dumper;

use HTTP::Request;
use YAML 'Load';

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
    my $result    = $block->{diff} . "\n";
    my $name      = $block->{name} // $name_v;

    my $todo;
    $todo = todo( $block->{todo})
        if $block->{todo};

    my @constructor;
    if( $block->{constructor} ) {
        @constructor = map { %$_ } @{ Load( $block->{constructor}) };
    }

    my $diff = HTTP::Request::Diff->new(reference => $reference, @constructor);
    my @diff = $diff->diff( $actual );
    my $table = $diff->as_table( @diff );
    is $table, $result, $name;
};

done_testing();

__DATA__
===
--- reference
GET / HTTP/1.1
--- actual
GET /foo HTTP/1.1
--- diff
+----------+-----------+--------+
| Type     | Reference | Actual |
| uri.path | /         | /foo   |
+----------+-----------+--------+
===
--- name
Missing fields
--- reference
GET / HTTP/1.1
Accept-Language: fi


--- actual
GET / HTTP/1.1
--- diff
+-------------------------+-----------+-----------+
| Type                    | Reference | Actual    |
| headers.Accept-Language | fi        | <missing> |
+-------------------------+-----------+-----------+
===
--- name
UTF-8 stuff
--- reference
GET / HTTP/1.1
Content-Charset: UTF-8

Ümloud
--- actual
GET / HTTP/1.1
Content-Charset: UTF-8

Umloud
--- diff
+-----------------+-----------+--------+
| Type            | Reference | Actual |
| request.content | Ümloud    | Umloud |
+-----------------+-----------+--------+
