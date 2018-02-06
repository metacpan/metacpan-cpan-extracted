use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::C::AST::Grammar::ISO_ANSI_C_2011::Scan::Actions;
use parent qw/MarpaX::Languages::C::Scan::Actions/;
use SUPER;

# ABSTRACT: ISO ANSI C 2011 grammar actions in Scan mode

our $VERSION = '0.48'; # VERSION


#
# Because Marpa is using $CODE{}
#
sub new {
  super()
}

sub nonTerminalSemantic {
  super()
}

sub getRuleDescription {
  my ($lhs, @rhs) = super();

  #
  # Remove known hiden terms that rule_expand do not remove
  #
  my @okRhs = grep {$_ ne 'structContextStart' &&
                    $_ ne 'structContextEnd' &&
                    $_ ne 'WS_MANY'} @rhs;

  return ($lhs, @okRhs)
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::C::AST::Grammar::ISO_ANSI_C_2011::Scan::Actions - ISO ANSI C 2011 grammar actions in Scan mode

=head1 VERSION

version 0.48

=head1 DESCRIPTION

This modules give the actions associated to ISO_ANSI_C_2011 grammar in Scan mode.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
