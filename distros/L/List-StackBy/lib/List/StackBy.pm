package List::StackBy;

use 5.020000;
use strict;
use warnings;
use base qw(Exporter);

our $VERSION = '0.01';

our %EXPORT_TAGS = ( 'all' => [ qw(
	stack_by
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
  stack_by
);

sub stack_by(&@) {
  my $code = shift;
  my @result;
  my $prev_key;

  for (@_) {
    my $cur_key = $code->( $_ );

    if (not(ref $prev_key)
     or not(defined $cur_key)
     or not(defined $$prev_key)
     or not($cur_key eq $$prev_key)) {

      push @result, [];
    }

    push @{ $result[-1] }, $_;
    
    $prev_key = \$cur_key;
  }

  return @result;
}

1;

__END__

=head1 NAME

List::StackBy - Group runs of similar elements

=head1 SYNOPSIS

  use List::StackBy;

  my @uniq = map { $_->[0] } stack_by { uc } qw/A B b A b B A/;
  # A B A b A

  my @by_col1 = map { /^\s*(\d+)/ ? $1 : undef } (
    "123,foo",
    "123,bar",
    "456,baz",
  );

  # ["123,foo", "123,bar"],
  # ["456,baz"]

=head1 DESCRIPTION

This module provides the function C<stack_by>.

=head1 FUNCTIONS

=over

=item stack_by { code } @list

Applies the code block to each item in the list and returns a list
of arrays containing runs of elements for which the code block
returned the same value. Items for which the code block returns an
undefined value are isolated from the rest.

=back

=head1 EXPORTS

C<stack_by> by default.

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2018 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
