#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Storable qw(dclone);

use Pod::Weaver;
use Pod::Elemental::Document;
use Pod::Elemental::Element::Nested;
use Pod::Weaver::PluginBundle::Author::GETTY;

my ($entry) = grep { $_->[0] eq '@GETTY/Support' }
  Pod::Weaver::PluginBundle::Author::GETTY->mvp_bundle_config;

# Weaves the SUPPORT section for the given resources into a fresh document
# with the given class (default: the one the bundle names); returns the pod
# of the section ('' if the document got none).
sub weave {
  my ($resources, $class) = @_;
  $class //= $entry->[1];
  eval "require $class; 1" or die $@;
  my $doc = Pod::Elemental::Document->new;
  $class->new(plugin_name => 'Support', weaver => Pod::Weaver->new, %{ { %{ $entry->[2] }, text => [ split /\n/, $entry->[2]{text} ] } })
    ->weave_section($doc, { zilla => {}, distmeta => {
      name      => 'Some-Dist',
      version   => '1',
      resources => $resources,
    } });
  my ($section) = @{ $doc->children };
  return ($section ? join("\n", map { $_->as_pod_string } @{ $section->children }) : '', scalar @{ $doc->children });
}

sub support_text {
  my ($web) = @_;
  return (weave({ bugtracker => { web => $web } }))[0];
}

for my $url (
  'https://github.com/getty/some-dist/issues',
  'https://codeberg.org/getty/p5-www-gitea/issues',
) {
  my $text = support_text($url);
  like($text, qr{\Q$url\E}, "the bugtracker $url is linked");
  unlike($text, qr/GitHub/, '... without naming a forge the weaver cannot know');
}

is($entry->[1], 'Pod::Weaver::Section::Author::GETTY::Support', 'the bundle uses the Support section class that drops an empty section');

# Neither bugtracker nor IRC: the template renders nothing, so no heading either.
{
  my ($text, $count) = weave({});
  is($count, 0, 'no bugtracker, no IRC: the document gets no SUPPORT section');
  is($text, '', '... and so no text');
  ($text, $count) = weave({ bugtracker => {} });
  is($count, 0, 'an empty bugtracker resource counts as none');
  ($text, $count) = weave({ x_IRC => '', x_IRC_user => '' });
  is($count, 0, 'empty IRC values count as none');

  # the plain GenerateSection does emit a heading here: this is what the class fixes
  my ($plain, $plain_count) = weave({}, 'Pod::Weaver::Section::GenerateSection');
  is($plain_count, 1, 'sanity: the unsubclassed GenerateSection leaves an (empty) section behind');
}

{
  my ($text, $count) = weave({ x_IRC => 'irc://irc.perl.org/#some-dist' });
  is($count, 1, 'only x_IRC: the section stays');
  like($text, qr/=head2 IRC/, '... with the IRC part');
  like($text, qr/#some-dist/, '... naming the channel');
  unlike($text, qr/=head2 Issues/, '... and no Issues part');

  ($text, $count) = weave({ x_IRC_user => 'Getty' });
  is($count, 1, 'only x_IRC_user: the section stays');
  like($text, qr/=head2 IRC.*Getty/s, '... naming the user');

  ($text, $count) = weave({ bugtracker => { web => 'https://example.org/issues' } });
  is($count, 1, 'a bugtracker: the section stays');
  like($text, qr{=head2 Issues\s+Please report bugs and feature requests at\s+L<https://example.org/issues>}, '... with the Issues part');
  unlike($text, qr/=head2 IRC/, '... and no IRC part');

  ($text, $count) = weave({ bugtracker => { web => 'https://example.org/issues' }, x_IRC => 'irc://irc.perl.org/#x' });
  like($text, qr/=head2 Issues.*=head2 IRC/s, 'bugtracker and IRC: both parts, Issues first');
}

# The weaver reads distmeta->{resources}{...}{web}; that must not write into the
# distribution's own metadata (the one META.json is written from).
sub weave_meta {
  my ($input) = @_;
  my $doc = Pod::Elemental::Document->new;
  my $class = $entry->[1];
  eval "require $class; 1" or die $@;
  $class->new(plugin_name => 'Support', weaver => Pod::Weaver->new, %{ { %{ $entry->[2] }, text => [ split /\n/, $entry->[2]{text} ] } })
    ->weave_section($doc, $input);
  my ($section) = @{ $doc->children };
  return $section ? join("\n", map { $_->as_pod_string } @{ $section->children }) : '';
}

for my $case (
  [ 'no resources key',            { name => 'Some-Dist', version => '1' } ],
  [ 'empty resources',             { name => 'Some-Dist', resources => {} } ],
  [ 'resources without bugtracker', { name => 'Some-Dist', resources => { homepage => 'https://example.org' } } ],
  [ 'an empty bugtracker',         { name => 'Some-Dist', resources => { bugtracker => {} } } ],
  [ 'a bugtracker',                { name => 'Some-Dist', resources => { bugtracker => { web => 'https://example.org/issues' } } } ],
  [ 'bugtracker, repository, IRC', { name => 'Some-Dist', resources => {
      bugtracker => { web => 'https://example.org/issues' }, repository => { web => 'https://example.org/r' },
      x_IRC => 'irc://irc.perl.org/#x', x_IRC_user => 'Getty' } } ],
) {
  my ($label, $distmeta) = @$case;
  my $before = dclone($distmeta);
  my $input  = { zilla => {}, distmeta => $distmeta };
  weave_meta($input);
  is_deeply($distmeta, $before, "$label: the caller's distmeta is unchanged after the weave");
  is($input->{distmeta}, $distmeta, "$label: the caller's input still holds the same distmeta");
}

{
  my $distmeta = { name => 'Some-Dist', resources => { bugtracker => { web => 'https://example.org/issues' }, x_IRC => 'irc://irc.perl.org/#x' } };
  my $text = weave_meta({ zilla => {}, distmeta => $distmeta });
  is($text, (weave($distmeta->{resources}))[0], 'with a bugtracker and IRC the SUPPORT text is the same');
  like($text, qr{=head2 Issues\s+Please report bugs and feature requests at\s+L<https://example.org/issues>.*=head2 IRC\s+Join C<#x> on C<irc.perl.org>}s,
    '... and has the Issues and the IRC part');
}

{
  my $text = eval { weave_meta({ zilla => {} }) };
  is($@, '', 'a weave without distmeta works');
  is($text, '', '... and leaves no SUPPORT section');
}

done_testing;
