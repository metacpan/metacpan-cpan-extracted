use strict;
use warnings;
use Path::Tiny;
use lib 't/lib';
use Test::More;
use Test::Raider::Env qw( isolate_home );
isolate_home();
use Langertha::Raider::CLI;  # populates $INC for pack discovery
use Langertha::Raider::Packs;
use YAML::PP;

subtest 'build_packs discovers share/packs' => sub {
  my $root = path('share')->absolute;
  my $coll = Langertha::Raider::Packs::build_packs(root => $root);

  my @packs = @{$coll->all_pack_names};

  ok(scalar(@packs) > 0, 'found at least one pack');
  ok($coll->is_active('caveman'), 'caveman enabled by default');
  ok(!$coll->is_active('git-guru'), 'git-guru not enabled by default');
};

subtest 'exclusive_group enforcement' => sub {
  my $root = path('share')->absolute;
  my $coll = Langertha::Raider::Packs::build_packs(root => $root);

  is_deeply([sort @{$coll->enabled_pack_names}], [sort qw(caveman)],
    'caveman is default and exclusive');

  $coll->enable('polite');
  ok(!$coll->is_active('caveman'), 'caveman disabled after enabling polite');
  ok($coll->is_active('polite'), 'polite now active');
  ok(!$coll->is_active('teacher'), 'teacher still off');

  $coll->enable('teacher');
  ok(!$coll->is_active('polite'), 'polite disabled after enabling teacher');
  ok($coll->is_active('teacher'), 'teacher now active');
};

subtest 'power packs stack' => sub {
  my $root = path('share')->absolute;
  my $coll = Langertha::Raider::Packs::build_packs(root => $root);

  $coll->enable('git-guru');
  ok($coll->is_active('caveman'), 'caveman still active');
  ok($coll->is_active('git-guru'), 'git-guru now active');

  $coll->enable('testing-fu');
  ok($coll->is_active('caveman'), 'caveman still active');
  ok($coll->is_active('git-guru'), 'git-guru still active');
  ok($coll->is_active('testing-fu'), 'testing-fu now active');
};

subtest 'toggle behavior' => sub {
  my $root = path('share')->absolute;
  my $coll = Langertha::Raider::Packs::build_packs(root => $root);

  $coll->toggle('git-guru');
  ok($coll->is_active('git-guru'), 'git-guru toggled on');

  $coll->toggle('git-guru');
  ok(!$coll->is_active('git-guru'), 'git-guru toggled off');
};

subtest 'disable removes from enabled list' => sub {
  my $root = path('share')->absolute;
  my $coll = Langertha::Raider::Packs::build_packs(root => $root);

  $coll->enable('git-guru');
  $coll->disable('caveman');

  ok(!$coll->is_active('caveman'), 'caveman disabled');
  ok($coll->is_active('git-guru'), 'git-guru still active');
};

subtest 'pack_info returns correct structure' => sub {
  my $root = path('share')->absolute;
  my $coll = Langertha::Raider::Packs::build_packs(root => $root);

  my $info = $coll->pack_info('caveman');
  ok($info, 'pack_info returned something');
  is($info->{name}, 'caveman', 'name correct');
  is($info->{exclusive_group}, 'persona', 'exclusive_group correct');
  ok($info->{is_active}, 'is_active true for default pack');
  ok($info->{has_skill_text}, 'caveman has skill text');
};

subtest 'skill_texts concatenates enabled pack texts' => sub {
  my $root = path('share')->absolute;
  my $coll = Langertha::Raider::Packs::build_packs(root => $root);

  $coll->enable('git-guru');
  my @texts = $coll->skill_texts;

  ok(scalar(@texts) >= 1, 'got at least one skill text');
  my $combined = join("\n", @texts);
  like($combined, qr/Pack: caveman/, 'caveman text present');
  like($combined, qr/Pack: git-guru/, 'git-guru text present');
};

subtest 'unknown pack name returns undef from pack_info' => sub {
  my $root = path('share')->absolute;
  my $coll = Langertha::Raider::Packs::build_packs(root => $root);

  ok(!defined($coll->pack_info('nonexistent')), 'pack_info returns undef for unknown');
  $coll->enable('nonexistent');  # should be no-op
};

subtest 'a pack without SKILL.md loads' => sub {
  my $dir = Path::Tiny->tempdir;
  $dir->child('bare')->mkpath;
  $dir->child('bare', 'pack.yml')->spew_utf8("exclusive_group: power\n");
  local $ENV{RAIDER_PACK_DIRS} = "$dir";

  my $coll = eval { Langertha::Raider::Packs::build_packs(root => path('share')->absolute) };
  ok($coll, 'build_packs survives a pack without SKILL.md') or return diag($@);
  my $pack = $coll->packs_by_name->{bare};
  ok($pack && !$pack->has_skill_text, 'bare pack loaded without skill text');

  $coll->enable('bare');
  ok($coll->is_active('bare'), 'bare pack can be enabled');
  unlike(join("\n", $coll->skill_texts), qr/Pack: bare/, 'no skill text contributed');
};

subtest 'shipped pack.yml files use only keys the loader reads (k104)' => sub {
  my %known = map { $_ => 1 } qw( exclusive_group enabled_by_default tools detect );
  for my $yml (sort { "$a" cmp "$b" } path('share/packs')->children) {
    $yml = $yml->child('pack.yml');
    next unless -f $yml;
    my $config = YAML::PP->new->load_string($yml->slurp_utf8) // {};
    is_deeply([ grep { !$known{$_} } sort keys %$config ], [],
      $yml->parent->basename.': no ignored keys');
  }
  my $coll = Langertha::Raider::Packs::build_packs(root => path('share')->absolute);
  is($coll->packs_by_name->{'git-guru'}->exclusive_group, 'power', 'git-guru stays a power pack');
};

done_testing;