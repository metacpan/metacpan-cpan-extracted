use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::SQL2003::AST::Actions::XML;
use parent 'MarpaX::Languages::SQL2003::AST::Actions';
use SUPER;
use XML::LibXML;
use Scalar::Util qw/blessed/;

# ABSTRACT: Translate SQL-2003 source to an AST - XML semantic actions

our $VERSION = '0.005'; # VERSION


sub new {
    my $class = shift;
    my $self = {
      dom => XML::LibXML::Document->new("1.0", "UTF-8"),
    };
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

  my $node = XML::LibXML::Element->new($lhs);

  foreach (0..$#_) {
    my $index = $_;
    my $child;
    if (! blessed($_[$index])) {
      #
      # This is a lexeme
      # We want to make sure that all data has the UTF8 flag on
      #
      foreach (0..$#{$_[$index]}) {
        utf8::upgrade($_[$index]->[$_]);
      }
      $child = XML::LibXML::Element->new($rhs[$index]);
      $child->setAttribute('start',  $_[$index]->[0]);
      $child->setAttribute('length', $_[$index]->[1]);
      $child->setAttribute('text',   $_[$index]->[2]);
      $child->setAttribute('value',  $_[$index]->[3]);
      my $i = 4;
      while ($#{$_[$index]} >= $i) {
        $child->setAttribute($_[$index]->[$i], $_[$index]->[$i+1]);
        $i += 2;
      }
    } else {
      $child = $_[$index];
    }
    $node->addChild($child);
  }

  my $rc;

  if ($lhs eq 'SQL_Start_Sequence') {
    $self->{dom}->setDocumentElement($node);
    $rc = $self->{dom};
  } else {
    $rc = $node;
  }

  return $rc;
}

# ----------------------------------------------------------------------------------------

sub _lexemeValue {
  my ($self, $node) = @_;

  my $rc = defined($node) ? $node->getAttribute('value') : undef;

  return $rc;
}

# ----------------------------------------------------------------------------------------

sub _lexemeStart {
  my ($self, $node) = @_;

  my $rc = defined($node) ? $node->getAttribute('start') : undef;

  return $rc;
}

# ----------------------------------------------------------------------------------------

sub _lexemeLength {
  my ($self, $node) = @_;

  my $rc = defined($node) ? $node->getAttribute('length') : undef;

  return $rc;
}

# ----------------------------------------------------------------------------------------

sub _childByIndex {
  my ($self, $node, $index) = @_;

  my $child = undef;

  if (defined($node)) {
    my $i = -1;
    $child = $node->firstChild();
    while (++$i < $index) {
      $child = $child->nextSibling();
    }
  }

  return $child;
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

MarpaX::Languages::SQL2003::AST::Actions::XML - Translate SQL-2003 source to an AST - XML semantic actions

=head1 VERSION

version 0.005

=head1 DESCRIPTION

This modules give the XML semantic actions associated to SQL-2003 grammar.

A non-terminal is an XML element with no attribute, element's name is the non-terminal symbol.

A terminal is an XML element with at least four attributes:

=over

=item start

Attribute's value is the start position in the input stream.

=item length

Attribute's value is the length of the terminal in the input stream.

=item text

Attribute's value is the terminal text.

=item value

Attribute's value is the terminal value.

=back

and optionaly other attributes, e.g. for character string literals, you'll might have:

=over

=item introducer

Attribute's value is the string introducer, e.g. "_utf8".

=back

=head1 SUBROUTINES/METHODS

=head2 new($class)

Instantiate a new object of the class $class.

=head1 SEE ALSO

L<MarpaX::Languages::SQL2003::AST::Actions>, L<XML::LibXML>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
