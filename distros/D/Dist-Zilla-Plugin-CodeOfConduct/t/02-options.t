use v5.20;
use warnings;

use Test::More;
use Test::Deep;
use Test::DZil;

use Path::Tiny qw( path );

use Software::License::Perl_5 0.011;

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw( source dist.ini )) => simple_ini(
                ['GatherDir'],
                [
                    'CodeOfConduct',
                    {
                        '-version'   => 'v0.4.1',
                        policy       => 'Contributor_Covenant_2.0',
                        name         => 'Our Thing',
                        contact      => 'project-team@example.com',
                        filename     => 'CODE-OF-CONDUCT',
                        entity       => 'community',
                        text_columns => 150,
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
            'Software::Policy::CodeOfConduct' => 'v0.4.1',
        }
    }
  },
  "prereqs";

my $file = path( $tzil->tempdir, "build", "CODE-OF-CONDUCT" );

ok $file->exists, "file exists";

ok my $text = $file->slurp_raw, "has content";

like $text, qr/\bversion 2\.0\b/,             "has specified version";
like $text, qr/\bOur\s+Thing\s+community\b/m, "has name";
like $text, qr/project-team\@example\.com\b/, "has contact";

note $text;

done_testing;
