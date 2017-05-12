package LaTeX::TikZ::Set::Sequence;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Set::Sequence - A set object grouping a sequence of objects.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use List::Util ();

use LaTeX::TikZ::Scope;

use LaTeX::TikZ::Interface;
use LaTeX::TikZ::Functor;

use Mouse;
use Mouse::Util::TypeConstraints qw<subtype as where find_type_constraint>;

=head1 RELATIONSHIPS

This class consumes the L<LaTeX::TikZ::Set> and L<LaTeX::TikZ::Set::Container> roles, and as such implements the L</draw>, L</kids> and L</add> methods.

=cut

with qw<
 LaTeX::TikZ::Set
 LaTeX::TikZ::Set::Container
>;

subtype 'LaTeX::TikZ::Set::Sequence::Elements'
     => as 'Object'
     => where {
             $_->does('LaTeX::TikZ::Set::Path')
          or $_->isa('LaTeX::TikZ::Set::Sequence')
     };

=head1 ATTRIBUTES

=head2 C<kids>

The L<LaTeX::TikZ::Set::Path> or L<LaTeX::TikZ::Set::Sequence> objects that from the sequence.

=cut

has '_kids' => (
 is       => 'ro',
 isa      => 'Maybe[ArrayRef[LaTeX::TikZ::Set::Sequence::Elements]]',
 init_arg => 'kids',
 default  => sub { [ ] },
);

sub kids { @{$_[0]->_kids} }

=head1 METHODS

=head2 C<add>

=cut

my $ltsse_tc = find_type_constraint('LaTeX::TikZ::Set::Sequence::Elements');

sub add {
 my $set = shift;

 $ltsse_tc->assert_valid($_) for @_;

 push @{$set->_kids}, @_;

 $set;
}

=head2 C<draw>

=cut

sub draw {
 my $set = shift;

 my @kids = $set->kids;
 return [ ] unless @kids;

 List::Util::reduce { LaTeX::TikZ::Scope::fold($a, $b) }
  map $_->draw(@_),
   @kids;
}

LaTeX::TikZ::Interface->register(
 seq => sub {
  shift;

  __PACKAGE__->new(kids => \@_);
 },
);

LaTeX::TikZ::Functor->default_rule(
 (__PACKAGE__) => sub {
  my ($functor, $set, @args) = @_;
  $set->new(kids => [ map $_->$functor(@args), $set->kids ])
 }
);

__PACKAGE__->meta->make_immutable;

=head1 SEE ALSO

L<LaTeX::TikZ>, L<LaTeX::TikZ::Set::Path>, L<LaTeX::TikZ::Set::Container>.

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

1; # End of LaTeX::TikZ::Set::Sequence
