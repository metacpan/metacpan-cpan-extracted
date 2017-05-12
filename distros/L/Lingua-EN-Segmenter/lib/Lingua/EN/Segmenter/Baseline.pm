# Baseline random segmenter
package Lingua::EN::Segmenter::Baseline;

=head1 NAME

Lingua::EN::Segmenter::Baseline - Segment text randomly for baseline purposes

=head1 SYNOPSIS

See L<Lingua::EN::Segmenter::TextTiling>

=head1 DESCRIPTION

See L<Lingua::EN::Segmenter::TextTiling>

=head1 EXTENDING

See L<Lingua::EN::Segmenter::TextTiling>

=head1 AUTHORS

David James <splice@cpan.org>

=head1 SEE ALSO

L<Lingua::EN::Segmenter::TextTiling>, L<Lingua::EN::Segmenter::Evaluator>,
L<http://www.cs.toronto.edu/~james>

=head1 LICENSE

  Copyright (c) 2002 David James
  All rights reserved.
  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.
  
=cut

$VERSION = 0.10;
use base 'Lingua::EN::Segmenter::TextTiling';    
use strict;

# Return random depth scores
sub smoothed_depth_scores {
    my ($self,$input) = @_;
    my $words = $self->{splitter}->words($input);
    my $tiles = $self->{splitter}->tile($words);
    my $num_scores = @$tiles - 2*$self->{TILES_PER_BLOCK};
    [ map { rand() } 0..$num_scores ]
}


1;
