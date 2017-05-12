package Lingua::YaTeA::PatternLeaf;
use strict;
use warnings;

use Lingua::YaTeA::Edge;

our @ISA = qw(Lingua::YaTeA::Edge);

our $VERSION=$Lingua::YaTeA::VERSION;

sub new
{
    my ($class,$tag,$father) = @_;
    my $this = $class->SUPER::new($father);
    bless ($this,$class);
    $this->{POS_TAG} = $tag;
    return $this;
}


sub getPOS
{
    my ($this) = @_;
    return $this->{POS_TAG};
}

sub print
{
    my ($this) = @_;
    print $this->getPOS;
}


1;

__END__

=head1 NAME

Lingua::YaTeA::PatternLeaf - Perl extension for the leaf node of a syntactic pattern tree

=head1 SYNOPSIS

  use Lingua::YaTeA::PatternLeaf;
  Lingua::YaTeA::PatternLeaf->new($tag, $father);

=head1 DESCRIPTION


This module implements the leaf node of a syntactic pattern. Objects
inherit of the module C<Lingua::YaTeA::Edge>. A Part-of-Speech tag can
be associated to the node. The node is connected to its father node.

=head1 METHODS

=head2 new()

    new($tag, $father);


This method creates a leaf node and associates a Part-of-Speech tag
C<$tag>. It also connects the node to its father node C<$father>.

=head2 getPOS()

    getPOS();

This method returns the Part-of-Speech tag associated to the node.

=head2 print()

    print();

This method prints the Part-of-Speech tag associated to the node.


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
