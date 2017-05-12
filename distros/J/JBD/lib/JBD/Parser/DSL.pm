package JBD::Parser::DSL;
# ABSTRACT: provides an import sub that exports everything in @map
our $VERSION = '0.04'; # VERSION

# Provides an import sub that exports everything in @map.
# @author Joel Dalley
# @version 2014/Feb/23

use JBD::Core::stern;
use JBD::Core::Exporter ();

use Module::Load 'load';

# Packages and their symbols.
my @map = (
    [qw| JBD::Parser 
         parser pair type 
         cat any star trans
    |],
    [qw| JBD::Parser::Token
         token Nothing End_of_Input
    |],
    [qw| JBD::Parser::Lexer
         match tokens 
    |],
    [qw| JBD::Parser::State
         parser_state
    |],
    [qw| JBD::Parser::Lexer::Std
         Signed Unsigned Num Int Float
         Word Space Op 
    |],
    );

# @param array Arguments for load().
# @return array Symbols to export.
sub symbols(@) { load shift, @_; @_ }

# Export all symbols in @map.
sub import() {
    my $b = \&JBD::Core::Exporter::bind_to_caller;
    $b->((caller)[0], __PACKAGE__, symbols @$_) for @map;
    JBD::Core::stern->import(1);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

JBD::Parser::DSL - provides an import sub that exports everything in @map

=head1 VERSION

version 0.04

=head1 AUTHOR

Joel Dalley <joeldalley@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Joel Dalley.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
