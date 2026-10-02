use strict;
use warnings;

use Test::More;
use Path::Tiny;

my $dockerfile = path('Dockerfile')->slurp_utf8;
my $dist_ini   = path('dist.ini')->slurp_utf8;
my $release    = path('maint/release-after.pl')->slurp_utf8;
my $ignore     = path('.dockerignore')->slurp_utf8;

unlike($dockerfile, qr/Langertha-Raider-\$\{RAIDER_VERSION\}\.tar\.gz/,
  'Dockerfile does not require a release tarball in the build context');

like($dockerfile, qr/RUN\b[^\n]*curl\b[^\n]*skaji\/cpm/s,
  'Dockerfile installs cpm explicitly');
like($dockerfile, qr/cpm install\b.*--cpanfile cpanfile/s,
  'Dockerfile installs dependencies through cpm from the cpanfile');
like($dockerfile, qr/cpm install\b.*--resolver metacpan/s,
  'Dockerfile uses the MetaCPAN resolver');
like($dockerfile, qr/ARG RAIDER_VERSION=dev/,
  'Dockerfile has a dev-safe version build arg');
like($dockerfile, qr/WORKDIR\s+\$\{RAIDER_SRC\}/,
  'Dockerfile builds from a stable source directory');

like($dist_ini, qr/run_after_release = %x %o\/maint\/release-after\.pl --archive %a --dir %d --version %v/,
  'release hook delegates archive, build directory, and version to maint script');
unlike($dist_ini, qr/Langertha-Raider-%v\.tar\.gz[^\n]*docker\} build/,
  'release hook does not require the archive as Docker input');
like($release, qr/\$docker, 'build'.*'--build-arg', 'RAIDER_VERSION=' \. \$opt\{version\}.*\$opt\{dir\}/s,
  'maint script builds Docker from the Dist::Zilla build directory');

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
