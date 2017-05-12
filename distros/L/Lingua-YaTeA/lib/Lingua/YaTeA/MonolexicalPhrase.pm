package Lingua::YaTeA::MonolexicalPhrase;
use Lingua::YaTeA::Phrase;
use Lingua::YaTeA::MonolexicalUnit;
use strict;
use warnings;
use NEXT;

our @ISA = qw(Lingua::YaTeA::Phrase Lingua::YaTeA::MonolexicalUnit);
our $counter = 0;
our $parsed = 0;
our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$num_content_words,$words_a,$tag_set) = @_;
    my $this = shift;
    $this = bless {}, $this unless ref $this;
    $this->NEXT::new(@_);
    return $this;
}

sub print
{
    my ($this,$fh) = @_;
    if(defined $fh)
    {
	print $fh "if: " . $this->getIF . "\n";
	print $fh "pos: " . $this->getPOS . "\n";
	print $fh "lf: " . $this->getLF . "\n";
	print $fh "is a term candidate: " . $this->isTC. "\n";
    }
    else
    {
	print "if: " . $this->getIF . "\n";
	print "pos: " . $this->getPOS . "\n";
	print "lf: " . $this->getLF . "\n";
	print "is a term candidate: " . $this->isTC. "\n";
    }
}



1;

__END__

=head1 NAME

Lingua::YaTeA::MonolexicalPhrase - Perl extension for monoloexical phrases

=head1 SYNOPSIS

  use Lingua::YaTeA::MonolexicalPhrase;
  Lingua::YaTeA::MonolexicalPhrase->new($num_content_words,$words_a,$tag_set);

=head1 DESCRIPTION

This module implements monolexical phrases. It inehirits of the module
C<Lingua::YaTeA::Phrase Lingua::YaTeA::MonolexicalUnit>.


=head1 METHODS

=head2 new()

    new($num_content_words,$words_a,$tag_set);


The method creates a monolexical word. C<$words_a> is the reference to
an array of words. C<$num_content_words> is the number of content
words. C<$tag_set> is the reference to the tag set used in the term
extractor.

=head2 print()

    print();

The method prints information related to the current monolexical unit.

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
