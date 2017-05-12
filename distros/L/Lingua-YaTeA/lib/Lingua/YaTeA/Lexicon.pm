package Lingua::YaTeA::Lexicon;
use strict;
use warnings;
use Lingua::YaTeA::LexiconItem;

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{ITEMS} = {};
    return $this;
}

sub addItem
{
    my ($this,$item,$key) = @_;
    $this->{ITEMS}->{$key} = $item;
    $Lingua::YaTeA::LexiconItem::counter++;
}




sub addOccurrence
{
    my ($this,$form) = @_;
    my $item = Lingua::YaTeA::LexiconItem->new($form);
    my $key = $this->buildKey($item);
    if (itemExists($this,$key) == 0)
    {
	$this->addItem($item,$key);
    }
    else
    {
	$item = $this->getItem($key);
    }
    $item->incrementFrequency;
    return $item;
}

sub getItem
{
    my ($this,$key) = @_;
    return $this->{ITEMS}->{$key};
}

sub itemExists
{
    my ($this,$key) = @_;
    if (exists $this->{ITEMS}->{$key}){
	return 1;
    }
    return 0;
}

sub buildKey
{
    my ($this,$item) = @_;
    my $key = $item->{IF}.$item->{POS}.$item->{LF};
    return $key;
}

1;

__END__

=head1 NAME

Lingua::YaTeA::LexiconItem - Perl extension for lexicon of the corpus.

=head1 SYNOPSIS

  use Lingua::YaTeA::LexiconItem;
  Lingua::YaTeA::LexiconItem->new();

=head1 DESCRIPTION

The module manages the lexicon of the corpus, i.e. the list of the
words appearing in the corpus. Each word, or lexicon unit is stores in
the field C<ITEM> (a reference to a hashtable). The key of the lexicon
unit is the concatenation of the inflected form, Part-Of-Speech tag,
and lemmatized form.

=head1 METHODS

=head2 new()

    new();

The method creates a new lexicon objet.


=head2 addItem()

    addItem($item,$key);

The method adds a lexicon unit (or item) C<$item> to the lexicon. The
associated key C<$key> is provided.

=head2 addOccurrence()

    addOccurrence($form);

the method adds an new occurrrence of the lexicon unit having the form
C<$form>. If the unit doesn't already exist, the lexicon item is
created, otherwise its frequency is incremented.

=head2 getItem()

    getItem($key);

The method returns the lexicon item given the key C<$key>.

=head2 itemExists()

    itemExists($key);

The method checks if the lexicon item exists given the key C<$key>. If
the item exists it returns 1, otherwise 0.


=head2 buildKey()

    buildKey($item);


The method builds the key of the lexicon item C<$item>.

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
