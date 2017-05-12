use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::IDL::AST::Data::Scan::Role::Consumer;
use Moo::Role;

# ABSTRACT: MarpaX::Languages::IDL::AST's Data::Scan Consumer

our $VERSION = '0.007'; # VERSION

# AUTHORITY

requires 'specification';

with 'Data::Scan::Role::Consumer';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::IDL::AST::Data::Scan::Role::Consumer - MarpaX::Languages::IDL::AST's Data::Scan Consumer

=head1 VERSION

version 0.007

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
