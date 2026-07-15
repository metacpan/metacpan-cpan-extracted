use Modern::Perl;
use Test2::V1 -ipP;
use Test2::Tools::Compare qw/hash array bag item match end/;
use Test2::Tools::Explain;
use Test2::Tools::JSON;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Path::Tiny;
use Storable qw(dclone);
use Test::DZil;

use Dist::Zilla::Plugin::Codeberg;
my $mock_dist_zilla_plugin_codeberg
   = mock 'Dist::Zilla::Plugin::Codeberg' => (
   override => [
      _build_credentials =>
         sub { return { login => 'bob', token => 'AbC00ToKeN' } },
   ],
   );

my @http_requests;

use HTTP::Tiny;
my $mock_http_tiny = mock 'HTTP::Tiny' => (
   override => [
      request => sub {
         my $self = shift;

         # keep a snapshot: the plugin reuses the same headers hashref
         # across calls, mutating it after this one is captured
         push @http_requests, dclone( [@_] );

         my ( $method, $url ) = @_;
         if ( $url =~ m{/namespaces$} ) {
            return {
               success => 1,
               content => '[{"id":42,"path":"myteam"}]',
            };
         }
         return {
            success => 1,
            content => '{"ssh_url":"git@codeberg.org:bob/My-Stuff.git"}',
         };
      }
   ]
);

my $auth_headers = { 'Authorization' => 'token AbC00ToKeN' };

my @tests = (
   {
      test_name    => 'default config creates a public repo',
      config       => {},
      mint_opts    => {},
      log_messages => [
         q/[Codeberg::Create] Creating new Codeberg repository 'DZT-Sample'/,
         '[Codeberg::Create] Issues are enabled',
         '[Codeberg::Create] Wiki is enabled',
         '[Codeberg::Create] Packages are enabled',
         '[Codeberg::Create] Snippets are enabled',
         '[Codeberg::Create] Merge requests are enabled',
         '[Codeberg::Create] Sending POST https://codeberg.org/api/v1/user/repos',
      ],
      expected_requests => [
         [
            'POST',
            'https://codeberg.org/api/v1/user/repos',
            {
               headers =>
                  { %$auth_headers, 'content-type' => 'application/json' },
               content => json(
                  {
                     name                   => 'DZT-Sample',
                     visibility             => 'public',
                     description            => undef,
                     issues_enabled         => 1,
                     wiki_enabled           => 1,
                     packages_enabled       => 1,
                     snippets_enabled       => 1,
                     merge_requests_enabled => 1,
                  }
               ),
            },
         ],
      ],
   },
   {
      test_name => 'disabled features, private repo, with description',
      config    => {
         public         => 0,
         issues         => 0,
         wiki           => 0,
         packages       => 0,
         snippets       => 0,
         merge_requests => 0,
      },
      mint_opts    => { description => 'A sample dist' },
      log_messages => [
         q/[Codeberg::Create] Creating new Codeberg repository 'DZT-Sample'/,
         '[Codeberg::Create] Issues are disabled',
         '[Codeberg::Create] Wiki is disabled',
         '[Codeberg::Create] Packages are disabled',
         '[Codeberg::Create] Snippets are disabled',
         '[Codeberg::Create] Merge requests are disabled',
         '[Codeberg::Create] Sending POST https://codeberg.org/api/v1/user/repos',
      ],
      expected_requests => [
         [
            'POST',
            'https://codeberg.org/api/v1/user/repos',
            {
               headers =>
                  { %$auth_headers, 'content-type' => 'application/json' },
               content => json(
                  {
                     name                   => 'DZT-Sample',
                     visibility             => 'private',
                     description            => 'A sample dist',
                     issues_enabled         => 0,
                     wiki_enabled           => 0,
                     packages_enabled       => 0,
                     snippets_enabled       => 0,
                     merge_requests_enabled => 0,
                  }
               ),
            },
         ],
      ],
   },
   {
      test_name => 'namespace lookup and templated repo name',
      config    => {
         namespace => 'myteam',
         repo      => '{{ lc $dist->name }}',
      },
      mint_opts    => {},
      log_messages => [
         q/[Codeberg::Create] Creating new Codeberg repository 'dzt-sample'/,
         '[Codeberg::Create] Issues are enabled',
         '[Codeberg::Create] Wiki is enabled',
         '[Codeberg::Create] Packages are enabled',
         '[Codeberg::Create] Snippets are enabled',
         '[Codeberg::Create] Merge requests are enabled',
         '[Codeberg::Create] Sending POST https://codeberg.org/api/v1/user/repos',
      ],
      expected_requests => [
         [
            'GET',
            'https://codeberg.org/api/v1/namespaces',
            { headers => $auth_headers },
         ],
         [
            'POST',
            'https://codeberg.org/api/v1/user/repos',
            {
               headers =>
                  { %$auth_headers, 'content-type' => 'application/json' },
               content => json(
                  {
                     name                   => 'dzt-sample',
                     namespace_id           => 42,
                     visibility             => 'public',
                     description            => undef,
                     issues_enabled         => 1,
                     wiki_enabled           => 1,
                     packages_enabled       => 1,
                     snippets_enabled       => 1,
                     merge_requests_enabled => 1,
                  }
               ),
            },
         ],
      ],
   },
   {
      test_name         => 'declining the prompt skips repo creation',
      config            => { prompt => 1 },
      prompt_response   => 0,
      mint_opts         => {},
      log_messages      => [],
      expected_requests => [],
   },
);

plan( tests => scalar @tests );

foreach my $test (@tests) {
   subtest $test->{test_name} => sub {
      plan( tests => 3 );

      my $tzil = Builder->from_config(
         { dist_root => 'does-not-exist' },
         {
            add_files => {
               path(qw(source dist.ini)) => simple_ini(
                  [ GatherDir          => ],
                  [ 'Codeberg::Create' => $test->{config} ],
               ),
               path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
         },
      );

      $tzil->chrome->logger->set_debug(1);
      $tzil->chrome->set_response_for(
         "Shall I create a Codeberg repository for @{[ $tzil->name ]}?",
         $test->{prompt_response},
      ) if exists $test->{prompt_response};

      @http_requests = ();
      my $plugin = $tzil->plugin_named('Codeberg::Create');

      ok(
         lives {
            $plugin->after_mint(
               { mint_root => $tzil->tempdir, %{ $test->{mint_opts} } } );
         },
         'after_mint proceeds without error'
      ) or note($@);

      is( \@http_requests, $test->{expected_requests},
         'HTTP requests sent as expected' );

      like(
         $tzil->log_messages,
         bag {
            item($_) for @{ $test->{log_messages} };
            end();
         },
         'logged the right things',
      ) or diag explain( $tzil->log_messages );
   }
}

done_testing;
