use strict;
use warnings;
use Test::More;
use Path::Tiny;
use version;

use Dist::Zilla::PluginBundle::Author::GETTY;

# The bundle demands a minimum plugin version at build time; the cpanfile pin
# must not be lower, or an installed bundle can meet a too-old plugin.
my $cpanfile = path(__FILE__)->parent->parent->child('cpanfile')->slurp_utf8;

my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
  name => '@Author::GETTY', payload => {},
);
$bundle->configure;

for my $entry (@{ $bundle->plugins }) {
  my ($name, $class, $conf) = @$entry;
  # Only plugins the bundle adds itself; the ones inside a nested bundle such as
  # @Git::VersionManager come with that bundle's own prerequisites.
  next unless $class eq 'Dist::Zilla::Plugin::Authority' and ref $conf eq 'HASH' and defined $conf->{':version'};
  my ($pin) = $cpanfile =~ /^requires\s+'\Q$class\E',\s*'([\d.]+)'/m;
  ok(defined $pin, "cpanfile pins $class");
  ok(version->parse($pin // 0) >= version->parse($conf->{':version'}),
    "the pin ($pin) of $class covers the :version the bundle demands ($conf->{':version'})");
}

done_testing;
