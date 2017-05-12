use strict;
use warnings;

package Gentoo::Dependency::AST::Node::TopLevel;
BEGIN {
  $Gentoo::Dependency::AST::Node::TopLevel::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::Dependency::AST::Node::TopLevel::VERSION = '0.001001';
}

# ABSTRACT: A C<root> node that contains all other nodes


use parent 'Gentoo::Dependency::AST::Node';

sub _croak {
  require Carp;
  goto &Carp::croak;
}

sub exit_group {
  return _croak(q[Cannot exit group at top level]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Gentoo::Dependency::AST::Node::TopLevel - A C<root> node that contains all other nodes

=head1 VERSION

version 0.001001

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Gentoo::Dependency::AST::Node::TopLevel",
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
