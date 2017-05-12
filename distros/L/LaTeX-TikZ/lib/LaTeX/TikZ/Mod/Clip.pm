package LaTeX::TikZ::Mod::Clip;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Mod::Clip - A modifier that clips sequences with a path.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use Sub::Name ();

use LaTeX::TikZ::Formatter;
use LaTeX::TikZ::Mod::Formatted;

use LaTeX::TikZ::Interface;
use LaTeX::TikZ::Functor;

use LaTeX::TikZ::Tools;

use Mouse;

=head1 RELATIONSHIPS

This class consumes the L<LaTeX::TikZ::Mod> role, and as such implements the L</tag>, L</covers>, L</declare> and L</apply> methods.

=cut

with 'LaTeX::TikZ::Mod';

=head1 ATTRIBUTES

=head2 C<clip>

The path that specifies the clipped area.

=cut

has clip => (
 is       => 'ro',
 does     => 'LaTeX::TikZ::Set::Path',
 required => 1,
);

my $default_formatter = LaTeX::TikZ::Formatter->new(
 unit   => 'cm',
 format => '%.07f',
 scale  => 1,
);

=head1 METHODS

=head2 C<tag>

=cut

sub tag { ref $_[0] }

=head2 C<covers>

=cut

my $get_tc = do {
 my %tc;

 Sub::Name::subname('get_tc' => sub {
  my ($class) = @_;

  return $tc{$class} if exists $tc{class};

  my $tc = LaTeX::TikZ::Tools::type_constraint($class);
  return unless defined $tc;

  $tc{$class} ||= $tc;
 })
};

my $cover_rectangle = Sub::Name::subname('cover_rectangle' => sub {
 my ($old, $new, $self_tc) = @_;

 my $p = $new->from;
 my $q = $new->to;

 my $x = $p->x;
 my $y = $p->y;
 my $X = $q->x;
 my $Y = $q->y;

 ($x, $X) = ($X, $x) if $x > $X;
 ($y, $Y) = ($Y, $y) if $y > $Y;

 if ($self_tc->check($old)) {
  # The old rectangle covers the new one if and only if it's inside the new.

  for ($old->from, $old->to) {
   my $r = $_->x;
   return 0 if LaTeX::TikZ::Tools::numcmp($r, $x) < 0
            or LaTeX::TikZ::Tools::numcmp($X, $r) < 0;
   my $i = $_->y;
   return 0 if LaTeX::TikZ::Tools::numcmp($i, $y) < 0
            or LaTeX::TikZ::Tools::numcmp($Y, $i) < 0;
  }

  return 1;
 }

 return 0;
});

my $cover_circle = Sub::Name::subname('cover_circle' => sub {
 my ($old, $new, $self_tc) = @_;

 my $c2 = $new->center;
 my $r2 = $new->radius;

 if ($self_tc->check($old)) {
  # The old circle covers the new one if and only if it's inside the new.

  my $c1 = $old->center;
  my $r1 = $old->radius;

  my $d = abs($c1 - $c2);

  return    LaTeX::TikZ::Tools::numcmp($d, $r2)       <= 0
         && LaTeX::TikZ::Tools::numcmp($d + $r1, $r2) <= 0;
 }

 return 0;
});

my @handlers = (
 [ 'LaTeX::TikZ::Set::Rectangle' => $cover_rectangle ],
 [ 'LaTeX::TikZ::Set::Circle'    => $cover_circle    ],
);

sub covers {
 my ($old, $new) = map $_->clip, @_[0, 1];

 for (@handlers) {
  my $tc = $get_tc->($_->[0]);
  next unless defined $tc and $tc->check($new);
  return $_->[1]->($old, $new, $tc);
 }

 $old->path($default_formatter) eq $new->path($default_formatter);
}

=head2 C<declare>

=cut

sub declare { }

=head2 C<apply>

=cut

sub apply {
 my ($self) = @_;

 LaTeX::TikZ::Mod::Formatted->new(
  type    => 'clip',
  content => $_[0]->clip->path($_[1]),
 )
}

LaTeX::TikZ::Interface->register(
 clip => sub {
  shift;

  __PACKAGE__->new(clip => $_[0]);
 },
);

LaTeX::TikZ::Functor->default_rule(
 (__PACKAGE__) => sub {
  my ($functor, $mod, @args) = @_;
  $mod->new(clip => $mod->clip->$functor(@args))
 }
);

__PACKAGE__->meta->make_immutable;

=head1 SEE ALSO

L<LaTeX::TikZ>, L<LaTeX::TikZ::Mod>.

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

1; # End of LaTeX::TikZ::Mod::Clip
