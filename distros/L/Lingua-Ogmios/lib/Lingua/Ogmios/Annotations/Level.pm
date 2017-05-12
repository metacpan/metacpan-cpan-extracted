package Lingua::Ogmios::Annotations::Level;

use strict;
use warnings;

sub new {
    my ($class, $fields) = @_;

#    if (defined $fields) {
    # TO UNCOMMENT LATER
#     if (!defined($fields->{'XML_order'})) {
# 	die 'No XML order defined';
#     }
#    }
#     if (!defined($fields->{'name'})) {
# 	die 'name order defined';
#     }
#    }

    my $level = {
	'name' => $fields->{'name'},
	'id' => 0,
	'log_id' => -1,
	'comments' => undef,
	'elements' => [],
	'indexfields' => ['id', 'token'],
	'indexes' => {'id' => {}, 'token' => {}},
	'XML_order' => [],
    };
    bless $level, $class;

    if (defined $fields) {
	if (defined $fields->{'indexes'}) {
	    $level->addIndex($fields->{'indexes'});
	}
	if (defined($fields->{'XML_order'})) {
	    $level->setXMLorder($fields->{'XML_order'});
	}

    }
    return $level;
}


sub setName {
    my ($self, $name) = @_;

    $self->{'name'} = $name;
}

sub getName {
    my ($self) = @_;

    return($self->{'name'});
}

sub setXMLorder {
    my ($self, $xml_order) = @_;

    push @{$self->getXMLorder}, @$xml_order;

}

sub getXMLorder {
    my ($self) = @_;

    return($self->{'XML_order'});
}


sub resetIndexes {
    my ($self) = @_;
    my $field;

    foreach $field (@{$self->getIndexfields}) {
	$self->getIndexes->{$field} = {};
    }
}

sub getIndexfields {
    my ($self) = @_;

    return($self->{indexfields});
}

sub getIndexes {
    my ($self) = @_;

    return($self->{'indexes'});
}

sub getElement {
    my ($self, $id) = @_;

    return($self->getIndexes->{'id'}->{$id});
}

sub existsElement {
    my ($self, $id) = @_;

    return(exists($self->getIndexes->{'id'}->{$id}));
}

sub getElementFromIndex {
    my ($self, $indexfield, $id) = @_;
    my $element;
    my %elements;
    my @elts;

#     return($self->getIndexes->{$indexfield}->{$id});

#    warn "$indexfield : $id\n";

    if ($self->existsElementFromIndex($indexfield,$id)) {
	foreach $element (@{$self->getIndexes->{$indexfield}->{$id}}) {
#	warn $element->getId . "\n";
	    $elements{$element->getId} = $element;
	}
	@elts = values(%elements);

#    warn join(" : ", @elts) . "\n";
    }
    return(\@elts);
}

sub getElementFromIndex2 {
    my ($self, $indexfield, $searchedElement) = @_;
    my $element;
    my %elements;
    my @elts;

#     return($self->getIndexes->{$indexfield}->{$id});

#     warn "$indexfield : $searchedElement " . $searchedElement->getId . "\n";

    foreach $element (@{$self->getIndexes->{$indexfield}->{$searchedElement->getId}}) {
 	# warn ref($element) . "\n";
	# warn "\t" . ref($element->_getField($indexfield)->{$element->_getField($indexfield)->{"reference"}}->[0]) . "\n";
	if (ref($searchedElement) eq ref($element->_getField($indexfield)->{$element->_getField($indexfield)->{"reference"}}->[0])) {
	    $elements{$element->getId} = $element;
	}
    }
    @elts = values(%elements);

#     warn join(" : ", @elts) . "\n";;

    return(\@elts);
}

sub existsElementFromIndex {
    my ($self, $indexfield, $id) = @_;

    return(exists($self->getIndexes->{$indexfield}->{$id}));

}

sub existsElementFromIndex2 {
    my ($self, $indexfield, $searchedElement) = @_;

    return((exists($self->getIndexes->{$indexfield}->{$searchedElement->getId})) && (ref($searchedElement) eq ref($self->getIndexes->{$indexfield}->{$searchedElement->getId})));

}

sub existsElementFromReference {
    my ($self, $element) = @_;

    if (exists $element->{'reference'}) {
	my @ref = @{$element->getReference};
	if ($self->existsElementFromIndex("list_refid_token", $ref[0]->getId)) {
	    my $ne = $self->getElementFromIndex("list_refid_token", $ref[0]->getId)->[0];
	    my @ref_ne = @{$ne->getReference};
	    my $i = 0;
	    
	    while(($i < scalar(@{$ne->getReference})) && ($i < scalar(@ref)) && 
		  ($ref_ne[$i]->equals($ref[$i]))) {
		$i++
	    };
	    if ($i < scalar(@ref)) {
		return(0);
	    } else {
		return(1);
	    }
	    
	}
    }

    

#     return(exists($self->getIndexes->{$indexfield}->{$id}));

}

sub printIndex {
    my ($self, $indexfield, $fh) = @_;
    if (!defined $fh) {
	$fh = \*STDERR
    }

    my $elt;
    my $idx;
    my $item;

    foreach $idx (keys %{$self->getIndex($indexfield)}) {
	print $fh "$idx:\n";
	print $fh "\t" . $self->getIndex($indexfield)->{$idx} . "\n";
	if (ref($self->getIndex($indexfield)->{$idx}) eq "ARRAY") {
	    foreach $item (@{$self->getIndex($indexfield)->{$idx}}) {
		print $fh "\t (" . ref($item) . ") " . $item->getId . "\n";
# 		print $fh "\t (" . ref($item) . ") " . $item->_getField($indexfield) . " : " . $item->getForm . "\n";
	    }
	} else {
		print $fh "\t (" . ref($item) . ") " . $self->getIndex($indexfield)->{$idx}->getId . "\n";
# 		print $fh "\t (" . ref($item) . ") " . $self->getIndex($indexfield)->{$idx}->_getField($indexfield) . " : " . $item->getForm . "\n";
	}
    }
    return(0);
}

sub getIndex {
    my ($self, $indexfield) = @_;

    return($self->getIndexes->{$indexfield});
}

sub existsIndex{
    my ($self, $indexfield) = @_;

    return(exists $self->getIndexes->{$indexfield});
}

# check if the method as to be generalized
sub addComponentToList {
    my ($self, $element, $component) = @_;

    if (exists $self->getIndexes->{'list_refid_components'}) {
	$element->addComponent($component);
	
	if (!exists $self->getIndexes->{'list_refid_components'}->{$component->getId}) {
	    $self->getIndexes->{'list_refid_components'}->{$component->getId} = [];
	}
	push @{$self->getIndexes->{'list_refid_components'}->{$component->getId}}, $element;
# 	$self->getIndexes->{'list_refid_components'}->{$component->getId} = $element;
    }
}


sub addElementToIndexes {
    my ($self, $element) = @_;
    my $field;
    my $value;
    my $val;
    my $val_element;
    my $component;

    my @indexfields = @{$self->getIndexfields};
    $field = shift @indexfields;
    $self->getIndexes->{$field}->{$element->getId} = $element;
    $field = shift @indexfields;
    # warn "== $element\n";
    $self->addElementToTokenIndex($element);
    # warn "--\n";
    foreach $field (@indexfields) {
	# warn "... ($field)\n";
	$self->addElementToIndex($element, $field);
	# warn "+++ ($field)\n";
    }
}

sub addElementToTokenIndex {
    my ($self, $element) = @_;
    my $ref;
    my $elt;
    my @refs;
    my $i;

    # warn "ref: " . ref($element) . "\n";

    if (ref($element) eq "Lingua::Ogmios::Annotations::Token") {
	if (! exists $self->getIndex('token')->{$element->getId}) {
	    $self->getIndex('token')->{$element->getId} = [];
	}
	push @{$self->getIndex('token')->{$element->getId}}, $element;
    } else {
	$ref = $element->reference;
	if (ref($ref) eq "ARRAY") {
	    @refs = @{$ref};
	} else {
	    push @refs, $ref;
	}
	for($i=0;$i< scalar(@refs);$i++) {
	    $elt = $refs[$i];
	    if (ref($elt) eq "Lingua::Ogmios::Annotations::Token") {
		if (! exists $self->getIndex('token')->{$elt->getId}) {
		    $self->getIndex('token')->{$elt->getId} = [];
		}
		push @{$self->getIndex('token')->{$elt->getId}}, $element;
	    } else {
		if ((ref($elt) eq "Lingua::Ogmios::Annotations::Word") || 
		    (ref($elt) eq "Lingua::Ogmios::Annotations::Phrase") ||
		    (ref($elt) eq "Lingua::Ogmios::Annotations::SemanticUnit")#  ||
		    ) {
		    $ref = $elt->reference;
		    if (ref($ref) eq "ARRAY") {
			push @refs, @$ref;
		    } else {
			push @refs, $ref;
		    }
		} else {
#			warn "->$elt\n";
		}
	    }
	}
#	    warn join(':', @{$element->reference}) . "\n";
    }
}

sub addElementToIndex {
    my ($self, $element, $field) = @_;
    my $value;
    my $val;
    my $val_element;
    my $component;

    $value = $element->_getField($field);
    # warn "$field\n";
    # warn "     ($value)\n";

    # if (($field eq "type") && (defined $value)) {
    # 	warn "$field ($value)\n";
    # }
    if (defined $value) {
	if (ref($value) eq "ARRAY") {
	    foreach $val (@$value) {
		$val_element = $val;
		if (index(ref($val), "Lingua::Ogmios::Annotations::") == 0) {
		    $val_element = $val->getId;
		}
		if (!exists $self->getIndexes->{$field}->{$val_element}) {
		    $self->getIndexes->{$field}->{$val_element} = [];
		}
		push @{$self->getIndexes->{$field}->{$val_element}}, $element;
	    }
	} else { 
	    if (ref($value) eq "HASH") {
		foreach $component (keys %$value) {
		    if ($component ne "reference") {
			foreach $val (@{$value->{$component}}) {
			    $val_element = $val;
			    if (index(ref($val), "Lingua::Ogmios::Annotations::") == 0) {
				$val_element = $val->getId;
			    }
			    if (!exists $self->getIndexes->{$field}->{$val_element}) {
				$self->getIndexes->{$field}->{$val_element} = [];
			    }
			    push @{$self->getIndexes->{$field}->{$val_element}}, $element; #{$element => $component};
			}
		    }
		}
		
	    } else {
		$val_element = $value;
		if (index(ref($value), "Lingua::Ogmios::Annotations::") == 0) {
		    $val_element = $value->getId;
		}
		if (!exists $self->getIndexes->{$field}->{$val_element}) {
		    $self->getIndexes->{$field}->{$val_element} = [];
		}
		push @{$self->getIndexes->{$field}->{$val_element}}, $element;
	    }
	}
    # } else {
    # 	warn "undefined field: $field\n";
    }
}


sub delElementToIndexes {
    my ($self, $element) = @_;
    my $field;
    my $value;
    my $val;
    my $val_element;
    my $component;
    my $i;

    my @indexfields = @{$self->getIndexfields};
    $field = shift @indexfields;

    # $value = $element->_getField($field);
    # print STDERR "$field";
    # warn " : $value\n";

    delete $self->getIndexes->{$field}->{$element->getId};
    # $field = shift @indexfields;
    # $self->delElementToTokenIndex($element);
    
    foreach $field (@indexfields) {
	$value = $element->_getField($field);
	# print STDERR "$field";
	# warn " : $value\n";

	if (defined $value) {
	    if (ref($value) eq "ARRAY") {
		foreach $val (@$value) {
		    $val_element = $val;
		    if (index(ref($val), "Lingua::Ogmios::Annotations::") == 0) {
			$val_element = $val->getId;
		    }
		    $self->delElementFromIndex($val_element, $field, $element);
		}
	    } else { 
		if (ref($value) eq "HASH") {
		    $i = 0;
		    foreach $component (keys %$value) {
			if ($component ne "reference") {
			    foreach $val (@{$value->{$component}}) {
				$val_element = $val;
				if (index(ref($val), "Lingua::Ogmios::Annotations::") == 0) {
				    $val_element = $val->getId;
				}
				$self->delElementFromIndex($val_element, $component, $element);
			    }
			}
		    }
		} else {
		    $val_element = $value;
		    if (index(ref($value), "Lingua::Ogmios::Annotations::") == 0) {
			$val_element = $value->getId;
		    }
		    # warn "====> $val_element\n";

		    $self->delElementFromIndex($val_element, $field, $element);
		}
	    }
	}
    }
}

sub delElementFromIndex {
    my ($self, $value, $field, $element) = @_;
    my $i;

    if (exists $self->getIndexes->{$field}->{$value}) {
	# warn "--> $field " . join(":", @{$self->getIndexes->{$field}->{$value}}) . "\n";
	$i = 0;
	while(($i < scalar(@{$self->getIndexes->{$field}->{$value}})) &&
	      (!($self->getIndexes->{$field}->{$value}->[$i]->equals($element)))) {
	    $i++;
	}
	if ($i < scalar(@{$self->getIndexes->{$field}->{$value}})) {
	    splice(@{$self->getIndexes->{$field}->{$value}}, $i, 1);
	    # warn "--del--\n";
	} else {
	    # warn "value ($value) not found in $field\n";
	}
	if (scalar(@{$self->getIndexes->{$field}->{$value}}) == 0) {
	    delete $self->getIndexes->{$field}->{$value};
	    # warn "---del---\n";
	}
    }
}


sub addIndex {
    my ($self, $fields) = @_;
    my $field;

    foreach $field (@$fields) {
	if (!$self->existsIndex($field)) {
	    push @{$self->getIndexfields}, $field;
	    $self->getIndexes->{$field} = {};
	}
    }
}

sub setId {
    my ($self, $id) = @_;

    $self->{'id'} = $id;
}

sub setMaxId {
    my ($self, $id) = @_;

    if ($id > $self->getId) {
	$self->setId($id);
    }
}

sub getId {
    my ($self) = @_;

    return($self->{'id'});
}

sub incrId {
    my ($self) = @_;

    return($self->setId($self->getId + 1));
}

sub _decrId {
    my ($self) = @_;

    return($self->setId($self->getId - 1));
}

sub getLog_Id {
    my ($self) = @_;

    return($self->{'log_id'});
}

sub incrLog_Id {
    my ($self) = @_;

    return($self->setLog_Id($self->getLog_Id + 1));
}

sub _decrLog_Id {
    my ($self) = @_;

    return($self->setLog_Id($self->getLog_Id - 1));
}


sub resetElements {
    my ($self) = @_;
    my $field;

    $self->{'elements'} = [];
    $self->resetIndexes;
}

sub getElements {
    my ($self) = @_;

    return($self->{'elements'});
}

sub getSize {
    my ($self) = @_;

    return(scalar(@{$self->getElements}));
}


sub getLastElement {
    my ($self) = @_;

    if ($self->getSize != 0) {
	return($self->getElements->[$#{$self->getElements}]);
    } else {
	return(undef);
    }
#     my $elements = $self->getElements;
#     $element->previous($elements->[$#$elements]);

#     $elements->[$#$elements]
#    return($self->{'elements'});
}

sub getFirstElement {
    my ($self) = @_;

    my $i = 0;

    while(($self->getSize != 0) && (!exists($self->getElements->[$i]))) { $i++; };

    if ($self->getSize != 0) {
	return($self->getElements->[$i]);
    } else {
	return(undef);
    }
#     my $elements = $self->getElements;
#     $element->previous($elements->[$#$elements]);

#     $elements->[$#$elements]
#    return($self->{'elements'});
}


sub setComments {
    my ($self) = @_;

    $self->{'comments'} = {};
}

sub getComments {
    my ($self) = @_;

    return($self->{'comments'});
}

sub replaceElement {
    my ($self, $oldElement, $newElement) = @_;

    $newElement->setId($oldElement->getId);

    $newElement->previous($oldElement->previous);
    if (defined $oldElement->previous) {
	$oldElement->previous->next($newElement);
    }
    $newElement->next($oldElement->next);
    if (defined $oldElement->next) {
	$oldElement->next->previous($newElement);
    }

    $self->delElementToIndexes($oldElement);
    $self->addElementToIndexes($newElement);

#     $self->delElement($oldElement);
    $self->addElementToIndexes($newElement);
    $self->delElementToIndexes($oldElement);

    return($newElement->getId);
}

sub addElement {
    my ($self, $element) = @_;

    my $id;

#    warn "++>" . $element->getId . "\n";
    if ($element->getId == -1) {
	$id = $self->incrId;
	$element->setId($id);
	
    } else {
	$id  = $element->getId;	
	$self->setMaxId($id);
#	warn "$id already exists (IdElement)\n";
    }
    if (defined $self->getLastElement) {
	$element->previous($self->getLastElement);
	$self->getLastElement->next($element);
    }
    push @{$self->getElements}, $element;
    $self->addElementToIndexes($element);
    return($id);
}

sub delElement {
    my ($self, $element) = @_;

    if (defined $element->previous) {
	$element->previous->next($element->next);
    }

    my $i = 0;

    while(($i < $self->getSize) && ((!defined($self->getElements->[$i])) || (!$self->getElements->[$i]->equals($element)))) {
	$i++;
    }

    if ($i < $self->getSize) {
	splice(@{$self->getElements},$i,1);
	# warn "delElement\n";
	$self->delElementToIndexes($element);
    }
    return($element->getId);
}

sub changeRefFromIndexField {
    my ($self, $indexfield, $oldvalue, $newvalue) = @_;
    my $section;

    foreach $section (@{$self->getElementFromIndex($indexfield, $oldvalue)}) {
	$section->_setField($indexfield, $newvalue);
    }
}

sub resetIndex {
    my ($self, $indexfield) = @_;

    $self->getIndexes->{$indexfield} = {};
}

sub rebuildIndex {
    my ($self) = @_;

    my $element;
    my $field;
    my $value;

#    warn "rebuild Index\n";
    my @indexfields = @{$self->getIndexfields};
#    shift @indexfields;
#     $field = shift @indexfields;
#     $self->getIndexes->{$field}->{$element->getId} = $element;
    foreach $field (@indexfields) {
	$self->resetIndex($field);
	# warn "field: $field\n";
	foreach $element (@{$self->getElements}) {
	    # warn "element: $element\n";
	    $self->addElementToIndexes($element);
# 	    $value = $element->_getField($field);
# 	    if (!exists $self->getIndexes->{$field}->{$value}) {
# 		$self->getIndexes->{$field}->{$value} = [];
# 	    }
# 	    push @{$self->getIndexes->{$field}->{$value}}, $element;
	}
    }
}

sub printXML {
    my ($self) = @_;

    
}

sub XMLout {
    my ($self) = @_;

    my $element;
    my $name = $self->getName;
    my $order = $self->getXMLorder;
    my $str;

    $str = "  <$name" . "_level>\n";
    foreach $element (@{$self->getElements}) {
	$str .= $element->XMLout($order);
    }
    $str .= "   </$name" . "_level>\n";
}

# sub getElementFromIndex {
#     my ($self, $indexfield, $id) = @_;

sub startsWith {
    my ($self, $element) = @_;

    if (exists $self->getIndex('from')->{$element->getFrom}) {
	return(1);
    } else {
	return(0);
    }
    
}

sub endsWith {
    my ($self, $element) = @_;
    
    if (exists $self->getIndex('to')->{$element->getTo}) {
	return(1);
    } else {
	return(0);
    }
}

sub existsElementByToken {
    my ($self, $token) = @_;

    return(exists($self->getIndex('token')->{$token->getId}));
}

sub getElementByToken {
    my ($self, $token) = @_;

    my @refs;
    my $elt = $self->getIndex('token')->{$token->getId};
    if (defined $elt) {
	return($elt);
    } else {
	return([]);
    }
    # push @refs, $self->getIndex('token')->{$token->getId};

    # warn scalar(@refs) . "\n";

    # return(\@refs);

	# return($self->getElementByOffset($token->getFrom));
}

sub getElementByToken1 {
    my ($self, $token) = @_;

#     if (exists $self->getElements->[0]->{'reference'}) {
# # TODO
#     } else {
#	$selt->getElements
#     warn "Search $token in ($self)\n";
	return($self->getElementByOffset($token->getFrom));
#     }
}

# this method has to be rewriten correctly
sub getElementByOffset {
    my ($self, $offset) = @_;

    my $element;

    my $fromOffset;
    my $from;
    my $toOffset;
    my $to;

    my @elements;
    
#         warn "Search $offset in ($self)\n";


    foreach $element (@{$self->getElements}) {
#    	warn "==> $element\n";
	if (defined $element) {
	    if ((defined $element->{'reference'}) || (defined $element->{'list_refid_components'})){
		$from = $element->start_token;
		$to = $element->end_token;
# 		warn "go1\n";
	    } else {
		if (defined $element->{'refid_start_token'}) {
# 		    warn "go2\n";
		    $from = $element->refid_start_token;
		    $to = $element->refid_end_token;

		} else {
		    $from = $element->getFrom;
		    $to = $element->getTo;
		}
	    }
	
#       	    warn "ref($from) : " . ref($from) . ";\n";
	    if (ref($from) eq "") {
		$fromOffset = $from;
	    } else {
		$fromOffset = $from->getFrom;		
	    }
#     	    warn "ref($to) : " . ref($to) . "\n";
	    if (ref($to) eq "") {
		$toOffset = $to;
	    } else {
		$toOffset = $to->getTo;		
	    }
	    
#    	warn "\tfrom $fromOffset to $toOffset\n";
	    if (($fromOffset <= $offset) && ($offset <= $toOffset)) {
#    	    warn "$offset is in the element " . $element->getId . " / " . $element->getForm . "\n";
#    	    warn "$offset is in the element " . $element->getId  . "\n";
		push @elements, $element;
	    }
	}
    }
#      warn "===================\n";
    return(\@elements);
}

sub getElementById {
    my ($self, $id) = @_;

    return($self->getElement($id));
}

sub contains {
    my ($self, $element) = @_;

    # warn "------------------------------------------------------------------------\n";
    # warn $element->getForm . "\n";
    my $levelElement;
    my $token = $element->start_token;
    my $offset = $token->getFrom;
    # warn "\t$offset\n\n";

    foreach $levelElement (@{$self->getElements}) {
	# warn "$levelElement\n";
	# warn "\t" . $levelElement->start_token->getFrom . "\n";
	# warn "\t" . $levelElement->end_token->getTo . "\n";
	if (($levelElement->start_token->getFrom <= $offset) &&
	    ($offset <= $levelElement->end_token->getTo)) {
#	    warn "OK\n";
	    return($levelElement);
	}
    }
    return(undef);
}

sub getElementsBetweenStartEndTokens {
    my ($self, $start_token, $end_token) = @_;

    my $token = $start_token;
    my %semFs;
    my $elt;

    foreach $elt (@{$self->getElementByToken($token)}) {
	$semFs{$elt->getId} = $elt;
#	warn $elt->getId . "\n";
    }

    while ((defined $token) && (!($token->equals($end_token)))) {
	$token = $token->next;
	if (defined $token) {
	    foreach $elt (@{$self->getElementByToken($token)}) {
		$semFs{$elt->getId} = $elt;
#		warn $elt->getId . "\n";
	    }
	}
    }

    return(values(%semFs));
}

sub getElementByStartEndTokens {
    my ($self, $start_token, $end_token) = @_;

    my $term;
    my @terms;

    # warn "$start_token: " . $start_token->getId . "\n";
    foreach $term (@{$self->getElementByToken($start_token)}) {
	# warn "$term\n";
	if (($term->start_token->equals($start_token)) && ($term->end_token->equals($end_token))) {
	    push @terms, $term;
	}
    }
    if (scalar(@terms) > 0) {
	return($terms[0]);
    } else {
	return(undef);
    }
}


sub existsElementByStartEndTokens {
    my ($self, $start_token, $end_token) = @_;

    my $term;
    my @terms;

    # warn "$start_token: " . $start_token->getId . "\n";
    foreach $term (@{$self->getElementByToken($start_token)}) {
	# warn "$term\n";
	if (($term->start_token->equals($start_token)) && ($term->end_token->equals($end_token))) {
	    push @terms, $term;
	}
    }
    return(scalar(@terms) > 0);
}

sub getElementsByStartToken {
    my ($self, $start_token) = @_;

    my $term;
    my @terms;

    # warn "$start_token: " . $start_token->getId . "\n";
    foreach $term (@{$self->getElementByToken($start_token)}) {
	# warn "$term\n";
	if ($term->start_token->equals($start_token)) {
	    push @terms, $term;
	}
    }
    return(\@terms);
}

1;

__END__

=head1 NAME

Lingua::Ogmios::Annotations::Level - Perl extension for the level of annotations

=head1 SYNOPSIS

use Lingua::Ogmios::Annotations::???;

my $word = Lingua::Ogmios::Annotations::???::new($fields);


=head1 DESCRIPTION


=head1 METHODS

=head2 function()

    function($rcfile);

=head1 FIELDS

=over

=item *


=back


=head1 SEE ALSO


=head1 AUTHORS

Thierry Hamon <thierry.hamon@limsi.fr>

=head1 LICENSE

Copyright (C) 2013 by Thierry Hamon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut

