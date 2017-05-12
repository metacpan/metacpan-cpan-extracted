package Lingua::Ogmios::Annotations::SyntacticRelation;

use strict;
use warnings;

use Lingua::Ogmios::Annotations::Element;
our @ISA = qw(Lingua::Ogmios::Annotations::Element);

# <!-- =================================================== --> 
# <!--               SYNTACTIC_RELATION_LEVEL              --> 
# <!-- =================================================== --> 
# <!ELEMENT  syntactic_relation_level 
#                         (log_id?, comments*, 
#                          syntactic_relation+)              > 
 
# <!--                    syntactic_relation               --> 
# <!ELEMENT  syntactic_relation 
#                         (id, log_id?, 
#                          syntactic_relation_type, 
#                          refid_head, refid_modifier)       > 
 
# <!--                    refid_head phrase or word        --> 
# <!ELEMENT  refid_head
#                         (refid_word | refid_phrase)        > 
 
# <!--                    refid_modifier phrase or word    --> 
# <!ELEMENT  refid_modifier
#                         (refid_word | refid_phrase)        > 
 
# <!--                    syntactic_relation_type          --> 
# <!ELEMENT  syntactic_relation_type 
#                         (#PCDATA)                          > 

sub new { 
    my ($class, $fields) = @_;

    if (!defined $fields->{'id'}) {
	$fields->{'id'} = -1;
    }
    if (!defined $fields->{'syntactic_relation_type'}) {
	die("syntactic_relation_type is not defined");
    }
#     if (!defined $fields->{'refid_head'}) {
# 	die("refid_head is not defined");
#     }
#     if (!defined $fields->{'refid_modifier'}) {
# 	die("refid_modifier is not defined");
#     }
    my $syntacticrelation = $class->SUPER::new({
	'id' => $fields->{'id'},
# 	'form' => $fields->{'form'},
				      }
	);
    bless ($syntacticrelation,$class);

    my $i = 0;
    my $reference_name;
    my $ref;
    foreach $ref ('refid_phrase', 'refid_word') {
  	if (defined $fields->{$ref . "_head"}) {
  	    $reference_name = $ref;
  	    last;
  	}
  	$i++;
    }
    if ($i == 2) {
  	die("reference (list) is not defined");
    }
    $syntacticrelation->refid_head($reference_name, $fields->{$reference_name . "_head"});    

    $i = 0;
    $reference_name = "";
    $ref = "";
    foreach $ref ('refid_phrase', 'refid_word') {
  	if (defined $fields->{$ref . "_modifier"}) {
  	    $reference_name = $ref;
  	    last;
  	}
  	$i++;
    }
    if ($i == 2) {
  	die("reference (list) is not defined");
    }
    $syntacticrelation->refid_modifier($reference_name, $fields->{$reference_name . "_modifier"});    

    $syntacticrelation->syntactic_relation_type($fields->{'syntactic_relation_type'});
#     $syntacticrelation->refid_head($fields->{'refid_head'});
#     $syntacticrelation->refid_modifier($fields->{'refid_modifier'});

    if (defined $fields->{'log_id'}) {
	$syntacticrelation->setLogId($fields->{'log_id'});
    }
    return($syntacticrelation);
}


sub syntactic_relation_type {
    my $self = shift;

    $self->{'syntactic_relation_type'} = shift if @_;
    return($self->{'syntactic_relation_type'});
}
sub refid_head {
    my $self = shift;
    my $refid_head;

    if ((@_) && (scalar @_ == 2)) {
	$self->{'refid_head'} = {};
	$self->{'refid_head'}->{'reference'} = shift;
	$self->{'refid_head'}->{$self->{'refid_head'}->{'reference'}} = [];
	$refid_head = shift;
	push @{$self->{'refid_head'}->{$self->{'refid_head'}->{'reference'}}}, $refid_head;
    }
    return($self->{'refid_head'}->{$self->{'refid_head'}->{'reference'}});

}
sub refid_modifier {
    my $self = shift;
    my $refid_modifier;

    if ((@_) && (scalar @_ == 2)) {
	$self->{'refid_modifier'} = {};
	$self->{'refid_modifier'}->{'reference'} = shift;
	$self->{'refid_modifier'}->{$self->{'refid_modifier'}->{'reference'}} = [];
	$refid_modifier = shift;
	push @{$self->{'refid_modifier'}->{$self->{'refid_modifier'}->{'reference'}}}, $refid_modifier;
    }
    return($self->{'refid_modifier'}->{$self->{'refid_modifier'}->{'reference'}});
    
#     $self->{'refid_modifier'} = shift if @_;
#     return($self->{'refid_modifier'});
}

sub XMLout {
    my ($self, $order) = @_;
    
    return($self->SUPER::XMLout("syntactic_relation", $order));
}

sub reference_name_head {
    my $self = shift;

    $self->{'refid_head'}->{'reference'} = shift if @_;
    return $self->{'refid_head'}->{'reference'};
}

sub reference_name_modifier {
    my $self = shift;

    $self->{'refid_modifier'}->{'reference'} = shift if @_;
    return $self->{'refid_modifier'}->{'reference'};
}


sub reference {
    my ($self) = @_;

    return($self->refid_head, $self->refid_modifier);

}

1;


__END__

=head1 NAME

Lingua::Ogmios::Annotations::SyntacticRelation - Perl extension for the annotations of the syntactic relations

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

