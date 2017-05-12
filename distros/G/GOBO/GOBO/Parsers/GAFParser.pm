package GOBO::Parsers::GAFParser;
use Moose;
use strict;
extends 'GOBO::Parsers::Parser';
with 'GOBO::Parsers::GraphParser';

use GOBO::Node;
use GOBO::Gene;
use GOBO::Evidence;
use GOBO::Annotation;
use GOBO::ClassExpression;
use Carp;

sub parse_header {
    my $self = shift;
    my $g = $self->graph;

    while($_ = $self->next_line) {
        if (/^\!.*/) {
        }
        else {
            $self->unshift_line($_);
            # set the parse_header to 1
            $self->parsed_header(1);
            return;
        }
    }
    # we are still in the header and have reached the end of the file
    $self->parsed_header(1);
    return;
}

sub parse_body {
    my $self = shift;
    my $g = $self->graph;

    while($_ = $self->next_line) {
        if (/^\!/) {
            print STDERR "Warning! header in unexpected location: $_\n";
            next;
        }
        chomp;
        my @vals = split(/\t/);
        my ($genedb,
            $geneacc,
            $genesymbol,
            $qualifier,
            $termacc,
            $ref,
            $evcode,
            $with,
            $aspect,
            $genename,
            $genesyn,
            $genetype,
            $genetaxa,
            $assocdate,
            $source_db,
            $annotxp,   # experimental! 
            $geneproduct
            ) = @vals;

        if (!$genesymbol) {
            confess("No symbol in line: $_");
        }

        my $geneid = "$genedb:$geneacc";
        my $gene = $g->noderef($geneid);
        my @taxa = split(/[\|\;]/,$genetaxa);
        @taxa = map {s/^taxon:/NCBITaxon:/;$_} @taxa;
        my $taxon = shift @taxa;
        if (!$gene->label) {
            bless $gene, 'GOBO::Gene';
            $gene->label($genesymbol);
            $gene->add_synonyms(split(/\|/,$genesyn));
            # TODO; split
            $gene->taxon($g->noderef($taxon));
            $gene->type($g->noderef($genetype));
        }
        my $cnode = $g->term_noderef($termacc);
        if (!$cnode->namespace) {
            $cnode->namespace(_aspect2ns($aspect));
        }

        my %qualh = map {lc($_)=>1} (split(/[\|]\s*/,$qualifier || ''));
        my $ev = new GOBO::Evidence(type=>$g->term_noderef($evcode));
        # TODO: discriminate between pipes and commas
        # (semicolon is there for legacy reasons - check if this can be removed)
        my @with_objs = map {$g->noderef($_)} split(/\s*[\|\;\,]\s*/, $with);
        $ev->supporting_entities(\@with_objs);
        my @refs = split(/\|/,$ref);
        my $provenance = $g->noderef(pop @refs); # last is usually PMID
        $provenance->add_xrefs([@refs]);
        my $annot = 
            new GOBO::Annotation(node=>$gene,
                                target=>$cnode,
                                provenance=>$provenance,
                                source=>$g->noderef($source_db),
                                date=>$assocdate,
            );
        if ($geneproduct) {
            $geneproduct =~ s/\s+//g;
            if ($geneproduct) {
                $annot->specific_node($g->noderef($geneproduct));
            }
        }
        # if >1 taxon supplied, additional taxon specifies target species
        if (@taxa) {
            my $xp = 
                GOBO::ClassExpression::RelationalExpression->new(relation=>'target_taxon',
                                                                 target=>$g->noderef($taxon));
            $annot->add_target_differentia($xp);
            
        }
        $annot->evidence($ev);
        foreach my $qk (keys %qualh) {
            $annot->add_qualifier($g->noderef($qk));
        }
        if ($qualh{not}) {
            $annot->negated(1);
        }
        if ($annotxp) {
            $annotxp =~ s/\s+//g; 
            if ($annotxp) {
                my $xp = GOBO::ClassExpression->parse_idexpr($g,$annotxp);
                $annot->add_target_differentia($xp);
            }
        }
        $g->add_annotation($annot);
        #push(@{$g->annotations},$annot);
    }
    return;
}

# the following is specific to GO
sub _aspect2ns {
    my $aspect = shift;
    return 'molecular_function' if $aspect eq 'F';
    return 'biological_process' if $aspect eq 'P';
    return 'cellular_component' if $aspect eq 'C';
}

1;
