use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::IDL::AST::Data::Scan::Impl::Perl5;

# ABSTRACT: Perl5 default implementation for transpiling IDL

our $VERSION = '0.007'; # VERSION

# AUTHORITY

use Moo;
use MarpaX::Languages::IDL::AST::Data::Scan::Impl::Perl5::_BaseTypes -all;
use Scalar::Util qw/blessed reftype/;
use Types::Standard -all;
use Types::Common::Numeric -all;

use constant {
  LEXEME_START => $[,
  LEXEME_LENGTH => $[ + 1,
  LEXEME_VALUE => $[ + 2,
  SEMICOLON => ';'
};

extends 'MarpaX::Languages::IDL::AST::Data::Scan::Impl::_Default';

has output    => (is => 'rwp', isa => Str);
has main      => (is => 'rwp', isa => Str, default => sub { 'IDL' }, trigger => 1 );
has indent    => (is => 'ro',  isa => Str, default => sub { '  ' } );
has separator => (is => 'ro',  isa => Str, default => sub { ' ' } );
has newline   => (is => 'ro',  isa => Str, default => sub { "\n" } );
has _lines    => (is => 'rw',  isa => ArrayRef[ArrayRef[Str]]);

sub _trigger_main {
  my ($self, $main) = @_;
  $self->_logger->debugf('main namespace is now %s', $main);
  return
}

sub _pushLine {
  my ($self) = @_;

  push(@{$self->_lines}, $self->level ? [ $self->indent x $self->level ] : [ ]);

  return
}
after trigger_level => sub {
  my ($self) = @_;

  $self->_pushLine;
  return
};

#
# We do not want to pollute perl5's main namespace
#
around globalScope => sub {
  my ($orig, $self) = @_;

  my $globalScope = $self->$orig;

  if ($globalScope =~ /^::/) {
    $globalScope = join('', $self->main, $globalScope)
  } else {
    $globalScope = $globalScope ? join('::', $self->main, $globalScope) : $self->main
  }

  return $globalScope
};
#
# At startup initialize work area and result
#
around dsstart => sub {
  my ($orig, $self, $item) = @_;

  $self->_lines([]);
  $self->_set_output('');

  return $self->$orig($item)
};
#
# At end set result an reset work area
#
around dsend => sub {
  my ($orig, $self) = @_;

  my $separator = $self->separator;
  $self->_set_output(join($self->newline, map { join($separator, @{$_}) } @{$self->_lines}));
  $self->_lines([]);

  return $self->$orig
};
#
# At dsopen, catch the need to push a new line
#
around dsread => sub {
  my ($orig, $self, $item) = @_;
  #
  # We identify a token like this:
  # this is a blessed array containing only scalars
  # [ start, length, value ]
  #
  my $blessed = blessed($item) // '';
  $blessed =~ s/.*:://;
  my $reftype = reftype($item) // '';
  my $isLexeme = $blessed && $reftype eq 'ARRAY' && scalar(@{$item}) == 3 && ! grep { ref } @{$item};
  #
  # Derive using blessed information
  #
  # ------------------------------------
  if ($blessed eq 'CPPSTYLEDIRECTIVE') {
    # ----------------------------------
    my $token = $item->[LEXEME_VALUE];
    #
    # We support only the #pragma prefix
    #
    if ($token =~ /#pragma\s+prefix\s"([^"]+)\"/) {
      my $pragma = substr($token, $-[1], $+[1] - $-[1]);
      my $newPragma = $pragma;
      $newPragma =~ s/\./::/g;
      $self->_set_main($self->main . '::' . $newPragma);
    } else {
      $self->_logger->infof('Ignored: %s', $token)
    }
  }
  # --------------------------
  if ($blessed eq 'TYPEDEF') {
    # ------------------------
  }
  if ($isLexeme) {
    my $token = $item->[LEXEME_VALUE];
    push(@{$self->_lines->[-1]}, $token);
    #
    # We want to force a newline if semicolon or CPP directive
    #
    if ($token eq SEMICOLON || $blessed eq 'CPPSTYLEDIRECTIVE') {
      $self->_pushLine
    }
  }

  return $self->$orig($item)
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::IDL::AST::Data::Scan::Impl::Perl5 - Perl5 default implementation for transpiling IDL

=head1 VERSION

version 0.007

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
