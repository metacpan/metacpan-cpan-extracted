use strict;
use warnings;
use Test2::V0;
use lib 't/lib';
use Test::Raider::Env qw( isolate_home );
isolate_home();
use File::Temp qw( tempdir );
use Path::Tiny;
use Langertha::Raider::CLI;

# /reload and /pack call reload_mission: it must keep a mission passed with
# -M as the instructions item (ADR 0014), and swap the mission of the
# running raider without losing its history.

sub app {
  my ( %args ) = @_;
  return Langertha::Raider::CLI->new(
    root    => tempdir(CLEANUP => 1),
    engine  => 'openai',
    api_key => 'test',
    trace   => 0,
    %args,
  );
}

subtest '-M mission survives reload' => sub {
  my $app = app(mission => 'You are the flag mission.');
  like($app->raider->mission, qr/\AYou are the flag mission\./, 'raider starts with -M');
  path($app->root)->child('.raider.md')->spew_utf8("Custom persona.\n");
  my $new = $app->reload_mission;
  like($new, qr/\AYou are the flag mission\./, 'reload returns -M');
  unlike($new, qr/Custom persona/, '.raider.md not used');
  is($app->raider->mission, $new, 'raider keeps -M');
};

subtest '-M mission survives a pack toggle' => sub {
  my $app = app(mission => 'You are the flag mission.');
  $app->raider;
  my ($name) = @{ $app->packs->all_pack_names } or skip_all 'no packs installed';
  $app->packs->toggle($name);
  $app->reload_mission;
  like($app->raider->mission, qr/\AYou are the flag mission\./, 'raider keeps -M');
};

subtest 'generated mission picks up .raider.md on reload' => sub {
  my $app = app();
  my $raider = $app->raider;
  unlike($raider->mission, qr/Custom persona/, 'no .raider.md yet');
  $raider->add_history(user => 'hello');
  path($app->root)->child('.raider.md')->spew_utf8("Custom persona.\n");
  like($app->reload_mission, qr/Custom persona/, 'reload returns the new mission');
  ref_is($app->raider, $raider, 'same raider instance');
  like($raider->mission, qr/Custom persona/, 'raider sees the new mission');
  is(scalar @{ $raider->history }, 1, 'history kept');
};

subtest 'raider mission writer' => sub {
  my $raider = app()->raider;
  $raider->_set_mission('Swapped.');
  is($raider->mission, 'Swapped.', '_set_mission sets the mission');
  like(dies { $raider->_set_mission([]) }, qr/Str/, 'type-checked');
};

done_testing;
