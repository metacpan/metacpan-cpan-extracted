package GOBO::Writers::OBOWriter;
use Moose;
use strict;
extends 'GOBO::Writers::Writer';
use GOBO::Node;
use GOBO::LinkStatement;

sub write_header {
    my $self = shift;
    my $g = $self->graph;
    $self->tagval('format-version','1.2');
    $self->tagval(data_version => $g->version) if $g->version;
    $self->tagval(date=>sprintf("%s %02d:%02d",$g->date->dmy(':'),$g->date->hour,$g->date->minute)) if $g->date;
    my $pvm = $g->property_value_map || {};
    $self->tagval($_ => $pvm->{$_}) foreach sort keys %$pvm;
    $self->tagval(subsetdef => sprintf('%s "%s"',$_->id, $_->label)) foreach sort { $a->id cmp $b->id || $a->label cmp $b->label } @{$g->declared_subsets || []};
    $self->tagval(remark=> $g->comment);
    return;
}

sub _order_by_id {
    my @nodes = @_;
    return sort {$a->id cmp $b->id} @nodes;
}

sub write_body {
    my $self = shift;
    my $g = $self->graph;

    foreach my $term (_order_by_id(@{$g->terms})) {
        $self->write_stanza($term);
    }
    foreach my $relation (_order_by_id(@{$g->relations})) {
        $self->write_stanza($relation);
    }
    foreach my $instance (_order_by_id(@{$g->instances})) {
        $self->write_stanza($instance);
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
        $stanzaclass = 'Term';
    }
    elsif ($node->isa('GOBO::RelationNode')) {
        $stanzaclass = 'Typedef';
    }
    elsif ($node->isa('GOBO::Annotation')) {
        # TODO
    }
    
    $self->open_stanza($stanzaclass);
    $self->tagval('id',$node->id);
    $self->tagval('name',$node->label);
    $self->tagval('namespace',$node->namespace);
    $self->tagval('alt_id',$_) foreach sort @{$node->alt_ids || []};
    if ($node->can('definition') && $node->definition) {
        $self->ntagval('def', _quote($node->definition), $node->definition_xrefs || [])
    }
    $self->tagval('comment',$node->comment);
    $self->tagval('subset',$_->id) foreach sort { $a->id cmp $b->id || $a->label cmp $b->label } @{$node->subsets || []};
    $self->ntagval('synonym',
        _quote($_->label),$_->scope,$_->type,$_->xrefs || []) foreach sort { $a->label cmp $b->label } @{$node->synonyms || []};

    $self->tagval('xref',$_) foreach (sort @{$node->xrefs || []});

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
                $self->tagval(intersection_of => $_->target);
            }
            else {
                $self->tagvals(intersection_of => ($_->relation, $_->target));
            }
        }
        else {
            if ($_->relation->is_subsumption) {
                $self->tagval(is_a => $_->target, $_);
            }
            else {
                $self->tagvals(relationship => ($_->relation, $_->target, {statement=>$_}));
            }
        }
    }
    if ($node->can('union_definition')) {
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
    }
    if ($node->can('logical_definition')) { # rely on expanded links for now
        my $intersection = $node->logical_definition;
        if ($intersection && $intersection->isa('GOBO::ClassExpression::Intersection')) {
            my $ul = $intersection->arguments;
            if (@$ul > 1) {
                foreach (@$ul) {
                    if ($_->isa('GOBO::ClassExpression::RelationalExpression')) {
                        $self->tagvals(intersection_of => ($_->relation, $_->target) );
                    }
                    else {
                        $self->tagvals(intersection_of => $_);
                    }
                }
            }
            else {
                $self->throw("illegal intersection term: $intersection in $node");
            }
        }
    }
    if ($node->can("disjoint_from_list")) {
        foreach my $x (@{$node->disjoint_from_list || []}) {
            $self->tagval(disjoint_from => $x);
        }
    }
    if ($node->can("equivalent_to_list")) {
        foreach my $x (@{$node->equivalent_to_list || []}) {
            $self->tagval(equivalent_to => $x);
        }
    }
    $self->unary("is_obsolete") if $node->obsolete;
    $self->tagval('replaced_by',$_) foreach sort @{$node->replaced_by || []};
    $self->tagval('consider',$_) foreach sort @{$node->consider || []};
    $self->tagval('created_by',$node->created_by);
    #$self->tagval('creation_date',$node->creation_date->format_cldr('yyyy-MM-ddTHH:mm:ss.SSSZ')) if $node->creation_date;
    $self->tagval('creation_date',$node->creation_date->iso8601 . 'Z') if $node->creation_date;
    
    return;
}

sub _chain {
    my $arr = shift;
    return join(' ',map {$_->id} @$arr);
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

sub open_stanza {
    my $self = shift;
    my $c = shift;
    $self->println("[$c]");
    return;
}

sub unary {
    my $self = shift;
    $self->tagval(shift, 'true');
}

sub tagval {
    my $self = shift;
    my $tag = shift;
    my $val = shift;
    my $s = shift;
    return unless defined $val;
    if (ref($val)) {
        if ($val->can('id')) {
            $self->printf("%s: %s",$tag,$val->id);
        }
        #$self->set_referenced($val);
    }
    else {
        $self->printf("%s: %s",$tag,$val);
    }

    $self->trailing_qualifiers($s);
    
    if (ref($val) && $val->can('label') && $val->label) {
        $self->printf(" ! %s\n",$val->label);
    }
    else {
        $self->printf("\n");
    }
}

sub tagvals {
    my $self = shift;
    my $tag = shift;
    my $s;
    if (ref($_[-1]) eq 'HASH') {
        my $h = pop @_;
        $s = $h->{statement};
    }
    $self->printf("%s: %s",$tag,join(' ', map {ref($_) ? $_->id : $_ } @_));
    #$self->set_referenced(@_);

    $self->trailing_qualifiers($s);

    my @labels = map {ref($_) && $_->label && $_->label ne $_->id ? $_->label : () } @_;
    if (@labels) {
        $self->print(" ! @labels");
    }
    $self->print("\n");
    return;
}

sub trailing_qualifiers {
    my $self = shift;
    my $s = shift;
    if ($s && scalar(@{$s->sub_statements || []})) {
        $self->printf(" {%s}",
                      join(', ',
                           map {
                               sprintf('%s="%s"', $_->relation->id, $_->target);
                           } @{$s->sub_statements}));
    }
    return;
}

sub set_referenced {
    my $self = shift;
    foreach (@_) {
        if (ref($_) && $_->isa('GOBO::ClassExpression')) {
            # TODO
        }
    }
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
