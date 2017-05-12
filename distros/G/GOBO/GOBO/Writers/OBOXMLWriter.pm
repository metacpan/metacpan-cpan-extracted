package GOBO::Writers::OBOXMLWriter;
use Moose;
use strict;
extends 'GOBO::Writers::Writer';
use GOBO::Node;
use GOBO::LinkStatement;

sub write_header {
    my $self = shift;
    my $g = $self->graph;
    $self->tagval('format-version','1.2');
    return;
}

sub write_body {
    my $self = shift;
    my $g = $self->graph;

    foreach my $term (@{$g->terms}) {
        $self->write_stanza($term);
    }
    foreach my $relation (@{$g->relations}) {
        $self->write_stanza($relation);
    }
    foreach my $ann (@{$g->annotations}) {
        $self->write_annotation_stanza($ann);
    }
    # TODO: instances
    return;
}

sub write_stanza {
    my $self = shift;
    my $node = shift;
    my $g = $self->graph;

    $self->nl;
    my $stanzaclass = 'Instance';
    if ($node->isa('GOBO::TermNode')) {
        $stanzaclass = 'term';
    }
    elsif ($node->isa('GOBO::RelationNode')) {
        $stanzaclass = 'typedef';
    }
    elsif ($node->isa('GOBO::Annotation')) {
        $stanzaclass = 'annotation';
    }
    
    $self->open_element($stanzaclass);
    $self->tagval('id',$node->id);
    $self->tagval('name',$node->label);
    $self->tagval('namespace',$node->namespace);
    $self->tagval('alt_id',$_) foreach @{$node->alt_ids || []};
    if ($node->definition) {
        $self->ntagval('def', [],
                       [defstr=>$node->definition], 
                       map {_dbxref($_)} @{$node->definition_xrefs || []});
    }
    $self->tagval('comment',$node->comment);
    $self->tagval('subset',$_->id) foreach @{$node->subsets || []};
    foreach my $s (@{$node->synonyms || []}) {
        $self->ntagval('synonym',[scope=>$s->scope],
                       [synonym_text=>$s->label],
                       map {_dbxref($_)} @{$s->definition_xrefs || []});

    # xref

    if ($node->isa('GOBO::RelationNode')) {
        $self->tagval('domain', $node->domain);
        $self->tagval('range', $node->range);
        foreach (GOBO::RelationNode->unary_property_names) {
            $self->unary("is_$_") if $node->$_();
        }
        $self->tagval('holds_over_chain', _chain($_)) foreach @{$node->holds_over_chain_list || []};
        $self->tagval('equivalent_to_chain', _chain($_)) foreach @{$node->equivalent_to_chain_list || []};
    }

    foreach (@{$g->get_target_links($node)}) {
        if ($_->is_intersection) {
            if ($_->relation->is_subsumption) {
                $self->ntagval(intersection_of => ([], [to=>$_->target]));
            }
            else {
                $self->ntagval(intersection_of => ([], [type=>$_->relation, to=>$_->target]));
            }
        }
        else {
            if ($_->relation->is_subsumption) {
                $self->tagval(is_a => $_->target, $_);
            }
            else {
                $self->ntagval(relationship => ([],[type=>$_->relation, to=>$_->target]);
            }
        }
    }
    my $union = $node->union_definition;
    if ($union) {
        my $ul = $union->arguments;
        if (@$ul > 1) {
            $self->tagvals(union_of => $_) foreach @$ul;
        }
        else {
            $self->throw("illegal union term: $union in $node");
        }
    }
    $self->close_element($stanzaclass);
    return;
}

sub _chain {
    my $arr = shift;
    return map {[relation=>$_->id] @$arr);
}

sub write_annotation_stanza {
    my $self = shift;
    my $ann = shift;
    my $g = $self->graph;

    $self->nl;
    my $stanzaclass = 'Annotation';
    
    $self->open_stanza($stanzaclass);
    $self->tagval('id',$ann->id) if $ann->id;  # annotations need not have an ID
    $self->tagval(subject=>$ann->node->id);
    $self->tagval(relation=>$ann->relation->id);
    $self->tagval(object=>$ann->target->id);
    $self->tagval(description=>$ann->description);
    $self->tagval(source=>$ann->provenance->id) if $ann->provenance;
    $self->tagval(assigned_by=>$ann->source->id) if $ann->source;
    return;
}

sub open_element {
    my $self = shift;
    my $c = shift;
    $self->println("<$c>");
    return;
}

sub open_element {
    my $self = shift;
    my $c = shift;
    $self->println("</$c>");
    return;
}

sub unary {
    my $self = shift;
    $self->tagval(shift, 'true');
}

sub tagval {
    my $self = shift;
    my $tag = shift;
    my $obj = shift;
    my $s = shift;
    return unless defined $obj;
    my $val = ref($obj) ? $obj->id : $obj;
    if (ref($val)) {
        $val;
    }
    else {
        $self->printf("%s: %s",$tag,$val);
    }

    # TODO
    if ($s && scalar(@{$s->sub_statements || []})) {
        $self->printf(" {%s}",
                      join(', ',
                           map {
                               sprintf('%s="%s"', $_->relation->id, $_->target);
                           } @{$s->sub_statements}));
    }
    
    if (ref($val) && $val->label) {
        $self->printf(" ! %s\n",$val->label);
    }
    else {
        $self->printf("\n");
    }

}

sub tagvals {
    my $self = shift;
    my $tag = shift;
    $self->printf("%s: %s",$tag,join(' ', map {ref($_) ? $_->id : $_ } @_));
    my @labels = map {ref($_) && $_->label && $_->label ne $_->id ? $_->label : () } @_;
    if (@labels) {
        $self->print(" ! @labels");
    }
    $self->print("\n");
    return;
}

sub _quote {
    my $s = shift;
    $s =~ s/\"/\\\"/g;
    return sprintf('"%s"',$s);
}

# n-ary tags
sub ntagval {
    my $self = shift;
    my $tag = shift;
    my @vals = @_;
    $self->printf("%s:",$tag);
    foreach my $v (@vals) {
        next unless defined $v;
        $self->print(" ");
        if (ref($v)) {
            if (ref($v) eq 'ARRAY') {
                $self->print("[");
                $self->print(join(', ',
                                  @$v)); # TODO
                $self->print("]");
            }
            elsif (ref($v) eq 'HASH') {
                $self->print("{");
                $self->print(join(', ',
                                  map {
                                      sprintf('%s=%s',$_,_quote($v->{$_}))
                                  } keys %$v)); # TODO
                $self->print("}");
            }
            else {
            }
        }
        else {
            $self->print($v);
        }
    }
    $self->nl;
}


1;
