use strict;
use warnings;
use Test::More;

use Pod::Weaver;
use Pod::Elemental::Document;
use Pod::Elemental::Element::Nested;
use Pod::Weaver::PluginBundle::Author::GETTY;

my ($entry) = grep { $_->[0] eq '@GETTY/Support' }
  Pod::Weaver::PluginBundle::Author::GETTY->mvp_bundle_config;

sub support_text {
  my ($web) = @_;
  my $class = $entry->[1];
  eval "require $class; 1" or die $@;
  my $doc = Pod::Elemental::Document->new;
  $class->new(plugin_name => 'Support', weaver => Pod::Weaver->new, %{ { %{ $entry->[2] }, text => [ split /\n/, $entry->[2]{text} ] } })
    ->weave_section($doc, { zilla => {}, distmeta => {
      name      => 'Some-Dist',
      version   => '1',
      resources => { bugtracker => { web => $web } },
    } });
  my ($section) = @{ $doc->children };
  return $section ? join("\n", map { $_->as_pod_string } @{ $section->children }) : '';
}

for my $url (
  'https://github.com/getty/some-dist/issues',
  'https://codeberg.org/getty/p5-www-gitea/issues',
) {
  my $text = support_text($url);
  like($text, qr{\Q$url\E}, "the bugtracker $url is linked");
  unlike($text, qr/GitHub/, '... without naming a forge the weaver cannot know');
}

done_testing;
