# Copyright 2022 Google LLC and contributors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $inc_flags  = '-I.';
my $libs_flags = '-lcrypto';

my @ssl_search_dirs = (
  '/opt/homebrew/opt/openssl@3', '/opt/homebrew/opt/openssl',
  '/usr/local/opt/openssl@3',    '/usr/local/opt/openssl',
);

for my $dir (@ssl_search_dirs) {
  if (-f "$dir/include/openssl/evp.h") {
    $inc_flags  = "-I. -I$dir/include";
    $libs_flags = "-L$dir/lib -lcrypto";
    last;
  }
}

my $is_win32  = $^O eq 'MSWin32';
my @exe_files = ('bin/gcloud-auth');
my %pl_files;
if ($is_win32) {
  $pl_files{'bin/gcloud-auth.PL'} = 'bin/gcloud-auth.ps1';
  push @exe_files, 'bin/gcloud-auth.ps1';
}

WriteMakefile(
  NAME               => 'Google::Auth',
  AUTHOR             => q{C.J. Collier <cjac@google.com>},
  VERSION_FROM       => 'lib/Google/Auth.pm',
  ABSTRACT_FROM      => 'lib/Google/Auth.pm',
  LICENSE            => 'apache_2_0',
  PL_FILES           => \%pl_files,
  LIBS               => [$libs_flags],
  INC                => $inc_flags,
  OBJECT             => '$(O_FILES)',
  MIN_PERL_VERSION   => '5.006',
  CONFIGURE_REQUIRES => {
    'ExtUtils::MakeMaker' => '0',
  },
  TEST_REQUIRES => {
    'Test::Exception'      => '0',
    'Test::LWP::UserAgent' => '0',
    'Test::MockModule'     => '0',
    'Test::More'           => '0',
    'Test::Perl::Critic'   => '0',
  },
  PREREQ_PM => {
    'Capture::Tiny'                          => '0.48',
    'Future'                                 => '0',
    'Google::Api::Common'                    => '0.05',
    'Google::Cloud::Transport::Adapter::LWP' => '0',
    'JSON::MaybeXS'                          => '0',
    'Log::Any'                               => '0',
    'Moo'                                    => '0',
    'URI'                                    => '0',
  },
  EXE_FILES  => \@exe_files,
  META_MERGE => {
    'meta-spec' => {version => 2},
    resources   => {
      repository => {
        type => 'git',
        url  =>
          'https://github.com/GoogleCloudPlatform/google-auth-library-perl.git',
        web =>
          'https://github.com/GoogleCloudPlatform/google-auth-library-perl',
      },
      bugtracker => {
        web =>
'https://github.com/GoogleCloudPlatform/google-auth-library-perl/issues',
      },
    },
  },
  dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
  clean => {
    FILES => 'Google-Auth-Library-Perl-* bin/gcloud-auth.ps1'
  },
);

package MY;

sub dist_basics {
  my $self       = shift;
  my $inherited  = $self->SUPER::dist_basics(@_);
  my $check_code = "\t\$(PERL) -Ilib maint/release_lint.pl\n";
  $inherited =~
    s/(distcheck\s*:)/$1 release_lint\n\nrelease_lint :\n$check_code\n/;
  return $inherited;
}

sub postamble {
  return <<'MAKE_EXTRAS';
author-tests :
	AUTHOR_TESTING=1 prove -Ilib -bv xt/
MAKE_EXTRAS
}

package main;
1;
