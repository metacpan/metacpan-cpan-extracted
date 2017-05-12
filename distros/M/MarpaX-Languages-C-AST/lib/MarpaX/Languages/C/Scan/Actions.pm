use strict;
use warnings FATAL => 'all';

package MarpaX::Languages::C::Scan::Actions;
use XML::LibXML;
use Carp qw/croak/;

# ABSTRACT: ISO ANSI C grammar actions in Scan mode

our $VERSION = '0.47'; # VERSION


sub new {
    my $class = shift;
    my $self = {
        dom => XML::LibXML::Document->new(),
        _ruleDescription => []
    };
    bless($self, $class);
    return $self
}

sub nonTerminalSemantic {
  my $self = shift;

  my ($lhs, @rhs) = $self->getRuleDescription();
  my $maxRhs = $#rhs;

  my $node = XML::LibXML::Element->new($lhs);

  foreach (0..$#_) {
    my $child;
    if (ref($_[$_]) eq 'ARRAY') {
      #
      # This is a lexeme
      #
      my $name;
      if ($_ > $maxRhs) {
        if ($maxRhs == 0) {
          #
          # Ok only if $maxRhs is 0 : this is (probably) a sequence
          #
          $name = $rhs[0]
        } else {
          croak "Too many arguments on the stack. Rule was: $lhs ::= @rhs\n"
        }
      } else {
        $name = $rhs[$_]
      }
      $child = XML::LibXML::Element->new($name);
      $child->setAttribute('start', $_[$_]->[0]);
      $child->setAttribute('length', $_[$_]->[1]);
      $child->setAttribute('text', $_[$_]->[2])
    } else {
      $child = $_[$_]
    }
    $node->addChild($child)
  }

  if ($lhs eq 'translationUnit') {
    $self->{dom}->setDocumentElement($node);
    return $self->{dom}
  } else {
    return $node
  }
}

sub getRuleDescription {
    my $rule_id          = $Marpa::R2::Context::rule;
    my $_ruleDescription = $_[0]->{_ruleDescription};
    my $rule_desc        = $_ruleDescription->[$rule_id];
    if (! $rule_desc) {
        my $slg                       = $Marpa::R2::Context::slg;
        $_ruleDescription->[$rule_id] = $rule_desc = [ map { $slg->symbol_display_form($_) } $slg->rule_expand($rule_id) ]
  }

  return @{$rule_desc}
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::C::Scan::Actions - ISO ANSI C grammar actions in Scan mode

=head1 VERSION

version 0.47

=head1 DESCRIPTION

This modules give the actions associated to ISO_ANSI_C grammar in Scan mode.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
