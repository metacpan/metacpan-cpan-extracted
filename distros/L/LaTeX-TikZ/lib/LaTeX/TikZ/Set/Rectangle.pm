package LaTeX::TikZ::Set::Rectangle;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Set::Rectangle - A set object representing a rectangle.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use LaTeX::TikZ::Set::Point;

use LaTeX::TikZ::Interface;
use LaTeX::TikZ::Functor;

use Mouse;

=head1 RELATIONSHIPS

This class consumes the L<LaTeX::TikZ::Set::Path> role, and as such implements the L</path> method.

=cut

with 'LaTeX::TikZ::Set::Path';

=head1 ATTRIBUTES

=head2 C<from>

The first corner of the rectangle, as a L<LaTeX::TikZ::Set::Point> object.

=cut

has 'from' => (
 is       => 'ro',
 isa      => 'LaTeX::TikZ::Set::Point',
 required => 1,
 coerce   => 1,
);

=head2 C<to>

The opposite endpoint of the rectangle, also as a L<LaTeX::TikZ::Set::Point> object.

=cut

has 'to' => (
 is       => 'ro',
 isa      => 'LaTeX::TikZ::Set::Point',
 required => 1,
 coerce   => 1,
);

=head2 C<width>

The algebraic width of the rectangle.

=cut

has 'width' => (
 is  => 'ro',
 isa => 'Num',
);

=head2 C<height>

The algebraic height of the rectangle.

=cut

has 'height' => (
 is  => 'ro',
 isa => 'Num',
);

=head1 METHODS

=head2 C<path>

=cut

sub path {
 my $set = shift;

 $set->from->path(@_) . ' rectangle ' . $set->to->path(@_);
}

=head2 C<begin>

=cut

sub begin { $_[0]->from->begin }

=head2 C<end>

=cut

sub end { $_[0]->to->end }

my $meta = __PACKAGE__->meta;
my $tc1  = $meta->find_attribute_by_name('from')->type_constraint;
my $tc2  = $meta->find_attribute_by_name('to')->type_constraint;

around 'BUILDARGS' => sub {
 my $orig  = shift;
 my $class = shift;

 if (@_ == 2 and $tc1->check($_[0]) and $tc2->check($_[1])) {
  my ($from, $to) = @_;
  @_ = (
   from   => $from,
   to     => $to,
   width  => $to->x - $from->x,
   height => $to->y - $from->y,
  );
 } else {
  my %args = @_;
  if (not exists $args{to} and exists $args{from}) {
   confess(<<'   MSG') unless exists $args{width} and exists $args{height};
Attributes 'width' and 'height' are required when 'to' was not given
   MSG
   $args{from} = $tc1->coerce($args{from});
   $meta->find_attribute_by_name($_)->type_constraint->assert_valid($args{$_})
                                                      for qw<from width height>;
   my $p = $args{from}->point;
   $args{to} = LaTeX::TikZ::Point->new(
    x => $p->x + $args{width},
    y => $p->y + $args{height},
   );
   @_ = %args;
  }
 }

 $class->$orig(@_);
};

LaTeX::TikZ::Interface->register(
 rectangle => sub {
  shift;
  my ($p, $q) = @_;

  my $is_relative = !blessed($q) && ref($q) eq 'HASH';

  __PACKAGE__->new(
   from => $p,
   ($is_relative ? (map +($_ => $q->{$_}), qw<width height>) : (to => $q)),
  );
 },
);

LaTeX::TikZ::Functor->default_rule(
 (__PACKAGE__) => sub {
  my ($functor, $set, @args) = @_;
  $set->new(map { $_ => $set->$_->$functor(@args) } qw<from to>)
 }
);

__PACKAGE__->meta->make_immutable;

=head1 SEE ALSO

L<LaTeX::TikZ>, L<LaTeX::TikZ::Set::Path>.

=head1 AUTHOR

Vincent Pit, C<< <perl at profvince.com> >>, L<http://www.profvince.com>.

You can contact me by mail or on C<irc.perl.org> (vincent).

=head1 BUGS

Please report any bugs or feature requests to C<bug-latex-tikz at rt.cpan.org>, or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LaTeX-TikZ>.
I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LaTeX::TikZ

=head1 COPYRIGHT & LICENSE

Copyright 2010,2011,2012,2013,2014,2015 Vincent Pit, all rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

1; # End of LaTeX::TikZ::Set::Rectangle
