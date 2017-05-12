use strict;
use warnings;
use Test::More 0.89;

use POSIX ':signal_h';

use Devel::bt ();

plan skip_all => 'Unable to locate gdb'
    unless Devel::bt::find_gdb();

my @signals = qw(SIGABRT SIGFPE SIGILL SIGQUIT SIGSEGV SIGBUS SIGTRAP);

use Config ();

local $ENV{PERL5LIB} = join $Config::Config{path_sep} => @INC;

for my $signal (@signals) {
    next unless __PACKAGE__->can($signal);
    my $signum = __PACKAGE__->can($signal)->();
    my @cmd = ($^X, qw(-d:bt -e), "kill $signum, \$\$");

    use Capture::Tiny 'capture';
    my ($stdout) = capture { system @cmd };

    like $stdout, qr/\bperl_run\b/, "perl backtrace for $signal";
}

done_testing;
