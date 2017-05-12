use Test::More tests=> 40;
use lib qw( ../lib ./lib );
use Egg::Helper;

my $e= Egg::Helper->run( Vtest=> {
  vtest_plugins=> [qw/ Banner::Rotate /],
  } );

$e->helper_create_file($e->helper_yaml_load(join '', <DATA>));

isa_ok $e, 'Egg::Plugin::Banner::Rotate';

can_ok $e, 'banner_rotate';
  ok my $br= $e->banner_rotate, q{my $br= $e->banner_rotate};

isa_ok $br, 'Egg::Plugin::Banner::Rotate::handler';

can_ok $br, 'param';
  ok $br->param('base_dir'), q{$br->param('base_dir')};
  is $br->param('extention'), 'yaml', q{$br->param('extention'), yaml};

can_ok $br, 'banners';
  ok my $banner= $br->banners('hoge'), q{my $banner= $br->banners('hoge')};
  isa_ok $banner, 'HASH';
  is $banner->{num}, 0, q{$banner->{num}, 0};
  like $banner->{time}, qr{^\d+$}, q{$banner->{time}, qr{^\d+$}};
  is $banner->{total}, 3, q{$banner->{total}, 3};
  ok $banner->{banners}, q{$banner->{banners}};
  isa_ok $banner->{banners}, 'ARRAY';
  sleep 2;
  ok $start_time= $banner->{time}, q{$start_time= $banner->{time}};
  is $br->banners('hoge')->{time}, $start_time, q{$br->banners('hoge')->{time}, $start_time};

can_ok $br, 'get_random';
  ok my $data= $br->get_random('hoge'), q{my $data= $br->get_random('hoge')};
  isa_ok $data, 'HASH';
  ok $data->{url}, q{$data->{url}};
  ok $data->{name}, q{$data->{name}};

can_ok $br, 'get_turns';
  ok $data= $br->get_turns('hoge'), q{$data= $br->get_turns('hoge')};
  isa_ok $data, 'HASH';
  ok $data->{url}, q{$data->{url}};
  ok $data->{name}, q{$data->{name}};
  is $banner->{num}, 1, q{$banner->{num}, 1};
  ok my $data2= $br->get_turns('hoge'), q{$data= $br->get_turns('hoge')};
  isa_ok $data2, 'HASH';
  ok $data2->{url}, q{$data2->{url}};
  ok $data2->{name}, q{$data2->{name}};
  ok $data->{url} ne $data2->{url}, q{$data->{url} ne $data2->{url}};
  ok $data->{name} ne $data2->{name}, q{$data->{name} ne $data2->{name}};
  is $banner->{num}, 2, q{$banner->{num}, 2};

can_ok $br, 'clear_cache';
  ok $br->clear_cache('hoge'), q{$br->clear_cache('hoge')};
  ok $banner= $br->banners('hoge'), q{$banner= $br->banners('hoge')};
  is $banner->{num}, 0, q{$banner->{num}, 0};
  ok $banner->{time} ne $start_time, q{$banner->{time} ne $start_time};


__DATA__
filename: etc/banners/hoge.yaml
value: |
  ---
  url: http://banner/01
  name: banner1
  ---
  url: http://banner/02
  name: banner2
  ---
  url: http://banner/03
  name: banner3
