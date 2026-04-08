use strict;
use warnings;
use Benchmark qw(cmpthese);
use JSON::XS qw(encode_json decode_json);
use JSON::YY ();

# import YY into a separate package to get keyword-compiled ops
package BenchKeyword {
    use JSON::YY qw(encode_json decode_json);
    sub enc { encode_json $_[0] }
    sub dec { decode_json $_[0] }
}

package main;

my $xs = JSON::XS->new->utf8;
my $yy = JSON::YY->new->utf8;

# test data
my $small = {name => "John", age => 30, active => \1};
my $medium = {
    users => [
        map { {
            id    => $_,
            name  => "user_$_",
            email => "user_$_\@example.com",
            tags  => [qw(alpha beta gamma delta)],
            score => $_ * 1.5,
        } } 1..100
    ],
    meta => {total => 100, page => 1, per_page => 100},
};
my $large = [map { {id => $_, val => "x" x 50, n => $_ * 0.1} } 1..10000];

my $small_json  = $xs->encode($small);
my $medium_json = $xs->encode($medium);
my $large_json  = $xs->encode($large);

print "=" x 60, "\n";
print "JSON::YY vs JSON::XS benchmark\n";
print "=" x 60, "\n";
printf "small:  %d bytes\n", length $small_json;
printf "medium: %d bytes\n", length $medium_json;
printf "large:  %d bytes\n", length $large_json;
print "\n";

print "=== Keyword API (custom ops, zero dispatch) ===\n\n";
for my $test (
    ['small encode',  sub { encode_json($small) },       sub { BenchKeyword::enc($small) }],
    ['small decode',  sub { decode_json($small_json) },   sub { BenchKeyword::dec($small_json) }],
    ['medium encode', sub { encode_json($medium) },       sub { BenchKeyword::enc($medium) }],
    ['medium decode', sub { decode_json($medium_json) },   sub { BenchKeyword::dec($medium_json) }],
    ['large encode',  sub { encode_json($large) },        sub { BenchKeyword::enc($large) }],
    ['large decode',  sub { decode_json($large_json) },    sub { BenchKeyword::dec($large_json) }],
) {
    my ($name, $xs_sub, $yy_sub) = @$test;
    print "--- $name ---\n";
    cmpthese(-2, {
        'JSON::XS' => $xs_sub,
        'JSON::YY kw' => $yy_sub,
    });
    print "\n";
}

print "=== Functional API (XS function call) ===\n\n";
for my $test (
    ['small encode',  sub { encode_json($small) },               sub { JSON::YY::encode_json($small) }],
    ['small decode',  sub { decode_json($small_json) },           sub { JSON::YY::decode_json($small_json) }],
    ['medium encode', sub { encode_json($medium) },               sub { JSON::YY::encode_json($medium) }],
    ['medium decode', sub { decode_json($medium_json) },           sub { JSON::YY::decode_json($medium_json) }],
    ['large encode',  sub { encode_json($large) },                sub { JSON::YY::encode_json($large) }],
    ['large decode',  sub { decode_json($large_json) },            sub { JSON::YY::decode_json($large_json) }],
) {
    my ($name, $xs_sub, $yy_sub) = @$test;
    print "--- $name ---\n";
    cmpthese(-2, {
        'JSON::XS' => $xs_sub,
        'JSON::YY fn' => $yy_sub,
    });
    print "\n";
}

print "=== OO API (\$obj->encode / \$obj->decode) ===\n\n";
for my $test (
    ['small encode',  sub { $xs->encode($small) },  sub { $yy->encode($small) }],
    ['small decode',  sub { $xs->decode($small_json) },  sub { $yy->decode($small_json) }],
    ['medium encode', sub { $xs->encode($medium) }, sub { $yy->encode($medium) }],
    ['medium decode', sub { $xs->decode($medium_json) }, sub { $yy->decode($medium_json) }],
    ['large encode',  sub { $xs->encode($large) },  sub { $yy->encode($large) }],
    ['large decode',  sub { $xs->decode($large_json) },  sub { $yy->decode($large_json) }],
) {
    my ($name, $xs_sub, $yy_sub) = @$test;
    print "--- $name ---\n";
    cmpthese(-2, {
        'JSON::XS' => $xs_sub,
        'JSON::YY oo' => $yy_sub,
    });
    print "\n";
}
