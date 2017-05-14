package HTML::Similarity;

use strict;
use warnings;
use Data::Dumper;

use HTML::DOM;
use Algorithm::LCS;

sub new {
    my $class = shift;
    bless {
	   dom_x => new HTML::DOM,
	   dom_y => new HTML::DOM,
	   lcs => Algorithm::LCS->new,
	  } => $class;
}

sub _serialize_tree {
    my $self = shift;
    my $node = shift;

    return unless $node->can('tagName');

    my @serialization;

    push @serialization, $node->tagName;
    for my $d ($node->childNodes) {
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

    $dom_x->open();
    $dom_x->write($x);
    $dom_x->close;

    $dom_y->open();
    $dom_y->write($y);
    $dom_y->close;

    my @seq_x = $self->_serialize_tree($dom_x->documentElement);
    my @seq_y = $self->_serialize_tree($dom_y->documentElement);

    my @lcs = $self->{lcs}->LCS(\@seq_x, \@seq_y);
    return 2 * (scalar @lcs) / (scalar(@seq_x) + scalar(@seq_y));
}

1;
__END__

=pod

=head1 NAME

HTML::Similarity - Calculate the structural similarity between two HTML documents

=head1 SYNOPSIS

  use HTML::Similarity;

  my $hs = new HTML::Similarity;

  my $a = "<html><body></body></html>";
  my $b = "<html><body><h1>HOMEPAGE</h1><h2>Details</h2></body></html>";

  my $score = $hs->calculate_similarity($a, $b);
  print "Similarity: $score\n";

=head1 DESCRIPTION

This module is a small and handy tool to calculate structural
similarity between any two HTML documents. The underlying algorithm is
quite simple and straight-forward. It serializes two HTML tree to two
arrays containing node's tag names and finds the longest common
sequence between the two serialized arrays.

The similarity is measured with the formula (2 * LCS' length) /
(treeA's length + treeB's length).

Structural similarity can be useful for web page classification and
clustering.

=head1 PREREQUISITE

L<HTML::DOM>, L<Algorithm::LCS>

=head1 COPYRIGHT

Copyright (c) 2011 Yung-chung Lin. 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
