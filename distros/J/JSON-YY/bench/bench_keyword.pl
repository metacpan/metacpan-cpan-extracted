use strict;
use warnings;
use Benchmark qw(cmpthese);

# JSON::XS functional — these compile to normal entersub
use JSON::XS ();

# JSON::YY keyword — these compile to custom ops at compile time
package KW {
    use JSON::YY qw(encode_json decode_json);
    # encode_json/decode_json here are keyword-compiled custom ops
    sub enc_small  { encode_json $_[0] }
    sub dec_small  { decode_json $_[0] }
    sub enc_medium { encode_json $_[0] }
    sub dec_medium { decode_json $_[0] }
}

# JSON::XS wrappers for fair comparison (same sub-call overhead)
package XS {
    sub enc_small  { JSON::XS::encode_json($_[0]) }
    sub dec_small  { JSON::XS::decode_json($_[0]) }
    sub enc_medium { JSON::XS::encode_json($_[0]) }
    sub dec_medium { JSON::XS::decode_json($_[0]) }
}

package main;

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

my $small_json  = JSON::XS::encode_json($small);
my $medium_json = JSON::XS::encode_json($medium);

print "=" x 60, "\n";
print "Keyword ops vs XS function calls\n";
print "(both wrapped in equivalent sub calls)\n";
print "=" x 60, "\n\n";

for my $test (
    ['small encode',  sub { XS::enc_small($small) },        sub { KW::enc_small($small) }],
    ['small decode',  sub { XS::dec_small($small_json) },    sub { KW::dec_small($small_json) }],
    ['medium encode', sub { XS::enc_medium($medium) },       sub { KW::enc_medium($medium) }],
    ['medium decode', sub { XS::dec_medium($medium_json) },   sub { KW::dec_medium($medium_json) }],
) {
    my ($name, $xs_sub, $kw_sub) = @$test;
    print "--- $name ---\n";
    cmpthese(-3, {
        'XS call' => $xs_sub,
        'keyword' => $kw_sub,
    });
    print "\n";
}

# now show the B::Concise output to prove it's a custom op
print "=== Op tree proof (B::Concise) ===\n\n";
system($^X, "-Iblib/lib", "-Iblib/arch", "-MO=Concise,KW::enc_small", "-e",
    'package KW; use JSON::YY qw(encode_json); sub enc_small { encode_json $_[0] }');
print "\n";
