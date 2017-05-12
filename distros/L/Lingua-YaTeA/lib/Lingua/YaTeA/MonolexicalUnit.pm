package Lingua::YaTeA::MonolexicalUnit;
use strict;
use warnings;
use NEXT;
use Data::Dumper;
use UNIVERSAL;
use Scalar::Util qw(blessed);
use Lingua::YaTeA::MonolexicalPhrase;

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class_or_object,$num_content_words,$words_a) = @_;
    my $this = shift;
    $this = bless {}, $this unless ref $this;
    $this->{CONTENT_WORDS} = $num_content_words;
    $this->{PARSING_METHOD} = ();
    $this->{LENGTH} = scalar @$words_a;
    $this->NEXT::new(@_);
    return $this;
}

sub setParsingMethod
{
    my ($this,$method) = @_;
    if ((blessed($this)) && ($this->isa('Lingua::YaTeA::Phrase')))
    {
	$Lingua::YaTeA::MonolexicalPhrase::parsed++;
    }
    $this->{PARSING_METHOD} = $method;
}

1;


__END__

=head1 NAME

Lingua::YaTeA::MonolexicalUnit - Perl extension for monolexical word

=head1 SYNOPSIS

  use Lingua::YaTeA::MonolexicalUnit;
  Lingua::YaTeA::MonolexicalUnit->new($num_content_words,$words_a);

=head1 DESCRIPTION

This module implements monolexical unit or single word. The unit is
described by the number of content words (field C<CONTENT_WORDS>), the
length of the unit (field C<LENGTH>), i.e. the number of words
(including stop words and content words), and the parsing methods
(field C<PARSING_METHOD> -- a reference to an array).


=head1 METHODS

=head2 new()

    new($num_content_words,$words_a);

The method creates a monolexical word. C<$words_a> is the
reference to an array of words. C<$num_content_words> is the
number of content words. 

=head2 setParsingMethod()

    setParsingMethod($method)

The method sets the parsing method (values are C<USER>,
C<PATTERN_MATCHING>, C<PROGRESSIVE>, C<MONOLEXICAL>). 

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
