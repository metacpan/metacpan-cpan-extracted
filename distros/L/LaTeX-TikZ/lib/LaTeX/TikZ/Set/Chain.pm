package LaTeX::TikZ::Set::Chain;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Set::Chain - A set object representing a connected path between several objects.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use LaTeX::TikZ::Set::Point;
use LaTeX::TikZ::Set::Raw;

use LaTeX::TikZ::Interface;
use LaTeX::TikZ::Functor;

use LaTeX::TikZ::Tools;

use Mouse;
use Mouse::Util::TypeConstraints qw<subtype as coerce from via>;

=head1 RELATIONSHIPS

This class consumes the L<LaTeX::TikZ::Set::Path> and L<LaTeX::TikZ::Set::Container> roles, and as such implements the L</path>, L</kids> and L</add> methods.

=cut

with qw<
 LaTeX::TikZ::Set::Path
 LaTeX::TikZ::Set::Container
>;

=head1 ATTRIBUTES

=head2 C<kids>

The L<LaTeX::TikZ::Set::Path> objects that form the chain.

=cut

subtype 'LaTeX::TikZ::Set::Chain::Elements'
     => as 'ArrayRef[LaTeX::TikZ::Set::Path]';

coerce 'LaTeX::TikZ::Set::Chain::Elements'
    => from 'ArrayRef[Any]'
    => via { [ map {
        blessed($_) && $_->does('LaTeX::TikZ::Set')
          ? $_
          : LaTeX::TikZ::Set::Point->new(point => $_)
       } @$_ ] };

has '_kids' => (
 is       => 'ro',
 isa      => 'LaTeX::TikZ::Set::Chain::Elements',
 init_arg => 'kids',
 default  => sub { [ ] },
 coerce   => 1,
);

sub kids { @{$_[0]->_kids} }

=head2 C<connector>

A code reference that describes how two successive elements of the chain are linked.
When the L</path> method is called, the connector is run repeatedly with these arguments :

=over 4

=item *

The current L<LaTeX::TikZ::Set::Chain> object.

=item *

The index C<$i> of the current position in the chain, starting at C<0> for the link between the two first elements.

=item *

The C<$i>-th L<LaTeX::TikZ::Set> object in the chain.

=item *

The C<$i+1>-th L<LaTeX::TikZ::Set> object in the chain.

=item *

The L<LaTeX::TikZ::Formatter> object.

=back

You can also pass a string, which will be upgraded to a code reference constantly returning that string ; or an array reference, which will be turned into a code reference returning the C<$i>-th element of the array when asked for the C<$i>-th link.

=cut

subtype 'LaTeX::TikZ::Set::Chain::Connector'
     => as 'CodeRef';

coerce 'LaTeX::TikZ::Set::Chain::Connector'
    => from 'Str'
    => via { my $conn = $_; sub { $conn } };

coerce 'LaTeX::TikZ::Set::Chain::Connector'
    => from 'ArrayRef[Str]'
    => via { my $conns = $_; sub { $conns->[$_[1]] } };

has 'connector' => (
 is       => 'ro',
 isa      => 'LaTeX::TikZ::Set::Chain::Connector',
 required => 1,
 coerce   => 1,
);

=head2 C<cycle>

A boolean that indicates whether the path is a cycle or not.

=cut

has 'cycle' => (
 is      => 'ro',
 isa     => 'Bool',
 default => 0,
);

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

 my @kids  = $set->kids;
 return '' unless @kids;

 my $conn  = $set->connector;

 my $prev  = $kids[0];
 my $path  = $prev->path(@_);

 if ($set->cycle) {
  push @kids, LaTeX::TikZ::Set::Raw->new(
   content => 'cycle',
  );
 }

 my $tikz = $_[0];
 for my $i (1 .. $#kids) {
  my $next = $kids[$i];
  my $link = $set->$conn($i - 1, $prev, $next, $tikz);
  confess('Invalid connector') unless defined $link and not blessed $link;
  $link    = " $link ";
  $link    =~ s/\s+/ /g;
  $path   .= $link . $next->path(@_);
  $prev    = $next;
 }

 return $path;
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
 join => sub {
  shift;
  my $conn = shift;

  __PACKAGE__->new(
   kids      => \@_,
   connector => $conn,
  );
 },
 chain => sub {
  shift;
  confess("The 'chain' command expects an odd number of arguments")
                                                                  unless @_ % 2;

  my @kids = shift;
  my @links;
  for (my $i = 0; $i < @_; $i += 2) {
   push @links, $_[$i];
   push @kids,  $_[$i + 1];
  }

  __PACKAGE__->new(
   kids      => \@kids,
   connector => \@links,
  );
 }
);

LaTeX::TikZ::Functor->default_rule(
 (__PACKAGE__) => sub {
  my ($functor, $set, @args) = @_;
  $set->new(
   kids      => [ map $_->$functor(@args), $set->kids ],
   connector => $set->connector,
   cycle     => $set->cycle,
  );
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

1; # End of LaTeX::TikZ::Set::Chain
