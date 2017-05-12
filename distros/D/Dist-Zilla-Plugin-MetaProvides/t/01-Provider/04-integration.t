
use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;
use Path::Tiny qw( path );
use Test::DZil qw( simple_ini Builder );

use lib 't/lib';

subtest "missing-meta-noindex" => sub {
  my $builder = Builder->from_config(
    {
      dist_root => 'invalid',
    },
    {
      add_files => {
        path('source/dist.ini') => simple_ini( 'GatherDir', [ 'FakePlugin' => { meta_noindex => 1 } ] ),
      },
    }
  );
  $builder->chrome->logger->set_debug(1);
  my $plugin = $builder->plugin_named('FakePlugin');

  my $meta = $plugin->metadata;
  ok( grep { /No no_index attribute/ } @{ $builder->log_messages } );
  is_deeply(
    $meta,
    { provides => { 'FakeModule' => { file => 'C:\temp\notevenonwindows.pl', version => '0.001' } } },
    'Top level metadata hash returns deep result'
  );

};

# Keepalive
subtest "empty-meta-noindex" => sub {
  {

    package Dist::Zilla::Plugin::Fake::MetaNoIndex;
    use Moose;
    with 'Dist::Zilla::Role::MetaProvider';
    around isa => sub {
      my ( $orig, $class, $hwhat ) = @_;
      return 1 if $hwhat eq 'Dist::Zilla::Plugin::MetaNoIndex';
      return $class->$orig($hwhat);
    };

    sub metadata {
      return { 'x_this_key_not_relevant' => 1 };
    }
    $INC{'Dist/Zilla/Plugin/Fake/MetaNoIndex.pm'} = 1;
  }
  my $builder = Builder->from_config(
    {
      dist_root => 'invalid',
    },
    {
      add_files => {
        path('source/dist.ini') => simple_ini( 'GatherDir', [ 'FakePlugin' => { meta_noindex => 1 } ], ['Fake::MetaNoIndex'] ),
      },
    }
  );
  $builder->chrome->logger->set_debug(1);
  my $plugin = $builder->plugin_named('FakePlugin');

  my $meta = $plugin->metadata;
  ok( grep { /No no_index attribute/ } @{ $builder->log_messages }, "Got meta-no-index warning" );
  is_deeply(
    $meta,
    { provides => { 'FakeModule' => { file => 'C:\temp\notevenonwindows.pl', version => '0.001' } } },
    'Top level metadata hash returns deep result'
  );

};

done_testing;
