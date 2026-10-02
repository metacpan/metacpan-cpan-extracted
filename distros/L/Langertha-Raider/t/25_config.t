use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use File::Temp qw( tempdir );
use Path::Tiny;
use YAML::PP ();

use Langertha::Raider::CLI;
use Langertha::Raider::Skill;

subtest 'app yml keys are not engine options' => sub {
  my $dir = tempdir(CLEANUP => 1);
  path($dir)->child('.raider.yml')->spew_utf8(YAML::PP->new->dump_string({
    skills => ['openai'],
    packs => ['git-guru'],
    perl => 1,
    preferred_lib_target => '.raider/lib',
    default => {
      temperature => 0.2,
    },
  }));

  my $app = Langertha::Raider::CLI->new(root => $dir, engine => 'openai', api_key => 'test', model => 'gpt-4o-mini');
  my $opts = $app->_engine_yml_options;
  is_deeply($opts, { temperature => 0.2 }, 'only engine options survive');
};

subtest 'skill export uses accessors for lazy attributes' => sub {
  my $dir = tempdir(CLEANUP => 1);
  my $app = Langertha::Raider::CLI->new(root => $dir, engine => 'openai', api_key => 'test', model => 'gpt-4o-mini');
  my $md = Langertha::Raider::Skill->new(app => $app)->markdown;
  like($md, qr/Engine: \*\*openai\*\*/, 'engine rendered from accessor');
  like($md, qr/Working root: `\Q$dir\E`/, 'root rendered from accessor');
};

subtest 'explicit pack names override yml without writing config' => sub {
  my $dir = tempdir(CLEANUP => 1);
  my $file = path($dir)->child('.raider.yml');
  $file->spew_utf8(YAML::PP->new->dump_string({ packs => ['polite'] }));

  my $app = Langertha::Raider::CLI->new(
    root => $dir,
    engine => 'openai',
    api_key => 'test',
    model => 'gpt-4o-mini',
    pack_names => ['git-guru'],
  );

  ok($app->packs->is_active('git-guru'), 'explicit pack active');
  ok(!$app->packs->is_active('polite'), 'yml pack ignored when explicit pack_names set');
  like($file->slurp_utf8, qr/polite/, 'config file left untouched');
};

done_testing;
