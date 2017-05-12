package LaTeX::TikZ::Mod::Pattern::Lines;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Mod::Pattern::Lines - An hatched pattern modifier.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use Sub::Name ();

use LaTeX::TikZ::Tools;

use Mouse;
use Mouse::Util::TypeConstraints;

=head1 RELATIONSHIPS

This class inherits the L<LaTeX::TikZ::Mod::Pattern> class and its L</tag>, L</covers>, L<LaTeX::TikZ::Mod::Pattern/declare> and L<LaTeX::TikZ::Mod::Pattern/apply> methods.

=cut

extends 'LaTeX::TikZ::Mod::Pattern';

=head1 ATTRIBUTES

=head2 C<direction>

=cut

enum 'LaTeX::TikZ::Mod::Pattern::Direction' => (
 'horizontal', 'vertical', 'north east', 'north west',
);

has 'direction' => (
 is      => 'ro',
 isa     => 'LaTeX::TikZ::Mod::Pattern::Direction',
 default => 'horizontal',
);

=head2 C<line_width>

=cut

has 'line_width' => (
 is      => 'ro',
 isa     => subtype('Num' => where { LaTeX::TikZ::Tools::numcmp($_, 0) >= 0 }),
 default => 1,
);

=head2 C<space_width>

=cut

has 'space_width' => (
 is      => 'ro',
 isa     => subtype('Num' => where { LaTeX::TikZ::Tools::numcmp($_, 0) >= 0 }),
 default => 10,
);

my $W = Sub::Name::subname('WIDTH' => sub { sprintf '#WIDTH=%0.1f#', @_ });

my $forge_template = Sub::Name::subname('forge_template' => sub {
 my ($direction, $line_width, $space_width) = @_;

 my ($low_left, $up_right, $tile_size, $line_begin, $line_end);
 my ($width, $half_width, $shadow_min, $shadow_max);

 $width      = $W->($space_width);
 $half_width = $W->($space_width / 2);

 $shadow_min = $W->(- $line_width);
 $shadow_max = $W->($space_width + $line_width);
 $line_width = $W->($line_width);

 $low_left   = "\\pgfqpoint{$shadow_min}{$shadow_min}";
 $up_right   = "\\pgfqpoint{$shadow_max}{$shadow_max}";
 $tile_size  = "\\pgfqpoint{$width}{$width}";

 if ($direction =~ /^(?:horizontal|vertical)$/) {

  if ($direction eq 'horizontal') {
   $line_begin = "\\pgfqpoint{$shadow_min}{$half_width}";
   $line_end   = "\\pgfqpoint{$shadow_max}{$half_width}";
  } else {
   $line_begin = "\\pgfqpoint{$half_width}{$shadow_min}";
   $line_end   = "\\pgfqpoint{$half_width}{$shadow_max}";
  }

 } elsif ($direction =~ /^north (?:east|west)$/) {

  if ($direction eq 'north east') {
   $line_begin = "\\pgfqpoint{$shadow_min}{$shadow_min}";
   $line_end   = "\\pgfqpoint{$shadow_max}{$shadow_max}";
  } else {
   $line_begin = "\\pgfqpoint{$shadow_min}{$shadow_max}";
   $line_end   = "\\pgfqpoint{$shadow_max}{$shadow_min}";
  }

 } else {
  return;
 }

 return [
  "\\pgfdeclarepatternformonly{#NAME#}{$low_left}{$up_right}{$tile_size}{",
  "\\pgfsetlinewidth{$line_width}",
  "\\pgfpathmoveto{$line_begin}",
  "\\pgfpathlineto{$line_end}",
  "\\pgfusepath{stroke}",
  "}",
 ];
});

around 'BUILDARGS' => sub {
 my ($orig, $class, %args) = @_;

 confess('Can\'t specify an explicit template for a '. __PACKAGE__ .' pattern')
                                                      if exists $args{template};

 my @params = qw<direction line_width space_width>;

 my $meta = $class->meta;
 for (@params) {
  my $attr = $meta->find_attribute_by_name($_);
  $args{$_} = $attr->default if $attr->has_default and not exists $args{$_};
  $attr->type_constraint->assert_valid($args{$_});
 }

 $args{template} = $forge_template->(@args{@params});

 $class->$orig(%args);
};

=head1 METHODS

=head2 C<tag>

=cut

sub tag { join '/', ref $_[0], $_[0]->direction }

=head2 C<covers>

=cut

sub covers {
 my ($this, $other) = @_;

 LaTeX::TikZ::Tools::numeq($this->line_width, $other->line_width) or return 0;

 my $ratio = $other->space_width / $this->space_width;

 return LaTeX::TikZ::Tools::numeq($ratio, int $ratio);
}

__PACKAGE__->meta->make_immutable;

=head1 SEE ALSO

L<LaTeX::TikZ>, L<LaTeX::TikZ::Mod::Pattern>.

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

1; # End of LaTeX::TikZ::Mod::Pattern::Lines
