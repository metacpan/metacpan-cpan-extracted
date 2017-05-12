
use strict;
use warnings;

package Gentoo::Dependency::AST::Node::Group::Use;
BEGIN {
  $Gentoo::Dependency::AST::Node::Group::Use::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::Dependency::AST::Node::Group::Use::VERSION = '0.001001';
}

# ABSTRACT: A group of dependencies that require a C<useflag> to be required

use parent 'Gentoo::Dependency::AST::Node';


use Class::Tiny qw( useflag );


sub _croak {
  require Carp;
  goto &Carp::croak;
}


sub BUILD {
  my ( $self, $args ) = @_;
  return _croak(q[useflag not defined]) if not defined $self->useflag;
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Gentoo::Dependency::AST::Node::Group::Use - A group of dependencies that require a C<useflag> to be required

=head1 VERSION

version 0.001001

=head1 METHODS

=head2 C<BUILD>

Ensures that C<useflag> is provided.

=head1 ATTRIBUTES

=head2 C<useflag>

B<Required.>

The literal flag that is required enabled to trigger this group.

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Gentoo::Dependency::AST::Node::Group::Use",
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
