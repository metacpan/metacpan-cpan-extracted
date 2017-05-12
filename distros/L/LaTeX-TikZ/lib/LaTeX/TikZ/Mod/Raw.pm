package LaTeX::TikZ::Mod::Raw;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Mod::Raw - A literal TikZ modifier.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use LaTeX::TikZ::Interface;

use Mouse;

=head1 RELATIONSHIPS

This class consumes the L<LaTeX::TikZ::Mod> role, and as such implements the L</tag>, L</covers>, L</declare> and L</apply> methods.

=cut

with 'LaTeX::TikZ::Mod';

=head1 ATTRIBUTES

=head2 C<content>

The bare string the raw mod is made of.

=cut

has 'content' => (
 is       => 'ro',
 isa      => 'Str',
 required => 1,
);

=head1 METHODS

=head2 C<tag>

=cut

sub tag {
 my ($self) = @_;

 ref($self) . '/' . $self->content;
}

=head2 C<covers>

=cut

sub covers { 0 }

=head2 C<declare>

=cut

sub declare { }

=head2 C<apply>

=cut

sub apply { $_[0]->content }

LaTeX::TikZ::Interface->register(
 raw_mod => sub {
  shift;

  __PACKAGE__->new(content => $_[0]);
 },
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

1; # End of LaTeX::TikZ::Mod::Raw
