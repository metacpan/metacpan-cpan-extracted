package LaTeX::TikZ::Set::Union;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Set::Union - A set object representing a path formed by the reunion of several subpaths.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use LaTeX::TikZ::Interface;
use LaTeX::TikZ::Functor;

use LaTeX::TikZ::Tools;

use Mouse;

=head1 RELATIONSHIPS

This class consumes the L<LaTeX::TikZ::Set::Path> and L<LaTeX::TikZ::Set::Container> roles, and as such implements the L</path>, L</kids> and L</add> methods.

=cut

with qw<
 LaTeX::TikZ::Set::Path
 LaTeX::TikZ::Set::Container
>;

=head1 ATTRIBUTES

=head2 C<kids>

The L<LaTeX::TikZ::Set::Path> objects that form the path.

=cut

has '_kids' => (
 is       => 'ro',
 isa      => 'Maybe[ArrayRef[LaTeX::TikZ::Set::Path]]',
 init_arg => 'kids',
 default  => sub { [ ] },
);

sub kids { @{$_[0]->_kids} }

=head1 METHODS

=head2 C<add>

=cut

my $ltsp_tc = LaTeX::TikZ::Tools::type_constraint('LaTeX::TikZ::Set::Path');

sub add {
 my $set = shift;

 $ltsp_tc->assert_valid($_) for @_;

 push @{$set->_kids}, @_;

 $set;
}

=head2 C<path>

=cut

sub path {
 my $set = shift;

 join ' ', map $_->path(@_), $set->kids;
}

=head2 C<begin>

=cut

sub begin {
 my $set = shift;

 my @kids = $set->kids;
 return undef unless @kids;

 $kids[0]->begin;
}

=head2 C<end>

=cut

sub end {
 my $set = shift;

 my @kids = $set->kids;
 return undef unless @kids;

 $kids[-1]->end;
}

LaTeX::TikZ::Interface->register(
 union => sub {
  shift;

  __PACKAGE__->new(kids => \@_);
 },
 path  => sub {
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

1; # End of LaTeX::TikZ::Set::Union
