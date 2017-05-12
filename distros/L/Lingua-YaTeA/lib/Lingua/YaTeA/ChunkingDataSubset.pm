package Lingua::YaTeA::ChunkingDataSubset;
use strict;
use warnings;

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{IF} = {};
    $this->{POS} = {};
    $this->{LF} = {};
    return $this;
}

sub getIF
{
    my ($this) = @_;
    return $this->{IF};
}

sub getPOS
{
    my ($this) = @_;
    return $this->{POS};
}

sub getLF
{
    my ($this) = @_;
    return $this->{LF};
}

sub getSome
{
    my ($this,$type) = @_;
    return $this->{$type};
}

sub addIF
{
    my ($this,$value);
    $this->{IF}->{$value}++;
}

sub addPOS
{
    my ($this,$value);
    $this->{POS}->{$value}++;
}

sub addLF
{
    my ($this,$value);
    $this->{LF}->{$value}++;
}

sub addSome
{
    my ($this,$type,$value) = @_;
     $this->{$type}->{$value}++;
}

sub existData
{
    my ($this,$type,$value) = @_;
    if(exists $this->getSome($type)->{$value})
    {
	return 1;
    }
    return 0;
}

1;

__END__

=head1 NAME

Lingua::YaTeA::ChunkingDataSubset - Perl extension for subset of chuncking data.

=head1 SYNOPSIS

  use Lingua::YaTeA::ChunkingDataSubset;
  Lingua::YaTeA::ChunkingDataSubset->new();

=head1 DESCRIPTION

The module implements subsets of chunking data, i.e. chunking
frontiers, chunking exceptions, cleaning frontiers, and cleaning
exceptions. Chunking data are stored in three hashtbles according to
their types: inflected form in C<IF> field, lemmatized form in C<LF>
field, and part-of-speech tags in C<POS> field.

=head1 METHODS


=head2 new()

    new();

The method creates a new empty chunking data subset.

=head2 getIF()

    getIF();

The method returns the reference to the hashtable of inflected forms.

=head2 getPOS()

    getPOS();

The method returns the reference to the hashtable of Part-of-Speech tags.

=head2 getLF()

    getLF();

The method returns the reference to the hashtable of lemmatized forms.

=head2 getSome()

    getSome($type);

The method returns the reference to the hashtable of the field defined
by C<$type>.

=head2 addIF()

    addIF($value);

The method adds C<$value> to the inflected form field of the chuncking
subset.

=head2 addPOS()

    addPOS($value);

The method adds C<$value> to the Part-of-Speech field of the chuncking
subset.


=head2 addLF()

    addLF($value);

The method adds C<$value> to the lemmatized form field of the chuncking
subset.

=head2 addSome()

    addSome($type,$value);

The method adds information related to the type C<$type> (i.e. IF --
inflected form, LF -- lemmatized form, POS -- Part-of-Speech tagqq)
with the value C<$Value>.

=head2 existData()

The methods checks if the value C<$value> exists in the field
C<$type>. It returns 1 if it exists, otherwise 0.


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
