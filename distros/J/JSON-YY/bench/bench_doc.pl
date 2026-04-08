use strict;
use warnings;
use Benchmark qw(cmpthese);
use JSON::XS ();
use JSON::YY qw(encode_json decode_json);
use JSON::YY ':doc';

my $json_small = '{"name":"John","age":30,"active":true}';
my $json_medium = encode_json({
    users => [map { {id => $_, name => "user_$_", email => "user_$_\@example.com",
                     tags => [qw(alpha beta gamma delta)], score => $_ * 1.5} } 1..100],
    meta => {total => 100, page => 1, per_page => 100},
});
my $json_large = encode_json([map { {id => $_, val => "x" x 50, n => $_ * 0.1} } 1..10000]);

printf "small:  %d bytes\nmedium: %d bytes\nlarge:  %d bytes\n\n",
    length $json_small, length $json_medium, length $json_large;

print "=" x 60, "\n";
print "Doc API vs Perl decode-modify-encode cycle\n";
print "=" x 60, "\n\n";

# Scenario 1: Parse + read single value
print "--- read single value (small) ---\n";
cmpthese(-2, {
    'Perl' => sub {
        my $d = JSON::XS::decode_json($json_small);
        my $v = $d->{age};
    },
    'Doc'  => sub {
        my $d = jdoc $json_small;
        my $v = jgetp $d, "/age";
    },
});
print "\n";

# Scenario 2: Parse + modify + serialize
print "--- modify + serialize (small) ---\n";
cmpthese(-2, {
    'Perl' => sub {
        my $d = JSON::XS::decode_json($json_small);
        $d->{age} = 31;
        JSON::XS::encode_json($d);
    },
    'Doc'  => sub {
        my $d = jdoc $json_small;
        jset $d, "/age", 31;
        jencode $d, "";
    },
});
print "\n";

# Scenario 3: Parse large + read one deep value
print "--- read one value from large doc ---\n";
cmpthese(-2, {
    'Perl' => sub {
        my $d = JSON::XS::decode_json($json_medium);
        my $v = $d->{users}[50]{name};
    },
    'Doc'  => sub {
        my $d = jdoc $json_medium;
        my $v = jgetp $d, "/users/50/name";
    },
});
print "\n";

# Scenario 4: Parse large + modify one value + serialize
print "--- modify one value in large doc + serialize ---\n";
cmpthese(-2, {
    'Perl' => sub {
        my $d = JSON::XS::decode_json($json_medium);
        $d->{users}[50]{name} = "modified";
        JSON::XS::encode_json($d);
    },
    'Doc'  => sub {
        my $d = jdoc $json_medium;
        jset $d, "/users/50/name", "modified";
        jencode $d, "";
    },
});
print "\n";

# Scenario 5: Iterate array
print "--- iterate 100-element array ---\n";
my $arr_json = encode_json([map { {id => $_, name => "item_$_"} } 1..100]);
cmpthese(-2, {
    'Perl' => sub {
        my $d = JSON::XS::decode_json($arr_json);
        my $sum = 0;
        for my $item (@$d) { $sum += $item->{id} }
    },
    'Doc'  => sub {
        my $d = jdoc $arr_json;
        my $it = jiter $d, "";
        my $sum = 0;
        while (defined(my $item = jnext $it)) {
            $sum += jgetp $item, "/id";
        }
    },
});
print "\n";

# Scenario 6: Clone subtree
print "--- clone subtree from medium doc ---\n";
cmpthese(-2, {
    'Perl' => sub {
        my $d = JSON::XS::decode_json($json_medium);
        my $copy = {%{$d->{users}[0]}};
    },
    'Doc'  => sub {
        my $d = jdoc $json_medium;
        my $copy = jclone $d, "/users/0";
    },
});
print "\n";

# Scenario 7: Type inspection without full decode
print "--- type check + length (no full decode) ---\n";
cmpthese(-2, {
    'Perl' => sub {
        my $d = JSON::XS::decode_json($json_medium);
        my $t = ref $d->{users};
        my $n = scalar @{$d->{users}};
    },
    'Doc'  => sub {
        my $d = jdoc $json_medium;
        my $t = jtype $d, "/users";
        my $n = jlen $d, "/users";
    },
});
print "\n";
