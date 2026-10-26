use strict;
use warnings;
use Test::More;

use Pod::Weaver;
use Pod::Elemental::Document;
use Software::License::Perl_5;
use Pod::Weaver::PluginBundle::Author::GETTY;

my ($entry) = grep { $_->[0] eq '@GETTY/Legal' }
  Pod::Weaver::PluginBundle::Author::GETTY->mvp_bundle_config;
is($entry->[1], 'Pod::Weaver::Section::Author::GETTY::Legal',
  'the weaver bundle uses this section for the legal text');

sub legal_text {
  my ($holder) = @_;
  my $class = $entry->[1];
  eval "require $class; 1" or die $@;
  my $license = Software::License::Perl_5->new({ holder => $holder, year => '2026' });
  my $doc = Pod::Elemental::Document->new;
  $class->new(plugin_name => 'Legal', weaver => Pod::Weaver->new)
    ->weave_section($doc, { license => $license });
  my ($section) = @{ $doc->children };
  return join "\n", map { $_->content } @{ $section->children };
}

my $plain = legal_text('Torsten Raudssus <torsten@raudssus.de>');
like($plain, qr{^L<https://raudssus\.de/>$}m, 'the link is added to a plain holder');
is(() = $plain =~ m{raudssus\.de/}g, 1, 'and appears once');

my $legacy = legal_text('Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>');
is(() = $legacy =~ m{https://raudssus\.de/}g, 1, 'a holder that carries the link itself does not get it twice');

done_testing;
