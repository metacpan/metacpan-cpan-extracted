package List::Collection;
use Modern::Perl;
use Exporter;
use Sort::Naturally;

our $VERSION = '0.0.4'; # VERSION
# ABSTRACT: List::Collection


our @ISA = qw/Exporter/;
our @EXPORT = qw/intersect union subtract complement/;


sub new {
  my $class = shift;
  return bless { @_ }, $class;
}

sub _remove_obj {
  return if @_ == 0;
  shift if ($_[0] and ref $_[0] eq __PACKAGE__);
  return @_;
}


sub intersect {
  my @lists = _remove_obj(@_);
  my $list_count = @lists;
  my (%elements, @out);
  for my $list (@lists) {
    $elements{$_}++ for (@$list);
  }
  for my $key (sort keys %elements) {
    push (@out, $key) if $elements{$key} == $list_count;
  }
  @out = nsort(@out);
  return @out;
}


sub union {
  my @lists = _remove_obj(@_);
  my (%elements, @out);
  for my $list (@lists) {
    $elements{$_} = 1 for (@$list);
  }
  @out = nsort(keys %elements);
  return @out;
}


sub subtract {
  my @lists = _remove_obj(@_);
  my %elements;
  $elements{$_} = 1 for (@{$lists[0]});
  delete $elements{$_} for (@{$lists[1]});
  my @out = nsort(keys %elements);
  return @out;
}


sub complement {
  my @lists = _remove_obj(@_);
  my @union = union(@lists);
  my @intersect = intersect(@lists);
  my @out = subtract(\@union, \@intersect);
  @out = nsort(@out);
  return @out;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

List::Collection - List::Collection

=head1 VERSION

version 0.0.4

=head1 SYNOPSIS

  use List::Collection;
  my @a = qw/1 2 3 4 5 6/;
  my @b = qw/4 5 6 7 8 9/;
  my @c = qw/5 6 7 8 9 10/;

  # get intersection set between two or more List
  my @intersect = intersect(\@a, \@b, \@c);  # result is (5,6)

  # get union set between two or more List
  my @union = union(\@a, \@b, \@c);    # result is (1,2,3,4,5,6,7,8,9,10)

  # get substraction between two
  my @substract = subtract(\@a, \@b);  # result is (1,2,3)

  # get complementation between two or more
  my @complement = complement(\@a, \@b);  # result is (1,2,3,7,8,9)

Or in a object-oriented way

  use List::Collection;
  my @a = qw/1 2 3 4 5 6/;
  my @b = qw/4 5 6 7 8 9/;
  my $lc = List::Collection->new();
  my @union = $lc->union(\@a, \@b);
  my @intersect = $lc->intersect(\@a, \@b);

=head1 DESCRIPTION

Blablabla

=head1 METHODS

=head2 new

List::Collection's construction function

=head2 intersect

Intersection of multiple Lists, number of parameter could be bigger than two and type is ArrayRef

  my @a = qw/1 2 3 4 5 6/;
  my @b = qw/4 5 6 7 8 9/;
  my @intersect = intersect(\@a, \@b);

=head2 union

union set of multiple Lists, number of parameter could be bigger than two and type is ArrayRef

  my @a = qw/1 2 3 4 5 6/;
  my @b = qw/4 5 6 7 8 9/;
  my @union = union(\@a, \@b);

=head2 subtract

subtraction(difference set) of two Lists, input parameters' type is ArrayRef

  my @a = qw/1 2 3 4 5 6/;
  my @b = qw/4 5 6 7 8 9/;
  my @subtract = subtract(\@a, \@b);

=head2 complement 

complement set of multiple Lists, number of parameter could be bigger than two and  type is ArrayRef

  my @a = qw/1 2 3 4 5 6/;
  my @b = qw/4 5 6 7 8 9/;
  my @complement = complement(\@a, \@b);

=head1 AUTHOR

Yan Xueqing <yanxueqing621@163.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yan Xueqing.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
