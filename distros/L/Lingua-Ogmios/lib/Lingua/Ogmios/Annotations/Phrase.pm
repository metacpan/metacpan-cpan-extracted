package Lingua::Ogmios::Annotations::Phrase;

use strict;
use warnings;

use Lingua::Ogmios::Annotations::Element;
our @ISA = qw(Lingua::Ogmios::Annotations::Element);

 
# <!-- =================================================== --> 
# <!--                    PHRASE LEVEL                     --> 
# <!-- =================================================== --> 
# <!ELEMENT  phrase_level 
#                         (log_id?, comments*, phrase+)      > 
 
# <!--                    phrase                           --> 
# <!ELEMENT  phrase      (id, log_id?, type?,
# 		        list_refid_components, 
#                         form?)                             > 
 
# <!--                    list_refid_components            --> 
# <!ELEMENT  list_refid_components 
#                         (refid_word | refid_phrase)+       > 
 
# <!--                    refid_phrase                     --> 
# <!ELEMENT  refid_phrase (#PCDATA)                          > 
 
sub new { 
    my ($class, $fields) = @_;

    my @refTypes = ('refid_phrase', 'refid_word');

    if (!defined $fields->{'id'}) {
	$fields->{'id'} = -1;
    }
#     if (!defined $fields->{'list_refid_components'}) { # list_refid_components
# 	die("list_refid_components is not defined");
#     }
    my $phrase = $class->SUPER::new({
	'id' => $fields->{'id'},
# 	'form' => $fields->{'form'},
				      }
	);
    bless ($phrase,$class);

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
    $phrase->list_refid_components($reference_name, $fields->{$reference_name});    

    if (defined $fields->{'form'}) {
	$phrase->setForm($fields->{'form'});
    }
    if (defined $fields->{'type'}) {
	$phrase->type($fields->{'type'});
    }
    if (defined $fields->{'log_id'}) {
	$phrase->setLogId($fields->{'log_id'});
    }
    return($phrase);
}


sub list_refid_components {
    my $self = shift;
    my $ref;
    my $elt;

    if ((@_) && (scalar @_ == 2)) {
	$self->{'list_refid_components'} = {};
	$self->{'list_refid_components'}->{'reference'} = shift;
	$self->{'list_refid_components'}->{$self->{'list_refid_components'}->{'reference'}} = [];
	$ref = shift;
	foreach $elt (@$ref) {
	    push @{$self->{'list_refid_components'}->{$self->{'list_refid_components'}->{'reference'}}}, $elt;
	}
    }
    return($self->{'list_refid_components'}->{$self->{'list_refid_components'}->{'reference'}});
}


sub type {
    my $self = shift;

    $self->{'type'} = shift if @_;
    return($self->{'type'});
}

sub reference {
    my $self = shift;
    my $ref;
    my $elt;

#     if ((@_) && (scalar @_ == 2)) {
# 	$self->{'reference'} = shift;
# 	$self->{$self->{'reference'}} = [];
# 	$ref = shift;
# 	foreach $elt (@$ref) {
# 	    push @{$self->{$self->{'reference'}}}, $elt;
# 	}
#     }
    return($self->{'list_refid_components'}->{$self->reference_name});
}


sub reference_name {
    my $self = shift;

    $self->{'list_refid_components'}->{'reference'} = shift if @_;
    return $self->{'list_refid_components'}->{'reference'};

}

sub getReferenceSize {
    my $self = shift;

    my $token;
    my $size = 0;

#     for $element (@{$self->list_refid_components}) {
# 	$size += $element->getReferenceSize;
#     }

    $token = $self->start_token;

    while(!($token->equals($self->end_token))) {
	$size++;
	$token = $token->next;
    }
    $size++;

    return($size);
}



sub end_token {
    my $self = shift;

#     warn $self->reference_name ;

    if ($self->reference_name eq "list_refid_token") {
	return($self->reference->[$#{$self->reference}]);
    }
    #if list_refid token -> OK

    # if refid word -> word->start_token
    # OR
    # if refid phrase -> phrase->start_token
    if (($self->reference_name eq "refid_word") ||
	($self->reference_name eq "refid_phrase")){
	return($self->reference->[$#{$self->reference}]->end_token);
    }
    return(undef);
}

sub start_token {
    my $self = shift;

#     warn $self->reference_name;

    if ($self->reference_name eq "list_refid_token") {
	return($self->reference->[0]);
    }
    #if list_refid token -> OK

    # if refid word -> word->start_token
    # OR
    # if refid phrase -> phrase->start_token
    if (($self->reference_name eq "refid_word") ||
	($self->reference_name eq "refid_phrase")){
	return($self->reference->[0]->start_token);
    }
    return(undef);
}



sub XMLout {
    my ($self, $order) = @_;
    
    return($self->SUPER::XMLout("phrase", $order));
}

sub getElementFormList {
    my ($self) = @_;

    my $element;
    my @elements;

    foreach $element (@{$self->list_refid_components}) {
# 	warn $element->getForm ."\n";"
	push @elements, $element->getElementFormList;
    }
    return(@elements);

}

sub getElementList {
    my ($self) = @_;

    my $element;
    my @elements;

    foreach $element (@{$self->list_refid_components}) {
# 	warn $element->getForm ."\n";
	# warn "==>" . __PACKAGE__ . "\n";
	if (ref($element) eq __PACKAGE__) {
	    push @elements, $element->getElementList;
	} else {
	    push @elements, $element;
	}
    }
    return(@elements);
}

sub getLemmaString {
    my ($self, $document) = @_;

    my $lemma = "";
    my $i = 0;
    my $token = $self->start_token;
    my @elmts = $self->getElementList;

	# warn join(':',$self->getElementList) . "\n";
    do {
	# warn $token->getId . "\n";
	# warn $elmts[$i]->start_token->getId . "\n";
	# warn $self->end_token->getId . "\n";
	if ($token->equals($elmts[$i]->start_token)) {
	    if (ref($elmts[$i]) eq "Lingua::Ogmios::Annotations::Word") {
		$lemma .= $elmts[$i]->getLemma($document)->canonical_form;
		$token = $elmts[$i]->end_token;
		$i++;
	    } elsif (ref($elmts[$i]) eq "Lingua::Ogmios::Annotations::Phrase") {
		$lemma .= $elmts[$i]->getLemmaString($document);
		$token = $elmts[$i]->end_token;
		$i++;
	    }
	} else {
	    $lemma .= $token->getContent;
	}
	# if (!($token->equals($self->end_token))) {
	#     warn "NEXT\n";
	    $token = $token->next;
	# }
	# warn "===\n";
    } while((defined $token) && (!($token->previous->equals($self->end_token))));

    # foreach $elmt ($self->getElementList) {
    # 	warn "$elmt\n";
    # 	# if (ref($elmt) eq "Lingua::Ogmios::Annotations::Token") {
    # 	#     $lemma .= $elmt->getContent;
    # 	# } 
    # 	if (ref($elmt) eq "Lingua::Ogmios::Annotations::Word") {
    # 	    $lemma .= $elmt->getLemma($document)->canonical_form;
    # 	} 
    # 	if (ref($elmt) eq "Lingua::Ogmios::Annotations::Phrase") {
    # 	    $lemma .= $elmt->getLemmaString($document);
    # 	}
    # 	$lemma .= " ";
    # }
    # chop $lemma;
    return($lemma);


}
sub getLemmaString_v1 {
    my ($self, $document) = @_;

    my $elmt;
    my $lemma = "";
    foreach $elmt ($self->getElementList) {
	warn "$elmt\n";
	if (ref($elmt) eq "Lingua::Ogmios::Annotations::Token") {
	    $lemma .= $elmt->getContent;
	} 
	if (ref($elmt) eq "Lingua::Ogmios::Annotations::Word") {
	    $lemma .= $elmt->getLemma($document)->canonical_form;
	} 
	if (ref($elmt) eq "Lingua::Ogmios::Annotations::Phrase") {
	    $lemma .= $elmt->getLemmaString($document);
	}
	$lemma .= " ";
    }
    chop $lemma;
    return($lemma);


}

1;

__END__

=head1 NAME

Lingua::Ogmios::Annotations::Phrase - Perl extension for the annotations of the phrases

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

