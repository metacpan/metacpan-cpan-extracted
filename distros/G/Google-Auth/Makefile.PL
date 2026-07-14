# Copyright 2022 Google LLC
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

WriteMakefile(
    NAME             => 'Google::Auth',
    AUTHOR           => q{C.J. Collier <CJCOLLIER@CPAN.ORG>},
    VERSION_FROM     => 'lib/Google/Auth.pm',
    ABSTRACT_FROM    => 'lib/Google/Auth.pm',
    LICENSE          => 'Apache 2.0',
    PL_FILES         => {},
    LIBS             => ['-lcrypto'],
    INC              => '-I.',
    OBJECT           => '$(O_FILES)',
    MIN_PERL_VERSION => '5.006',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    BUILD_REQUIRES => {
        'Test::Deep'           => '0',
        'Test::Exception'      => '0',
        'Test::LWP::UserAgent' => '0',
        'Test::More'           => '0',
        'Test::Perl::Critic'   => '0',
    },
    PREREQ_PM => {
        'Capture::Tiny'         => '0.48',
        'JSON::MaybeXS'         => '0',
        'Log::Any'              => '0',
        'Moo'                   => '0',
        'URI'                   => '0',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Google-Auth-Library-Perl-*' },
);
