package Lingua::Ogmios::Annotations::Word;

use Lingua::Ogmios::Annotations::Element;

use strict;
use warnings;

our @ISA = qw(Lingua::Ogmios::Annotations::Element);

# <!--                    word                             --> 
# <!ELEMENT  word         (id, log_id?, list_refid_token, 
#                          form?)                            > 
 
# <!--                    id of the element                --> 
# <!ELEMENT  id           (#PCDATA)                          > 
 
# <!--          list of the tokens which compose the words --> 
# <!ELEMENT  list_refid_token (refid_token)+                 > 
 
# <!--               token id, part of the words           --> 
# <!ELEMENT  refid_token  (#PCDATA)                          > 
 
# <!--                         form                        --> 
# <!ELEMENT  form    (#PCDATA)                               > 

sub new { 
    my ($class, $fields) = @_;

    if (!defined $fields->{'id'}) {
	$fields->{'id'} = -1;
    }
    my $word = $class->SUPER::new({
	'id' => $fields->{'id'},
# 	'form' => $fields->{'form'},
				      }
	);
    bless ($word,$class);

    my $i = 0;
    my $reference_name;
    my $ref;
    foreach $ref ('refid_phrase', 'refid_word', 'list_refid_token') {
	if (defined $fields->{$ref}) {
	    $reference_name = $ref;
	    last;
	}
	$i++;
    }
    if ($i == 3) {
	die("reference (list) is not defined");
    }
    $word->reference($reference_name, $fields->{$reference_name});    

    if (defined $fields->{'form'}) {
	$word->setForm($fields->{'form'});
    }
    if (defined $fields->{'isNE'}) {
	$word->isNE($fields->{'isNE'});
    }

    if (defined $fields->{'log_id'}) {
	$word->setLogId($fields->{'log_id'});
    }
    return($word);
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
	$self->{$self->{'reference'}} = [];
	$ref = shift;
	foreach $elt (@$ref) {
	    push @{$self->{$self->{'reference'}}}, $elt;
	}
    }
    return($self->{$self->{'reference'}});
}



sub end_token {
    my $self = shift;


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


sub getLastToken {
    my $self = shift;

    my @Refs = @{$self->getReference};
    my $last_token = $Refs[$#Refs];

    return($last_token);
}

sub getReferenceSize {
    my $self = shift;

    return(scalar(@{$self->{$self->{'reference'}}}));
}

sub getReference {
    my $self = shift;

    return($self->{$self->{'reference'}});
}

sub getReferenceIndex {
    my $self = shift;
    my $idx = shift;

    return($self->{$self->{'reference'}}->[$idx]);
}

sub isNE {
    my $self = shift;

    $self->{'isNE'} = shift if @_;
    return($self->{'isNE'});
}

sub XMLout {
    my ($self, $order) = @_;
    
    return($self->SUPER::XMLout("word", $order));
}


sub getMorphoSyntacticFeatures {
    my ($self, $document) = @_;

    return($document->getAnnotations->getMorphosyntacticFeaturesLevel->getElementFromIndex("refid_word", $self->getId)->[0]);
}

sub getLemma {
    my ($self, $document) = @_;

    return($document->getAnnotations->getLemmaLevel->getElementFromIndex("refid_word", $self->getId)->[0]);
}

sub getElementFormList {
    my ($self) = @_;

#     warn $self->getForm ."\n";

    return($self->getForm);

}

1;

__END__

=head1 NAME

Lingua::Ogmios::Annotations::Word - Perl extension for the word annotations

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

