
use strict;
use warnings;

package Gentoo::Dependency::AST::Node::Group::NotUse;
BEGIN {
  $Gentoo::Dependency::AST::Node::Group::NotUse::AUTHORITY = 'cpan:KENTNL';
}
{
  $Gentoo::Dependency::AST::Node::Group::NotUse::VERSION = '0.001001';
}

# ABSTRACT: A group of dependencies that require a C<useflag> disabled to trigger require


use parent 'Gentoo::Dependency::AST::Node::Group::Use';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Gentoo::Dependency::AST::Node::Group::NotUse - A group of dependencies that require a C<useflag> disabled to trigger require

=head1 VERSION

version 0.001001

=begin MetaPOD::JSON v1.1.0

{
    "namespace":"Gentoo::Dependency::AST::Node::Group::NotUse",
    "interface":"class",
    "inherits":"Gentoo::Dependency::AST::Node::Group::Use"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
