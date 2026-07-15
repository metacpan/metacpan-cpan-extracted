use Modern::Perl;
use Test2::V1 -ipP;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Path::Tiny;
use Test::DZil;

my @tests = (
   {
      test_name => 'defaults',
      config    => { repo => 'SomeRepo' },
      expect    => {
         bugs      => 1,
         fork      => 1,
         p3rl      => 0,
         metacpan  => 0,
         meta_home => 0,
         remote    => 'origin',
         wiki      => 0,
         repo      => 'SomeRepo',
      },
   },
   {
      test_name => 'all options overridden',
      config    => {
         repo      => 'someuser/SomeRepo',
         bugs      => 0,
         fork      => 0,
         p3rl      => 1,
         metacpan  => 1,
         meta_home => 1,
         remote    => 'upstream',
         wiki      => 1,
      },
      expect => {
         bugs      => 0,
         fork      => 0,
         p3rl      => 1,
         metacpan  => 1,
         meta_home => 1,
         remote    => 'upstream',
         wiki      => 1,
         repo      => 'someuser/SomeRepo',
      },
   },
   {
      test_name => 'repo left unset',
      config    => {},
      expect    => {
         bugs      => 1,
         fork      => 1,
         p3rl      => 0,
         metacpan  => 0,
         meta_home => 0,
         remote    => 'origin',
         wiki      => 0,
         repo      => undef,
      },
   },
);

plan( tests => scalar @tests );

foreach my $test (@tests) {
   subtest $test->{test_name} => sub {
      my $tzil = Builder->from_config(
         { dist_root => 'does-not-exist' },
         {
            add_files => {
               path(qw(source dist.ini)) => simple_ini(
                  [ GatherDir   => ],
                  [ '@Codeberg' => $test->{config} ],
               ),
               path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            },
         },
      );

      my $meta_plugin   = $tzil->plugin_named('@Codeberg/Codeberg::Meta');
      my $update_plugin = $tzil->plugin_named('@Codeberg/Codeberg::Update');

      isa_ok( $meta_plugin,   ['Dist::Zilla::Plugin::Codeberg::Meta'] );
      isa_ok( $update_plugin, ['Dist::Zilla::Plugin::Codeberg::Update'] );

      for my $attr (qw(bugs fork p3rl metacpan meta_home remote wiki repo)) {
         is( $meta_plugin->$attr, $test->{expect}{$attr},
            "Codeberg::Meta $attr" );
      }

      is( $update_plugin->repo, $test->{expect}{repo},
         'Codeberg::Update repo' );

      done_testing;
   }
}

done_testing;
