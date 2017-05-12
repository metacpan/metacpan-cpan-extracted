
use strict;
use warnings;

package Gentoo::Dependency::AST::State;
BEGIN {
  $Gentoo::Dependency::AST::State::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::Dependency::AST::State::VERSION = '0.001001';
}

# ABSTRACT: Temporal Tree State controller


use Class::Tiny {
  stack => sub {
    require Gentoo::Dependency::AST::Node::TopLevel;
    return [ Gentoo::Dependency::AST::Node::TopLevel->new() ];
  },
};


sub _croak {
  require Carp;
  goto &Carp::croak;
}


## no critic (ProhibitBuiltinHomonyms)
sub state {
  my ($self) = @_;
  if ( not defined $self->stack->[-1] ) {
    return _croak(q[Empty stack]);
  }
  return $self->stack->[-1];
}


sub _pushstack {
  my ( $self, $element ) = @_;
  push @{ $self->stack }, $element;
  return;
}


sub _popstack {
  my ($self) = @_;
  return pop @{ $self->stack };
}


sub add_dep {
  my ( $self, $depstring ) = @_;
  require Gentoo::Dependency::AST::Node::Dependency;
  $self->state->add_dep(
    $self,
    Gentoo::Dependency::AST::Node::Dependency->new(
      depstring => $depstring
    )
  );
  return;
}


sub enter_notuse_group {
  my ( $self, $useflag ) = @_;
  require Gentoo::Dependency::AST::Node::Group::NotUse;
  $self->state->enter_notuse_group(
    $self,
    Gentoo::Dependency::AST::Node::Group::NotUse->new(
      useflag => $useflag
    )
  );
  return;
}


sub enter_use_group {
  my ( $self, $useflag ) = @_;
  require Gentoo::Dependency::AST::Node::Group::Use;
  $self->state->enter_use_group( $self, Gentoo::Dependency::AST::Node::Group::Use->new( useflag => $useflag ) );
  return;
}


sub enter_or_group {
  my ($self) = @_;
  require Gentoo::Dependency::AST::Node::Group::Or;
  $self->state->enter_or_group( $self, Gentoo::Dependency::AST::Node::Group::Or->new() );
  return;
}


sub enter_and_group {
  my ($self) = @_;
  require Gentoo::Dependency::AST::Node::Group::And;
  $self->state->enter_and_group( $self, Gentoo::Dependency::AST::Node::Group::And->new() );
  return;
}


sub exit_group {
  my ($self) = @_;
  $self->state->exit_group($self);
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Gentoo::Dependency::AST::State - Temporal Tree State controller

=head1 VERSION

version 0.001001

=head1 METHODS

=head2 C<state>

Return the B<current> state object.

This is C<-1> on the C<stack> array.

    $state->state;

=head2 C<add_dep>

    $state->add_dep($depstring);

Tell B<current> state controller C<< $state->state >> that a literal dependency C<$depstring> has been seen.

    $state->add_dep("dev-lang/perl");
    → $dep_object = ::Node::Dependency->new( depstring => "dev-lang/perl");
    → $state->state->add_dep( $state , $dep_object );

=head2 C<enter_notuse_group>

    $state->enter_notuse_group($useflag)

Tell B<current> state controller C<< $state->state >> that a negative useflag(C<$useflag>) group opener has been seen.

    $state->enter_notuse_group("aqua");
    → $group_object = ::Node::Group::NotUse->new( useflag => "aqua" );
    → $state->state->enter_notuse_group( $state , $group_object );

=head2 C<enter_use_group>

    $state->enter_use_group($useflag)

Tell B<current> state controller C<< $state->state >> that a useflag(C<$useflag>) group opener has been seen.

    $state->enter_use_group("qt4");
    → $group_object = ::Node::Group::Use->new( useflag => "qt4" );
    → $state->state->enter_use_group( $state , $group_object );

=head2 C<enter_or_group>

    $state->enter_or_group()

Tell B<current> state controller C<< $state->state >> that an C<or> group opener has been seen.

    $state->enter_or_group();
    → $group_object = ::Node::Group::Or->new();
    → $state->state->enter_or_group( $state , $group_object );

=head2 C<enter_and_group>

    $state->enter_and_group()

Tell B<current> state controller C<< $state->state >> that an C<and> group opener has been seen.

    $state->enter_and_group();
    → $group_object = ::Node::Group::And->new();
    → $state->state->enter_and_group( $state , $group_object );

=head2 C<exit_group>

    $state->exit_group()

Tell B<current> state controller C<< $state->state >> that a group exit has been seen.

    $state->exit_group();
    → $state->state->exit_group();

=head1 ATTRIBUTES

=head2 C<stack>

Contains an C<ARRAYREF> of all the states.

Starts off as:

    [ Gentoo::Dependency::AST::Node::TopLevel->new() ]

=head1 PRIVATE METHODS

=head2 C<_pushstack>

Set C<$element> as the new parse state, by pushing it on to the stack.

    $state->_pushstack($element);

=head2 C<_popstack>

Remove the top element from the stack, deferring control to its parent.

    $discarded = $state->_popstack();

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Gentoo::Dependency::AST::State",
    "interface":"class",
    "inherits":"Class::Tiny::Object"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
