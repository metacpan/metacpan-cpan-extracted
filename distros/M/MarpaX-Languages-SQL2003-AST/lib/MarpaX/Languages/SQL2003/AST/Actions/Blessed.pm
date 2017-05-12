use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::SQL2003::AST::Actions::Blessed;
use parent 'MarpaX::Languages::SQL2003::AST::Actions';
use SUPER;
use Scalar::Util qw/blessed/;

# ABSTRACT: Translate SQL-2003 source to an AST - Blessed semantic actions

our $VERSION = '0.005'; # VERSION


sub new {
    my $class = shift;
    my $self = {};
    bless($self, $class);
    return $self;
}

# ----------------------------------------------------------------------------------------

sub _nonTerminalSemantic {
  my $self = shift;

  my ($lhs, @rhs) = $self->_getRuleDescription();
  my $maxRhs = $#rhs;

  $lhs =~ s/^<//;
  $lhs =~ s/>$//;

  my @array = ();

  foreach (0..$#_) {
    my $child;
    my $index = $_;
    if (! blessed($_[$index])) {
      #
      # This is a lexeme
      #
      my $raw = {start => $_[$index]->[0], length => $_[$index]->[1], text => $_[$index]->[2], value => $_[$index]->[3]};
      my $i = 4;
      while ($#{$_[$index]} >= $i) {
        $raw->{$_[$index]->[$i]} = $_[$index]->[$i+1];
        $i += 2;
      }
      $child = bless($raw, $rhs[$index]);
    } else {
      $child = $_[$index];
    }
    push(@array, $child);
  }

  return bless(\@array, $lhs);
}

# ----------------------------------------------------------------------------------------

sub _lexemeValue {
  my ($self, $node) = @_;

  my $rc = defined($node) ? $node->[2] : undef;

  return $rc;
}

# ----------------------------------------------------------------------------------------

sub _lexemeStart {
  my ($self, $node) = @_;

  my $rc = defined($node) ? $node->[0] : undef;

  return $rc;
}

# ----------------------------------------------------------------------------------------

sub _lexemeLength {
  my ($self, $node) = @_;

  my $rc = defined($node) ? $node->[1] : undef;

  return $rc;
}

# ----------------------------------------------------------------------------------------

sub _childByIndex {
  my ($self, $node, $index) = @_;

  my $rc = defined($node) ? (($index <= $#{$node}) ? $node->[$index] : undef) : undef;

  return $rc;
}

# ----------------------------------------------------------------------------------------

sub _unicodeDelimitedIdentifier { super(); }

# ----------------------------------------------------------------------------------------

sub _unicodeDelimitedIdentifierUescape { super(); }

# ----------------------------------------------------------------------------------------

sub _nationalCharacterStringLiteral { super(); }

# ----------------------------------------------------------------------------------------

sub _characterStringLiteral { super(); }

# ----------------------------------------------------------------------------------------

sub _unsignedNumericLiteral { super(); }

# ----------------------------------------------------------------------------------------


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::SQL2003::AST::Actions::Blessed - Translate SQL-2003 source to an AST - Blessed semantic actions

=head1 VERSION

version 0.005

=head1 DESCRIPTION

This modules give the blessed semantic actions associated to SQL-2003 grammar.

A non-terminal is a blessed array reference, blessed name is the non-terminal symbol. Each array item is also a blessed array reference.

A terminal is a blessed hash reference, blessed name is the terminal symbol. The referenced array contain no blessed item, and there are at least four of them: start, length, text, value;

=over

=item start

Start position in the input stream.

=item length

Length of the terminal in the input stream.

=item text

Terminal text.

=item value

Terminal value.

=back

optionaly followed by pairs of (key, value), e.g. for character string literals, you'll might have:

=over

=item introducer

This really is the string 'introducer'

=item _utf8

This really is the string '_utf8', which is the introducer's value.

=back

=head1 SUBROUTINES/METHODS

=head2 new($class)

Instantiate a new object of the class $class.

=head1 SEE ALSO

L<MarpaX::Languages::SQL2003::AST::Actions>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
