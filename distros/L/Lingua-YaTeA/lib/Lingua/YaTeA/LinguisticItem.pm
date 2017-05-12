package Lingua::YaTeA::LinguisticItem;
use strict;
use warnings;

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$type,$form) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{TYPE} = $type;
    $this->{FORM} = $form;
    return $this;
}

sub getForm
{
    my ($this) = @_;
    return $this->{FORM};
}

sub getType
{
    my ($this) = @_;
    return $this->{TYPE};
}

sub matchesWord
{
    my ($this,$word) = @_;
    if($this->getForm eq $word->getLexItem->getAny($this->getType))
    {
	return 1;
    }
    return 0;
}
1;

__END__

=head1 NAME

Lingua::YaTeA::LinguisticItem - Perl extension for the linguistic item of the forbiddent structures

=head1 SYNOPSIS

  use Lingua::YaTeA::LinguisticItem;
  Lingua::YaTeA::LinguisticItem->new($type, $form);

=head1 DESCRIPTION

This module implements the linguistic items. Each linguistic item is
composed of a form (a word or a Part-of-Speech tag) and the type of
the form (C<IF> for inflected form, C<LF> for lemma or C<POS> for
Part-of-Speech tag).


=head1 METHODS


=head2 new()

    new ($type, $form);

The method creates a new linguistic item having the type C<$type> and the form C<form>.


=head2 getForm()

    getForm();

The methods returns the form of the linguistic item.

=head2 getType())

    getType();

The methods returns the type of the linguistic item.

=head2 matchesWord()

    matchesWord($word)

The method checks if the word C<$word> matches the form of the
linguistic item. It returns 1 if the word matches, otherwise 0.

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
