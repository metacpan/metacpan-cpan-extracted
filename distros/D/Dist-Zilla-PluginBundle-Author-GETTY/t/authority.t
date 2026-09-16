use strict;
use warnings;
use Test::More;

use Dist::Zilla::PluginBundle::Author::GETTY;

sub _authority {
  my ($payload) = @_;
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => $payload // {},
  );
  return $bundle->authority;
}

# Regression for k3: the cpan: prefix was prepended unconditionally, so a
# payload already carrying it (authority = cpan:JLMARTIN) produced the
# malformed cpan:cpan:JLMARTIN. The prefix must appear exactly once.

is _authority({ authority => 'JLMARTIN' }), 'cpan:JLMARTIN',
  'bare authority id gets a single cpan: prefix';

is _authority({ authority => 'cpan:JLMARTIN' }), 'cpan:JLMARTIN',
  'cpan:-prefixed authority id is not doubled';

is _authority({ authority => 'cpan:JLMARTIN' }),
  _authority({ authority => 'JLMARTIN' }),
  'both spellings produce the same authority (idempotent)';

is _authority({}), 'cpan:GETTY',
  'default authority derives cpan:GETTY from the default author';

is _authority({ author => 'GETTY' }), 'cpan:GETTY',
  'authority falls back to the author value with one cpan: prefix';

is _authority({ author => 'cpan:GETTY' }), 'cpan:GETTY',
  'a cpan:-prefixed author fallback is not doubled either';

done_testing;
