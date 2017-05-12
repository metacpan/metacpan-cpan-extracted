use strict;
use warnings;

use Test::More; 

use Escape::Houdini qw/ :all /;

my @functions = sort 
    map( "escape_$_", qw/ html xml url uri href js / ),
    map( "unescape_$_", qw/ html url uri js / ),
;

my %test_string;

$test_string{"hello world"} = {
    ( map { $_ => 'hello+world' } qw/ escape_url / ),
    map { $_ => 'hello%20world' } qw/ escape_href escape_uri /
};
$test_string{"<foo>"} = {
    ( map { $_ => '&lt;foo&gt;' } qw/ escape_html escape_xml / ),
    map { $_ => '%3Cfoo%3E' } qw/ escape_href  escape_uri escape_url  /
};

plan tests => scalar keys %test_string;

for my $s ( sort keys %test_string ) {
    subtest $s => sub {
        plan tests => scalar @functions;

        for my $func ( @functions ) {
            my $eval = "$func('$s')";
            is eval $eval => $test_string{$s}{$func} || $s, $func;
        }
    }
}

