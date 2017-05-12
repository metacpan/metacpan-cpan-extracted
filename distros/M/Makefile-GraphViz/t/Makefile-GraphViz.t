#: Makefile-GraphViz.t
#: Test Makefile::GraphViz

use strict;
use warnings;

use Test::More tests => 38;
use Makefile::GraphViz;
use File::Compare;

my $debug = 0;

my $parser = Makefile::GraphViz->new;
ok $parser;
isa_ok $parser, 'Makefile::GraphViz';
ok $parser->parse("t/Makefile");
is $parser->{_file}, 't/Makefile';

# plot the tree rooted at the install target in Makefile:
#warn "Target: ", $parser->target('t\pat_cover.ast.asm');
my $gv = $parser->plot(
    't\\pat_cover.ast.asm',
    vir_nodes    => ['pat_cover'],
    normal_nodes => [qw(pat_cover.ast C\\idu.lib)],
);
ok $gv;
isa_ok $gv, 'GraphViz';
my $outfile = 't/doc.dot';
ok $gv->as_canon($outfile);
$gv->as_png('t/doc.png') if $debug;
is fcmp($outfile, "t/doc.dot.expected"), 0;
unlink $outfile if !$debug;

$gv = $parser->plot(
    'cmintester',
    exclude  => [qw(
        all hex2bin.exe exe2hex.pl bin2asm.pl
        asm2ast.pl ast2hex.pl cod2ast.pl
    ), qr/hello/],
    end_with => [qw(pat_cover.ast pat_cover)],
    normal_nodes => ['pat_cover.ast'],
    vir_nodes => ['pat_cover'],
    trim_mode => 0,
);
ok $gv;
isa_ok $gv, 'GraphViz';
my $tar = $parser->target('types.cod');
ok $tar;
is join("\n", $tar->commands), "cl /nologo /c /FAsc types.c\ndel types.obj";
is Makefile::GraphViz::_trim_cmd('del types.obj'), 'del types.obj';
is Makefile::GraphViz::_trim_cmd("del t\\tmp"), "del t\\\\tmp";

$outfile = 't/cmintest.dot';
ok $gv->as_canon($outfile);
$gv->as_png('t/cmintest.png') if $debug;
is fcmp($outfile, "t/cmintest.dot.expected"), 0, $outfile;
unlink $outfile if !$debug;

ok $parser->parse("t/Makefile2");
is $parser->{_file}, 't/Makefile2';

# plot the tree rooted at the install target in Makefile:
$gv = $parser->plot('install', trim_mode => 1);
ok $gv;
isa_ok $gv, 'GraphViz';
$outfile = 't/install.dot';
ok $gv->as_canon($outfile);
$gv->as_png('t/install.png') if $debug;
is fcmp($outfile, "t/install.dot.expected"), 0, $outfile;
#exit;
unlink $outfile if !$debug;

$gv = $parser->plot(
    'install',
    trim_mode => 1,
    edge_style => {
        style => 'dashed',
        color => 'seagreen',
    },
    normal_node_style => {
       shape => 'circle',
       style => 'filled',
       fillcolor => 'red',
    },
    vir_nodes => ['config', 'pure_all'],
    vir_node_style => {
       shape => 'diamond',
       style => 'filled',
       fillcolor => 'yellow',
    },
);
ok $gv;
isa_ok $gv, 'GraphViz';
$outfile = 't/install2.dot';
ok $gv->as_canon($outfile);
$gv->as_png('t/install2.png') if $debug;
is fcmp($outfile, "t/install2.dot.expected"), 0;
#exit
unlink $outfile if !$debug;

$parser->parse('t/Makefile3');
$gv = $parser->plot(
    'all',
);
ok $gv;
isa_ok $gv, 'GraphViz';
$outfile = 't/sum.dot';
ok $gv->as_canon($outfile);
$gv->as_png('t/sum.png') if $debug;
is fcmp($outfile, "t/sum.dot.expected"), 0;
unlink $outfile if !$debug;

$parser->parse('t/Makefile4');
$gv = $parser->plot(
    'all',
);
ok $gv;
isa_ok $gv, 'GraphViz';
$outfile = 't/bench.dot';
ok $gv->as_canon($outfile);
$gv->as_png('t/bench.png') if $debug;
is fcmp($outfile, "t/bench.dot.expected"), 0;
unlink $outfile if !$debug;

$parser->parse('t/Makefile5');
$gv = $parser->plot_all;
ok $gv;
isa_ok $gv, 'GraphViz';
$outfile = 't/multi.dot';
ok $gv->as_canon($outfile);
$gv->as_png('t/multi.png') if $debug;
is fcmp($outfile, "t/multi.dot.expected"), 0;
unlink $outfile if !$debug;

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

