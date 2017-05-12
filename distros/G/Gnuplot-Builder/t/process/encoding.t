use strict;
use warnings;
use Test::More;
use Gnuplot::Builder::Process;
use Gnuplot::Builder qw(gscript);
use utf8;

note("ENCODING doesn't affect data passed to writers");
$Gnuplot::Builder::Process::ENCODING = "utf8";

{
    my $ret;
    gscript->plot_with(
        dataset => "'テスト.dat'",
        writer => sub { $ret .= shift }
    );
    like $ret, qr{テスト\.dat}, 'plot_with: writer gets decoded string';
}

foreach my $method ("multiplot_with", "run_with") {
    my $ret;
    gscript->$method(
        writer => sub { $ret .= shift },
        do => sub {
            my ($writer) = @_;
            $writer->("ほげ\n");
            gscript->plot("ふが");
        }
    );
    like $ret, qr{ほげ}, "$method: writer gets decoded string from inner writer";
    like $ret, qr{ふが}, "$method: writer gets decoded string from inner plot";
}

done_testing;
