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
            path(qw( source dist.ini )) => simple_ini( ['GatherDir'], [ 'CodeOfConduct', ], ),
        }
    }
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

cmp_deeply $tzil->distmeta->{prereqs},
  {
    develop => {
        requires => {
            'Software::Policy::CodeOfConduct' => 'v0.4.0',
        }
    }
  },
  "prereqs";

my $file = path( $tzil->tempdir, "build", "CODE_OF_CONDUCT.md" );

ok $file->exists, "file exists";

ok my $text = $file->slurp_raw, "has content";

like $text, qr/\bDZT-Sample\s+project\b/m, "has default name";
like $text, qr/\bexample\@example\.org\b/, "has author";

note $text;

done_testing;
