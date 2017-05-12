use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Util::BNF;

# ABSTRACT: Provides common BNF top and header contents

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Data::Section -setup;
use Exporter 'import';

our @EXPORT_OK = qw/bnf/;
our %EXPORT_TAGS = (all => \@EXPORT_OK);

my $_bnf_top    = ${__PACKAGE__->section_data('bnf_top')};
my $_bnf_bottom = ${__PACKAGE__->section_data('bnf_bottom')};

#
# Class method
#
sub bnf {
  my ($class, $bnf, $top, $bottom) = @_;
  join('', $top // $_bnf_top, $bnf, $bottom // $_bnf_bottom)
}

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Util::BNF - Provides common BNF top and header contents

=head1 VERSION

version 0.008

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
__[ bnf_top ]__
#
# latm is a sane default that can be common to all grammars
#
lexeme default = latm => 1
#
# This is more dangerous, but let's say we know what we are doing.
#
inaccessible is ok by default

__[ bnf_bottom ]__
###################################################
# Prevent Marpa saying that a lexeme is unreachable
# External BNF's are not supposed to use these
###################################################
u1_internal      ::= U1
u2_internal      ::= U2
u4_internal      ::= U4
managed_internal ::= MANAGED

########################################
#          Common lexemes              #
########################################
_U1      ~ [\s\S]
_U2      ~ _U1 _U1
_U4      ~ _U2 _U2
_MANAGED ~ [^\s\S]

U1      ~ _U1
U2      ~ _U2
U4      ~ _U4
MANAGED ~ _MANAGED
