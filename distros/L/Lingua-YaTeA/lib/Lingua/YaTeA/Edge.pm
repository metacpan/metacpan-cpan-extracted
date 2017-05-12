package Lingua::YaTeA::Edge;
use strict;
use warnings;
use UNIVERSAL;
use Scalar::Util qw(blessed);

our $VERSION=$Lingua::YaTeA::VERSION;


sub new
{
    my ($class) = @_;
    my $this = {};
    bless ($this,$class);
    #$this->{FATHER} = $father;
    #$this->{POSITION} = "";
    return $this;
}


sub copyRecursively
{
    my ($this,$new_set,$father) = @_;
    my $new;
    if ((blessed($this)) && ($this->isa('Lingua::YaTeA::TermLeaf')))
    {
	return "";
    }
    else{
	if ((blessed($this)) && ($this->isa('Lingua::YaTeA::InternalNode')))
	{
	    return $this->copyRecursively($new_set,$father);
	}
	else{
	    if ((blessed($this)) && ($this->isa('Lingua::YaTeA::PatternLeaf')))
	    {
		return "";
	    }
	}
    }
}

sub update
{
    my ($this,$new_value) = @_;
    $this = $new_value;
}



sub print
{
    my ($this,$words_a,$fh) = @_;
    if ((blessed($this)) && ($this->isa("Lingua::YaTeA::Node")))
    {
	 print $fh "Node " . $this->getID;
    }
    else{
	$this->printWords($words_a,$fh);
    }
}

1;

__END__

=head1 NAME

Lingua::YaTeA::Edge - Perl extension for edge between nodes

=head1 SYNOPSIS

  use Lingua::YaTeA::Edge;
  Lingua::YaTeA::Edge->new();

=head1 DESCRIPTION

The module implements edges between any sort of nodes. It is inherited
from several modules.

=head1 METHODS

=head2 new()

    new();

The method creates a new edge.

=head2 copyRecursively()

    copyRecursively($newset, $father);

The method copies recursively the current node in the node set
C<$newset> and return the copy. It also connect the copy to the father
of the original node (C<$father>).

=head2 update()

    update($new_value);

The method updates the edge with new edge information C<$new_value>.

=head2 print()

    print($words, $fh);

The method prints the status of the edge or the associated words
C<$words> in the file handler C<$fh>.


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
