use strict;
use warnings;

use Test::More;
use Path::Tiny;

my $dockerfile = path('Dockerfile')->slurp_utf8;
my $dist_ini   = path('dist.ini')->slurp_utf8;
my $ignore     = path('.dockerignore')->slurp_utf8;

unlike($dockerfile, qr/Langertha-Raider-\$\{RAIDER_VERSION\}\.tar\.gz/,
  'Dockerfile does not require a release tarball in the build context');

like($dockerfile, qr/RUN\b[^\n]*curl\b[^\n]*skaji\/cpm/s,
  'Dockerfile installs cpm explicitly');
like($dockerfile, qr/cpm install\b.*--cpanfile cpanfile/s,
  'Dockerfile installs dependencies through cpm from the cpanfile');
like($dockerfile, qr/cpm install\b.*--resolver metacpan/s,
  'Dockerfile uses the MetaCPAN resolver');
like($dockerfile, qr/cpm install\b[^&]*--metafile META\.json[^&]*--top-level-phase configure[^&]*&& perl Makefile\.PL/s,
  'Dockerfile installs the configure prereqs of the built META.json before Makefile.PL');
like($dockerfile, qr/ARG RAIDER_VERSION=dev/,
  'Dockerfile has a dev-safe version build arg');
like($dockerfile, qr/WORKDIR\s+\$\{RAIDER_SRC\}/,
  'Dockerfile builds from a stable source directory');

like($dist_ini, qr/^docker_image = raudssus\/raider$/m,
  'the bundle builds and pushes raudssus/raider');
like($dist_ini, qr/^docker_tags = latest %V %v$/m,
  'the image is tagged latest, major and version');
unlike($dist_ini, qr/^docker_default\b/m,
  'the bundle\'s automatic Docker section is on');
unlike($dist_ini, qr/^\[\@Author::GETTY::Docker\b/m,
  'no explicit Docker section beside it');
unlike($dist_ini, qr/^run_after_release\b/m,
  'no release hook: Docker image and GitHub release both come from the bundle');
ok(!-e 'maint/release-after.pl',
  'no maint script creates the GitHub release beside GitHub::CreateRelease');

my @stages = $dockerfile =~ /^FROM \S+ AS (\S+)$/mg;
is($stages[-1], 'runtime-root',
  'the published image is the last stage, the one a build without a target gets');

SKIP: {
  # README.md lives in the repository only; the built distribution ships the
  # generated README instead.
  skip 'README.md not present (built distribution)', 1 unless -e 'README.md';
  like(path('README.md')->slurp_utf8,
    qr/Dockerfile installs from the Dist::Zilla-built distribution directory/,
    'README documents the Dist::Zilla distribution directory build');
}

for my $manifest_file (qw( .dockerignore .gitignore Dockerfile .claude README )) {
  unlike($ignore, qr/^\Q$manifest_file\E$/m,
    ".dockerignore does not exclude MANIFEST file $manifest_file");
}

done_testing;
