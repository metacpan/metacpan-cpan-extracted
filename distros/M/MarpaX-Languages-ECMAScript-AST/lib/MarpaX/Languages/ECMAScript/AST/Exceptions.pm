use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::ECMAScript::AST::Exceptions;

# ABSTRACT: ECMAScript, Exceptions definition

our $VERSION = '0.020'; # VERSION

use Exception::Class (
    'MarpaX::Languages::ECMAScript::AST::Exception::InternalError' =>
        { description => 'Internal error',
          alias  => 'InternalError',},
    'MarpaX::Languages::ECMAScript::AST::Exception::SyntaxError' =>
        { description => 'Syntax error',
          alias  => 'SyntaxError'},
    ,
);

use Exporter 'import';
our @EXPORT_OK = qw/InternalError SyntaxError/;
our %EXPORT_TAGS = ('all' => [ @EXPORT_OK ]);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::ECMAScript::AST::Exceptions - ECMAScript, Exceptions definition

=head1 VERSION

version 0.020

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
