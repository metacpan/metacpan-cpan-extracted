package Lingua::Ogmios::Annotations::Enumeration;

use strict;
use warnings;

use Lingua::Ogmios::Annotations::Element;
our @ISA = qw(Lingua::Ogmios::Annotations::Element);

 
# <!-- =================================================== --> 
# <!--                 ENUMERATION LEVEL                   --> 
# <!-- =================================================== --> 
# <!ELEMENT  enumeration_level 
#                         (log_id?, comments*, enumeration+) > 
 
# <!--                  enumeration                        --> 
# <!ELEMENT  enumeration      (id, log_id?, type?,
# 		        list_refid_components, 
#                         form?)                             > 
 
# <!--                    list_refid_components            --> 
# <!ELEMENT  list_refid_components 
#                         (refid_word | refid_phrase 
#                              | refid_semantic_unit)+       > 
 
# <!--                    refid_phrase                     --> 
# <!ELEMENT  refid_phrase (#PCDATA)                          > 
 
sub new { 
    my ($class, $fields) = @_;

    my @refTypes = ('refid_phrase', 'refid_word', 'refid_semantic_unit');

    if (!defined $fields->{'id'}) {
	$fields->{'id'} = -1;
    }
#     if (!defined $fields->{'list_refid_components'}) { # list_refid_components
# 	die("list_refid_components is not defined");
#     }
    my $enumeration = $class->SUPER::new({
	'id' => $fields->{'id'},
# 	'form' => $fields->{'form'},
				      }
	);
    bless ($enumeration,$class);

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
    $enumeration->list_refid_components($reference_name, $fields->{$reference_name});    

    if (defined $fields->{'form'}) {
	$enumeration->setForm($fields->{'form'});
    }
    if (defined $fields->{'type'}) {
	$enumeration->type($fields->{'type'});
    }
    if (defined $fields->{'log_id'}) {
	$enumeration->setLogId($fields->{'log_id'});
    }
    return($enumeration);
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


sub addComponent {
    my ($self, $component) = @_;

    push @{$self->list_refid_components}, $component;

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
    # if refid phrase -> enumeration->start_token
    if (($self->reference_name eq "refid_word") ||
	($self->reference_name eq "refid_phrase") ||
	($self->reference_name eq "refid_semantic_unit")){
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
    # if refid phrase -> enumeration->start_token
    if (($self->reference_name eq "refid_word") ||
	($self->reference_name eq "refid_phrase") ||
	($self->reference_name eq "refid_semantic_unit")){
	return($self->reference->[0]->start_token);
    }
    return(undef);
}



sub XMLout {
    my ($self, $order) = @_;
    
    return($self->SUPER::XMLout("enumeration", $order));
}

sub getElementFormList {
    my ($self) = @_;

    my $element;
    my @elements;

    foreach $element (@{$self->list_refid_components}) {
# 	warn $element->getForm ."\n";
	push @elements, $element->getElementFormList;
    }
    return(@elements);

}


1;

__END__

=head1 NAME

Lingua::Ogmios::Annotations::Enumeration - Perl extension for the annotations of the enumerations.

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

