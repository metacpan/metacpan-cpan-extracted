package Lingua::Ogmios::Annotations::SemanticFeatures;

use strict;
use warnings;

use Lingua::Ogmios::Annotations::Element;
our @ISA = qw(Lingua::Ogmios::Annotations::Element);

 
# <!-- =================================================== --> 
# <!--                    SEMANTIC_FEATURES_LEVEL          --> 
# <!-- =================================================== --> 
# <!ELEMENT  semantic_features_level 
#                         (log_id?, comments*, 
#                          semantic_features+)               > 
 
# <!--                    semantic_features                --> 
# <!ELEMENT  semantic_features 
#                         (id, log_id?, semantic_category, 
#                          refid_semantic_unit)              > 
 
# <!--                    semantic_category                --> 
 
# <!ELEMENT  semantic_category
#                         (list_refid_ontology_node)+        >

# <!--                    list_refid_ontology_node         -->
# <!ELEMENT  list_refid_ontology_node
#                         (refid_ontology_node)+             >

# <!--                    refid_ontology_node              -->
# <!ELEMENT  refid_ontology_node
#                         (#PCDATA)                          >

sub new { 
    my ($class, $fields) = @_;

    if (!defined $fields->{'id'}) {
	$fields->{'id'} = -1;
    }
    if ((!defined $fields->{'semantic_category'}) ||
	(ref($fields->{'semantic_category'} ne "ARRAY")) ||
	(ref($fields->{'semantic_category'}->[0] ne "ARRAY"))) { # semantic_category
	die("semantic_category is not defined");
    }
    if (!defined $fields->{'refid_semantic_unit'}) { # refid_semantic_unit
	die("refid_semantic_unit is not defined");
    }

    my $semanticfeatures = $class->SUPER::new({
	'id' => $fields->{'id'},
# 	'form' => $fields->{'form'},
				      }
	);
    bless ($semanticfeatures,$class);

    $semanticfeatures->refid_semantic_unit($fields->{'refid_semantic_unit'});
    $semanticfeatures->semantic_category('list_refid_ontology_node', $fields->{'semantic_category'});

    if (defined $fields->{'log_id'}) {
	$semanticfeatures->setLogId($fields->{'log_id'});
    }
    return($semanticfeatures);
}

sub semantic_category {
    my $self = shift;
    my $ref;
    my $elt;
    my $node;
    my $position;
    my $internal_field;

    if ((@_) && (scalar @_ == 2)) {
	$self->{'semantic_category'} = {};
	$self->{'semantic_category'}->{'reference'} = shift;
# 	warn "reference: " . $self->{'semantic_category'}->{'reference'} . "\n";
	$self->{'semantic_category'}->{$self->{'semantic_category'}->{'reference'}} = [];

#  	$position = index($self->{'semantic_category'}->{'reference'}, "list_");
#  	if ($position == 0) {
#  	    $internal_field = substr($self->{'semantic_category'}->{'reference'}, $position + 5);
#  	} else {
#  	    $internal_field = shift;
#  	}
	$ref = shift;
	foreach $elt (@$ref) {
	    my @tmp;
	    foreach $node (@$elt) {
		push @tmp, $node;
# 		warn "node: $node (" . join(":", @tmp) . ")\n";
	    }
	    push @{$self->{'semantic_category'}->{$self->{'semantic_category'}->{'reference'}}}, \@tmp;
	}
# 	foreach $elt (@$ref) {
# 	    foreach $node (@$elt) {
# 		push @{$self->{$self->{'reference'}}}, $node;
# 	    }
# 	}

    }
    return($self->{'semantic_category'}->{$self->{'semantic_category'}->{'reference'}});
}

sub first_node_first_semantic_category {
    my $self = shift;

    return($self->{'semantic_category'}->{$self->{'semantic_category'}->{'reference'}}->[0]->[0]);
}

sub refid_semantic_unit {
    my $self = shift;

    if (@_) {
	# my $old_refid = $self->{'refid_semantic_unit'};
	$self->{'refid_semantic_unit'} = shift;
	# if (defined $old_refid) {
	    
	# }
    }
    return($self->{'refid_semantic_unit'});
}

sub reference {
    my ($self) = @_;

    return($self->refid_semantic_unit);
}

sub XMLout {
    my ($self, $order) = @_;
    
    return($self->SUPER::XMLout("semantic_features", $order));
}

sub toString {
    my $self = shift;

    my $semf;
    my $semfString = "";
    

    # foreach $semf (@{$self->{'semantic_category'}->{$self->{'semantic_category'}->{'reference'}}}) {
    foreach $semf (@{$self->semantic_category}) {
	$semfString .= join('/', @$semf) . ":";
    }
    chop $semfString;
    return($semfString);
}

sub semantic_categorySize {
    my $self = shift;

    return(scalar(@{$self->semantic_category}))
}


1;


__END__

=head1 NAME

Lingua::Ogmios::Annotations::SemanticFeatures - Perl extension for the annotations of the semantic features

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

