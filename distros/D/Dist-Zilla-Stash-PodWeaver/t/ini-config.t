# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More;
use Test::MockObject;

use Dist::Zilla::Tester;

my %confs = (
  't/ini-none' => undef,
  't/ini-sep'  => {
    mods => {
      'Pod::Weaver::Plugin::PlugName' => { 'Attr::Name' => 'oops' },
      'Mod::Name' => { '!goo-ber' => 'nuts', pea => [qw( nut pod )] }
    },
    'argument_separator'  => '([^|]+)\|([^|]+?)',
    _config => {
      '-PlugName|Attr::Name' => 'oops',
      '+Mod::Name|!goo-ber'  => 'nuts',
      '+Mod::Name|pea[0]'    => 'nut',
      '+Mod::Name|pea[1]'    => 'pod',
    }
  },
  't/ini-test' => {
    mods => {
      'Pod::Weaver::PluginBundle::ABundle' => {'fakeattr' => 'fakevalue1'},
      'Pod::Weaver::Plugin::APlugin' => {'fakeattr' => 'fakevalue2'},
      'Pod::Weaver::Section::ASection' => {'heading' => [qw( head5 head6 )]},
      'Pod::Weaver::Plugin::APlug::Name' => {'config' => 'confy'},
    },
    'argument_separator'  => '(.+?)\W+(\w+)',
    _config => {
      '@ABundle-fakeattr'    => 'fakevalue1',
      '-APlugin/fakeattr'    => 'fakevalue2',
      'ASection->heading[a]' => 'head5',
      'ASection->heading[b]' => 'head6',
      '-APlug::Name::config' => 'confy',
    }
  }
);

my $mock = Test::MockObject->new;
foreach my $dir ( keys %confs ){

  my $zilla = Dist::Zilla::Tester->from_config(
    { dist_root => $dir },
    {}
  );

  $zilla->build;

  my $mods = defined($confs{$dir}) ? delete($confs{$dir}->{mods}) : undef;

  my @fields = qw(argument_separator _config);
  my $stash = $zilla->stash_named('%PodWeaver');
  is_deeply [@$stash{@fields}], [@{$confs{$dir}}{@fields}], "stash matches in $dir";

  next unless $mods;

  foreach my $mod ( keys %$mods ){
    $mock->fake_module($mod, new => sub { bless $_[1], $_[0] }, plugin_name => sub { $_[0]->{name} });
    my $plug = $mod->new({name => ($mod =~ /([^:]+)$/)[0]});
    isa_ok($plug, $mod);
    my $stash = $zilla->stash_named('%PodWeaver')->get_stashed_config($plug);
    is_deeply($stash, $mods->{$mod}, "stashed config expected ($dir / $mod)");
  }
}

done_testing;
