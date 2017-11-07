use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/../t";
use Test::Most qw(!any !none);
use JSON::PP;
use JSV::Compiler;
use Module::Load;

my $jsc = JSV::Compiler->new();

my $test_suite = [
    {   "description" => "allOf",
        "schema"      => {
            "allOf" => [
                {   "properties" => {"bar" => {"type" => "integer"}},
                    "required"   => ["bar"]
                },
                {   "properties" => {"foo" => {"type" => "string"}},
                    "required"   => ["foo"]
                }
            ]
        },
        "tests" => [
            {   "description" => "allOf",
                "data"        => {"foo" => "baz", "bar" => 2},
                "valid"       => 1
            },
            {   "description" => "mismatch second",
                "data"        => {"foo" => "baz"},
                "valid"       => 0
            },
            {   "description" => "mismatch first",
                "data"        => {"bar" => 2},
                "valid"       => 0
            },
            {   "description" => "wrong type",
                "data"        => {"foo" => "baz", "bar" => "quux"},
                "valid"       => 0
            }
        ]
    },
    {   "description" => "allOf with base schema",
        "schema"      => {
            "properties" => {"bar" => {"type" => "integer"}},
            "required"   => ["bar"],
            "allOf"      => [
                {   "properties" => {"foo" => {"type" => "string"}},
                    "required"   => ["foo"]
                },
                {   "properties" => {"baz" => {"type" => "null"}},
                    "required"   => ["baz"]
                }
            ]
        },
        "tests" => [
            {   "description" => "valid",
                "data"        => {"foo" => "quux", "bar" => 2, "baz" => undef},
                "valid"       => 1
            },
            {   "description" => "mismatch base schema",
                "data"        => {"foo" => "quux", "baz" => undef},
                "valid"       => 0
            },
            {   "description" => "mismatch first allOf",
                "data"        => {"bar" => 2, "baz" => undef},
                "valid"       => 0
            },
            {   "description" => "mismatch second allOf",
                "data"        => {"foo" => "quux", "bar" => 2},
                "valid"       => 0
            },
            {   "description" => "mismatch both",
                "data"        => {"bar" => 2},
                "valid"       => 0
            }
        ]
    },
    {   "description" => "allOf simple types",
        "schema"      => {"allOf" => [{"maximum" => 30}, {"minimum" => 20}]},
        "tests"       => [
            {   "description" => "valid",
                "data"        => 25,
                "valid"       => 1
            },
            {   "description" => "mismatch one",
                "data"        => 35,
                "valid"       => 0
            }
        ]
    },
    {   "description" => "allOf with boolean schemas, all 1",
        "schema"      => {"allOf" => [JSON::PP::true, JSON::PP::true]},
        "tests"       => [
            {   "description" => "any value is valid",
                "data"        => "foo",
                "valid"       => 1
            }
        ]
    },
    {   "description" => "allOf with boolean schemas, some 0",
        "schema"      => {"allOf" => [JSON::PP::true, JSON::PP::false]},
        "tests"       => [
            {   "description" => "any value is invalid",
                "data"        => "foo",
                "valid"       => 0
            }
        ]
    },
    {   "description" => "allOf with boolean schemas, all 0",
        "schema"      => {"allOf" => [JSON::PP::false, JSON::PP::false]},
        "tests"       => [
            {   "description" => "any value is invalid",
                "data"        => "foo",
                "valid"       => 0
            }
        ]
    },
];

for my $test (@$test_suite) {
    $jsc->load_schema($test->{schema});
    my ($res, %load) = $jsc->compile();
    for my $m (keys %load) {
        load $m, @{$load{$m}} ? @{$load{$m}} : ();
    }
    ok($res, "Compiled");
    my $test_sub_txt = "sub { my \$errors = []; $res; print \"\@\$errors\\n\" if \@\$errors; return \@\$errors == 0 }\n";
    my $test_sub     = eval $test_sub_txt;
    is($@, '', "Successfully compiled");
    explain $test_sub_txt if $@;
    for my $tcase (@{$test->{tests}}) {
        my $tn = $test->{description} . " | " . $tcase->{description};
        if ($tcase->{valid}) {
            ok($test_sub->($tcase->{data}), $tn) or explain $test_sub_txt;
        } else {
            ok(!$test_sub->($tcase->{data}), $tn) or explain $test_sub_txt;
        }
    }
}

done_testing();

