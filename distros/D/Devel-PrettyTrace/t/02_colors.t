use Test::More tests => 1;

delete $ENV{ANSI_COLORS_DISABLED};
use Term::ANSIColor;
use Devel::PrettyTrace;

sub f{bt}

is(f(1), '  main::f(
    '.colored('[0] ', 'bright_white').colored(1, 'bright_blue').'
  ) called at t/02_colors.t line 9
');
