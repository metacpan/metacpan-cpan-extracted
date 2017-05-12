use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::ECMAScript::AST::Grammar::Base::DefaultSemanticsPackage;

# ABSTRACT: ECMAScript 262, Edition 5, default semantics package

our $VERSION = '0.020'; # VERSION



sub new {
    my $class = shift;
    my $self = {};
    bless($self, $class);
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::ECMAScript::AST::Grammar::Base::DefaultSemanticsPackage - ECMAScript 262, Edition 5, default semantics package

=head1 VERSION

version 0.020

=head1 DESCRIPTION

This modules give the default semantics package associated to any ECMAScript_262_5 lexical grammar.

=head2 new($class)

Instantiate a new object.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
