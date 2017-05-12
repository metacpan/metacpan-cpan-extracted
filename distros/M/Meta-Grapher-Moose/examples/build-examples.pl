#!/usr/bin/perl

use strict;
use warnings;
use autodie qw( :all );

use FindBin;

my $jarfile = shift || '/Users/Mark/bin/jar/plantuml.jar';
unless ( -e $jarfile ) {
    die "You must pass in the plantuml.jar location as the only arg\n";
}

chdir("$FindBin::Bin/..");

my @PERL = $^X, qw( -Ilib -It/lib );
my $SCRIPT = 'bin/graph-meta.pl';

build( 'graphviz', $_ ) for qw(png pdf jpg svg dot);

# note we don't build PDF because that requires installing batik
# we don't build HTML because it's building support files
build( 'plantuml', $_, '--renderer=plantuml', "--plantuml-jar=$jarfile" )
    for qw(
    png
    svg
    eps
    vdx
    xmi
    scxml
    txt
    utxt
    latex
);

sub build {
    my $type   = shift;
    my $format = shift;
    my @extra  = @_;

    mkdir('examples/output')       unless -d 'examples/output';
    mkdir("examples/output/$type") unless -d "examples/output/$type";

    system(
        @PERL, $SCRIPT,
        '--package=My::Example::Class',
        "--output=examples/output/$type/example.$format",
        @extra,
    );
}
