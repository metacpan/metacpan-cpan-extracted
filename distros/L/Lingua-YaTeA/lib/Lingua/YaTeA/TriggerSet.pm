package Lingua::YaTeA::TriggerSet;
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

sub addTrigger
{
    my ($this,$fs) = @_;
    my $trigger = $fs->getFirstItem;
    push @{$this->getSubset($trigger->getType)->{$trigger->getForm}}, $fs; 
}



sub getSubset
{
    my ($this,$type) = @_;
    return $this->{$type};
}

sub findTrigger
{
    my ($this,$word) = @_;
    my @types = ("IF","POS","LF");
    my $type;
    foreach $type (@types)
    {
	if(defined $this->getSubset($type))
	{
	    if(exists $this->getSubset($type)->{$word->getLexItem->{$type}})
	    {
		return $this->getSubset($type)->{$word->getLexItem->{$type}};
	    }
	}
    }
    return;
}


1;
__END__

=head1 NAME

Lingua::YaTeA::TriggerSet - Perl extension for managing the trigger set 

=head1 SYNOPSIS

  use Lingua::YaTeA::TriggerSet;
  Lingua::YaTeA::TriggerSet->new();

=head1 DESCRIPTION


The trigger set contains any part of structures required by the
chunking step. It contains several types of triggers inflectional
forms (IF), part-of-speech tags (POS) and lemmatized forms (LF).

=head1 METHODS

=head2 new()

    new();

This method creates a empty set of triggers. 

=head2 addTrigger


    addTrigger($fs)


The method adds a trigger in the trigger set. C<$fs> is the forbidden
structure related to the trigger.


=head2 getSubset

    getSubset($type)

This method returns the subset of trigger according the type defined
by C<$type>.


=head2 findTrigger

    findTrigger($word)


This method returns a trigger given the word definied by C<$word>.

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
