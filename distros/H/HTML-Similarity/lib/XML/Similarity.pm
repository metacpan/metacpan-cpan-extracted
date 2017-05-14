package XML::Similarity;

use strict;
use warnings;
use Data::Dumper;

use XML::DOM;
use Algorithm::LCS;

sub new {
    my $class = shift;
    bless {
	   dom_x => new XML::DOM::Parser,
	   dom_y => new XML::DOM::Parser,
	   lcs => Algorithm::LCS->new,
	  } => $class;
}

sub _serialize_tree {
    my $self = shift;
    my $node = shift;

    return unless $node->can('getTagName');

    my @serialization;

    push @serialization, $node->getTagName;
    for my $d ($node->getChildNodes) {
	push @serialization, $self->_serialize_tree($d);
    }

    return @serialization;
}

sub calculate_similarity {
    my $self = shift;
    my $x = shift || return 0;
    my $y = shift || return 0;

    my $dom_x = $self->{dom_x};
    my $dom_y = $self->{dom_y};

    my $doc_x = $dom_x->parse($x);
    my $doc_y = $dom_y->parse($y);

    my @seq_x = $self->_serialize_tree($doc_x->getDocumentElement);
    my @seq_y = $self->_serialize_tree($doc_y->getDocumentElement);

    $doc_x->dispose;
    $doc_y->dispose;

    my @lcs = $self->{lcs}->LCS(\@seq_x, \@seq_y);
    return 2 * (scalar @lcs) / (scalar(@seq_x) + scalar(@seq_y));
}

1;
__END__

=pod

=head1 NAME

XML::Similarity - Calculate the structural similarity between two XML documents

=head1 SYNOPSIS

  use XML::Similarity;

  my $hs = new XML::Similarity;

  my $a = "<html><body></body></html>";
  my $b = "<html><body><h1>HOMEPAGE</h1><h2>Details</h2></body></html>";

  my $score = $hs->calculate_similarity($a, $b);
  print "Similarity: $score\n";

=head1 DESCRIPTION

This module is a small and handy tool to calculate structural
similarity between any two XML documents. The underlying algorithm is
quite simple and straight-forward. It serializes two XML tree to two
arrays containing node's tag names and finds the longest common
sequence between the two serialized arrays.

The similarity is measured with the formula (2 * LCS' length) /
(treeA's length + treeB's length).

Structural similarity can be useful for XML document classification
and clustering.

=head1 PREREQUISITE

L<XML::DOM>, L<Algorithm::LCS>

=head1 COPYRIGHT

Copyright (c) 2011 Yung-chung Lin. 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
