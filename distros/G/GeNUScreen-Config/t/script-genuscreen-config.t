use strict;
use File::Spec;
use Probe::Perl;
use Test::More;

plan tests => 4;

my @scriptcall = qw(perl -Iblib/lib blib/script/genuscreen-config);

my $perl = Probe::Perl->find_perl_interpreter;
my $script = File::Spec->catfile(qw/scripts genuscreen-config.pl/); 

# first check whether script with option -help or -man runs
#
is(system($perl, $script, '-help'),0, "run with -help");
is(system($perl, $script, '-man'),0, "run with -man");

my ($pipe,@out,@args);

# this configuration should have 324 lines if printed
#
@args = qw(-config t/data/config.hdf print);
#
# On MSWin32: List form of pipe open not implemented
#
open($pipe, join(' ', $perl, $script, @args, '|'));
@out = <$pipe>;
close $pipe;
is(scalar(@out),324,"number of config lines printed");

# those configurations should be equal
#
@args = qw(-config t/data/config.hdf diff t/data/example.cfg);
open($pipe, join(' ', $perl, $script, @args, '|'));
@out = <$pipe>;
close $pipe;
like($out[0],qr/configurations are equal/,"compare configs");
