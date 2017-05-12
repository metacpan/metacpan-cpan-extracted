package LaTeX::TikZ::Interface;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Interface - LaTeX::TikZ public interface register and loader.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use Sub::Name ();

=head1 METHODS

=head2 C<register>

    LaTeX::Tikz::Interface->register($keyword => $code)

Registers C<$code> to be available with C<< Tikz->$keyword >>.

=cut

sub register {
 shift;

 while (@_ >= 2) {
  my ($name, $code) = splice @_, 0, 2;

  unless (defined $name and $name =~ /^[a-z_][a-z0-9_]+$/i) {
   require Carp;
   Carp::confess('Invalid interface name');
  }

  if (do { no strict 'refs'; defined &{__PACKAGE__."::$name"} }) {
   require Carp;
   Carp::confess("'$name' is already defined in the interface");
  }

  unless (defined $code and ref $code eq 'CODE') {
   require Carp;
   Carp::confess('Invalid code reference');
  }

  Sub::Name::subname($name => $code);

  {
   no strict 'refs';
   *{__PACKAGE__.'::'.$name} = $code;
  }
 }

 return;
}

=head2 C<load>

Load all the modules of the L<LaTeX::TikZ> official suite that register a keyword in the interface.

=cut

sub load {
 require LaTeX::TikZ::Formatter;      # formatter
 require LaTeX::TikZ::Functor;        # functor

 require LaTeX::TikZ::Set::Raw;       # raw

 require LaTeX::TikZ::Set::Union;     # union, path
 require LaTeX::TikZ::Set::Sequence;  # seq
 require LaTeX::TikZ::Set::Chain;     # chain, join

 require LaTeX::TikZ::Set::Point;     # point
 require LaTeX::TikZ::Set::Line;      # line
 require LaTeX::TikZ::Set::Polyline;  # polyline, closed_polyline
 require LaTeX::TikZ::Set::Rectangle; # rectangle
 require LaTeX::TikZ::Set::Circle;    # circle
 require LaTeX::TikZ::Set::Arc;       # arc
 require LaTeX::TikZ::Set::Arrow;     # arrow

 require LaTeX::TikZ::Mod::Raw;       # raw_mod

 require LaTeX::TikZ::Mod::Clip;      # clip
 require LaTeX::TikZ::Mod::Layer;     # layer

 require LaTeX::TikZ::Mod::Scale;     # scale
 require LaTeX::TikZ::Mod::Width;     # width
 require LaTeX::TikZ::Mod::Color;     # color
 require LaTeX::TikZ::Mod::Fill;      # fill
 require LaTeX::TikZ::Mod::Pattern;   # pattern
}

=head1 SEE ALSO

L<LaTeX::TikZ>.

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

1; # End of LaTeX::TikZ::Interface
