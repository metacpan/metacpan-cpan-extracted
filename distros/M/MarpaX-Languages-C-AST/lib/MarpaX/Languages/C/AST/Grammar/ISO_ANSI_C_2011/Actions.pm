use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::C::AST::Grammar::ISO_ANSI_C_2011::Actions;

# ABSTRACT: ISO ANSI C 2011 grammar actions

our $VERSION = '0.47'; # VERSION


sub new {
    my $class = shift;
    my $self = {};
    bless($self, $class);
    return $self;
}

sub deref {
    my $self = shift;
    return [ @{$_[0]} ];
}

sub deref_and_bless_declaration {
    my $self = shift;
    return bless $self->deref(@_), 'C::AST::declaration';
}

sub deref_and_bless_declarator {
    my $self = shift;
    return bless $self->deref(@_), 'C::AST::declarator';
}

sub deref_and_bless_compoundStatement {
    my $self = shift;
    return bless $self->deref(@_), 'C::AST::compoundStatement';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::C::AST::Grammar::ISO_ANSI_C_2011::Actions - ISO ANSI C 2011 grammar actions

=head1 VERSION

version 0.47

=head1 DESCRIPTION

This modules give the actions associated to ISO_ANSI_C_2011 grammar.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
