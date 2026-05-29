use strict;
use warnings;
use Test::More;

use_ok('Dist::Zilla::Plugin::GitHub::CreateRelease');

my $class = 'Dist::Zilla::Plugin::GitHub::CreateRelease';

# _extract_changes only works on its arguments, so it can be exercised as
# a class method without a Dist::Zilla instance or a git checkout.

my $changes = <<'CHANGES';
0.003     2026-05-27
  - third release
  - more stuff

0.002     2026-05-01
  - second release

0.001     2026-04-01
  - first release
CHANGES

# A normal release: notes run from the current tag up to (not including)
# the previous tag.
{
  my $notes = $class->_extract_changes($changes, '0.003', '0.002');
  like($notes,   qr/third release/,  'current section included');
  unlike($notes, qr/second release/, 'previous section excluded');
}

# First release: for-each-ref --count=2 returns only one tag, so $prev is
# undef.  This used to emit "Use of uninitialized value $prev in regexp".
{
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, $_[0] };

  my $notes = $class->_extract_changes($changes, '0.001', undef);

  is_deeply(\@warnings, [], 'no warnings when previous tag is undef')
    or diag "got: @warnings";
  like($notes, qr/first release/, 'first release section captured');
}

# Version numbers must be matched literally, not as a regex (the "." in
# 0.003 must not match an arbitrary character).
{
  my $tricky = "0x003  not a real version\n0.003  the real one\n";
  my $notes  = $class->_extract_changes($tricky, '0.003', undef);
  unlike($notes, qr/not a real version/, 'dot in version is matched literally');
  like($notes,   qr/the real one/,       'literal version section captured');
}

done_testing;
