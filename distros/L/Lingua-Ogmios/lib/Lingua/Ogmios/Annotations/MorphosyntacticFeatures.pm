package Lingua::Ogmios::Annotations::MorphosyntacticFeatures;

use strict;
use warnings;

use Lingua::Ogmios::Annotations::Element;
our @ISA = qw(Lingua::Ogmios::Annotations::Element);

# <!-- =================================================== --> 
# <!--              MORPHOSYNTACTIC FEATURES LEVEL         --> 
# <!-- =================================================== --> 
 
# <!ELEMENT  morphosyntactic_features_level 
#                         (log_id?, comments*,
#                          morphosyntactic_features+)        > 
 
# <!--                    morphosyntactic_features         --> 
# <!ELEMENT  morphosyntactic_features 
#                         (id, log_id?, (refid_word |
#                          refid_phrase), syntactic_category, 
#                          category?, type?, gender?, number?, 
#                          case?, mood_vform?, tense?, 
#                          person?, degree?, possessor?, 
#                          formation?, form?)                > 

# <!--                    type                             -->
# <!--                    applicable for nouns, verbs, 
#                         adjectives, pronouns, determiners, 
#                         adverbs, adpositions, conjunctions, 
#                         numerals                         -->
# <!ELEMENT  type                                                      
# 			(#PCDATA)			   >

# <!--                    gender                           -->
# <!--                    applicable for nouns, verbs, 
#                         adjectives, pronouns, determiners, 
#                         numerals                         -->
# <!ELEMENT  gender                                    
# 			(#PCDATA)                          >

# <!--                    number                           -->
# <!--                    applicable for nouns, verbs, 
#                         adjectives, pronouns, determiners, 
#                         numerals                         -->
# <!ELEMENT  number                                           
# 			(#PCDATA)                          >

# <!--                    case                             -->
# <!--                    applicable for nouns, adjectives,
#                         pronouns, determiners, numerals  -->
# <!ELEMENT  case         (#PCDATA)                          >

# <!--                    mood_vform                       -->
# <!--                    applicable for verbs             -->
# <!ELEMENT  mood_vform   (#PCDATA)                          >

# <!--                    tense                            -->
# <!--                    applicable for verbs             -->
# <!ELEMENT  tense        (#PCDATA)                          >

# <!--                    person                           -->
# <!--                    applicable for verbs, pronouns,
#                          determiners                     -->
# <!ELEMENT  person       (#PCDATA)                          >

# <!--                    degree                           -->
# <!--                    applicable for adjectives, 
#                         adverbs                          -->
# <!ELEMENT  degree       (#PCDATA)                          >

# <!--                    possessor                        -->
# <!--                    applicable for pronouns,
#                          determiners                     -->
# <!ELEMENT  possessor    (#PCDATA)                          >

# <!--                    formation                        -->
# <!--                    applicable for adpositions       -->
# <!ELEMENT  formation    (#PCDATA)                          >

# <!--                    syntactic_category               --> 
# <!--                    POS categories                   -->

# <!--                    category                         --> 
# <!--                    Multext POS categories           -->
# <!--          Noun (N), Verb (V), Adjective (A), Pronoun
#               (P), Determiner (D), Article (T), Adverb
#               (R), Adposition (S) Conjunction (C),
#               Numerals (M), Interjection (I), Unique (U)
#               Resiual (X), Abbreviation (Y)              -->
# <!ELEMENT  syntactic_category 
#                         (#PCDATA)                          > 
 
sub new { 
    my ($class, $fields) = @_;

    if (!defined $fields->{'id'}) {
	$fields->{'id'} = -1;
    }

    if (!defined $fields->{'syntactic_category'}) { # syntactic_category
	die("syntactic_category is not defined");
    }

    my $morphosyntacticfeatures = $class->SUPER::new({
	'id' => $fields->{'id'},
# 	'form' => $fields->{'form'},
				      }
	);
    bless ($morphosyntacticfeatures, $class);


    $morphosyntacticfeatures->syntactic_category($fields->{'syntactic_category'});

    my $i = 0;
    my $reference_name;
    my $ref;
    foreach $ref ('refid_phrase', 'refid_word') {
	if (defined $fields->{$ref}) {
	    $reference_name = $ref;
	    last;
	}
	$i++;
    }
    if ($i == 2) {
	die("reference (list) is not defined");
    }

    $morphosyntacticfeatures->reference($reference_name, $fields->{$reference_name});    

    my $field;
    foreach $field ('type', 'gender', 'number', 'case', 'mood_vfrom', 'tense', 'person', 'degree', 'possessor', 'formation') {
	if (defined $fields->{$field}) {
	    $morphosyntacticfeatures->_setField($fields->{$field});
	}
    }

    if (defined $fields->{'form'}) {
	$morphosyntacticfeatures->setForm($fields->{'form'});
    }

    if (defined $fields->{'log_id'}) {
	$morphosyntacticfeatures->setLogId($fields->{'log_id'});
    }
    return($morphosyntacticfeatures);
}

sub type {
    my $self = shift;

    $self->{'type'} = shift if @_;
    return($self->{'type'});
}

sub category {
    my $self = shift;

    $self->{'category'} = shift if @_;
    return($self->{'category'});
}

sub syntactic_category {
    my $self = shift;

    $self->{'syntactic_category'} = shift if @_;
    return($self->{'syntactic_category'});
}

sub gender {
    my $self = shift;

    $self->{'gender'} = shift if @_;
    return($self->{'gender'});
}

sub number {
    my $self = shift;

    $self->{'number'} = shift if @_;
    return($self->{'number'});
}

sub case {
    my $self = shift;

    $self->{'case'} = shift if @_;
    return($self->{'case'});
}

sub mood_vform {
    my $self = shift;

    $self->{'mood_vform'} = shift if @_;
    return($self->{'mood_vform'});
}

sub tense {
    my $self = shift;

    $self->{'tense'} = shift if @_;
    return($self->{'tense'});
}

sub person {
    my $self = shift;

    $self->{'person'} = shift if @_;
    return($self->{'person'});
}

sub degree {
    my $self = shift;

    $self->{'degree'} = shift if @_;
    return($self->{'degree'});
}

sub possessor {
    my $self = shift;

    $self->{'possessor'} = shift if @_;
    return($self->{'possessor'});
}

sub formation {
    my $self = shift;

    $self->{'formation'} = shift if @_;
    return($self->{'formation'});
}

sub reference {
    my $self = shift;
    my $ref;
    my $elt;

    if ((@_) && (scalar @_ == 2)) {
	$self->{'reference'} = shift;
#	$self->{$self->{'reference'}} = [];
	$ref = shift;
	$self->{$self->{'reference'}} = $ref;
# 	foreach $elt (@$ref) {
# 	    push @{$self->{$self->{'reference'}}}, $elt;
# 	}
    }
    return($self->{$self->{'reference'}});
}


sub XMLout {
    my ($self, $order) = @_;
    
    return($self->SUPER::XMLout("morphosyntactic_features", $order));
}

1;

__END__

=head1 NAME

Lingua::Ogmios::Annotations::MorphosyntacticFeatures - Perl extension for the annotations of morpho-syntactic features

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

