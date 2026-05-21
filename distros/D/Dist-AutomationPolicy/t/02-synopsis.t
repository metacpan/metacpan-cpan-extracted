use Test::File::ShareDir -share => {
    -dist => {
        "Dist-AutomationPolicy" => "share"
    }
};

use Test2::V0 -target => 'Dist::AutomationPolicy';
use Test2::Tools::Compare;

use Dist::AutomationPolicy;
use Path::Tiny 0.130 qw( path tempdir );

my $dir = tempdir;

subtest write => sub {

    ok my $pol = Dist::AutomationPolicy->new(
        distribution            => "Dist-AutomationPolicy-v0.1.0",
        code_generation         => "toolchain",
        automated_contributions => "issue",
        automated_actions       => "code_request",
        models                  => [ "claude-sonnet-4.6" ],
      ),
      "new";

    if ( ok( $pol->validate, "validate" ) ) {

        my $path = path( $dir, $pol->filename );    # "CPAN-META/automation-policy.json"
        $path->parent->mkdir;
        $path->spew_raw( $pol->to_json );

        ok $path->exists, "${path} exists";

    }

};

subtest read => sub {

    my $path = path( $dir, "CPAN-META/automation-policy.json" );
    ok my $pol = Dist::AutomationPolicy->from_json( json => $path->slurp_raw ), "from_json";

    ok $pol->validate, "validate";

};

done_testing;
