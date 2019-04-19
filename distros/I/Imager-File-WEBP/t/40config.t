#!perl -w
use strict;
use Test::More;

use Imager::File::WEBP;
use Imager::Test qw(test_image is_image_similar is_image);

my $im = test_image;

{
  my $cfg = Imager::File::WEBP::Config->new($im);
  ok($cfg, "make a default config");
  my $clone = $cfg->clone;
  ok($clone, "cloned it");
}
pass("hopefully destroyed it");

{
  my $cfg = Imager::File::WEBP::Config->new($im);
  ok($cfg->target_size(100_000), "set target_size");
  is($cfg->target_size, 100_000, "check target_size");
  ok(!$cfg->target_size(-1), "try a bad target_size");
  is($cfg->target_size, 100_000, "check target_size wasn't changed");

  ok($cfg->quality(50.5), "set quality")
    or diag(Imager->_error_as_msg);
  is($cfg->quality, 50.5, "check quality");
  ok(!$cfg->quality(101), "try a bad quality");
  is($cfg->quality, 50.5, "check quality wasn't changed");

  ok($cfg->image_hint("picture"), "set hint to picture");
  is($cfg->image_hint, "picture", "check it was set");
  ok(!$cfg->image_hint("xx"), "set hint to bad value");
  is($cfg->image_hint, "picture", "check hint wasn't changed");

  my $im = test_image();
  ok($im->settag(name => "webp_quality", value => 90.5),
     "set quality on check image");
  ok($cfg->update($im), "update from new image");
  is($cfg->quality, 90.5, "check update worked");
}

{
  my $cfgim = test_image();
  $cfgim->settag(name => "webp_mode", value => "lossless");
  my $cfg = Imager::File::WEBP::Config->new($cfgim);
  ok($cfg, "made a config object asking for lossless");
  my $data;
  my $im = test_image();
  ok($im->write(data => \$data, type => "webp", webp_config => $cfg),
     "write with config data")
    or diag $im->errstr;
  my $cmpim = Imager->new;
  ok($cmpim->read(data => \$data, type => "webp"),
     "read it back in ")
    or diag $im->errstr;
  is_image($cmpim, $im, "check it really was lossless");
}

{
  my $cfg = Imager::File::WEBP::Config->new(webp_mode => "lossless");
  ok($cfg, "made a config object asking for lossless (no config image visible)");
  my $data;
  my $im = test_image();
  ok($im->write(data => \$data, type => "webp", webp_config => $cfg),
     "write with config data")
    or diag $im->errstr;
  my $cmpim = Imager->new;
  ok($cmpim->read(data => \$data, type => "webp"),
     "read it back in ")
    or diag $im->errstr;
  is_image($cmpim, $im, "check it really was lossless");
}

{
  my $cfg = Imager::File::WEBP::Config->new(webp_mode => "lossless");
  ok($cfg, "made a config object asking for lossless (no config image visible)");
  my $data;
  my $im = test_image();
  ok(Imager->write_multi({data => \$data, type => "webp", webp_config => $cfg}, $im, $im),
     "write multi with config data")
    or diag $im->errstr;
  my $cmpim = Imager->new;
  ok($cmpim->read(data => \$data, type => "webp"),
     "read it back in ")
    or diag $im->errstr;
  is_image($cmpim, $im, "check it really was lossless");
}

{
  # name, min abi, good value, bad value
  # bad value can be undef
  # ordered by the WebPConfig member order
  my @tests =
    (
     [ "quality",           0,     80,      101 ],
     [ "method",            0,     5,       100 ],
     [ "image_hint",        0,     "photo", "unknown" ],
     [ "target_size",       0,     100_000, -1 ],
     [ "target_psnr",       0,     5,       -1 ],
     [ "segments",          0,     1,       100 ],
     [ "sns_strength",      0,     1,       -1 ],
     [ "filter_strength",   0,     80,      101 ],
     [ "filter_sharpness",  0,     5,       100 ],
     [ "filter_type",       0,     1,       -1 ],
     [ "autofilter",        0,     1,       100 ],
     [ "alpha_compression", 0,     0,       -1 ],
     [ "alpha_filtering",   0,     2,       10 ],
     [ "pass",              0,     5,       100 ],
     [ "preprocessing",     0,     1,       100 ],
     [ "partitions",        0,     3,       5 ],
     [ "partition_limit",   0,     5,       101 ],
     [ "emulate_jpeg_size", 0x200, 1,       100 ],
     [ "thread_level",      0x201, 1,       -1 ],
     [ "low_memory",        0x201, 1,       -1 ],
     [ "near_lossless",     0x205, 1,       -1 ],
     [ "exact",             0x209, 1,       -1 ],
     [ "use_sharp_yuv",     0x20e, 1,       -1 ],
    );

  my $cfg = Imager::File::WEBP::Config->new;
  my $abiversion = Imager::File::WEBP::encode_abi_version();
  for my $test (@tests) {
    my ($name, $minabi, $good, $bad) = @$test;

    can_ok($cfg, $name);
    if ($abiversion >= $minabi) {
      ok($cfg->$name($good), "can set $name to $good");
      is($cfg->$name(), $good, "and got the value of $name back");
      ok(!$cfg->$name($bad), "cannot set $name to $bad")
	if defined $bad;
    }
    else {
      is($cfg->$name(), undef, "always fails for old abi");
    }
  }
}

done_testing();
