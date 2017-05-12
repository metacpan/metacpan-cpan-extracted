package LaTeX::TikZ::Mod::Pattern;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Mod::Pattern - A modifier that fills a closed path with a pattern.

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

=head2 C<template>

=cut

has 'template' => (
 is       => 'ro',
 isa      => 'ArrayRef[Str]',
 required => 1,
);

has '_cache' => (
 is       => 'ro',
 isa      => 'HashRef',
 init_arg => undef,
 default  => sub { +{ } },
);

=head1 METHODS

=head2 C<name>

=cut

sub name {
 my ($pat, $tikz) = @_;

 my $cache = $pat->_cache->{$tikz->id};
 confess('Template not yet declared') unless defined $cache;

 $cache->[0];
}

my $id = 'a';

my %handlers = (
 name  => sub { $_[0]->name($_[1]) },
 width => sub { sprintf '%0.1fpt', $_[1]->thickness($_[2]) },
);

=head2 C<tag>

=cut

sub tag { ref $_[0] }

=head2 C<covers>

=cut

sub covers { 0 }

=head2 C<declare>

=cut

sub declare {
 my ($pat, $tikz) = @_;

 my $tikz_id = $tikz->id;
 my $cache   = $pat->_cache->{$tikz_id};
 return @{$cache->[1]} if defined $cache;

 $cache = $pat->_cache->{$tikz_id} = [ ];
 $cache->[0] = 'pat' . $id++;

 my $template = [ map $_, @{$pat->template} ];
 s!#([^#]+)#!
  my ($command, @opts) = split /=/, $1, 2;
  @opts = split /,/, $opts[0] if @opts;
  $handlers{lc $command}->($pat, $tikz, @opts);
 !ge for @$template;
 $cache->[1] = $template;

 return @$template;
}

=head2 C<apply>

=cut

sub apply { 'fill', 'pattern=' . $_[0]->name($_[1]) }

LaTeX::TikZ::Interface->register(
 pattern => sub {
  my $class = shift;

  my %args = @_;
  if (exists $args{class}) {
   $class = delete $args{class};
   $class = __PACKAGE__ . '::' . $class unless $class =~ /::/;
   (my $pm = $class) =~ s{::}{/}g;
   $pm .= '.pm';
   require $pm;
  }

  $class->new(%args);
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

1; # End of LaTeX::TikZ::Mod::Pattern
