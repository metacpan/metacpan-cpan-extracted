use Test::File::ShareDir -share => {
    -dist => {
        "Dist-AutomationPolicy" => "share"
    }
};

use Test2::V0 -target => 'Dist::AutomationPolicy';
use Test2::Tools::Compare;

subtest "simple" => sub {

    my $pol = Dist::AutomationPolicy->new(
        distribution            => "Dist-AutomationPolicy",
        code_generation         => "toolchain",
        automated_contributions => "none",
        automated_actions       => "comment",
    );

    is $pol->data,
      {
        version                 => 1,
        distribution            => "Dist-AutomationPolicy",
        code_generation         => "toolchain",
        automated_contributions => "none",
        automated_actions       => "comment",
      },
      "data";

    ok my $copy = Dist::AutomationPolicy->from_json( $pol->to_json ), "from_json";

    is $copy->data, $pol->data, "round trip";

};

subtest "template" => sub {

    my $pol = Dist::AutomationPolicy->new(
        template => "human_supervised",
    );

    is $pol->data,
      {
        version                 => 1,
        code_generation         => "machine_generated",
        automated_contributions => "code_request",
        automated_actions       => "code_request",
      },
      "data";

    ok my $copy = Dist::AutomationPolicy->from_json( json => $pol->data ), "from_json";

    is $copy->data, $pol->data, "round trip";

};

subtest "template with override" => sub {

    my $pol = Dist::AutomationPolicy->new(
        template => "no_automation",
        code_generation => "external_sources",
    );

    is $pol->data,
      {
        version                 => 1,
        code_generation         => "external_sources",
        automated_contributions => "none",
        automated_actions       => "comment",
      },
      "data";

};

subtest "template with model (coerced)" => sub {

    my $pol = Dist::AutomationPolicy->new(
        template => "human_supervised",
        models   => "5pt-5.1-codex",
    );

    is $pol->data,
      {
        version                 => 1,
        code_generation         => "machine_generated",
        automated_contributions => "code_request",
        automated_actions       => "code_request",
        models                  => [qw( 5pt-5.1-codex )],
      },
      "data";

    ok my $copy = Dist::AutomationPolicy->from_json( json => $pol->data ), "from_json";

    is $copy->data, $pol->data, "round trip";

};

done_testing;
