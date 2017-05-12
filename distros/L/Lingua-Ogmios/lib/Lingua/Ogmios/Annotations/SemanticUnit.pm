package Lingua::Ogmios::Annotations::SemanticUnit;

use Lingua::Ogmios::Annotations::Element;

use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::Annotations::Element);

# <!--                    Named entities and terms         --> 
# <!ELEMENT  semantic_unit 
#                         (named_entity | term | undefined)+ > 
 

# <!--                    term                             --> 
# <!ELEMENT  term         (id, log_id?, (refid_phrase 
#                          | refid_word | list_refid_token), 
#                          weights, negation
#                          form?, canonical_form?)           > 

# <!ELEMENT weights       (                                  >
 
# <!--                    undefined semantic unit          --> 
# <!ELEMENT  undefined    (id, log_id?, (refid_phrase 
#                          | refid_word | list_refid_token), 
#                            form?, canonical_form?)         > 

# <!--                    named entity                     --> 
# <!ELEMENT  named_entity (id?, log_id?, (refid_phrase | 
#                          refid_word | list_refid_token)? , 
#                          form?, canonical_form?, 
#                          named_entity_type)                >

# at the creation defined a type (named_netity, term, undefined)

sub new {
    my ($class, $fields) = @_;

    my @refTypes = ('refid_phrase', 'refid_word', 'list_refid_token');

    if (!defined $fields->{'id'}) {
	$fields->{'id'} = -1;
    }
    if (!defined $fields->{'type'}) { # named_entity, term or undefined
	die("type is not defined");
    }
    my $sem_unit = $class->SUPER::new({
	'id' => $fields->{'id'},
# 	'form' => $fields->{'form'},
				      }
	);

    my $i = 0;
    my $reference_name;
    my $ref;
    foreach $ref (@refTypes) {
	if (defined $fields->{$ref}) {
	    $reference_name = $ref;
	    last;
	}
	$i++;
    }
    if ($i == scalar(@refTypes)) {
	die("reference (list) is not defined");
    }

#     if ((!defined $fields->{'refid_phrase'}) ||
# 	(!defined $fields->{'refid_word'}) ||
# 	(!defined $fields->{'list_refid_token'}))
#     {
# 	die("reference (list) is not defined");

#     }

    bless ($sem_unit,$class);

#     warn "=>>$reference_name\n";

    $sem_unit->reference($reference_name, $fields->{$reference_name});

    if (defined $fields->{'form'}) {
	$sem_unit->setForm($fields->{'form'});
    }
    if (defined $fields->{'weights'}) {
	$sem_unit->weights($fields->{'weights'});
    }

    if (defined $fields->{'negation'}) {
	$sem_unit->negation($fields->{'negation'});
    }

    if (defined $fields->{'log_id'}) {
	$sem_unit->setLogId($fields->{'log_id'});
    }	

    $sem_unit->type($fields->{'type'});
    
    if (defined $fields->{'canonical_form'}) {
	$sem_unit->canonical_form($fields->{'canonical_form'});
    }

    if ($sem_unit->isNamedEntity) { 
	$sem_unit->NEtype($fields->{'named_entity_type'});
    }

    return($sem_unit);
}

sub negation {
    my $self = shift;

    if (@_) {
	$self->{'negation'} = shift;
    }
    return($self->{'negation'});
}
sub printWeights {
    my ($self, $fh) = @_;
    my $weight_name;

    if (!defined $fh) {
	$fh = \*STDERR;
    }

    if (defined $self->weights) {
	foreach $weight_name (keys %{$self->weights}) {
	    print $fh "$weight_name : " . $self->weight($weight_name) . "\n";
	}
    }
}

sub weights {
    my $self = shift;
    
     if (@_) {
 	my $weights = shift;
	
# 	warn "$weights\n";

 	my $weight_name;
 	foreach $weight_name (keys %$weights) {
  	    # warn "$weight_name\n";
	    $self->{'weights'}->{$weight_name} = $weights->{$weight_name};
#  	    warn "$weight_name : " . $self->weights->{$weight_name} .  "\n";
 	}
     }
    
     return($self->{'weights'});
}

sub sortedWeightValues {
    my $self = shift;

    my @w;
    my $weight_name;

    foreach $weight_name (sort keys %{$self->weights}) {
	push @w, $self->weight($weight_name);
    }    
    return(@w);
}

sub numberOfWeights {
    my $self = shift;

    return(scalar(keys %{$self->weights}));
}

sub existsWeight {
    my $self = shift;
    my $weight_name = shift;

    return(exists($self->{'weights'}->{$weight_name}));
}

sub incr_weight {
    my ($self, $weight_name, $step) = @_;

    if (!defined($self->weight($weight_name))) {
	$self->weight($weight_name, 0);
    }
    $self->weight($weight_name, $self->weight($weight_name) + 1);
    return($self->weight($weight_name));
}

sub weight {
    my $self = shift;

    if (!defined $self->weights) {
	if (scalar(@_) > 0) {
	    $self->{'weights'} = {};
	} else {
	    return(undef);
	}
    }
    my $weight_name = shift;
    
    # warn "--> " .  $weight_name . "\n";
    # warn "\tOK\n";
    # warn scalar(@_) . "\n";
    if (@_) {
	# warn "\t  In\n";
	$self->{'weights'}->{$weight_name} = shift;
    }
    # warn "\t\t" . $self->{'weights'}->{$weight_name} . "\n";
    return($self->{'weights'}->{$weight_name});
}

sub newNamedEntity {
    my ($class, $fields) = @_;

    if (!defined $fields->{'named_entity_type'}) {
	die("named_entity_type is not defined");
    }

    $fields->{'type'} = "named_entity";

    return($class->new($fields));

}

sub newTerm {
    my ($class, $fields) = @_;

    $fields->{'type'} = "term";

    return($class->new($fields));
}

sub newUndefinedSemanticUnit {
    my ($class, $fields) = @_;

    $fields->{'type'} = "undefined";

    return($class->new($fields));
}

# type canonical_form reference NEtype isNamedEntoty

sub canonical_form {
    my $self = shift;

    $self->{'canonical_form'} = shift if @_;
    return $self->{'canonical_form'};
}

sub exists_canonical_form {
    my $self = shift;

    return exists($self->{'canonical_form'});
}

sub type {
    my $self = shift;

    $self->{'type'} = shift if @_;
    return $self->{'type'};
}

sub reference_name {
    my $self = shift;

    $self->{'reference'} = shift if @_;
    return $self->{'reference'};

}

sub reference {
    my $self = shift;
    my $ref;
    my $elt;

    if ((@_) && (scalar @_ == 2)) {
	$self->{'reference'} = shift;
	$ref = shift;

#	warn "term ref: " . ref($ref) . "\n";
	if (ref($ref)  eq "ARRAY") {
	    $self->{$self->{'reference'}} = [];
	    foreach $elt (@$ref) {
		push @{$self->{$self->{'reference'}}}, $elt;
	    }
	} else { # it's a single string
# 	    warn $self->{'reference'}  . ": $ref\n";
	    $self->{$self->{'reference'}} = $ref;

	}
    }
    return($self->{$self->{'reference'}});
}


sub getReferenceSize {
    my $self = shift;

    if ($self->reference_name eq "list_refid_token") {
	return(scalar(@{$self->{$self->{'reference'}}}));
    }
    if ($self->reference_name eq "refid_word") {
	return(1);
    }
    if ($self->reference_name eq "refid_phrase") {
	return(1);
    }
}

sub getReferenceWordSize {
    my $self = shift;

    my $elmt;
    if ($self->reference_name eq "list_refid_token") {
	return(scalar(@{$self->{$self->{'reference'}}}));
    }
    if ($self->reference_name eq "refid_word") {
	return(1);
    }
    if ($self->reference_name eq "refid_phrase") {
	my $wordCount = 0;
	foreach $elmt ($self->reference->getElementList) {
	    if (ref($elmt) eq "Lingua::Ogmios::Annotations::Word") {
		$wordCount++;
	    }	    
	}
	
	return($wordCount);
    }
}

sub getReferenceTokenSize {
    my $self = shift;

    if ($self->reference_name eq "list_refid_token") {
	return(scalar(@{$self->{$self->{'reference'}}}));
    }
    if ($self->reference_name eq "refid_word") {
	return($self->reference->getReferenceSize);
    }
    if ($self->reference_name eq "refid_phrase") {
	return($self->reference->getReferenceSize);
    }
}

sub getReference {
    my $self = shift;

    return($self->{$self->{'reference'}});
}

# sub equals_ref {
#     my ($self, $element) = @_;

#     my $i;
#     while(($i <scalar($self->getReference)) && ($i <scalar($element->getReference)) && 
# 	  ($self->getReference->[$i].equals($element->getReference->[$i]))) {
# 	$i++
#     };
#     if ($i < scalar($self->getReference)) {
# 	return(0);
#     } else {
# 	return(1);
#     }

# }

sub getElementFormList {
    my ($self) = @_;

    my $element;
    my @elements;
    

#     warn ref($self->getReference) . "\n";

    if (ref($self->getReference) eq "ARRAY") {
	foreach $element (@{$self->getReference}) {
# 	    warn "\t". $element->getElementFormList . "\n";
	    push @elements, $element->getElementFormList;
	}
    } else {
	push @elements, $self->getReference->getElementFormList;
    }
    return(@elements);
}


sub NEtype {
    my $self = shift;

    $self->{'named_entity_type'} = shift if @_;
    return $self->{'named_entity_type'};
}

sub isNamedEntity {
    my $self = shift;

    if ((exists $self->{'type'}) && ($self->{'type'} eq "named_entity")) {
	return 1;
    } else {
	return 0;
    }
}

sub isTerm {
    my $self = shift;

    if ((exists $self->{'type'}) && ($self->{'type'} eq "term")) {
	return(1);
    } else {
	return(0);
    }
}

sub end_token {
    my $self = shift;

#    warn $self->reference_name . "\n";

    if ($self->reference_name eq "list_refid_token") {
	return($self->reference->[$#{$self->reference}]);
    }
    #if list_refid token -> OK
    # if refid word -> word->start_token
    # OR
    # if refid phrase -> phrase->start_token
    if (($self->reference_name eq "refid_word") ||
	($self->reference_name eq "refid_phrase")){
	return($self->reference->end_token);
    }
    return(undef);
}

sub start_token {
    my $self = shift;


    if ($self->reference_name eq "list_refid_token") {
	return($self->reference->[0]);
    }
    #if list_refid token -> OK

    # if refid word -> word->start_token
    # OR
    # if refid phrase -> phrase->start_token
    if (($self->reference_name eq "refid_word") ||
	($self->reference_name eq "refid_phrase")){
	return($self->reference->start_token);
    }
    return(undef);
}

# Not check
sub preceeds {
    my ($self, $elt, $wordLimit, $document) = @_;

    my $token = $self->end_token;

    my $wordcount = 0;

    do {
	do {
	    $token = $token->next;
	} while($token->isSep);

	if ((!$token->equals($elt->end_token)) && ($wordcount < $wordLimit)){
	    if (scalar(@{$document->getAnnotations->getWordLevel->getElementByToken($token)}) > 0) {
		$token = $document->getAnnotations->getWordLevel->getElementByToken($token)->end_token;
		$wordcount++;
	    }
	}
    } while((!$token->equals($elt->end_token)) && ($wordcount < $wordLimit));

    if ($token->equals($elt->end_token)) {
	return(1);
    } else {
	return(0);
    }
}


sub getPreceedingTerm {
    my ($self, $wordLimit, $document) = @_;

    my $token = $self->start_token;

    my $wordcount = 0;

    my $lastword;

#     warn "go in ($token)\n";
    do {
	do {
	    $token = $token->previous;
	} while($token->isSep);

# 	warn "not sep $token\n";
	if (scalar(@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) > 0) {
#      warn "go out\n";
	    return($document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)->[0]);
	} else {
#  	    warn "Go\n";
	    while((defined $token->previous) && (scalar(@{$document->getAnnotations->getWordLevel->getElementByToken($token)})== 0)) {
# 	    warn "go\n";
		$token = $token->previous;
	    }
# 	    warn "GO\n";

	    if ((defined $token->previous) && (scalar(@{$document->getAnnotations->getWordLevel->getElementByToken($token)}) > 0)) {
# 	    warn "GO2\n";
		$token = $document->getAnnotations->getWordLevel->getElementByToken($token)->[0]->start_token;
		$lastword = $document->getAnnotations->getWordLevel->getElementByToken($token)->[0];
		if (scalar(@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) > 0) {
#      warn "go out\n";
		    return($document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)->[0]);
		}#     warn "go out\n";
# 	    warn "GO3\n";
		$wordcount++;
	    } else {
#     warn "go out\n";
		return($lastword);
	    }
# 	    warn "GO4\n";

	}
    } while($wordcount < $wordLimit);
    if (scalar(@{$document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)}) > 0) {
#      warn "go out\n";
	return($document->getAnnotations->getSemanticUnitLevel->getElementByToken($token)->[0]);
    }#     warn "go out\n";
    return($lastword);

}


sub XMLout {
    my ($self, $order) = @_;
    
    my $str;

    $str = "\t<semantic_unit>\t\n";
    $str .= $self->SUPER::XMLout($self->type, $order);
    $str .= "\t</semantic_unit>\n";

    return($str);
}


sub getSemanticFeatureFC {
    my ($self, $document) = @_;

    if (defined ($document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $self->getId)->[0]))  {
	return($document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $self->getId)->[0]->first_node_first_semantic_category);
    } else {
	return(undef);
    }
}

sub getSemanticFeature1 {
    my ($self, $document) = @_;

    if (defined ($document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $self->getId)->[0]))  {
	return($document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $self->getId)->[0]);
    } else {
	return(undef);
    }
}

sub SemanticFeatureFCEquals {
    my ($self, $document, $semTypeValue) = @_;

    # warn $self->getForm . "\n";
    # warn "semTypeValue: $semTypeValue\n";
    # warn "semTypeValue: " . $self->getSemanticFeatureFC($document) ."\n";

    if ((defined ($self->getSemanticFeatureFC($document))) && 
	($self->getSemanticFeatureFC($document) eq $semTypeValue)) {
# 	($document->getAnnotations->getSemanticFeaturesLevel->getElementFromIndex("refid_semantic_unit", $self->getId)->[0]->first_node_first_semantic_category eq $semTypeValue)) {
	return(1);
    } else {
	return(0);
    }
}


sub equalsAtTokenLevel {
    my ($self, $element) = @_;

    if (($self->start_token->equals($element->start_token)) && 
	($self->end_token->equals($element->end_token)))
    {
	return(1);
    } else {
	return(0);
    }
}

sub getLemmaString {
    my ($self, $document) = @_;

    my $elmt;
    my $lemma;

    if ($self->reference_name eq "list_refid_token") {
	# warn "TOKEN: " . $self->{'reference'} . "\n";
	# warn join(':', @{$self->{$self->{'reference'}}}) . "\n";
#     	return(scalar(@{$self->{$self->{'reference'}}}));
	foreach $elmt (@{$self->{$self->{'reference'}}}) {
	    $lemma .= $elmt->getContent;
	}
    }
    if ($self->reference_name eq "refid_word") {
#	warn $self->reference . "\n";
	$lemma .= $self->reference->getLemma($document)->canonical_form;
    }
    if ($self->reference_name eq "refid_phrase") {
	# warn "PHRASE: " . $self->reference . "\n";
	$lemma .= $self->reference->getLemmaString($document);
    }
    return($lemma);
}


1;

__END__

=head1 NAME

Lingua::Ogmios::Annotations::SemanticUnit - Perl extension for the annotations of the semantic units

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

