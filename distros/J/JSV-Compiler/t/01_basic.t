use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/../t";
use Test::Most;
use JSV::Compiler;

my $jsc = JSV::Compiler->new();
$jsc->{full_schema} = {
    "\$schema"    => "http://json-schema.org/draft-06/schema#",
    "title"       => "Product",
    "description" => "A product from Acme's catalog",
    "type"        => "object",
    "properties"  => {
        "id" => {
            "description" => "The unique identifier for a product",
            "type"        => "integer"
        },
        "name" => {
            "description" => "Name of the product",
            "type"        => "string"
        },
        "price" => {
            "type"             => "number",
            "exclusiveMinimum" => 0
        },
        "tags" => {
            "type"        => "array",
            "items"       => {"type" => "string"},
            "minItems"    => 1,
            "uniqueItems" => 1
        }
    },
    "required" => ["id", "name", "price"]
};

my $ok_products = [
    {   "id"    => 2,
        "name"  => "An ice sculpture",
        "price" => 12.50,
    },
    {   "id"    => 3,
        "name"  => "A blue mouse",
        "price" => 25.50,
        tags    => ["a1", "a2"],
    }
];

my $bad_products = [
    {   "id"    => 2.5,
        "name"  => "An ice sculpture",
        "price" => 1,
        tags    => [],
    },
    {   "id"    => 3,
        "name"  => "A blue mouse",
        "price" => -1,
        tags    => [1, 2, 3, 4, 1],
    }
];

my $res = $jsc->compile();
ok($res, "Compiled");
my $test_sub = eval "sub { my \$errors = []; $res; print \"\@\$errors\\n\" if \@\$errors; return \@\$errors == 0 }";
is($@, '', "Successfully compiled");
explain $res if $@;

for my $p (@$ok_products) {
    ok($test_sub->($p), "Tested product");
}

for my $p (@$bad_products) {
    ok(!$test_sub->($p), "Tested product") or explain $res;
}
#explain $res;

done_testing();
