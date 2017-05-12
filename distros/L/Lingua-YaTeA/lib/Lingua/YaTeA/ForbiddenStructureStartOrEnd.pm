package Lingua::YaTeA::ForbiddenStructureStartOrEnd;
use strict;
use warnings;
use Lingua::YaTeA::ForbiddenStructure;
use Lingua::YaTeA::LinguisticItem;
use Lingua::YaTeA::TriggerSet;
use UNIVERSAL;
use Scalar::Util qw(blessed);


our @ISA = qw(Lingua::YaTeA::ForbiddenStructure);
our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$infos_a,$triggers) = @_;
    my ($form,$items_a) = $class->parse($infos_a->[0]);
    my $this = $class->SUPER::new($form);
    bless ($this,$class);
    $this->{POSITION} = $infos_a->[1];
    $this->{ITEMS} = $items_a;
    $triggers->addTrigger($this);
    return $this;
}

sub getFirstItem
{
    my ($this) = @_;
    if($this->isStart)
    {
	return $this->getItemSet->[0];
    }
    if($this->isEnd)
    {
	return $this->getItemSet->[$#{$this->getItemSet}];
    }
}


sub getItemSet
{
    my ($this) = @_;
    return $this->{ITEMS};
}

sub parse
{
    my ($class,$string) = @_;
    my @elements = split / /, $string;
    my $element;
    my $i_form;
    my $fs_form;
    my $type;
    my $rank = 0;
    my @items;

    foreach $element (@elements){
	$element =~ /^([^\\]+)\\(.+)$/;
	$i_form = $1;
	$type =$2;
	push @items, Lingua::YaTeA::LinguisticItem->new($type,$i_form);
	if($rank == 0){
	   
	}
	$fs_form .= $i_form . " ";
	$rank++;
    }
    $fs_form =~ s/ $//;
    return ($fs_form,\@items);
}



sub getItem
{
    my ($this,$index) = @_;
    return $this->getItemSet->[$index];    
}

sub isStart
{
    my ($this) = @_;
    if($this->getPosition eq "START")
    {
	return 1;
    }
    return 0;
}

sub isEnd
{
    my ($this) = @_;
    if($this->getPosition eq "END")
    {
	return 1;
    }
    return 0;
}

sub getPosition
{
    my ($this) = @_;
    return $this->{POSITION};
}





sub apply
{
    my ($this,$words_a) = @_;
    my $i;
    my $j;
   
    $i = 0;
    $j = 0;
    my $to_delete;
    
    if($this->isStart){
	while ($j < $this->getLength)
	{

#	    warn "ref: " . ref($words_a->[$i]) . "\n";
	    if ((blessed($words_a->[$i])) && ($words_a->[$i]->isa('Lingua::YaTeA::TestifiedTermMark')))
	    {
		return;
		#return $to_delete;
	    }
	    else
	    {
		if
		    (
		     (((blessed($words_a->[$i])) && ($words_a->[$i]->isa('Lingua::YaTeA::ForbiddenStructureStartOrEnd'))))
		     ||
		     (
		      (((blessed($words_a->[$i])) && ($words_a->[$i]->isa('Lingua::YaTeA::WordFromCorpus'))))
		      &&
		      ($this->getItem($j)->matchesWord($words_a->[$i]))
		     )
		    )
		{
		    $i++;
 		    $j++;
		    $to_delete++;
		}
		else
		{
		    return;
		}
	    }
	}
    }
    if($this->isEnd)
    {
	$i = $#$words_a;
	$j = $this->getLength -1;
	while ($j >= 0)
	{
	    
	    if((blessed($words_a->[$i])) && ($words_a->[$i]->isa('Lingua::YaTeA::TestifiedTermMark')))
	    {
		return;
	    }
	    else
	    {
		
		if
		    (
		     (((blessed($words_a->[$i])) && ($words_a->[$i]->isa('Lingua::YaTeA::ForbiddenStructureStartOrEnd'))))
		     ||
		    (
		     (((blessed($words_a->[$i])) && ($words_a->[$i]->isa('Lingua::YaTeA::WordFromCorpus'))))
		     &&
		     ($this->getItem($j)->matchesWord($words_a->[$i]))
		    )
		    )
		{
		    $i--;
		    $j--;
		    $to_delete++;
		}
		else
		{
		    return;
		}
	    }
	}
    }
    return $to_delete;
}

sub print
{
    my ($this) = @_;
    print $this->{FORM} . "\n";
    print $this->{POSITION} . "\n";
}

1;

__END__

=head1 NAME

Lingua::YaTeA::ForbiddenStructureStartOrEnd - Perl extension for forbidden
structures in at the start or end position of a chunk.

=head1 SYNOPSIS

  use Lingua::YaTeA::ForbiddenStructureStartOrEnd;
  Lingua::YaTeA::ForbiddenStructureStartOrEnd->new(\@infos_a, $triggerSet);

=head1 DESCRIPTION

The module describes the forbidden structures that can be used in the start or end
position in the chunk. This is a specialisation of the
C<Lingua::YaTeA::ForbiddenStructure> module. Two fields are added:

=over

=item *

C<POSITION>: the field contains the position of the forbiedden structure (C<START> or C<END>).


=item *

C<ITEMS>: this field contains the reference of the array of the
linguistic items.



=back

=head1 METHODS


=head2 new()

    new($infos_a, $triggerSet);

The method creates a forbidden structure that can be found at the
start or end position of a chunk. The forbidden structure is defined
from the array given by reference C<$infos_a>.  All fields are set.  A
trigger is added to the trigger Set C<triggerSet>.


=head2 getFirstItem()

    getFirstItem();

The method returns the first item of the linguistic item set.


=head2 getItemSet()

    getItemSet()

The method returns the linguistic item set.

=head2 parse()

    parse($string);

The method parses the pattern of the forbidden structure C<$string>
and returns the C<$form> of the forbidden structure and the
corresponding regular expression.


=head2 getItem()

    getItem($index);

The method returns the linguistic item at he index C<$index>.

=head2 isStart()

    isStart();

The method indicates if the forbidden structure should be used in the
start position. It returns 1 if yes.

=head2 isEnd()

    isEnd();

The method indicates if the forbidden structure should be used in the
end position. It returns 1 if yes.

=head2 getPosition()

    getPosition()


The method returns the position if the forbidden structure (C<START>
or C<END>).


=head2 apply()

    apply($word_a);

This method applies the given forbidden structure of the array of
words given by reference C<$word_a>.

=head2 print()

    print();

This method prints the description of the forbidden structure,
i.e. its form and its position.


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
