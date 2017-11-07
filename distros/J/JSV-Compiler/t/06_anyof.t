use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/../t";
use Test::Most qw(!any !none);
use JSON::PP;
use JSV::Compiler;
use Module::Load;

my $jsc = JSV::Compiler->new();

my $test_suite = [
    {   "description" => "anyOf",
        "schema"      => {"anyOf" => [{"type" => "integer"}, {"minimum" => 2}]},
        "tests"       => [
            {   "description" => "first anyOf valid",
                "data"        => 1,
                "valid"       => 1
            },
            {   "description" => "second anyOf valid",
                "data"        => 2.5,
                "valid"       => 1
            },
            {   "description" => "both anyOf valid",
                "data"        => 3,
                "valid"       => 1
            },
            {   "description" => "neither anyOf valid",
                "data"        => 1.5,
                "valid"       => 0
            }
        ]
    },
    {   "description" => "anyOf with base schema",
        "schema"      => {
            "type"  => "string",
            "anyOf" => [{"maxLength" => 2}, {"minLength" => 4}]
        },
        "tests" => [
            {   "description" => "match base schema",    # adapted test for perl
                "data"        => 3,
                "valid"       => 1
            },
            {   "description" => "one anyOf valid",
                "data"        => "foobar",
                "valid"       => 1
            },
            {   "description" => "both anyOf invalid",
                "data"        => "foo",
                "valid"       => 0
            }
        ]
    },
    {   "description" => "anyOf with boolean schemas, all JSON::PP::true",
        "schema"      => {"anyOf" => [JSON::PP::true, JSON::PP::true]},
        "tests"       => [
            {   "description" => "any value is valid",
                "data"        => "foo",
                "valid"       => 1
            }
        ]
    },
    {   "description" => "anyOf with boolean schemas, some JSON::PP::true",
        "schema"      => {"anyOf" => [JSON::PP::true, JSON::PP::false]},
        "tests"       => [
            {   "description" => "any value is valid",
                "data"        => "foo",
                "valid"       => 1
            }
        ]
    },
    {   "description" => "anyOf with boolean schemas, all JSON::PP::false",
        "schema"      => {"anyOf" => [JSON::PP::false, JSON::PP::false]},
        "tests"       => [
            {   "description" => "any value is invalid",
                "data"        => "foo",
                "valid"       => 0
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

