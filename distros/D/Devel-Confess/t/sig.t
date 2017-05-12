use strict;
use warnings;
BEGIN {
  $ENV{DEVEL_CONFESS_OPTIONS} = '';
}
use Test::More tests => 14;
use lib 't/lib';
use Capture;

# preload to make sure we only test the effect of our own import
use base ();
use Exporter ();
use Exporter::Heavy ();
use Carp ();
use Carp::Heavy ();
use Symbol ();

my $pre_die;
BEGIN { $pre_die = $SIG{__DIE__} }

use Devel::Confess ();

is $SIG{__DIE__}, $pre_die, 'not activated without import';
my $called;
sub CALLED { $called++ };
$SIG{__DIE__} = \&CALLED;
Devel::Confess->import;
isnt $SIG{__DIE__}, \&CALLED, 'import overwrites existing __DIE__ handler';
$called = 0;
eval { die };
is 0+$called, 1, 'calls outer __DIE__ handler';
Devel::Confess->unimport;
is $SIG{__DIE__}, \&CALLED, 'unimport restores __DIE__ handler';

$SIG{__DIE__} = '';
Devel::Confess->import;
Devel::Confess->unimport;
ok !$SIG{__DIE__}, 'unimport restores nonexistent __DIE__ handler';

sub IGNORE { $called++ }
sub DEFAULT { $called++ }
sub other::sub { $called++ }

$SIG{__DIE__} = 'IGNORE';
Devel::Confess->import;
$called = 0;
eval { die };
is 0+$called, 0, 'no dispatching to IGNORE';
Devel::Confess->unimport;

$SIG{__DIE__} = 'DEFAULT';
Devel::Confess->import;
$called = 0;
eval { die };
is 0+$called, 0, 'no dispatching to DEFAULT';
Devel::Confess->unimport;

$SIG{__DIE__} = 'CALLED';
Devel::Confess->import;
$called = 0;
eval { die };
is 0+$called, 1, 'dispatches by name';
Devel::Confess->unimport;

$SIG{__DIE__} = 'other::sub';
Devel::Confess->import;
$called = 0;
eval { die };
is 0+$called, 1, 'dispatches by name to package sub';
Devel::Confess->unimport;

is capture <<'END_CODE',
BEGIN { $SIG{__DIE__} = sub { 1 } }
use Devel::Confess;
package A;

sub f {
#line 1 test-block.pl
  die "Beware!";
}

sub g {
#line 2 test-block.pl
  f();
}

package main;

#line 3 test-block.pl
A::g();
END_CODE
  <<"END_OUTPUT",
Beware! at test-block.pl line 1.
\tA::f() called at test-block.pl line 2
\tA::g() called at test-block.pl line 3
END_OUTPUT
  'trace still added when outer __DIE__ exists';

is capture <<'END_CODE', '',
BEGIN { $SIG{__WARN__} = sub { } }
use Devel::Confess;
package A;

sub f {
#line 1 test-block.pl
  warn "Beware!";
}

sub g {
#line 2 test-block.pl
  f();
}

package main;

#line 3 test-block.pl
A::g();
END_CODE
  'outer __WARN__ can silence warnings';

is capture <<'END_CODE',
BEGIN { $SIG{__WARN__} = sub { warn $_[0] } }
use Devel::Confess;
package A;

sub f {
#line 1 test-block.pl
  warn "Beware!";
}

sub g {
#line 2 test-block.pl
  f();
}

package main;

#line 3 test-block.pl
A::g();
END_CODE
  <<"END_OUTPUT",
Beware! at test-block.pl line 1.
\tA::f() called at test-block.pl line 2
\tA::g() called at test-block.pl line 3
END_OUTPUT
  'outer __WARN__ gets full location';

is capture <<'END_CODE',
use strict;
use warnings 'FATAL' => 'all';
use Devel::Confess;
BEGIN {
  my $warn = $SIG{__WARN__} || die;
  $SIG{__WARN__} = sub { $warn->(@_) };
}
use Devel::Confess;
package A;

sub f {
#line 1 test-block.pl
  warn "Beware!";
}

sub g {
#line 2 test-block.pl
  f();
}

package main;

#line 3 test-block.pl
A::g();
END_CODE
  <<"END_OUTPUT",
Beware! at test-block.pl line 1.
\tA::f() called at test-block.pl line 2
\tA::g() called at test-block.pl line 3
END_OUTPUT
  'no infinite loop with mutually recursing __WARN__';

is capture <<'END_CODE',
use strict;
use warnings 'FATAL' => 'all';
use Devel::Confess;
BEGIN {
  my $die = $SIG{__DIE__} or die;
  $SIG{__DIE__} = sub { $die->(\@_) };
}
use Devel::Confess;
package A;

sub f {
#line 1 test-block.pl
  die "Beware!";
}

sub g {
#line 2 test-block.pl
  f();
}

package main;

#line 3 test-block.pl
A::g();
END_CODE
  <<"END_OUTPUT",
Beware! at test-block.pl line 1.
\tA::f() called at test-block.pl line 2
\tA::g() called at test-block.pl line 3
END_OUTPUT
  'no infinite loop with mutually recursing __DIE__';
