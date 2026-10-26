use strict;
use warnings;
use Test::More;

use Dist::Zilla::PluginBundle::Author::GETTY;

sub configure_error {
  my (%payload) = @_;
  my $bundle = Dist::Zilla::PluginBundle::Author::GETTY->new(
    name    => '@Author::GETTY',
    payload => \%payload,
  );
  eval { $bundle->configure; 1 } and return;
  return $@;
}

my @guards = (
  [ 'weaver_config with is_task', { task => 1, weaver_config => '@Other' },
    qr/\[\@Author::GETTY\] you must not specify both weaver_config and is_task/ ],
  [ 'author with no_cpan', { no_cpan => 1, author => 'SOMEONE' },
    qr/\[\@Author::GETTY\] you must not specify both author and no_cpan/ ],
  [ 'no_install with no_makemaker', { no_install => 1, no_makemaker => 1 },
    qr/\[\@Author::GETTY\] no_install can't be used together with no_makemaker/ ],
);

for my $g (@guards) {
  my ($name, $payload, $re) = @$g;
  my $err = configure_error(%$payload);
  like($err, $re, "$name aborts with its own message");
  unlike($err // '', qr/Can't locate object method/, "$name does not trip over log_fatal");
}

done_testing;
