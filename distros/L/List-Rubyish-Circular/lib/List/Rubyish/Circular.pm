package List::Rubyish::Circular;
use 5.008001;
use strict;
use warnings;
use parent qw(List::Rubyish);

our $VERSION = '0.04';

sub cycle {
    my ($self, $count) = @_;
    $count ||= 1;

    my @list;
    for my $index ($count .. (($self->size - 1) + $count)) {
        push @list, $self->[$index % $self->size];
    }

    @{$self} = @list;
    $self;
}

sub rcycle {
    my ($self, $count) = @_;
    $count ||= 1;
    $self->cycle(- $count);
}

1;

__END__

=encoding utf8

=head1 NAME

List::Rubyish::Circular - A circular list implementation based on
List::Rubyish

=head1 SYNOPSIS

  use Test::More;
  use List::Rubyish::Circular;

  my $list = List::Rubyish::Circular->new(qw(jkondo reikon cinnamon));

  is_deeply, $list->cycle->to_a,     [qw(reikon cinnamon jkondo)];
  is_deeply, $list->cycle(2)->to_a,  [qw(jkondo reikon cinnamon)];

  is_deeply, $list->rcycle->to_a,    [qw(cinnamon jkondo reikon)];
  is_deeply, $list->rcycle(2)->to_a, [qw(jkondo reikon cinnamon)];

  # $list is still a circular list after destracive operation
  $list->push(qw(tokky));

  is_deeply, $list->to_a,            [qw(jkondo reikon cinnamon tokky)];
  is_deeply, $list->cycle->to_a,     [qw(reikon cinnamon tokky jkondo)];
  is_deeply, $list->rcycle(2)->to_a, [qw(tokky jkondo reikon cinnamon)];

=head1 DESCRIPTION

List::Rubyish::Circular is a cirlular list implementation besed on
L<List::Rubyish>, so that You can utilize some convenient methods from
List::Rubyish against a circular list.

=head1 METHODS

=head2 cycle ( I<$count> )

=over 4

Shifts list to the left according to C<$count>. If $count not passed
in, its value is 1. This operation is destructive.

  my $list = List::Rubyish::Circular->new(qw(jkondo reikon cinnamon));

  is_deeply, $list->cycle->to_a,    [qw(reikon cinnamon jkondo)];
  is_deeply, $list->cycle(2)->to_a, [qw(jkondo reikon cinnamon)];

=back

=head2 rcycle ( I<$count> )

=over 4

The opposite of C<cycle>.

=back

=head1 SEE ALSO

=over 4

=item L<List::Rubyish>

=back

=head1 AUTHOR

Kentaro Kuribayashi E<lt>kentarok@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

Copyright (C) Kentaro Kuribayashi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
