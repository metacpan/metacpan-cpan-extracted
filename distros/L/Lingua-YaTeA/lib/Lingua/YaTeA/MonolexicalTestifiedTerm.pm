package Lingua::YaTeA::MonolexicalTestifiedTerm;
use strict;
use warnings;
use Lingua::YaTeA::TestifiedTerm;

our @ISA = qw(Lingua::YaTeA::TestifiedTerm);

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$num_content_words,$words_a,$tag_set,$source,$match_type) = @_;
    my $this = $class->SUPER::new($num_content_words,$words_a,$tag_set,$source,$match_type);
    bless ($this,$class);
   
    return $this;
}

sub getHeadAndLinks
{
    my ($this,$LGPmapping_h) = @_;
    my $head = $this->getWord(0);
    my @links;
    return ($head,0,\@links);
}

sub getLength
{
    my ($this) = @_;
    return 1;
}


1;

__END__

=head1 NAME

Lingua::YaTeA::MonolexicalTestifiedTerm - Perl extension for monolexical testified terms

=head1 SYNOPSIS

  use Lingua::YaTeA::MonolexicalTestifiedTerm;
  Lingua::YaTeA::MonolexicalTestifiedTerm->new($num_content_words,$words_a,$tag_set,$source,$match_type);

=head1 DESCRIPTION

This module implements monolexical testified terms (i.e. single word
terms). The objects inherit of the module
Lingua::YaTeA::TestifiedTerm.

=head1 METHODS


=head2 new()

    new($num_content_words,$words_a,$tag_set,$source,$match_type);

This method creates a monolexical testified term. C<$words_a> is the
reference to an array of words. C<$num_content_words> is the number of
content words. C<$tag_set> is the reference to the tag set used in the
term extractor. C<$source> is the file name from which the testifed
term is issued. C<$match_type> indicates if the term matches inflected
or lemmatized form (value is C<loose>) of if the term matches
inflected form and Part-Of-Speech tag).

=head2 getHeadAndLinks()

    getHeadAndLinks($LGPmapping_h);

This method returns the head of the term (in the case of monolexical
term, the word itself) and the reference to an array of syntactic
relations (in the current case, the array is empty).


=head2 getLength

    getLength();

This method returns the length of the monolexical term, i.e. always 1.

=head1 SEE ALSO

Sophie Aubin and Thierry Hamon. Improving Term Extraction with
Terminological Resources. In Advances in Natural Language Processing
(5th International Conference on NLP, FinTAL 2006). pages
380-387. Tapio Salakoski, Filip Ginter, Sampo Pyysalo, Tapio Pahikkala
(Eds). August 2006. LNAI 4139.


=head1 AUTHOR

Thierry Hamon <thierry.hamon@univ-paris13.fr> and Sophie Aubin <sophie.aubin@lipn.univ-paris13.fr>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Thierry Hamon and Sophie Aubin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
