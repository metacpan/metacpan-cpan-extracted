
use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;
use Path::Tiny qw( path );
use Test::DZil qw( simple_ini Builder );

use lib 't/lib';

# Keepalive
my $builder;

sub make_plugin_metanoindex {
  my $iconfig = shift;
  $builder = Builder->from_config(
    { dist_root => 'invalid' },
    {
      add_files => {
        path('source/dist.ini') => simple_ini(
          [ 'FakePlugin'  => $iconfig->{fakeplugin} ],    #
          [ 'MetaNoIndex' => $iconfig->{noindex} ],       #
        )
      },
    },
  );
  return $builder->plugin_named('FakePlugin');
}

subtest '_try_regen_metadata tests' => sub {
  if ( not defined eval 'use Dist::Zilla::Plugin::MetaNoIndex;1' ) {
    plan skip_all => 'MetaNoIndex subtests invaid without the plugin';

    #return;
  }

  subtest 'empty noindex params' => sub {

    my $plugin = make_plugin_metanoindex( { fakeplugin => {}, noindex => {} } );
    my $metadata = {};
    is( exception { $metadata = $plugin->_try_regen_metadata() }, undef, 'regenerting metadata manually does not fail' );
    is_deeply( $metadata, { no_index => {} }, 'Metadata is empty' );

  };
  subtest 'noindex params arrive' => sub {
    my $plugin = make_plugin_metanoindex( { fakeplugin => {}, noindex => { file => ['foo.pl'] } } );
    my $metadata = {};
    is( exception { $metadata = $plugin->_try_regen_metadata() }, undef, 'regenerting metadata manually does not fail' );
    is_deeply( $metadata, { no_index => { file => ['foo.pl'] } }, 'NoIndex params arrive' );
  };
};

subtest '_apply_meta_noindex tests' => sub {
  if ( not defined eval 'use Dist::Zilla::Plugin::MetaNoIndex;1' ) {
    plan skip_all => 'MetaNoIndex subtests invaid without the plugin';

    #return;
  }

  my $rules = {
    file      => ['foo.pl'],
    dir       => [ 'ignoreme', 'ignoreme/too' ],
    package   => ['Test::YouShouldNot::SeeThis'],
    namespace => ['Test::ThisIsAlso'],
  };
  my ( $normal_plugin, $noindex_plugin );
  is(
    exception {
      $normal_plugin  = make_plugin_metanoindex( { fakeplugin => { meta_noindex => 0 }, noindex => $rules } );
      $noindex_plugin = make_plugin_metanoindex( { fakeplugin => { meta_noindex => 1 }, noindex => $rules } );
    },
    undef,
    'object construction is successful'
  );
  my $example_items;
  is(
    exception {
      require Dist::Zilla::MetaProvides::ProvideRecord;
      $example_items->{A} = Dist::Zilla::MetaProvides::ProvideRecord->new(
        file    => 'foo.pl',
        module  => '_THISDOESNOTMATTER',
        version => 1.0,
        parent  => $normal_plugin,
      );
      $example_items->{B} = Dist::Zilla::MetaProvides::ProvideRecord->new(
        file    => 'bar.pl',
        module  => '_THISDOESNOTMATTER',
        version => 1.0,
        parent  => $normal_plugin,
      );
      $example_items->{C} = Dist::Zilla::MetaProvides::ProvideRecord->new(
        file    => 'ignoreme/quux.pl',
        module  => '_THISDOESNOTMATTER',
        version => 1.0,
        parent  => $normal_plugin,
      );
      $example_items->{D} = Dist::Zilla::MetaProvides::ProvideRecord->new(
        file    => 'dontignoreme/quux.pl',
        module  => '_THISDOESNOTMATTER',
        version => 1.0,
        parent  => $normal_plugin,
      );
      $example_items->{E} = Dist::Zilla::MetaProvides::ProvideRecord->new(
        file    => 'ignoreme/too/quux.pl',
        module  => '_THISDOESNOTMATTER',
        version => 1.0,
        parent  => $normal_plugin,
      );
      $example_items->{F} = Dist::Zilla::MetaProvides::ProvideRecord->new(
        file    => 'dontignoreme/too/quux.pl',
        module  => '_THISDOESNOTMATTER',
        version => 1.0,
        parent  => $normal_plugin,
      );
      $example_items->{G} = Dist::Zilla::MetaProvides::ProvideRecord->new(
        file    => '_THISDOESNOTMATTER',
        module  => 'Test::YouShouldNot::SeeThis',
        version => 1.0,
        parent  => $normal_plugin,
      );
      $example_items->{H} = Dist::Zilla::MetaProvides::ProvideRecord->new(
        file    => '_THISDOESNOTMATTER',
        module  => 'Test::YouShould::SeeThis',
        version => 1.0,
        parent  => $normal_plugin,
      );
      $example_items->{I} = Dist::Zilla::MetaProvides::ProvideRecord->new(
        file    => '_THISDOESNOTMATTER',
        module  => 'Test::YouShouldNot::SeeThis::ActuallyYouShould',
        version => 1.0,
        parent  => $normal_plugin,
      );
      $example_items->{J} = Dist::Zilla::MetaProvides::ProvideRecord->new(
        file    => '_THISDOESNOTMATTER',
        module  => 'Test::ThisIsAlso::Forbidden',
        version => 1.0,
        parent  => $normal_plugin,
      );
      $example_items->{K} = Dist::Zilla::MetaProvides::ProvideRecord->new(
        file    => '_THISDOESNOTMATTER',
        module  => 'Test::ThisIsAlso::ATest',
        version => 1.0,
        parent  => $normal_plugin,
      );
      $example_items->{L} = Dist::Zilla::MetaProvides::ProvideRecord->new(
        file    => '_THISDOESNOTMATTER',
        module  => 'Test::ThisIsAlso',     # Should not be excluded by namespace rule
        version => 1.0,
        parent  => $normal_plugin,
      );

    },
    undef,
    'Test item construction does not die in a fire'
  );
  my %items = %{$example_items};
  is_deeply(
    [ $normal_plugin->_apply_meta_noindex( @items{qw( A B C D E F G H I J K L )} ) ],
    [ @items{qw( A B C D E F G H I J K L )} ],
    'Normal ignorance works still'
  );
  is_deeply(
    [ $noindex_plugin->_apply_meta_noindex( @items{qw( A B C D E F G H I J K L )} ) ],
    [ @items{qw( B D F H I L )} ],
    'NoIndex Filtering application works'
  );
};

done_testing;
