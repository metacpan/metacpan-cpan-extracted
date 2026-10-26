use strict;
use warnings;
use Test::More;

use Dist::Zilla::PluginBundle::Author::GETTY;

# Test::ChangesHasContent wants the version heading NextRelease writes into
# Changes; where there is none, the generated release test can only fail.
sub has_test {
  my (%payload) = @_;
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name => '@Author::GETTY', payload => \%payload,
  );
  $bundle->configure;
  return scalar grep { $_->[1] eq 'Dist::Zilla::Plugin::Test::ChangesHasContent' } @{ $bundle->plugins };
}

ok  has_test(),                          'default: Changes is checked';
ok !has_test(no_changes => 1),           'no_changes: the version heading is blank, no check';
ok !has_test(task => 1),                 'task: no NextRelease, no check';
ok  has_test(manual_version => 1),   'manual_version: the author writes the heading, so it is checked';

done_testing;
