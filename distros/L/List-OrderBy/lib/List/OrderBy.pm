package List::OrderBy;
use strict;
use warnings;
use Exporter;

use vars qw{ $VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS };

BEGIN {
  @ISA = qw(Exporter);
  %EXPORT_TAGS = ( 'all' => [ qw(
    order_by              then_by
    order_cmp_by          then_cmp_by
    order_by_desc         then_by_desc
    order_cmp_by_desc     then_cmp_by_desc
  ) ] );

  @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
  @EXPORT = @EXPORT_OK;
  $VERSION = '0.2';
};

sub order_by(&;@) {
  List::OrderBy::Container->new(sub { $_[0] <=> $_[1] }, @_)->get();
}

sub order_by_desc(&;@) {
  List::OrderBy::Container->new(sub { $_[1] <=> $_[0] }, @_)->get();
}

sub order_cmp_by_desc(&;@) {
  List::OrderBy::Container->new(sub { $_[1] cmp $_[0] }, @_)->get();
}

sub order_cmp_by(&;@) {
  List::OrderBy::Container->new(sub { $_[0] cmp $_[1] }, @_)->get();
}

sub then_by(&;@) {
  List::OrderBy::Container->new(sub { $_[0] <=> $_[1] }, @_)
}

sub then_by_desc(&;@) {
  List::OrderBy::Container->new(sub { $_[1] <=> $_[0] }, @_)
}

sub then_cmp_by(&;@) {
  List::OrderBy::Container->new(sub { $_[0] cmp $_[1] }, @_)
}

sub then_cmp_by_desc(&;@) {
  List::OrderBy::Container->new(sub { $_[1] cmp $_[0] }, @_)
}

package List::OrderBy::Container;
use strict;
use warnings;

sub new {
  my $class = shift;
  my $key_comparer = shift;
  my $key_extractor = shift;
  my @list = @_;
  my $self = bless { }, $class;

  # Chained then_by calls are merged into a single object
  if (@list and UNIVERSAL::isa($list[0], __PACKAGE__)) {

    # Copy reference to the list and the existing key extractors
    $self->{key_extractors} = [ @{ $list[0]->{key_extractors} } ];
    $self->{key_comparers}  = [ @{ $list[0]->{key_comparers} } ];
    $self->{list}           = $list[0]->{list};

  } else {
    $self->{list} = \@list;
  }

  # A sequence `order_by { ... } then_by { ... }` is evaluated from
  # the right to the left, and to make the first element the first
  # extractor to be applied, elements are unshifted into the list.

  unshift @{ $self->{key_extractors} }, $key_extractor;
  unshift @{ $self->{key_comparers} }, $key_comparer;

  $self;
}

sub get {
  my $merged = shift;

  # Extract all keys
  my @keys = map {
    my $code = $_;

    # When a sub is used as key extractor instead of a code block,
    # authors would expect the data passed in as argument, so this
    # does both, pass through $_ and pass through the parameter.

    [ map { scalar $code->($_); } @{ $merged->{list} } ]

  } @{ $merged->{key_extractors} };

  my @sorted_indices = sort {
    my $compare = 0;
    for (my $ix = 0; !$compare and $ix <= $#keys; ++$ix) {
      $compare = $merged->{key_comparers}[$ix]
        ->($keys[$ix]->[$a], $keys[$ix]->[$b]);
    }
    $compare;
  } 0 .. $#{ $merged->{list} };

  return map { $merged->{list}[$_] } @sorted_indices;
}

1;

__END__

=head1 NAME

List::OrderBy - Multi-key sorting using order_by and then_by

=head1 SYNOPSIS

  use List::OrderBy;
  my @sorted = order_by { ... }
                then_by { ... }
                then_by { ... } @unsorted;

=head1 DESCRIPTION

Routines to generate ordered lists using key extraction code blocks
with support for multi-key sorting.

=head2 ROUTINES

=over 2

=item order_by { ... } @list

=item order_by \&code, @list

The main routine takes a code block or subroutine reference and a list,
applies the specified code to every element in the list to extract a sorting
key, and then returns a list ordered according to the extracted keys, using
C<sort> and `<=>` internally. In the code block the list item value is
available as C<$_>, and subroutines are additionally called with the value
as first parameter.

  my @sorted = order_by { length }
    qw/xxx xx x/; # returns qw/x xx xxx/

=item then_by { ... } @list

In a chain starting with C<order_by>, C<then_by> specifies an additional
ordering key extractor. The extracted key will be used to order elements if
keys extracted by preceding C<order_by> or C<then_by> calls are equivalent.

  my @sorted = order_by { $_->width  }
                then_by { $_->height } @shapes;

This would first sort elements by their width and then by their height.

=item order_by_desc { ... } @list

Same as C<order_by> but uses descending order.

=item order_cmp_by { ... } @list

Same as C<order_by> but uses C<cmp> to compare extracted keys.

=item order_cmp_by_desc { ... } @list

=item then_cmp_by { ... } @list

=item then_by_desc { ... } @list

=item then_cmp_by_desc { ... } @list

Analogous to the similarily named routines.

=back

=head2 EXPORTS

The functions C<order_by>, C<then_by>, C<order_cmp_by>, C<then_cmp_by>,
C<order_by_desc>, C<then_by_desc>, C<order_cmp_by_desc>, and C<then_cmp_by_desc>,
by default.

=head2 KNOWN ISSUES

This module is mainly an experiment to see how Schwartzian transforms
can be avoided in code, considering the pattern can be difficult to read,
and it becomes unmaintainable with multiple keys. There are a number of
issues though, like how to manage side-effects: should the module call a
secondary key extractor even when the key is not actually needed? Should
the module ensure that the key extractor is called only once? Does the
ordering between calls to the key extractors matter?

Another problem is of course naming, C<order_by { ... } then_by { ... }>
is nice enough, but there does not seem to be a good way to add options
like the comparison operator or ascending/descending behavior. Same for
the side-effects question above if that was to be made configurable. A
syntax with named parameters like in C<order_by :cmp :desc { ... }> would
be better but is not yet available with Perl5.

One gotcha I've noticed is with sorting strings by length. Since they are
strings, you might be inclined to use a C<cmp> variant, but
C<order_cmp_by { length }> usually is not what authors want. In a draft
version of this module I actually called the routine C<order_strings_by>,
and switched to C<order_cmp_by> to make it less misleading.

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2013 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
