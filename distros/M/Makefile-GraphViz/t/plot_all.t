use strict;
use Test::More tests => 4;
use Makefile::GraphViz;
use File::Compare;

my $debug = 1;

{
    my $parser = Makefile::GraphViz->new;
    ok $parser->parse("t/Makefile4");
    my $gv = $parser->plot_all();
    ok $gv;
    $gv->as_png('t/Makefile4.png') if $debug;
    my $outfile = 't/Makefile4.dot';
    ok $gv->as_canon($outfile);
    is fcmp($outfile, "t/Makefile4.dot.expected"), 0;
    unlink $outfile if !$debug;
}

sub fcmp {
    return File::Compare::compare_text(
        @_,
        sub {
            my ($a, $b) = @_;
            $a =~ s/[\r\n\s]//g;
            $b =~ s/[\r\n\s]//g;
            $a ne $b;
        }
    );
}

