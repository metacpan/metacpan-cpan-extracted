
use strict;
use warnings;

package Gentoo::Dependency::AST::Node::Dependency;
BEGIN {
  $Gentoo::Dependency::AST::Node::Dependency::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::Dependency::AST::Node::Dependency::VERSION = '0.001001';
}

# ABSTRACT: A single C<Gentoo> dependency atom


use parent 'Gentoo::Dependency::AST::Node';

use Class::Tiny qw( depstring );


sub _croak {
  require Carp;
  goto &Carp::croak;
}


sub BUILD {
  my ( $self, $args ) = @_;
  return _croak(q[<depstring> not defined])   if not defined $self->depstring;
  return _croak(q[<depstring> has no length]) if not length $self->depstring;
  return;
}

sub add_dep {
  return _croak(q[Dependencies cannot have children]);
}

sub enter_notuse_group {
  return _croak(q[Dependencies cannot have 'use' child components]);
}

sub enter_use_group {
  return _croak(q[Dependencies cannot have 'use' child components]);
}

sub enter_or_group {
  return _croak(q[Dependencies cannot have 'or' child components]);
}

sub enter_and_group {
  return _croak(q[Dependencies cannot have 'and' child components]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Gentoo::Dependency::AST::Node::Dependency - A single C<Gentoo> dependency atom

=head1 VERSION

version 0.001001

=head1 METHODS

=head2 C<BUILD>

=head1 ATTRIBUTES

=head2 C<depstring>

B<Required.>

Should be a Gentoo dependency atom, e.g:

    dev-lang/perl
    =dev-lang/perl-5.10
    dev-lang/perl:0
    =dev-lang/perl-5.10[test]
    =dev-lang/perl-5.10[-test]
    !<dev-lang/perl-5.18.0

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Gentoo::Dependency::AST::Node::Dependency",
    "interface":"class",
    "inherits":"Gentoo::Dependency::AST::Node"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
