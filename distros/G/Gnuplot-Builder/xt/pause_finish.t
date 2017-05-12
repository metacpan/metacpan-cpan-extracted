use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Script;
use Gnuplot::Builder::Process;
use File::Temp;

my $tempfile = File::Temp->new(UNLINK => 1, EXLOCK => 0);

@Gnuplot::Builder::Process::COMMAND = ("perl", "./xt/testlib/tee.pl", "$tempfile");

sub get_echo {
    local $/;
    open my $file, "<", "$tempfile" or die "Cannot open $tempfile: $!";
    my $data = <$file>;
    return $data;
}

{
    note("-- when PAUSE_FINISH = 0");
    local $Gnuplot::Builder::Process::PAUSE_FINISH = 0;
    my $result = Gnuplot::Builder::Script->new->plot("sin(x)");
    note("plot result:");
    note($result);
    my $echo = get_echo();
    like $echo, qr{plot +sin\(x\)}, "plot string OK";
    unlike $echo, qr{pause}, "no pause OK";
}

{
    note("-- when PAUSE_FINISH = 1");
    local $Gnuplot::Builder::Process::PAUSE_FINISH = 1;
    my $result = Gnuplot::Builder::Script->new->plot("cos(x)");
    note("plot result:");
    note($result);
    my $echo = get_echo();
    like $echo, qr{plot +cos\(x\)}, "plot string OK";
    like $echo, qr{pause}, "pause OK";
}

done_testing;
