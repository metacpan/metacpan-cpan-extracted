package t::Gmake;

use lib 't/lib';
use Test::Make::Base -Base;
use FindBin;
#use Smart::Comments;

my $UTIL_PATH = File::Spec->catdir($FindBin::Bin, '../../../script');
my $MAIN_PATH = File::Spec->catdir($FindBin::Bin, '../../../script');
my $sh_vm  = $PERL . ' ' . File::Spec->catfile($UTIL_PATH, 'sh');
$sh_vm = $^O eq 'MSWin32' ? 'sh' : '/bin/sh';
my $pgmake = $PERL . ' ' . File::Spec->catfile($MAIN_PATH, 'pgmake');
$pgmake = 'make';

$ENV{MAKELEVEL} = 0;

set_make('GNU_MAKE_PATH', $pgmake);
set_shell('GNU_SHELL_PATH', $sh_vm);
set_filters(
    stdout => sub {
        my ($s) = @_;
        return $s if ! $s;
        return $s;
    },
    stderr => sub {
        my ($s) = @_;
        return $s if ! $s;
        $s =~ s/^$MAKE(?:\[\d+\])?:\s+Warning:\s+File `\S+' has modification time \S+ s in the future\n//gsmi;
        $s =~ s/^$MAKE(?:\[\d+\])?:\s+warning:  Clock skew detected\.  Your build may be incomplete\.\n//gsmi;
        $s =~ s{\.\\Makefile_}{./Makefile_}g;
        return $s;
    },
);

# to ease debugging (the output is normally small)
#no_diff();

1;

