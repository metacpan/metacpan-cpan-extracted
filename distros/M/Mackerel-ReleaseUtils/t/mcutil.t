use strict;
use warnings;
use utf8;
use Test::More;

use Mackerel::ReleaseUtils;

my $version = '0.1.2';
my ($major, $minor, $patch) = Mackerel::ReleaseUtils::parse_version $version;
is $major, 0;
is $minor, 1;
is $patch, 2;
is Mackerel::ReleaseUtils::suggest_next_version($version), '0.2.0';

my $deb_revision = Mackerel::ReleaseUtils::_detect_debian_revision('mackerel-agent', <<'_CHANGELOG_');
mackerel-agent (0.43.1-1.systemd) stable; urgency=low

  * rename command.Context to command.App (by Songmu)
    <https://github.com/mackerelio/mackerel-agent/pull/384>
  * Add `prevent_alert_auto_close` option for check plugins (by mechairoi)
    <https://github.com/mackerelio/mackerel-agent/pull/387>
  * Remove supported OS section from README. (by astj)
    <https://github.com/mackerelio/mackerel-agent/pull/388>
_CHANGELOG_

is $deb_revision, '1.systemd';

done_testing;
