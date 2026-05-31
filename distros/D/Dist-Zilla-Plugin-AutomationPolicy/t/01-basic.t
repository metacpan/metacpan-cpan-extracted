use v5.24;

use warnings;

use Test::More;
use Test::Deep;
use Test::DZil;

use JSON       qw( decode_json );
use Path::Tiny qw( path );

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw( source dist.ini )) => simple_ini(
                ['GatherDir'],
                [
                    'AutomationPolicy',
                 {
                        description => 'Test for Dist-Zilla-Plugin-AutomationPolicy',
                        document => 'AI_POLICY.md',
                        template => 'human_supervised',
                        models   => [qw( claude-opus-4-7 claude-opus-4-8 )],
                    }
                ],
            ),
        }
    }
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

cmp_deeply $tzil->distmeta->{prereqs},
  {
    develop => {
        requires => {
            'Dist::AutomationPolicy' => 'v0.2.0',
        }
    }
  },
  "prereqs";

my $file = path( $tzil->tempdir, "build", "CPAN-META/automation-policy.json" );

ok $file->exists, "file exists";

ok my $json = $file->slurp_raw, "has content";

note $json;

ok my $data = decode_json($json), "decoded JSON";

is_deeply $data,
  {
    "automated_actions"       => "code_request",
    "automated_contributions" => "code_request",
    "code_generation"         => "machine_generated",
    "description"             => 'Test for Dist-Zilla-Plugin-AutomationPolicy',
    "distribution"            => "DZT-Sample-0.001",
    "document"                => "AI_POLICY.md",
    "models"                  => [qw( claude-opus-4-7 claude-opus-4-8 )],
    "version"                 => 1
  },
  "expected data";

done_testing;
