use Modern::Perl;
use Test2::V0;
use Test2::Tools::Compare qw/hash array bag match/;
use Test2::Tools::Explain;
use Test2::Tools::JSON;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Path::Tiny;
use Test::DZil;

use Dist::Zilla::Plugin::GitLab;
my $mock_dist_zilla_plugin_gitlab = mock 'Dist::Zilla::Plugin::GitLab' => (
   override => [
      _build_credentials =>
         sub { return { login => 'bob', token => 'AbC00ToKeN' } },
      _get_repo_name => sub { return 'bob/My-Stuff' },
   ],
);

my $http_request;

use HTTP::Tiny;
my $mock_http_tiny = mock 'HTTP::Tiny' => (
   override => [
      request => sub {
         my $self = shift;
         $http_request = \@_;
         return +{
            success => 1,
            content => '{}',
         };
      }
   ]
);

# TODO Add more tests here
#  - no update needed

my @tests = (
   {
      test_name    => 'update needed',
      config       => { remote => 'origin' },
      log_messages => [
         '[GitLab::Update] Updating GitLab repository info',
         '[GitLab::Update] Sending GET https://gitlab.com/api/v4/projects/bob%2FMy-Stuff',
         '[GitLab::Update] Sending PUT https://gitlab.com/api/v4/projects/bob%2FMy-Stuff'
      ],
      errors           => match(qr/Error:/),
      expected_request => [
         'PUT',
         'https://gitlab.com/api/v4/projects/bob%2FMy-Stuff',
         {
            headers => {
               'content-type'  => 'application/json',
               'PRIVATE-TOKEN' => 'AbC00ToKeN',
            },
            content => json(
               {
                  name        => 'My-Stuff',
                  description => 'Sample DZ Dist',
               }
            ),
         },
      ],
   },
);

plan( tests => scalar @tests );

foreach my $test (@tests) {
   subtest $test->{test_name} => sub {
      plan( tests => 5 );

      my $tzil = Builder->from_config(
         { dist_root => 'does-not-exist' },
         {
            add_files => {
               path(qw(source dist.ini)) => simple_ini(
                  [ GatherDir        => ],
                  [ MetaConfig       => ],
                  [ FakeRelease      => ],
                  [ 'GitLab::Update' => $test->{config} ],
               ),
               path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
         },
      );

      $tzil->chrome->logger->set_debug(1);
      ok( lives { $tzil->release }, 'release proceeds without error' )
         or note($@);
      is( $http_request, $test->{expected_request},
         'HTTP request sent as requested', );

      like(
         $tzil->distmeta,
         hash {
            x_Dist_Zilla => {
               plugins => bag {
                  item => {
                     class  => 'Dist::Zilla::Plugin::GitLab::Update',
                     config => {
                        'Dist::Zilla::Plugin::GitLab::Update' =>
                           $test->{config},
                     },
                     name => 'GitLab::Update',
                  }
               },
            },
         },
         'configs are logged',
      ) or diag explain( $tzil->distmeta );

      like( $tzil->log_messages, bag { $test->{log_messages} },
         'logged the right things', );
      unlike(
         $tzil->log_messages,
         bag { all_items( match(qr/Error: /) ) },
         'no errors were spotted'
      );
   }
}

done_testing;
