package Lingua::ResourceAdequacy;

use strict;
use warnings;


our $VERSION='0.1';

sub new {
    my $class = shift;
    my %arg = @_;

    my @word_list;
    my @term_list;
    my $word;
    my @UP_list;
    my @DUP_list;

    if (exists $arg{"word_list"}) {
	@word_list = @{$arg{"word_list"}};
    }
    if (exists $arg{"term_list"}) {
	@term_list = @{$arg{"term_list"}};
    }

    if (exists $arg{"DUP_list"}) {
	@DUP_list = @{$arg{"DUP_list"}};
    }

    if (exists $arg{"UP_list"}) {
	@UP_list = @{$arg{"UP_list"}};
    }

    my $RA = {
	"word_list" => \@word_list,
	"term_list" => \@term_list,
	"word_list_stats" => {},
	"term_list_stats" => {},
	"DecompUsefulPart" => \@DUP_list,
	"UsefulPart" => \@UP_list,
	"UsefulPart_stats" => {},
	"DecompUsefulPart_stats" => {},
	"AdequacyMeasures" => {},
    };
    bless $RA, $class;
    return $RA;
}

sub set_word_list {
    my $self = shift;
    my $word_list_ref = shift;
    my @word_list;

    if (defined $word_list_ref) {
	@word_list = @$word_list_ref;
	$self->{"word_list"} = \@word_list;
	return(scalar(@word_list));
    } else {
	return -1;
    }

}

sub set_term_list {
    my $self = shift;
    my $term_list_ref = shift;
    my @term_list;

    if (defined $term_list_ref) {
	@term_list = @$term_list_ref;
	$self->{"term_list"} = \@term_list;
	return(scalar(@term_list));
    } else {
	return -1;
    }

}

sub set_DUP_list {
    my $self = shift;
    my $DUP_list_ref = shift;
    my @DUP_list;

    if (defined $DUP_list_ref) {
	@DUP_list = @$DUP_list_ref;
	$self->{"DecompUsefulPart"} = \@DUP_list;
	return(scalar(@DUP_list));
    } else {
	return 0;
    }

}

sub set_UP_list {
    my $self = shift;
    my $UP_list_ref = shift;
    my @UP_list;

    if (defined $UP_list_ref) {
	@UP_list = @$UP_list_ref;
	$self->{"UsefulPart"} = \@UP_list;
	return(scalar(@UP_list));
    } else {
	return 0;
    }

}

sub word_list_stats {
    my $self = shift;

    
    $self->_list_stats("word_list");

}

sub term_list_stats {
    my $self = shift;

    $self->_list_stats("term_list");

}

sub print_word_list_stats {
    my $self = shift;

    print STDERR "---\n";
    print STDERR "Word list statistics:\n";
    $self->_print_list_stats("word_list");
    print STDERR "---\n";
    print STDERR "\n";
}

sub print_term_list_stats {
    my $self = shift;

    print STDERR "---\n";
    print STDERR "Term list statistics:\n";
    $self->_print_list_stats("term_list");
    print STDERR "---\n";
    print STDERR "\n";

}

sub _average_Frequency {
    my $self = shift;
    my $field_name = $_[0];

    $self->{$field_name . "_stats"}->{'averageFreq'} = 0;
    map { $self->{$field_name . "_stats"}->{'averageFreq'} += $_} values %{$self->{$field_name . "_stats"}->{'vocableFreq'}};

    $self->{$field_name . "_stats"}->{'averageFreq'} /= $self->{$field_name . "_stats"}->{'vocabularySize'};

}

sub _list_stats {
    my $self = shift;
    my $field_name = $_[0];
    
    my $vocable;

    $self->{$field_name . "_stats"}->{'listSize'} = scalar(@{$self->{$field_name}});
    
    foreach $vocable (@{$self->{$field_name}}) {
	$self->{$field_name . "_stats"}->{'vocableFreq'}->{$vocable}++;
    }



    $self->{$field_name . "_stats"}->{'vocabularySize'} = scalar(keys %{$self->{$field_name . "_stats"}->{'vocableFreq'}});

    $self->_average_Frequency($field_name);
    
#     map { $self->{$field_name . "_stats"}->{'averageFreq'} += $_} values %{$self->{$field_name . "_stats"}->{'vocableFreq'}};

#     $self->{$field_name . "_stats"}->{'averageFreq'} /= $self->{$field_name . "_stats"}->{'vocabularySize'};

#     print $self->{$field_name . "_stats"}->{'vocabularySize'};
#     foreach $vocable (keys %{$self->{$field_name . "_stats"}->{'vocableFreq'}}) {
	
# 	print "$vocable : " . $self->{$field_name . "_stats"}->{'vocableFreq'}->{$vocable} . "\n";
#     }

}

sub get_Vocabulary_size {
    my $self = shift;
    my $field_name = shift;
    
    if (defined $field_name) {
	return ($self->{$field_name . "_stats"}->{'vocabularySize'});
    } else {
	return(-1);
    }
}

sub get_List_size {
    my $self = shift;
    my $field_name = shift;
    
    if (defined $field_name) {
	return ($self->{$field_name . "_stats"}->{'listSize'});
    } else {
	return(-1);
    }
}

sub get_Average_frequency {
    my $self = shift;
    my $field_name = shift;
    
    if (defined $field_name) {
	return ($self->{$field_name . "_stats"}->{'averageFreq'});
    } else {
	return(-1);
    }
}

sub get_FrequencyLength {
    my $self = shift;
    my $field_name = shift;
    
    if ((defined $field_name) && (exists $self->{$field_name . "_stats"}->{'FreqLength'})) {
	return ($self->{$field_name . "_stats"}->{'FreqLength'});
    } else {
	return(-1);
    }
}




sub _print_list_stats {
    my $self = shift;
    my $field_name = $_[0];
    my $vocable;

    print STDERR "List size: " .  $self->get_List_size($field_name) . "\n";
    print STDERR "Vocabulary size: " . $self->get_Vocabulary_size($field_name) . "\n";
    print STDERR "Average frequency: " . $self->get_Average_frequency($field_name) . "\n";
#     if (exists $self->{$field_name . "_stats"}->{'FreqLength'}) {
	print STDERR "Frequency * Length: " . $self->get_FrequencyLength($field_name) . "\n";
#     }

    print STDERR "Vocable : freqency\n";
    foreach $vocable (keys %{$self->{$field_name . "_stats"}->{'vocableFreq'}}) {
	print STDERR "\t$vocable : " . $self->{$field_name . "_stats"}->{'vocableFreq'}->{$vocable} . "\n";
    }

}


sub UP_list_stats {
    my $self = shift;
    my $vocable;
    my $term;
    
    $self->_list_stats("UsefulPart");

    foreach $vocable (keys %{$self->{"UsefulPart_stats"}->{'vocableFreq'}}) {
	foreach $term (keys %{$self->{"UsefulPart_stats"}->{'vocableFreq'}}) {
	    if (length($vocable) < length($term)) {
		if ((length($vocable) > 0) && ($vocable ne $term)) {
		    if ($term =~ /\b$vocable\b/o) {
			$self->{"UsefulPart_stats"}->{'vocableFreq'}->{$vocable} -= $self->{"UsefulPart_stats"}->{'vocableFreq'}->{$term};
		    }
		}
	    } 
	}
    }
    $self->_average_Frequency("UsefulPart");

    my $term_components;
    my @components;
    my $freq_length = 0;
	
    foreach $term (keys %{$self->{"UsefulPart_stats"}->{'vocableFreq'}}) {
# 	print STDERR "$term\n";
# 	print STDERR $self->{"UsefulPart_stats"}->{'vocableFreq'}->{$term} . "\n";
#	$term_components = $term;
	@components = split /\s/, $term;
# 	print STDERR join(":", @components) . "\n";
# 	print STDERR scalar(@components) . "\n";
	$freq_length += $self->{"UsefulPart_stats"}->{'vocableFreq'}->{$term} * scalar(@components);
# 	print STDERR "=> $freq_length\n";
    }
    $self->{"UsefulPart_stats"}->{'FreqLength'} = $freq_length;
}

sub print_UP_list_stats {
    my $self = shift;

    print STDERR "---\n";
    print STDERR "Useful Part list statistics:\n";
    $self->_print_list_stats("UsefulPart");
    print STDERR "---\n";
    print STDERR "\n";

}

sub DUP_list_stats {
    my $self = shift;
    my $vocable;
    my $term;
    
    $self->_list_stats("DecompUsefulPart");


}

sub print_DUP_list_stats {
    my $self = shift;

    print STDERR "---\n";
    print STDERR "Decomposed Useful Part list statistics:\n";
    $self->_print_list_stats("DecompUsefulPart");
    print STDERR "---\n";
    print STDERR "\n";

}

sub get_UP_VocabularySize {
    my $self = shift;

    return($self->get_Vocabulary_size("UsefulPart"));

}

sub get_UP_ListSize {
    my $self = shift;

    return($self->get_List_size("UsefulPart"));

}

sub get_UP_AverageFrequency {
    my $self = shift;

    return($self->get_Average_frequency("UsefulPart"));

}

sub get_UP_FrequencyLength {
    my $self = shift;

    return($self->get_FrequencyLength("UsefulPart"));

}

sub get_DUP_VocabularySize {
    my $self = shift;

    return($self->get_Vocabulary_size("DecompUsefulPart"));

}

sub get_DUP_ListSize {
    my $self = shift;

    return($self->get_List_size("DecompUsefulPart"));

}

sub get_DUP_AverageFrequency {
    my $self = shift;

    return($self->get_Average_frequency("DecompUsefulPart"));

}

sub get_term_list_VocabularySize {
    my $self = shift;

    return($self->get_Vocabulary_size("term_list"));

}

sub get_term_list_ListSize {
    my $self = shift;

    return($self->get_List_size("term_list"));

}

sub get_term_list_AverageFrequency {
    my $self = shift;

    return($self->get_Average_frequency("term_list"));

}

sub get_word_list_VocabularySize {
    my $self = shift;

    return($self->get_Vocabulary_size("word_list"));

}

sub get_word_list_ListSize {
    my $self = shift;

    return($self->get_List_size("word_list"));

}

sub get_word_list_AverageFrequency {
    my $self = shift;

    return($self->get_Average_frequency("word_list"));

}


sub AdequacyMeasures {
    my $self = shift;

    $self->{"AdequacyMeasures"}->{"Contribution"} = $self->get_UP_VocabularySize / $self->get_term_list_VocabularySize;
    $self->{"AdequacyMeasures"}->{"Excess"} = 1 - $self->{"AdequacyMeasures"}->{"Contribution"};

    $self->{"AdequacyMeasures"}->{"Recognition"} = $self->get_DUP_VocabularySize / $self->get_word_list_VocabularySize;
    $self->{"AdequacyMeasures"}->{"Ignorance"} = 1 - $self->{"AdequacyMeasures"}->{"Recognition"};

    $self->{"AdequacyMeasures"}->{"Coverage"} = $self->get_UP_FrequencyLength / $self->get_word_list_ListSize;

    $self->{"AdequacyMeasures"}->{"Density"} = $self->get_DUP_AverageFrequency / $self->get_word_list_AverageFrequency;
    return(0);
}


sub print_AdequacyMeasures {
    my $self = shift;

    print STDERR "-----\n";
    print STDERR "Adequacy Measures: \n";
    print STDERR "\tContribution: " . $self->{"AdequacyMeasures"}->{"Contribution"} . "\n";
    print STDERR "\tExcess: " . $self->{"AdequacyMeasures"}->{"Excess"} . "\n";
    print STDERR "\t-----\n";
    print STDERR "\tRecognition: " . $self->{"AdequacyMeasures"}->{"Recognition"} . "\n";
    print STDERR "\tIgnorance: " . $self->{"AdequacyMeasures"}->{"Ignorance"} . "\n";
    print STDERR "\t-----\n";
    print STDERR "\tCoverage: " . $self->{"AdequacyMeasures"}->{"Coverage"} . "\n";
    print STDERR "\tDensity: " . $self->{"AdequacyMeasures"}->{"Density"} . "\n";

    print STDERR "-----\n";
}

1;

__END__



=head1 NAME

Lingua::FR::ResourceAdequacy - Measures to estimate the adequacy of a terminology given a text

=head1 SYNOPSIS

use Lingua::ResourceAdequacy;

my $RA = Lingua::ResourceAdequacy->new("word_list" => \@words, 
	  			       "term_list" => \@terms,
                                       "UP" => \@UP,
                                       "DUP" => \@DUP);
$RA->term_list_stats();
$RA->word_list_stats();
$RA->AdequacyMeasures();
$RA->print_AdequacyMeasures();


=head1 DESCRIPTION

Lingua-ResourceAdequacy provides measures to estimate the adequacy of
a terminological resource regarding a textual corpus, i.e. whether a
terminological resource can be used on a specialised textual corpus.

Given a textual document collection and a terminological resource
i.e. a term list, and its useful part, i.e. term found in the texts,
the module provides four measures to estimate the adequacy of the
resource regarding the document collection: Contribution, Recognition,
Coverage and Density.

Four lists are required as input: a term list and its useful part
(terms that matched in the texts), the decomposed useful part (each
term is segmentized in words) and word list of the document
collection.

As output, the adequacy measures are stored in the C<AdequacyMeasures>
field. The complementary measures are also provided for the
contribution, i.e. excess, and the recognition, i.e. ignorance.

=head1 METHODS


=head2 new()

    $RA = Lingua::ResourceAdequacy->new("word_list" => \@words, "term_list" => \@terms, 
              "UP_list" => \@UP_list, "DUP_list" => \@DUP_list, );

This method creates a new C<Lingua::ResourceAdequacy> object. The
following optional key/value parameters may be employed to set the
internal field. All keys have a corresponding method that can be used
to change the behaviour later on. At the beginning, you can just
ignore them.

=over 8

=item B<word_list>: this key can be used to set the word list of the
corpus. The array containing the word list is recopied in a internal
array.


=item B<term_list>: this key can be used to set the term list. The
array containing the term list is recopied in a internal array.


=item B<UP_list>: this key can be used to set the useful part of the
term list. The array containing this list is recopied in a internal
array.



=item B<DUP_list>: this key can be used to set the word segmentized
useful part of the term list. The array containing this list is
recopied in a internal array.

=back


=head2 set_word_list()

   $RA->set_word_list(\@word_list);

This method sets the internal field containing the word list of the
corpus. The parameter is a array reference.

=head2 set_term_list()

   $RA->set_term_list(\@term_list);

This method sets the internal field containing the term list i.e. all
the terminological resource. The parameter is a array reference.


=head2 set_DUP_list()

   $RA->set_DUP_list(\@DUP_list);

This method sets the internal field containing the useful part of the
term list, each term being word segmentized. Each array element
contains a word of a term. The word can appear several times. The parameter
is a array reference.


=head2 set_UP_list()

   $RA->set_DUP_list(\@DUP_list);

This method sets the internal field containing the useful part of the
term list i.e. all the term matching in the corpus. Each array element
contains a term. The term can appear several times. The parameter is a
array reference.

=head2 word_list_stats()

     $RA->word_list_stats();

This method computes the basic statistics associated to the word list:
the size of the list, the frequency of each word, the size of the
vocabulary (the word list without duplicated ones), the average
frequency of the words.

=head2 term_list_stats()

     $RA->term_list_stats();

This method computes the basic statistics associated to the term list:
the size of the list, the frequency of each term, the number of term
without duplicated ones, the average frequency of the terms.


=head2 print_word_list_stats()

     $RA->print_word_list_stats();

This method prints the statistics associated to the word list.

=head2 print_term_list_stats()

This method prints the statistics associated to the term list.


=head2 _average_Frequency()

     $RA->_average_Frequency($filed_name);

This internal method computes the average frequency of the elements
issued form the list defined by C<$field_name>.

=head2 _list_stats()

     $RA->_list_stats($field_name);


This method computes the basic statistics associated to the list
defined by C<$field_name>: the size of the list, the frequency of each
element, the number of elements without duplicated ones, the average
frequency of the elements.

=head2 get_Vocabulary_size()

     $RA->get_Vocabulary_size($field_name);

This method returns the vocabulary size, i.e. the number of elements
without duplicated ones, given the list defined by C<$field_name>. If
the list doesn't exist, the method returns -1.

=head2 get_List_size()

     $RA->get_List_size($field_name);

This method returns the list size, i.e. the number of elements of the
list defined by C<$field_name>. If the list doesn't exist, the method
returns -1.


=head2 get_Average_frequency()

     $RA->get_Average_frequency($field_name);

This method returns the average frequency of the list elements. The
list name is defined by C<$field_name>. If the list doesn't exist, the
method returns -1.

=head2 get_FrequencyLength()

     $RA->get_FrequencyLength($field_name);

This method returns the sum of the product of the frequency by the
length, for each element of the list defined by C<$field_name>. If the
list doesn't exist, the method returns -1.


=head2 _print_list_stats()

     $RA->_print_list_stats($field_name);


This internal method prints the statistics associated to the list
defined by C<$field_name>.

=head2 UP_list_stats()

     $RA->UP_list_stats();

This method computes the basic statistics associated to the useful
part of term list: the size of the list, the frequency of each term,
the number of term without duplicated ones, the average frequency of
the terms and the sum of the product of the frequency by the length,
for each element of the useful part of the term list.

=head2 print_UP_list_stats()

     $RA->print_UP_list_stats();

This method prints the statistics associated to the useful part of the
term list.

=head2 DUP_list_stats()

     $RA->UP_list_stats();

This method computes the basic statistics associated to the decomposed
useful part of term list: the size of the list, the frequency of each
term, the number of term without duplicated ones, the average
frequency of the terms.

=head2 print_DUP_list_stats()

     $RA->print_DUP_list_stats();

This method prints the statistics associated to the decomposed useful
part of the term list.

=head2 get_UP_VocabularySize()

     $RA->get_UP_Vocabulary_size();

This method returns the size of the useful part of term list where
duplicated terms are removed. If the list doesn't exist, the method
returns -1.

=head2 get_UP_ListSize()

     $RA->get_UP_List_size();

This method returns the size of useful part of the term list. If the
list doesn't exist, the method returns -1.

=head2 get_UP_AverageFrequency()

     $RA->get_UP_Average_frequency();

This method returns the average frequency of the useful part of the
term list.  If the list doesn't exist, the method returns -1.

=head2 get_UP_FrequencyLength()

     $RA->get_UP_FrequencyLength();

This method returns the sum of the product of the frequency by the
length, for each element of the useful part of the term list. If the
list doesn't exist, the method returns -1.

=head2 get_DUP_VocabularySize()

     $RA->get_DUP_Vocabulary_size();

This method returns the size of the word segmentized useful part of
term list where duplicated words are removed. If the list doesn't
exist, the method returns -1.


=head2 get_DUP_ListSize()

     $RA->get_DUP_List_size();

This method returns the size of word segmentized useful part of the
term list. If the list doesn't exist, the method returns -1.


=head2 get_DUP_AverageFrequency()

     $RA->get_DUP_Average_frequency();

This method returns the average frequency of the word segmentized
useful part of the term list.  If the list doesn't exist, the method
returns -1.


=head2 get_term_list_VocabularySize()

     $RA->get_term_list_Vocabulary_size();

This method returns the size of the term list where duplicated terms
are removed. If the list doesn't exist, the method returns -1.

=head2 get_term_list_ListSize()

     $RA->get_term_List_size();

This method returns the size of the term list. If the list doesn't
exist, the method returns -1.

=head2 get_term_list_AverageFrequency()

     $RA->get_term_list_Average_frequency();

This method returns the average frequency of the term list.  If the
list doesn't exist, the method returns -1.

=head2 get_word_list_VocabularySize()

     $RA->get_word_list_Vocabulary_size();

This method returns the size of the word list where duplicated words
are removed. If the list doesn't exist, the method returns -1.


=head2 get_word_list_ListSize()

     $RA->get_word_List_size();

This method returns the size of the word list. If the list doesn't
exist, the method returns -1.

=head2 get_word_list_AverageFrequency()

     $RA->get_word_list_Average_frequency();

This method returns the average frequency of the word list.  If the
list doesn't exist, the method returns -1.

=head2 AdequacyMeasures()

     $RA->AdequacyMeasures();

This method computes the measures to estimate the adequacy of the
terminological resource regarding the textual corpus: Contribution,
Recognition, Coverage and Density.

=head2 print_AdequacyMeasures()

     $RA->print_AdequacyMeasures();

This method prints the adequacy measures.

=head1 SEE ALSO

Goritsa Ninova, Adeline Nazarenko, Thierry Hamon et Sylvie
Szulman. "Comment mesurer la couverture d'une ressource terminologique
pour un corpus ?" TALN 2005. pages 293-302. 6-12 juin 2005. Dourdan,
France.

=head1 AUTHORS

Thierry Hamon <thierry.hamon@lipn.univ-paris13.fr>

=head1 LICENSE

Copyright (C) 2007 by Thierry Hamon

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

