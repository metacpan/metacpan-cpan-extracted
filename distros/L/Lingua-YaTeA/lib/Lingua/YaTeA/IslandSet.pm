package Lingua::YaTeA::IslandSet;
use strict;
use warnings;

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class) = @_;
    my $this = {};
    bless ($this,$class);
    $this->{ISLANDS} = {};
    return $this;
}

sub getIslands
{
    my ($this) = @_;
    return $this->{ISLANDS};
}

sub existIsland
{
    my ($this,$index_set) = @_;
    my $key = $index_set->joinAll('-');
    if(exists $this->getIslands->{$key})
    {
	return 1;
    }
    return 0; 
}

sub getIsland
{
    my ($this,$index_set) = @_;
    my $key = $index_set->joinAll('-');
    return $this->getIslands->{$key};
}

sub existLargerIsland
{
    my ($this,$index) = @_;
    my $key = $index->joinAll('-');
    my $island;
    foreach $island (values (%{$this->getIslands}))
    {
	if($index->isCoveredBy($island->getIndexSet))
	{
	    return 1;
	}
    }
    return 0;
}

sub addIsland
{
    my ($this,$island,$fh) = @_;
    my $key = $island->getIndexSet->joinAll('-');
  #  print $fh " key: ". $key . "  - ";
    $this->getIslands->{$key} = $island;
  #  print $fh "\tilot ajoute";
}

sub removeIsland
{
    my ($this,$island,$fh) = @_;
    my $key = $island->getIndexSet->joinAll('-');
    delete($this->getIslands->{$key});
#    print $fh "remove";
    $island = undef;
}


sub size
{
    my ($this) = @_;
    return scalar (keys %{$this->getIslands});
}

sub print
{
    my ($this,$fh) = @_;
    my $island;
    if(defined $fh)
    {
	foreach $island (values (%{$this->getIslands}))
	{
	print $fh "\t";
	$island->print($fh);
	}
    }
    else
    {
	foreach $island (values (%{$this->getIslands}))
	{
	print "\t";
	$island->print;
	}
    }
}


1;

__END__

=head1 NAME

Lingua::YaTeA::IslandSet - Perl extension for set of reliability islands

=head1 SYNOPSIS

  use Lingua::YaTeA::IslandSet;
  Lingua::YaTeA::IslandSet->new();

=head1 DESCRIPTION

The module implements a set of reliability islands. Islands are stored
if the field C<ISLANDS> which is a reference to a hashtable.

=head1 METHODS

=head2 new()

    new();

The method creates a new island set.

=head2 getIslands()

    getIslands();


The method returns the reference to the hashtable containing the islands.

=head2 existIsland()

    existIsland($index_set);

The method returns 1 if the island referred by C<$index_set> exists in
the current set of island, otherwise 0.

=head2 getIsland()

    getIsland($index_set);

The method returns the island referred by C<$index_set> exists in the
current set of island.


=head2 existLargerIsland()

    existLargerIsland($index);

The method returns 1 if it exists a larger island than the island
referred by C<$index>, otherwise 0.

=head2 addIsland()

    addIsland($island);

The method adds the island C<$island> in the current set.

=head2 removeIsland()

    removeIsland($island);

The method removes the island C<$island> in the current set.

=head2 size()

    size();

The method returns the number of islands in the current set.

=head2 print()

    print($fh);

The method prints the island of the current set in the file referred
by C<$fh>.


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
