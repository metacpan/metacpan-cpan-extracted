package List::Intersperse;

use strict;
use Exporter;

use vars qw/$VERSION @ISA @EXPORT @EXPORT_OK/;

@ISA        = qw/Exporter/;
@EXPORT     = qw//;
@EXPORT_OK  = qw/intersperseq intersperse/;

$VERSION = '1.00';

=pod

=head1 NAME

List::Intersperse - Intersperse / unsort / disperse a list

=head1 SYNOPSIS

  use List::Intersperse qw/intersperseq/;

  @ispersed = intersperseq {substr($_[0],0,1)} qw/A1 A2 B1 B2 C1 C2/;

  @ispersed = List::Intersperse::intersperse qw/A A B B B B B B C/;

=head1 DESCRIPTION

C<intersperse> and C<intersperseq> evenly distribute elements of a
list. Elements that are considered equal are spaced as far apart from each
other as possible.

=head1 FUNCTIONS

=over 4

=item intersperse LIST

This function returns a list of elements interspersed so that equivalent items
are evenly distributed throughout the list.

=item intersperseq BLOCK LIST

C<intersperseq> works like C<intersperse> but it applies BLOCK to the elements
of LIST to determine the equivalance key.

=cut

sub intersperseq(&@) {
  # wrapper with a prototype, allows calling like map
  _intersperse( @_ )
}

sub intersperse(@) { # no key func
  _intersperse( sub { $_[0] }, @_ )
}

sub _intersperse {
  my $keyf = shift;
  my %h;
  for ( @_ ) { push @{$h{$keyf->($_)}}, $_; }
  my( $b, @bins ) = sort { @$a <=> @$b } values %h;
  my @result = @$b;
  for $b ( @bins ) {
    # (consider rotating @result here.)

    @result = _intersperse2( $b, \@result );
  }
  @result
}

sub _take_one {
  my( $counter_sr, $source_ar ) = @_;
  ${$counter_sr}++;
  shift @$source_ar
}

sub _intersperse2 {
  my( $aa, $ab ) = @_; # two arrays, by ref.
  @$aa > @$ab and ( $aa, $ab ) = ( $ab, $aa );
  # so that @$aa is the shorter array,
  # and @$ab is the longer array.

  my $ratio = @$ab / @$aa;
  my @accum;
  my( $na, $nb ) = (0,0);

  # take one from each, to start with:
  push @accum, _take_one( \$nb, $ab );
  push @accum, _take_one( \$na, $aa );

  while ( @$aa and @$ab ) {
    push @accum, _take_one(
      $nb / $na < $ratio
        ? ( \$nb, $ab )
        : ( \$na, $aa )
    );
  }

  ( @accum, @$ab, @$aa )
}

1;

__END__

=pod

=head1 AUTHORS

 This module was written by
 Tim Ayers (http://search.cpan.org/search?mode=author&query=tayers) and
 John Porter (http://search.cpan.org/search?mode=author&query=jdporter).

=head1 ACKNOWLEDGEMENTS

Thanks to John Porter for providing and implementing an improved algorithm for
solving the problem.

=head1 COPYRIGHT

Copyright (c) 2001 Tim Ayers and John Porter.

All rights reserved. This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut
