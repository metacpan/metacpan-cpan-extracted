use strict;
use warnings;

package Gentoo::Dependency::AST::Node::Group::And;
BEGIN {
  $Gentoo::Dependency::AST::Node::Group::And::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::Dependency::AST::Node::Group::And::VERSION = '0.001001';
}

# ABSTRACT: A Group of dependencies of which, all are required


use parent 'Gentoo::Dependency::AST::Node';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Gentoo::Dependency::AST::Node::Group::And - A Group of dependencies of which, all are required

=head1 VERSION

version 0.001001

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Gentoo::Dependency::AST::Node::Group::And",
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
