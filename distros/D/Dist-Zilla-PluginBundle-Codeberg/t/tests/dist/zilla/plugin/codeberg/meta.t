use Modern::Perl;
use Test2::V1 -ipP;
use Test2::Tools::Compare qw/hash array bag item match end/;
use Test2::Tools::Explain;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Path::Tiny;
use Test::DZil;

use Dist::Zilla::Plugin::Codeberg;
my $mock_dist_zilla_plugin_codeberg
   = mock 'Dist::Zilla::Plugin::Codeberg' => (
   override => [
      _build_credentials =>
         sub { return { login => 'bob', token => 'AbC00ToKeN' } },
      _get_repo_name => sub { return 'bob/DZT-Sample' },
   ],
   );

my @http_responses;

use HTTP::Tiny;
my $mock_http_tiny = mock 'HTTP::Tiny' => (
   override => [
      request => sub {
         shift;
         return shift(@http_responses) // { success => 1, content => '{}' };
      }
   ]
);

my $repo_response
   = '{'
   . '"html_url":"https://codeberg.org/bob/DZT-Sample",'
   . '"ssh_url":"git@codeberg.org:bob/DZT-Sample.git",'
   . '"has_issues":true' . '}';

my @tests = (
   {
      test_name =>
         'default config fetches repo info and sets metacpan homepage',
      config    => {},
      responses => [ { success => 1, content => $repo_response } ],
      expect    => {
         resources => {
            repository => {
               web  => 'https://codeberg.org/bob/DZT-Sample',
               url  => 'git@codeberg.org:bob/DZT-Sample.git',
               type => 'git',
            },
            homepage   => 'https://metacpan.org/release/DZT-Sample/',
            bugtracker =>
               { web => 'https://codeberg.org/bob/DZT-Sample/issues' },
         },
      },
      log_messages => ['[Codeberg::Meta] Getting Codeberg repository info'],
   },
   {
      test_name =>
         'bugs disabled skips bugtracker even when issues are enabled',
      config    => { bugs => 0 },
      responses => [ { success => 1, content => $repo_response } ],
      expect    => {
         resources => {
            repository => {
               web  => 'https://codeberg.org/bob/DZT-Sample',
               url  => 'git@codeberg.org:bob/DZT-Sample.git',
               type => 'git',
            },
            homepage => 'https://metacpan.org/release/DZT-Sample/',
         },
      },
      log_messages => ['[Codeberg::Meta] Getting Codeberg repository info'],
   },
   {
      test_name => 'p3rl homepage is used instead of metacpan when requested',
      config    => { metacpan => 0, p3rl => 1 },
      responses => [
         {
            success => 1,
            content => '{"html_url":"https://codeberg.org/bob/DZT-Sample",'
               . '"ssh_url":"git@codeberg.org:bob/DZT-Sample.git","has_issues":false}',
         },
      ],
      expect => {
         resources => {
            repository => {
               web  => 'https://codeberg.org/bob/DZT-Sample',
               url  => 'git@codeberg.org:bob/DZT-Sample.git',
               type => 'git',
            },
            homepage => 'https://p3rl.org/DZT::Sample',
         },
      },
      log_messages => ['[Codeberg::Meta] Getting Codeberg repository info'],
   },
   {
      test_name => 'a fork pulls repository info from the upstream project',
      config    => { fork => 1 },
      responses => [
         {
            success => 1,
            content => '{"html_url":"https://codeberg.org/bob/DZT-Sample",'
               . '"ssh_url":"git@codeberg.org:bob/DZT-Sample.git","has_issues":true,'
               . '"forked_from_project":{"path_with_namespace":"upstream/Orig"}}',
         },
         {
            success => 1,
            content => '{"html_url":"https://codeberg.org/upstream/Orig",'
               . '"ssh_url":"git@codeberg.org:upstream/Orig.git","has_issues":true}',
         },
      ],
      expect => {
         resources => {
            repository => {
               web  => 'https://codeberg.org/upstream/Orig',
               url  => 'git@codeberg.org:upstream/Orig.git',
               type => 'git',
            },
            homepage   => 'https://metacpan.org/release/DZT-Sample/',
            bugtracker =>
               { web => 'https://codeberg.org/upstream/Orig/issues' },
         },
      },
      log_messages => ['[Codeberg::Meta] Getting Codeberg repository info'],
   },
   {
      test_name => 'network failure falls back to offline repository info',
      config    => {},
      responses => [
         {
            success => 0, status => 404, content => '{"message":"not found"}'
         }
      ],
      expect => {
         resources => {
            repository => {
               web  => 'https://codeberg.org/bob/DZT-Sample',
               url  => 'git://git@codeberg.org/bob/DZT-Sample.git',
               type => 'git',
            },
            homepage => 'https://metacpan.org/release/DZT-Sample/',
         },
      },
      log_messages => [
         '[Codeberg::Meta] Getting Codeberg repository info',
         match(qr/^\[Codeberg::Meta\] Err: /),
         '[Codeberg::Meta] Using offline repository information',
      ],
   },
);

plan( tests => scalar @tests );

foreach my $test (@tests) {
   subtest $test->{test_name} => sub {
      plan( tests => 2 );

      my $tzil = Builder->from_config(
         { dist_root => 'does-not-exist' },
         {
            add_files => {
               path(qw(source dist.ini)) => simple_ini(
                  [ GatherDir        => ],
                  [ 'Codeberg::Meta' => $test->{config} ],
               ),
               path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
         },
      );

      @http_responses = @{ $test->{responses} };
      my $plugin = $tzil->plugin_named('Codeberg::Meta');
      my $meta   = $plugin->metadata;

      is( $meta, $test->{expect}, 'metadata built as expected' )
         or diag explain($meta);

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
