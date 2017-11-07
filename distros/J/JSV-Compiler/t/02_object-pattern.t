use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib "$Bin/../t";
use Test::Most qw(!any !none);
use JSV::Compiler;
use Module::Load;

my $jsc = JSV::Compiler->new();
$jsc->{full_schema} = {
    "\$schema"   => "http://json-schema.org/draft-06/schema#",
    "type"       => "object",
    "properties" => {
        "/" => {}
    },
    "patternProperties" => {
        "^(/[^/]+)+\$" => {}
    },
    "additionalProperties" => 0,
    "required"             => ["/"]
};

my $ok_path = [
    {
        "/"    => {},
        "/usr" => {},
    },
];

my $bad_path = [
    {
        "/home" => {},
    },
];

my ($res, %load) = $jsc->compile();
for my $m (keys %load) {
    load $m, @{$load{$m}} ? @{$load{$m}} : ();
}
ok( $res, "Compiled" );
my $test_sub_txt = "sub { my \$errors = []; $res; print \"\@\$errors\\n\" if \@\$errors; return \@\$errors == 0 }\n";
my $test_sub     = eval $test_sub_txt;

is( $@, '', "Successfully compiled" );
explain $res if $@;

for my $p (@$ok_path) {
    ok( $test_sub->($p), "Tested path" );
}

for my $p (@$bad_path) {
    ok( !$test_sub->($p), "Tested path" ) or explain $res;
}

#explain $res;

#print $test_sub_txt;

done_testing();