package LaTeX::TikZ::Set::Raw;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Set::Raw - A literal chunk of TikZ code.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use LaTeX::TikZ::Interface;
use LaTeX::TikZ::Functor;

use Mouse;

=head1 RELATIONSHIPS

This class consumes the L<LaTeX::TikZ::Set::Path> role, and as such implements the L</path> method.

=cut

with 'LaTeX::TikZ::Set::Path';

=head1 ATTRIBUTES

=head2 C<content>

The bare string the raw set is made of.

=cut

has 'content' => (
 is       => 'ro',
 isa      => 'Str',
 required => 1,
);

=head1 METHODS

=head2 C<path>

=cut

sub path { $_[0]->content }

=head2 C<begin>

=cut

sub begin { undef }

=head2 C<end>

=cut

sub end { undef }

LaTeX::TikZ::Interface->register(
 raw => sub {
  shift;

  __PACKAGE__->new(content => join ' ', @_);
 },
);

LaTeX::TikZ::Functor->default_rule(
 (__PACKAGE__) => sub {
  my ($functor, $set, @args) = @_;
  $set->new(content => $set->content);
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

1; # End of LaTeX::TikZ::Set::Raw
