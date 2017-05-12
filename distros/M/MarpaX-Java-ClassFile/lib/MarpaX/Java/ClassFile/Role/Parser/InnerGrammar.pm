use strict;
use warnings FATAL => 'all';

package MarpaX::Java::ClassFile::Role::Parser::InnerGrammar;

# ABSTRACT: Parsing engine role for .class file parsing - inner grammar

our $VERSION = '0.008'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

use Moo::Role;

use MarpaX::Java::ClassFile::Util::ProductionMode qw/prod_isa/;
use Types::Common::Numeric qw/PositiveOrZeroInt/;
use Types::Standard qw/Int ArrayRef/;
#
# size have this meaning:
#   0 none    output will always be []
# < 0 unknown (then caller should set max)
# > 0 fixed
#
has size  => ( is => 'ro',  prod_isa(Int), default => sub {  0 } );

with qw/MarpaX::Java::ClassFile::Role::Parser/;

# ------------------
# Role modifications
# ------------------
sub nbDone { $MarpaX::Java::ClassFile::Role::Parser::InnerGrammar::nbDone }
sub inc_nbDone { $MarpaX::Java::ClassFile::Role::Parser::InnerGrammar::nbDone++ }

around ast => sub {
  my ($orig, $self) = @_;

  local $MarpaX::Java::ClassFile::Role::Parser::InnerGrammar::nbDone = 0;
  (($self->size > 0) || (($self->size < 0) && ($self->max > $self->pos))) ? $self->$orig : []
};

around manageEvents => sub {
  my ($orig, $self) = @_;

  $self->$orig;
  $self->_set_max($self->pos) if (($self->size > 0) && ($MarpaX::Java::ClassFile::Role::Parser::InnerGrammar::nbDone >= $self->size))
};

around whoami => sub {
  my ($orig, $self, @args) = @_;

  my $whoami = $self->$orig(@args);
  my $size   = $self->size;
  my $i      = $MarpaX::Java::ClassFile::Role::Parser::InnerGrammar::nbDone // 0;

  ++$i if ($i < $size);
  "${whoami}[${i}/${size}]"
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Java::ClassFile::Role::Parser::InnerGrammar - Parsing engine role for .class file parsing - inner grammar

=head1 VERSION

version 0.008

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
