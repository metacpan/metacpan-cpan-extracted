package LaTeX::TikZ::Functor;

use strict;
use warnings;

=head1 NAME

LaTeX::TikZ::Functor - Build functor methods that recursively visit nodes of a LaTeX::TikZ::Set tree.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 DESCRIPTION

A functor takes a L<LaTeX::TikZ::Set> tree and returns a new, transmuted version of it according to certain rules.
It recursively visits all the nodes of the tree, building a new set out of the result of the functor on the child sets.

Rules are stored as L<LaTeX::TikZ::Functor::Rule> objects.
They can apply not only to L<LaTeX::TikZ::Set> consumer objects, but also to the L<LaTeX::TikZ::Mod> consumer objects they contain.
When the functor is called against a set object and that the returned set is different from the original (as told by C<==>, which defaults to object identity), then the functor is also applied to all the mods of the set, and their transformed counterparts are added to the new set.

When the functor is called onto a set or mod object, all its associated rules are tried successively, and the handler of the first matching rule is executed with :

=over 4

=item *

the functor object as its first argument ;

=item *

the current set or mod object as its second argument ;

=item *

the arguments passed to the functor itself starting at the third argument.

=back

The handler is expected to return the new set or mod that will replace the old one in the resulting set tree.

If no matching rule is found, the object is returned as-is.

=cut

use Carp ();

use Sub::Name ();

use LaTeX::TikZ::Functor::Rule;

use LaTeX::TikZ::Interface;

use LaTeX::TikZ::Tools;

my $lts_tc = LaTeX::TikZ::Tools::type_constraint('LaTeX::TikZ::Set');

my $validate_spec;
BEGIN {
 $validate_spec = Sub::Name::subname('validate_spec' => sub {
  my ($spec) = @_;

  my ($replace, $target);
  if (defined $spec and ref $spec eq ''
    and $spec =~ /^(\+?)([A-Za-z][A-Za-z0-9_]*(?:::[A-Za-z][A-Za-z0-9_]*)*)$/) {
   $replace = defined($1) && $1 eq '+';
   $target  = $2;
  } else {
   Carp::confess("Invalid rule spec $spec");
  }

  return $target, $replace;
 });
}

=head1 METHODS

=head2 C<new>

    my $functor = LaTeX::TikZ::Functor->new(
     rules => [ $spec1 => $handler1, $spec2 => $handler2, ... ],
    );

Creates a new functor object that will use both the default and the user-specified rules.
The functor is also a code reference that expects to be called against L<LaTeX::TikZ::Set> objects.

The default set and mod rules clone their relevant objects, so you get a clone functor (for the default set types) if you don't specify any user rule.

    # The default is a clone method
    my $clone = Tikz->functor;
    my $dup = $set->$clone;

If there is already a default rule for one of the C<$spec>s, it is replaced by the new one ; otherwise, the user rule is inserted into the list of default rules after all its descendants' rules and before all its ancestors' rules.

    # A translator
    my $translate = Tikz->functor(
     # Only replace the way point sets are cloned
     'LaTeX::TikZ::Set::Point' => sub {
      my ($functor, $set, $x, $y) = @_;

      $set->new(
       point => [
        $set->x + $x,
        $set->y + $y,
       ],
       label => $set->label,
       pos   => $set->pos,
      );
     },
    );
    my $shifted = $set->$translate(1, 1);

But if one of the C<$spec>s begins with C<'+'>, the rule will replace I<all> default rules that apply to subclasses or subroles of C<$spec> (including C<$spec> itself).

    # A mod stripper
    my $strip = Tikz->functor(
     # Replace all existent mod rules by this simple one
     '+LaTeX::TikZ::Mod' => sub { return },
    );
    my $naked = $set->$strip;

The functor will map unhandled sets and mods to themselves without cloning them, since it has no way to know how to do it.
Thus, if you define your own L<LaTeX::TikZ::Set> or L<LaTeX::TikZ::Mod> object, be sure to register a default rule for it with the L</default_rule> method.

=cut

my @default_set_rules;
my @default_mod_rules;

sub new {
 my ($class, %args) = @_;

 my @set_rules = @default_set_rules;
 my @mod_rules = @default_mod_rules;

 my @user_rules = @{$args{rules} || []};
 while (@user_rules) {
  my ($spec, $handler) = splice @user_rules, 0, 2;

  my ($target, $replace) = $validate_spec->($spec);

  my $rule = LaTeX::TikZ::Functor::Rule->new(
   target  => $target,
   handler => $handler,
  );

  $rule->insert(
   into      => $rule->is_set ? \@set_rules : \@mod_rules,
   overwrite => 1,
   replace   => $replace,
  );
 }

 my %dispatch = map { $_->target => $_ } @set_rules, @mod_rules;

 my $self;

 $self = bless sub {
  my $set = shift;

  $lts_tc->assert_valid($set);

  my $rule = $dispatch{ref($set)};
  unless ($rule) {
   for (@set_rules) {
    if ($_->handles($set)) {
     $rule = $_;
     last;
    }
   }
  }
  return $set unless $rule;

  my $new_set = $rule->handler->($self, $set, @_);
  return $set if $new_set == $set;

  my @new_mods;
MOD:
  for my $mod ($set->mods) {
   my $rule = $dispatch{ref($mod)};
   unless ($rule) {
    for (@mod_rules) {
     if ($_->handles($mod)) {
      $rule = $_;
      last;
     }
    }
   }
   push @new_mods, $rule ? $rule->handler->($self, $mod, @_)
                         : $mod;
  }
  $new_set->mod(@new_mods);

  return $new_set;
 }, $class;
}

LaTeX::TikZ::Interface->register(
 functor => sub {
  shift;

  __PACKAGE__->new(rules => \@_);
 },
);

=head2 C<default_rule>

    LaTeX::TikZ::Functor->default_rule($spec => $handler)

Adds to all subsequently created functors a default rule for the class or role C<$spec>.

An exception is thrown if there is already a default rule for C<$spec> ; otherwise, the new rule is inserted into the current list of default rules after all its descendants' rules and before all its ancestors' rules.
But if C<$spec> begins with C<'+'>, the rule will replace I<all> default rules that apply to subclasses or subroles of C<$spec> (including C<$spec> itself).

Returns true if and only if an existent rule was replaced.

=cut

sub default_rule {
 shift;
 my ($spec, $handler) = @_;

 my ($target, $replace) = $validate_spec->($spec);

 my $rule = LaTeX::TikZ::Functor::Rule->new(
  target  => $target,
  handler => $handler,
 );

 $rule->insert(
  into      => $rule->is_set ? \@default_set_rules : \@default_mod_rules,
  overwrite => 0,
  replace   => $replace,
 );
}

=head1 SEE ALSO

L<LaTeX::TikZ>, L<LaTeX::TikZ::Functor::Rule>.

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

1; # End of LaTeX::TikZ::Functor
