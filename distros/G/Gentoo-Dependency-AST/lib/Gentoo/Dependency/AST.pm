use strict;
use warnings;

package Gentoo::Dependency::AST;
BEGIN {
  $Gentoo::Dependency::AST::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::Dependency::AST::VERSION = '0.001001';
}

# ABSTRACT: Convert a canonicalized (R|P|)DEPEND into an Abstract Syntax Tree




sub _carp {
  require Carp;
  goto &Carp::carp;
}

sub parse_dep_string {
  my ( $class, $string ) = @_;
  require Gentoo::Dependency::AST::State;
  my $state           = Gentoo::Dependency::AST::State->new();
  my @tokens          = grep { defined and length } split /\s+/msx, $string;
  my $sub_skip_tokens = sub { splice @tokens, 0, $_[0], () };

  while (@tokens) {
    if ( not defined $tokens[0] ) {
      _carp('Undefined token!');
      next;
    }
    if ( defined $tokens[1] and $tokens[1] eq q[(] ) {
      if ( $tokens[0] =~ /\A!(.*)[?]\z/msx ) {
        $state->enter_notuse_group($1);
        $sub_skip_tokens->(2);
        next;
      }
      if ( $tokens[0] =~ /\A([^!].*)[?]\z/msx ) {
        $state->enter_use_group($1);
        $sub_skip_tokens->(2);
        next;
      }
      if ( $tokens[0] eq q[||] ) {
        $state->enter_or_group();
        $sub_skip_tokens->(2);
        next;
      }
    }
    if ( $tokens[0] eq q[(] ) {
      $state->enter_and_group($1);
      $sub_skip_tokens->(1);
      next;
    }
    if ( $tokens[0] eq q[)] ) {
      $state->exit_group($1);
      $sub_skip_tokens->(1);
      next;
    }
    $state->add_dep( $tokens[0] );
    $sub_skip_tokens->(1);
  }
  if ( not $state->state->isa('Gentoo::Dependency::AST::Node::TopLevel') ) {
    _carp(q[Parse was inbalanced]);
  }
  return $state->state;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Gentoo::Dependency::AST - Convert a canonicalized (R|P|)DEPEND into an Abstract Syntax Tree

=head1 VERSION

version 0.001001

=head1 SYNOPSIS

Those familiar with Gentoo's C<ebuild> format will be aware there are several variables that contain strings
of dependencies that are required.

Namely: C<PDEPEND> , C<RDEPEND> and C<DEPEND>

If you're a C<paludis> user, one can get the canonicalized versions of these variables via

    cave show -c =cat/pkg-version

This module exists to parse those strings and provide a structured graph representing the dependencies:

    use Gentoo::Dependency::AST;

    my $node = Gentoo::Dependency::AST->parse_dep_string( $string_from_portage );

=head1 METHODS

=head2 C<parse_dep_string>

    $class->parse_dep_string( $string )  # returns Gentoo::Dependency::AST::Node of some kind

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Gentoo::Dependency::AST",
    "interface":"single_class"
}


=end MetaPOD::JSON

=head1 SUPPORTED FEATURES

=head2 C<use?>

    useflag? (
        children
    )

Maps to a L<< C<::Node::Group::Use>|Gentoo::Dependency::AST::Node::Group::Use >>

=head2 C<!use?>

    !useflag? (
        children
    )

Maps to a L<< C<::Node::Group::NotUse>|Gentoo::Dependency::AST::Node::Group::NotUse >>

=head2 C<|| ()>

    || (
        children
    )

Maps to L<< C<::Node::Group::Or>|Gentoo::Dependency::AST::Node::Group::Or >>

=head2 C<()>

    (
        children
    )

Maps to L<< C<::Node::Group::And>|Gentoo::Dependency::AST::Node::Group::And >>

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
