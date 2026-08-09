use strict;
use warnings;
use Test::More;

use Dist::Zilla::PluginBundle::Author::GETTY;

{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => {},
  );

  is(
    $bundle->tag_format,
    '%v',
    'tag_format defaults to %v',
  );
}

{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { tag_format => 'v%v' },
  );

  is(
    $bundle->tag_format,
    'v%v',
    'tag_format passes through when set',
  );
}

{
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => { tag_format => 'v%v.0' },
  );

  is(
    $bundle->tag_format,
    'v%v.0',
    'tag_format passes through a multi-part format unchanged',
  );

  # Mirrors the %v substitution Dist::Zilla::Role::Git::StringFormatter
  # performs at release time (%v => $zilla->version) to confirm the POD's
  # documented example, tag_format = v%v.0, really does turn Perl's bare
  # two-part decimal $VERSION into a strict three-part SemVer tag.
  ( my $tag = $bundle->tag_format ) =~ s/%v/0.317/;

  is( $tag, 'v0.317.0', 'v%v.0 expands to a strict vMAJOR.MINOR.PATCH tag' );
  like(
    $tag,
    qr/\Av\d+\.\d+\.\d+\z/,
    'expanded tag_format satisfies SemVer vMAJOR.MINOR.PATCH',
  );
}

done_testing;
