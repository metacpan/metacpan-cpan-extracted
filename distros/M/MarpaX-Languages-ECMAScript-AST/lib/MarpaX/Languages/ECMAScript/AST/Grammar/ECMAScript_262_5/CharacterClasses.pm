use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses;
use MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses qw/:all/;

# ABSTRACT: ECMAScript-262, Edition 5, character classes

our $VERSION = '0.020'; # VERSION


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses - ECMAScript-262, Edition 5, character classes

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use strict;
    use warnings FATAL => 'all';
    use MarpaX::Languages::ECMAScript::AST::Grammar::ECMAScript_262_5::CharacterClasses;

=head1 DESCRIPTION

This modules subclasses if needed MarpaX::Languages::ECMAScript::AST::Grammar::CharacterClasses. This is not really subclassing, because class methods cannot be overwrite using SUPER - and the parse is not Moose/Mouse/Moo whatever based.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
