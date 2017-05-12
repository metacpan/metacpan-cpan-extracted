package List::EachCons;

use 5.010000;
use strict;
use warnings;
use base qw(Exporter);

our $VERSION = '0.01';

our %EXPORT_TAGS = ( 'all' => [ qw(
	each_cons
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
  each_cons
);

sub each_cons($\@&) {
  my ($count, $list, $code) = @_;
  return unless @$list >= $count;
  return unless $count > 0;
  my $ix = 0;
  my @current;
  push @current, $list->[$ix++] for 1 .. $count;
  my @result;
  while (1) {
    my $value = $code->(@current);
    push @result, $value if wantarray;
    last if $ix >= @$list;
    shift @current;
    push @current, $list->[$ix++];
  }
  @result;
}

1;

__END__

=head1 NAME

List::EachCons - Apply code to each array element and a block of successors

=head1 SYNOPSIS

  use List::EachCons;
  my @list = qw/a b c d/;
  each_cons 3, @list, sub {
    say "@_";
  };
  # a b c
  # b c d
  
=head1 DESCRIPTION

This module provides the function C<each_cons>.

=head1 FUNCTIONS

=over

=item each_cons($size, $array, $code)

If C<$array> has at least C<$size> elements then this function calls
C<$code> for each element in C<$array> with C<$size> consecutive
elements from the array as argument in the order of elements in the
array. Returns a list of return values from invoking the code reference.

=back

=head1 EXPORTS

C<each_cons> by default.

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2014 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
