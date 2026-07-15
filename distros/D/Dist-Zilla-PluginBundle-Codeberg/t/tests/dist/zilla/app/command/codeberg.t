use Modern::Perl;
use Test2::V1 -ipP;
use Test2::Tools::Compare qw/hash array bag item match end/;
use Test2::Tools::Explain;
use Test2::Tools::JSON;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Path::Tiny;
use Storable   qw(dclone);
use Test::DZil qw(simple_ini);
use Dist::Zilla::App::Tester;

use Dist::Zilla::App::Command::codeberg;
use Dist::Zilla::Plugin::Codeberg;
my $mock_dist_zilla_plugin_codeberg
   = mock 'Dist::Zilla::Plugin::Codeberg' => (
   override => [
      _build_credentials =>
         sub { return { login => 'bob', token => 'AbC00ToKeN' } },
      _get_repo_name => sub { return 'bob/DZT-Sample' },
   ],
   );

my @http_requests;

use HTTP::Tiny;
my $mock_http_tiny = mock 'HTTP::Tiny' => (
   override => [
      request => sub {
         my $self = shift;
         push @http_requests, dclone( [@_] );
         return { success => 1, content => '{}' };
      }
   ]
);

# a stand-in for the minter built from a real profile, so 'create' can be
# tested without needing an actual Codeberg::Create-enabled minting profile
# installed on the system
{

   package Test::Codeberg::FakeCreatePlugin;

   sub new {
      my $class = shift;
      return bless { after_mint_calls => [], @_ }, $class;
   }
   sub plugin_name { return 'Codeberg::Create' }

   sub after_mint {
      my ( $self, $opts ) = @_;
      push @{ $self->{after_mint_calls} }, $opts;
      return;
   }
}
{

   package Test::Codeberg::FakeMinter;
   sub new     { my $class = shift; return bless {@_}, $class }
   sub plugins { return $_[0]->{plugins} }
}

sub write_source_dist {
   my $dir = Path::Tiny->tempdir;
   $dir->child('dist.ini')->spew_utf8(
      simple_ini(
         [ GatherDir          => ],
         [ 'Codeberg::Update' => {} ],
      )
   );
   $dir->child('lib')->mkpath;
   $dir->child( 'lib', 'Foo.pm' )->spew_utf8("package Foo;\n1;\n");
   return $dir;
}

subtest 'command metadata' => sub {
   plan( tests => 3 );

   is(
      Dist::Zilla::App::Command::codeberg->abstract,
      'use the Codeberg plugins from the command-line',
      'abstract'
   );
   is(
      Dist::Zilla::App::Command::codeberg->usage_desc,
      '%c %o [ update | create [<repository>] ]',
      'usage_desc'
   );

   my %opt_spec = map { $_->[0] => $_->[2]{default} }
      Dist::Zilla::App::Command::codeberg->opt_spec;
   is(
      \%opt_spec,
      { 'profile|p=s' => 'default', 'provider|P=s' => 'Default' },
      'profile/provider option defaults',
   );
};

subtest 'dzil codeberg update' => sub {
   plan( tests => 3 );

   @http_requests = ();
   my $dir    = write_source_dist();
   my $result = test_dzil( "$dir", [ 'codeberg', 'update' ] );

   is( $result->error, undef, 'command ran without error' )
      or diag $result->error;

   is(
      \@http_requests,
      [
         [ 'GET', 'https://codeberg.org/api/v1/repos/bob/DZT-Sample' ],
         [
            'PATCH',
            'https://codeberg.org/api/v1/repos/bob/DZT-Sample',
            {
               headers => {
                  'Authorization' => 'token AbC00ToKeN',
                  'content-type'  => 'application/json',
               },
               content => json(
                  { description => 'Sample DZ Dist', name => 'DZT-Sample' }
               ),
            },
         ],
      ],
      'the Codeberg::Update plugin sent the expected HTTP requests',
   ) or diag explain( \@http_requests );

   like(
      $result->log_messages,
      bag { item('[Codeberg::Update] Updating Codeberg repository info') },
      'logged the update',
   ) or diag explain( $result->log_messages );
};

subtest 'dzil codeberg create' => sub {
   plan( tests => 3 );

   my $fake_plugin = Test::Codeberg::FakeCreatePlugin->new;
   my $fake_minter
      = Test::Codeberg::FakeMinter->new( plugins => [$fake_plugin] );
   my @minter_calls;

   use Dist::Zilla::Dist::Minter;
   my $mock_minter = mock 'Dist::Zilla::Dist::Minter' => (
      override => [
         _new_from_profile => sub {
            my ( undef, $profile_data, $arg ) = @_;
            push @minter_calls,
               {
               provider => $profile_data->[0],
               profile  => $profile_data->[1],
               name     => $arg->{name},
               };
            return $fake_minter;
         },
      ],
   );

   my $dir    = write_source_dist();
   my $result = test_dzil(
      "$dir",
      [
         'codeberg', '--profile', 'custom', '--provider', 'MyProvider',
         'create',   'myrepo'
      ],
   );

   is( $result->error, undef, 'command ran without error' )
      or diag $result->error;

   is(
      \@minter_calls,
      [
         {
            provider => 'MyProvider', profile => 'custom',
            name     => 'DZT-Sample'
         }
      ],
      'the minter was built with the requested profile/provider and dist name',
   );

   is(
      $fake_plugin->{after_mint_calls},
      [
         {
            mint_root => path( $result->tempdir )->child('source')->stringify,
            repo      => 'myrepo',
            description => 'Sample DZ Dist',
         },
      ],
      'the Codeberg::Create plugin was invoked with the mint root, repo, and description',
   ) or diag explain( $fake_plugin->{after_mint_calls} );
};

done_testing;
