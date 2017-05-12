package Lingua::YaTeA::InternalNode;
use strict;
use warnings;
use Lingua::YaTeA::Node;
use Lingua::YaTeA::Edge;
use UNIVERSAL;
use Scalar::Util qw(blessed);

our @ISA = qw(Lingua::YaTeA::Node Lingua::YaTeA::Edge);

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$level) = @_;
    my $this = $class->SUPER::new($level);
    $this->{FATHER} = ();
    bless ($this,$class);
    return $this;
}

sub setFather
{
    my ($this,$father) = @_;
    $this->{FATHER} = $father;
}

sub getFather
{
    my ($this) = @_;
    return $this->{FATHER};
}

sub updateLevel
{
    my ($this,$new_level) = @_;
    $this->{LEVEL} = $new_level++;

#     warn "Debug: Level in updateLevel: $new_level \n";

    if ($new_level < 50) { # Temporary added by Thierry Hamon 02/02/2007
	if ((blessed($this->getLeftEdge)) && ($this->getLeftEdge->isa('Lingua::YaTeA::InternalNode')))
	{
	    $this->getLeftEdge->updateLevel($new_level);
	}
	if ((blessed($this->getRightEdge)) && ($this->getRightEdge->isa('Lingua::YaTeA::InternalNode')))
	{
	    $this->getRightEdge->updateLevel($new_level);
	}
    } else {
	warn "updateLevel: Going out a deep recursive method call (more than 50 calls)\n";
    }
}

sub searchRoot
{
    my ($this) = @_;
    if ((blessed($this->getFather)) && ($this->getFather->isa('Lingua::YaTeA::RootNode')))
    {
	return $this->getFather;
    }
    
    return $this->getFather->searchRoot;
}




sub printFather
{
    my ($this,$fh) = @_;
    print $fh "\t\tfather: " . $this->getFather->getID . "\n"; 
}

1;

__END__

=head1 NAME

Lingua::YaTeA::InternalNode - Perl extension for internal nodes

=head1 SYNOPSIS

  use Lingua::YaTeA::InternalNode;
  Lingua::YaTeA::InternalNode->new($level);

=head1 DESCRIPTION

The module implements internal syntactic node. It inherits of the
module C<Lingua::YaTeA::Node> and C<Lingua::YaTeA::Edge>. The field
C<FATHER> records the father node.


=head1 METHODS

=head2 new()

    new($level);

The method creates a new internal node and sets the level C<$level>
inherited of the module C<Lingua::YaTeA::Node>.

=head2 setFather()

    setFather($father);

The method sets the father C<$father> of the node.

=head2 getFather()

    getFather();

The method returns the father of the node.


=head2 updateLevel()

    updateLevel($new_level);

The method updates the level of the node to the value C<$new_level>.

=head2 searchRoot()

    searchRoot();

The method returns the root of the tree which contains the current node. 

=head2 printFather()

    printFather();

The method prints the father node of the current internal node, a
C<Lingua::YaTeA::RootNode> object.


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
