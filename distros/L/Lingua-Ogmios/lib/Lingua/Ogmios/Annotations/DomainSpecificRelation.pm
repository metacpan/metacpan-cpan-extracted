package Lingua::Ogmios::Annotations::DomainSpecificRelation;

use strict;
use warnings;

use Lingua::Ogmios::Annotations::Element;
our @ISA = qw(Lingua::Ogmios::Annotations::Element);

# <!-- =================================================== --> 
# <!--               DOMAIN_SPECIFIC_RELATION_LEVEL        --> 
# <!-- =================================================== --> 
 
# <!--               domain_specific_relation              --> 
# <!ELEMENT  domain_specific_relation 
#                         (id, log_id?, 
#                          domain_specific_relation_type, 
#                          list_refid_semantic_unit)         > 
 
# <!--               domain_specific_relation_type         --> 
# <!ELEMENT  domain_specific_relation_type (#PCDATA)         > 

# <!ELEMENT  list_refid_semantic_unit (refid_semantic_unit)+ >
# <!ELEMENT  refid_semantic_unit (#PCDATA)                   >

 
sub new { 
    my ($class, $fields) = @_;

    if (!defined $fields->{'id'}) {
	$fields->{'id'} = -1;
    }
    if (!defined $fields->{'domain_specific_relation_type'}) {
	die("domain_specific_relation_type is not defined");
    }
    if (!defined $fields->{'list_refid_semantic_unit'}) {
	die("list_refid_semantic_unit is not defined");
    }
    my $domainspecificrelation = $class->SUPER::new({
	'id' => $fields->{'id'},
# 	'form' => $fields->{'form'},
				      }
	);
    bless ($domainspecificrelation,$class);

    $domainspecificrelation->list_refid_semantic_unit($fields->{'list_refid_semantic_unit'});
    $domainspecificrelation->domain_specific_relation_type($fields->{'domain_specific_relation_type'});

    if (defined $fields->{'log_id'}) {
	$domainspecificrelation->setLogId($fields->{'log_id'});
    }
    return($domainspecificrelation);
}

sub list_refid_semantic_unit {
    my $self = shift;

    my $ref;
    my $elt;

    if (@_) {
	$self->{'reference'} = 'list_refid_semantic_unit';
	$self->{$self->{'reference'}} = [];
	$ref = shift;
	if (ref($ref) eq "ARRAY") {
	    foreach $elt (@$ref) {
# 	    warn $elt->getForm . "\n";
		push @{$self->{$self->{'reference'}}}, $elt;
	    }
	} else {
	    if (ref($ref) eq "HASH") {
		foreach $elt (keys %$ref) {
# 	    warn $elt->getForm . "\n";
		    push @{$self->{$self->{'reference'}}}, { $elt => $ref->{$elt}};
		}
	    }
	}
    }
    return($self->{$self->{'reference'}});

#     $self->{'list_refid_semantic_unit'} = shift if @_;
#     return($self->{'list_refid_semantic_unit'});
}

sub domain_specific_relation_type {
    my $self = shift;

    $self->{'domain_specific_relation_type'} = shift if @_;
    return($self->{'domain_specific_relation_type'});
}

sub XMLout {
    my ($self, $order) = @_;
    
    return($self->SUPER::XMLout("domain_specific_relation", $order));
}

sub reference {
    my ($self) = @_;

    return($self->list_refid_semantic_unit);
}

1;

__END__

=head1 NAME

Lingua::Ogmios::Annotations::DomainSpecificRelation - Perl extension for the annotations of the domain-specific relations

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

