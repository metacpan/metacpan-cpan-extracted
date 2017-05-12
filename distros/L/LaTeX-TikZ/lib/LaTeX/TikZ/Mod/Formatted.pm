package LaTeX::TikZ::Mod::Formatted;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Mod::Formatted - Intermediate object between a modifier object and its code representation.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use Mouse;
use Mouse::Util::TypeConstraints qw<enum coerce from via>;

=head1 ATTRIBUTES

=head2 C<type>

=cut

has 'type' => (
 is       => 'ro',
 isa      => enum([ qw<clip layer raw> ]),
 required => 1,
);

=head2 C<content>

=cut

has 'content' => (
 is       => 'ro',
 isa      => 'Str',
 required => 1,
);

coerce 'LaTeX::TikZ::Mod::Formatted'
    => from 'Str'
    => via { LaTeX::TikZ::Mod::Formatted->new(type => 'raw', content => $_) };

=head1 METHODS

=head2 C<tag>

=cut

sub tag {
 my ($self) = @_;

 ref($self) . '/' . $self->type . '/' . $self->content;
}

__PACKAGE__->meta->make_immutable;

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

1; # End of LaTeX::TikZ::Mod::Formatted
