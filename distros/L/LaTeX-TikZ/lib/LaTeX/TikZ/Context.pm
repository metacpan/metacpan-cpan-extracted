package LaTeX::TikZ::Context;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Context - An object modeling in which context a set is evaluated.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

use LaTeX::TikZ::Mod (); # Required to work around a bug in Mouse

use LaTeX::TikZ::Tools;

use Mouse;

=head1 ATTRIBUTES

=head2 C<parent>

The parent context of the current one, or C<undef> for the topmost context.

=cut

has 'parent' => (
 is       => 'ro',
 isa      => 'Maybe[LaTeX::TikZ::Context]',
 required => 0,
 default  => undef,
);

=head2 C<mods>

The list of mods that are asked to be applied in this context.

=cut

has '_mods' => (
 is       => 'ro',
 isa      => 'ArrayRef[LaTeX::TikZ::Mod]',
 required => 0,
 default  => sub { [ ] },
 init_arg => 'mods',
);

sub mods { @{$_[0]->_mods} }

has '_applied_mods' => (
 is       => 'ro',
 isa      => 'HashRef[LaTeX::TikZ::Mod]',
 required => 0,
 default  => sub { { } },
 init_arg => undef,
);

=head2 C<effective_mods>

The list of mods that actually need to be applied in this context.

=cut

has '_effective_mods' => (
 is       => 'ro',
 isa      => 'ArrayRef[LaTeX::TikZ::Mod]',
 required => 0,
 default  => sub { [ ] },
 init_arg => undef,
);

sub effective_mods { @{$_[0]->_effective_mods} }

has '_last_mod' => (
 is       => 'rw',
 isa      => 'Int',
 required => 0,
 default  => 0,
 init_arg => undef,
);

my $ltml_tc = LaTeX::TikZ::Tools::type_constraint('LaTeX::TikZ::Mod::Layer');

sub BUILD {
 my $cxt  = shift;
 my $pcxt = $cxt->parent;

 my $applied_mods = $cxt->_applied_mods;
 for (my $c = $pcxt; defined $c; $c = $c->parent) {
  my $mods = $c->_applied_mods;
  while (my ($tag, $mods_info) = each %$mods) {
   unshift @{$applied_mods->{$tag}}, @$mods_info;
  }
 }

 my $last_mod       = defined $pcxt ? $pcxt->_last_mod : 0;
 my $effective_mods = $cxt->_effective_mods;

 my $last_layer;

MOD:
 for my $mod ($cxt->mods) {
  my $is_layer = $ltml_tc->check($mod);
  $last_layer  = $mod if $is_layer;

  my $tag = $mod->tag;
  my $old = $applied_mods->{$tag} || [];
  for (@$old) {
   next MOD if $_->[0]->covers($mod);
  }

  push @{$applied_mods->{$tag}}, [ $mod, $last_mod++, $is_layer ];
  push @$effective_mods, $mod;
 }

 if ($last_layer) {
  # Clips and mods don't propagate through layers. Hence, if a layer is set,
  # we should force their reuse.
  @$effective_mods = $last_layer;
  push @$effective_mods, map $_->[0],
                          sort { $a->[1] <=> $b->[1] }
                           grep !$_->[2],
                            map @$_,
                             values %$applied_mods;
 }

 $cxt->_last_mod($last_mod);
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

1; # End of LaTeX::TikZ::Context
