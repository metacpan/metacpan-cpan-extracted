#!/usr/bin/perl
use strict;
use GOBO::Graph;
use GOBO::Statement;
use GOBO::LinkStatement;
use GOBO::Annotation;
use GOBO::Node;
use GOBO::Parsers::GAFParser;
use GOBO::Parsers::OBOParser;
use GOBO::Writers::GAFWriter;
use GOBO::Writers::CustomizableWriter;
use GOBO::InferenceEngine;
use GOBO::InferenceEngine::GAFInferenceEngine;
use List::MoreUtils;
use Set::Object;
use DateTime;
use FileHandle;

my $ontf;
my %relh = ();
my @ids = ();
my $writer = new GOBO::Writers::CustomizableWriter;
while ($ARGV[0] =~ /^\-/) {
    my $opt = shift @ARGV;
    if ($opt eq '-i' || $opt eq '--ontology') {
        $ontf = shift;
    }
    elsif ($opt eq '-r' || $opt eq '--relation') {
        $relh{shift @ARGV} = 1;
    }
    elsif ($opt eq '-t' || $opt eq '--term') {
        push(@ids, shift @ARGV);
    }
    elsif ($opt eq '-h' || $opt eq '--help') {
        system("perldoc $0");
        exit(0);
    }
    elsif ($opt eq '--gaf') {
        bless $writer, 'GOBO::Writers::GAFWriter';
    }
    else {
        die "no such opt: $opt";
    }
}
if (!$ontf) {
    $ontf = shift;
}
if (!$ontf) {
    system("perldoc $0");
    exit(1);
}

#if (!@ids) {
#    print "Enter IDs:\n";
#    @ids = split(/\n/, <STDIN>);
#}
my $idset = new Set::Object;
$idset->insert(@ids);

my $obo_parser = new GOBO::Parsers::OBOParser(file=>$ontf);
$obo_parser->parse;
my $ontg = $obo_parser->graph;
my $ie = new GOBO::InferenceEngine::GAFInferenceEngine(graph=>$ontg);


# iterate through annotations writing new ICs
my @ics = ();
foreach my $f (@ARGV) {
    my $gafparser = new GOBO::Parsers::GAFParser(file=>$f);
    $gafparser->graph($ontg);
    $ontg->annotations([]);
    # iterate through one chunk at a time
    while ($gafparser->parse_chunk(10000)) {
        foreach my $ann (@{$gafparser->graph->annotations}) {
            if (@ids) {
                my $rset = new Set::Object;
                $rset->insert(map {$_->id} @{$ie->get_inferred_target_nodes($ann->target)});
                if ($rset->intersection($idset)->size) {
                    show_ann($ann);
                }
            }
            else {
                show_ann($ann);
            }
        }
        # clear
        $gafparser->graph(new GOBO::Graph);
    }
}
exit 0;

# TODO: use a general customizable writer class
sub show_ann {
    my $ann = shift;
    #printf "%s %s %s %s\n", $ann->node, $ann->evidence, $ann->target->id, $ann->target->label;
    $writer->write_annotation($ann);
}



=head1 NAME

go-gaf-extract.pl

=head1 SYNOPSIS

  # extract nucleotide binding terms
  go-gaf-extract.pl -t GO:0000166 t/data/gtp.obo t/data/test-fb.gaf 

=head1 DESCRIPTION

Extracts all annotations to a term, including annotations inferred from graph

=cut
