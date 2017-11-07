use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/../t";
use Test::Most qw(!any !none);
use JSON::PP;
use JSV::Compiler;
use Module::Load;

my $jsc = JSV::Compiler->new();

my $test_suite = [
    {   "description" => "not",
        "schema"      => {"not" => {"type" => "integer"}},
        "tests"       => [
            {   "description" => "allowed",
                "data"        => "foo",
                "valid"       => 1
            },
            {   "description" => "disallowed",
                "data"        => 1,
                "valid"       => 0
            }
        ]
    },
    {   "description" => "not more complex schema",
        "schema"      => {
            "not" => {
                "type"       => "object",
                "properties" => {"foo" => {"type" => "string"}}
            }
        },
        "tests" => [
            {   "description" => "match",
                "data"        => 1,
                "valid"       => 1
            },
            {   "description" => "other match",
                "data"        => {"foo" => 1},
                "valid"       => 0
            },
            {   "description" => "mismatch",
                "data"        => {"foo" => "bar"},
                "valid"       => 0
            }
        ]
    },
    {   "description" => "forbidden property",
        "schema"      => {"properties" => {"foo" => {"not" => {}}}},
        "tests"       => [
            {   "description" => "property present",
                "data"        => {"foo" => 1, "bar" => 2},
                "valid"       => 0
            },
            {   "description" => "property absent",
                "data"        => {"bar" => 1, "baz" => 2},
                "valid"       => 1
            }
        ]
    },
    {   "description" => "not with boolean schema true",
        "schema"      => {"not" => JSON::PP::true},
        "tests"       => [
            {   "description" => "any value is invalid",
                "data"        => "foo",
                "valid"       => 0
            }
        ]
    },
    {   "description" => "not with boolean schema false",
        "schema"      => {"not" => JSON::PP::false},
        "tests"       => [
            {   "description" => "any value is valid",
                "data"        => "foo",
                "valid"       => 1
            }
        ]
    }
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

