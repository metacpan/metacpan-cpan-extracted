use Test::More tests => 1;

delete $ENV{ANSI_COLORS_DISABLED};
use Term::ANSIColor;
use Devel::PrettyTrace;
$Devel::PrettyTrace::Opts{show_readonly} = 0;
$Devel::PrettyTrace::Opts{colors}{array} = 'bright_white';
$Devel::PrettyTrace::Opts{colors}{number} = 'bright_blue';

sub f{bt}

is(f(1), '  main::f(
    '.colored('[0] ', 'bright_white').colored(1, 'bright_blue').'
  ) called at t/02_colors.t line 12
');
