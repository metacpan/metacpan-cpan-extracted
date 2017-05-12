use warnings;
use strict;
use Test::More;

use Log::Fast;


plan tests => 40;


our $LOG = Log::Fast->global();
my $BUF = q{};
open my $fh, '>', \$BUF;
$LOG->config({ fh=>$fh });
sub _log() { seek $fh, 0, 0; substr $BUF, 0, length $BUF, q{} }



# empty prefix
$LOG->ERR('msg');
is _log, "msg\n", $LOG->{prefix};

# static prefix
$LOG->config({ prefix=>'pre' });
$LOG->ERR('msg');
is _log, "premsg\n", $LOG->{prefix};

# %L - log level of current message
$LOG->config({ prefix=>'%L' });
$LOG->ERR('msg');
is _log, "ERRmsg\n", $LOG->{prefix};
$LOG->WARN('msg');
is _log, "WARNmsg\n", $LOG->{prefix};

# %S - hi-resolution time (seconds.microseconds)
$LOG->config({ prefix=>'%S' });
$LOG->ERR('msg');
like _log, qr/\A\d+\.\d{5}msg\n\z/xms, $LOG->{prefix};

# %D - current date in format YYYY-MM-DD
$LOG->config({ prefix=>'%D' });
$LOG->ERR('msg');
like _log, qr/\A20\d\d-\d\d-\d\dmsg\n\z/xms, $LOG->{prefix};

# %T - current time in format HH:MM:SS
$LOG->config({ prefix=>'%T' });
$LOG->ERR('msg');
like _log, qr/\A\d\d:\d\d:\d\dmsg\n\z/xms, $LOG->{prefix};

# %P - caller's function package ('main' or 'My::Module')
$LOG->config({ prefix=>'%P' });
$LOG->ERR('msg');
is _log, "mainmsg\n", $LOG->{prefix};

# %F - caller's function name
$LOG->config({ prefix=>'%F' });
$LOG->ERR('msg');
is _log, "msg\n", $LOG->{prefix};

# %_ - X spaces, where X is current stack depth
$LOG->config({ prefix=>'%_' });
$LOG->ERR('msg');
is _log, " msg\n", $LOG->{prefix};

# %% - % character
$LOG->config({ prefix=>'%%' });
$LOG->ERR('msg');
is _log, "%msg\n", $LOG->{prefix};

# all prefixes
$LOG->config({ prefix=>'%S %D %T [%L]%_%P::%F %% ' });
$LOG->ERR('msg');
like _log, qr/\A\d+\.\d{5} 20\d\d-\d\d-\d\d \d\d:\d\d:\d\d \[ERR\] main:: % msg\n\z/ms, $LOG->{prefix};

# all prefixes, twice
$LOG->config({ prefix=>'%S %D %T [%L]%_%P::%F %% 'x2 });
$LOG->ERR('msg');
like _log, qr/\A(\d+\.\d{5} 20\d\d-\d\d-\d\d \d\d:\d\d:\d\d \[ERR\] main:: % ){2}msg\n\z/ms, $LOG->{prefix};

###
# stack/package/function
###

$LOG->config({ prefix=>'%_%P->%F ' });

# from main script
$LOG->ERR('in script');
is _log, " main-> in script\n", 'script';
eval { $LOG->ERR('in script') };
is _log, " main->(eval) in script\n", 'script eval {}';
eval '$LOG->ERR("in script");';
is _log, " main->(eval) in script\n", 'script eval ""';

# from main::sub
sub M { $LOG->ERR('in M') }
M();
is _log, " main->M in M\n", 'M';
eval { M() };
is _log, "  main->M in M\n", 'eval {M}';
eval 'M()';
is _log, "  main->M in M\n", 'eval "M"';
sub MEB { eval { $LOG->ERR('in MEB') } };
sub MES { eval ' $LOG->ERR("in MES") ' };
MEB();
is _log, "  main->(eval) in MEB\n", 'MEB';
MES();
is _log, "  main->(eval) in MES\n", 'MES';

# from a::A
use lib 't';
use a;
a::A();
is _log, " a->A in a::A\n", 'a::A';
a::call('a::A');
is _log, "  a->A in a::A\n", 'a::call->a::A';
a::call('a::call', 'a::A');
is _log, "   a->A in a::A\n", 'a::call->a::call->a::A';

# from a::b::B
use a::b;
a::b::B();
is _log, " a::b->B in a::b::B\n", 'a::b::B';
a::b::call('a::b::B');
is _log, "  a::b->B in a::b::B\n", 'a::b::call->a::b::B';
a::call('a::b::B');
is _log, "  a::b->B in a::b::B\n", 'a::call->a::b::B';
a::b::call('a::call', 'a::b::B');
is _log, "   a::b->B in a::b::B\n", 'a::b::call->a::call->a::b::B';

# from injected a::b::Fx
sub a::b::F1 { $LOG->ERR('in a::b::F1') }
*a::b::F2 = sub { $LOG->ERR('in a::b::F2') };
*a::b::F3 = eval 'sub { $LOG->ERR("in a::b::F3") };';
eval 'sub a::b::F4 { $LOG->ERR("in a::b::F4") };';
eval 'package a::b; sub F5 { $LOG->ERR("in a::b::F5") };';
package a::b; sub F6 { $LOG->ERR("in a::b::F6") }; package main;
a::b::F1();
is _log, " main->F1 in a::b::F1\n", 'a::b::F1';
a::b::F2();
is _log, " main->__ANON__ in a::b::F2\n", 'a::b::F2';
a::b::F3();
is _log, " main->__ANON__ in a::b::F3\n", 'a::b::F3';
a::b::F4();
is _log, " main->F4 in a::b::F4\n", 'a::b::F4';
a::b::F5();
is _log, " a::b->F5 in a::b::F5\n", 'a::b::F5';
a::b::F6();
is _log, " a::b->F6 in a::b::F6\n", 'a::b::F6';

# from injected a::b::Fx with 1 additional stack
a::call('a::b::F1');
is _log, "  main->F1 in a::b::F1\n", 'a::b::F1 plus 1 stack';
a::call('a::b::F2');
is _log, "  main->__ANON__ in a::b::F2\n", 'a::b::F2 plus 1 stack';
a::call('a::b::F3');
is _log, "  main->__ANON__ in a::b::F3\n", 'a::b::F3 plus 1 stack';
a::call('a::b::F4');
is _log, "  main->F4 in a::b::F4\n", 'a::b::F4 plus 1 stack';
a::call('a::b::F5');
is _log, "  a::b->F5 in a::b::F5\n", 'a::b::F5 plus 1 stack';
a::call('a::b::F6');
is _log, "  a::b->F6 in a::b::F6\n", 'a::b::F6 plus 1 stack';

