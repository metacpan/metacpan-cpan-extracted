package Lingua::Ogmios::Annotations::AnaphoraRelation;

use strict;
use warnings;

use Lingua::Ogmios::Annotations::Element;
our @ISA = qw(Lingua::Ogmios::Annotations::Element);

# <!-- =================================================== --> 
# <!--                    ANAPHORA_RELATION_LEVEL          --> 
# <!-- =================================================== --> 
# <!ELEMENT  anaphora_relation_level 
#                         (log_id?, comments*, 
#                          anaphora_relation+)               > 
# <!--                    anaphora_relation                --> 
# <!ELEMENT  anaphora_relation 
#                         (id, log_id?, 
#                          anaphora_relation_type, 
#                          anaphora, antecedent)             > 
 
# <!ELEMENT  antecedent   (list_refid_semantic_unit)+        >
# <!ELEMENT  anaphora
#                         (refid_semantic_unit)              > 
 
 
# <!--                    anaphora_relation_type           --> 
# <!ELEMENT  anaphora_relation_type 
#                         (#PCDATA)                          >

sub new { 
    my ($class, $fields) = @_;

    if (!defined $fields->{'id'}) {
	$fields->{'id'} = -1;
    }
    if (!defined $fields->{'anaphora_relation_type'}) {
	die("anaphora_relation_type is not defined");
    }
    if (!defined $fields->{'anaphora'}) {
	die("anaphora is not defined");
    }
    if (!defined $fields->{'antecedent'}) {
	die("antecedent is not defined");
    }
    my $anaphorarelation = $class->SUPER::new({
	'id' => $fields->{'id'},
# 	'form' => $fields->{'form'},
				      }
	);
    bless ($anaphorarelation,$class);

    $anaphorarelation->anaphora_relation_type($fields->{'domain_specific_relation_type'});

#    $anaphorarelation->list_refid_semantic_unit($fields->{'list_refid_semantic_unit'});

    if (defined $fields->{'log_id'}) {
	$anaphorarelation->setLogId($fields->{'log_id'});
    }
    return($anaphorarelation);
}

sub anaphora {
    my $self = shift;

    if (@_) {
	$self->{anaphora}->{'reference'} = 'refid_semantic_unit';
	$self->{anaphora}->{$self->{'reference'}} = shift;
    }
    return($self->{anaphora}->{$self->{'reference'}});
    
}

sub list_refid_semantic_unit {
    my $self = shift;

    my $ref;
    my $elt;

    if (@_) {
	$self->{antecedent}->{'reference'} = 'list_refid_semantic_unit';
	$self->{antecedent}->{$self->{'reference'}} = [];
	$ref = shift;
	foreach $elt (@$ref) {
	    push @{$self->{antecedent}->{$self->{'reference'}}}, $elt;
	}
    }
    return($self->{antecedent}->{$self->{'reference'}});

}

sub anaphora_relation_type {
    my $self = shift;

    $self->{'anaphora_relation_type'} = shift if @_;
    return($self->{'anaphora_relation_type'});
}

sub XMLout {
    my ($self, $order) = @_;
    
    return($self->SUPER::XMLout("anaphora_relation", $order));
}


1;

__END__

=head1 NAME

Lingua::Ogmios::Annotations::AnaphoraRelation - Perl extension for the annotations of the anaphora relations

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

