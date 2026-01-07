use strict;
use warnings;

use 5.024001;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Google::RestApi',
    AUTHOR            => 'Robin Murray <mvsjes@cpan.org>',
    ABSTRACT_FROM     => 'lib/Google/RestApi.pm',
    VERSION_FROM      => 'lib/Google/RestApi.pm',
    PREREQ_PM         => {
      'aliased'                         => 0,
      'autodie'                         => 0,
      'autovivification'                => 0,
      'constant'                        => 0,
      'Cache::Memory::Simple'           => 0,
      'Carp'                            => 0,
      'Exporter'                        => 0,
      'File::Slurp'                     => 0,
      'Furl'                            => 0,
      'Hash::Merge'                     => 0,
      'JSON::MaybeXS'                   => 0,
      'List::MoreUtils'                 => 0,
      'List::Util'                      => 0,
      'LWP::Protocol::https'            => 0,
      'Log::Log4perl'                   => 0,
      'Module::Load'                    => 0,
      'Net::OAuth2::Client'             => 0,
      'Net::OAuth2::Profile::WebServer' => 0,
      'PerlX::Maybe'                    => 0,
      'Readonly'                        => 0,
      'Retry::Backoff'                  => 0,
      'Scalar::Util'                    => 0,
      'Storable'                        => 0,
      'Term::Prompt'                    => 0,
      'Tie::Hash'                       => 0,
      'Try::Tiny'                       => 0,
      'ToolSet'                         => 0,
      'Type::Params'                    => 1.004004,
      'Types::Standard'                 => 0,
      'URI'                             => 0,
      'URI::QueryParam'                 => 0,
      'WWW::Google::Cloud::Auth::ServiceAccount' => 0,
      'YAML::Any'                       => 0,
    },
    TEST_REQUIRES     => {
      'Sub::Override'               => 0,
      'Test::Class'                 => 0,
      'Test::Class::Load'           => 0,
      'Test::Deep'                  => 0,
      'Test::Most'                  => 0,
      'Test::Perl::Critic'          => 0,
      'Perl::Critic::TooMuchCode'   => 0,
    },
    EXE_FILES         => [qw(bin/google_restapi_oauth_token_creator)],
    META_MERGE        => {
      "meta-spec" => { version => 2 },
      resources   => {
        repository => {
          type => 'git',
          url  => 'https://github.com/mvsjes2/p5-google-restapi.git',
          web  => 'https://github.com/mvsjes2/p5-google-restapi',
        },
      },
    },
    LICENSE           => 'perl',
);
