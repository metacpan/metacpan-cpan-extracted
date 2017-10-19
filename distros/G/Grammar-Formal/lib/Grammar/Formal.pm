#####################################################################
# Base package for operators
#####################################################################
package Grammar::Formal::Pattern;
use Modern::Perl;
use Moose;
use MooseX::SetOnce;

has 'parent' => (
  is => 'ro',
  required => 0,
  isa => 'Maybe[Grammar::Formal::Pattern]',
  writer => '_set_parent',
  traits => [qw/SetOnce/],
  weak_ref => 1,
);

has 'user_data' => (
  is => 'rw',
  required => 0,
);

has 'position' => (
  is => 'ro',
  isa => 'Maybe[Int]',
  required => 0,
);

sub owner_grammar {
  my ($self) = @_;

  for (my $p = $self->parent; $p; $p = $p->parent) {
    next unless $p->isa('Grammar::Formal::Grammar');
    return $p;
  }

  die "Called owner_grammar on orphan pattern";
}

#####################################################################
# Base package for unary operators
#####################################################################
package Grammar::Formal::Unary;
use Modern::Perl;
use Moose;

extends 'Grammar::Formal::Pattern';

has 'p' => (
  is       => 'ro',
  required => 1,
  isa      => 'Grammar::Formal::Pattern'
);

sub BUILD {
  my $self = shift;
  $self->p->_set_parent($self);
}

#####################################################################
# Base package for binary operators
#####################################################################
package Grammar::Formal::Binary;
use Modern::Perl;
use Moose;

extends 'Grammar::Formal::Pattern';

has 'p1' => (
  is       => 'ro',
  required => 1,
  isa      => 'Grammar::Formal::Pattern'
);

has 'p2' => (
  is       => 'ro',
  required => 1,
  isa      => 'Grammar::Formal::Pattern'
);

sub BUILD {
  my $self = shift;
  $self->p1->_set_parent($self);
  $self->p2->_set_parent($self);
}

#####################################################################
# Group
#####################################################################
package Grammar::Formal::Group;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Binary';

#####################################################################
# Choice
#####################################################################
package Grammar::Formal::Choice;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Binary';

#####################################################################
# OrderedChoice
#####################################################################
package Grammar::Formal::OrderedChoice;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Binary';

#####################################################################
# Conjunction
#####################################################################
package Grammar::Formal::Conjunction;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Binary';

#####################################################################
# OrderedConjunction
#####################################################################
package Grammar::Formal::OrderedConjunction;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Binary';

#####################################################################
# Subtraction
#####################################################################
package Grammar::Formal::Subtraction;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Binary';

#####################################################################
# Empty
#####################################################################
package Grammar::Formal::Empty;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Pattern';

#####################################################################
# NotAllowed
#####################################################################
package Grammar::Formal::NotAllowed;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Pattern';

#####################################################################
# ZeroOrMore
#####################################################################
package Grammar::Formal::ZeroOrMore;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Unary';

#####################################################################
# OneOrMore
#####################################################################
package Grammar::Formal::OneOrMore;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Unary';

#####################################################################
# SomeOrMore
#####################################################################
package Grammar::Formal::SomeOrMore;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Unary';

has 'min' => (
  is       => 'ro',
  required => 1,
  isa      => 'Int'
);

#####################################################################
# BoundedRepetition
#####################################################################
package Grammar::Formal::BoundedRepetition;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Unary';

has 'min' => (
  is       => 'ro',
  required => 1,
  isa      => 'Int'
);

has 'max' => (
  is       => 'ro',
  required => 1,
  isa      => 'Int'
);

#####################################################################
# Reference
#####################################################################
package Grammar::Formal::Reference;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Pattern';

has 'name'  => (
  is       => 'ro',
  required => 1,
  isa      => 'Str'
);

sub expand {
  my ($self) = @_;

  my $p = $self->owner_grammar;

  return $p->rules->{$self->name}
    if $p->rules->{$self->name};

  warn "rule expansion for " . $self->name . " failed.";

  return;
}

#####################################################################
# Rule
#####################################################################
package Grammar::Formal::Rule;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Unary';

has 'name'  => (
  is       => 'ro',
  required => 1,
  isa      => 'Str'
);

#####################################################################
# Grammar
#####################################################################
package Grammar::Formal::Grammar;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Pattern';

has 'start'  => (
  is       => 'ro',
  required => 0,
  isa      => 'Maybe[Str]',
);

has 'rules' => (
  is       => 'ro',
  required => 1,
  isa      => 'HashRef[Grammar::Formal::Rule]',
  default  => sub { {} },
);

# TODO: lock the rules hashref against external access?

sub set_rule {
  my ($self, $name, $value) = @_;
  $self->rules->{$name} = $value;
  $value->_set_parent($self);
}

# TODO: validate that rules include start symbol?

#####################################################################
# Factory methods
#####################################################################

# FIXME(bh): better alternative for this?

sub NotAllowed {
  my ($self, @o) = @_;
  Grammar::Formal::NotAllowed->new(@o);
}

sub Empty {
  my ($self, @o) = @_;
  Grammar::Formal::Empty->new(@o);
}

sub Choice {
  my ($self, $p1, $p2, @o) = @_;
  Grammar::Formal::Choice->new(p1 => $p1, p2 => $p2, @o);
}

sub Group {
  my ($self, $p1, $p2, @o) = @_;
  Grammar::Formal::Group->new(p1 => $p1, p2 => $p2, @o);
}

sub Optional {
  my ($self, $p, @o) = @_;
  $self->Choice($self->Empty, $p, @o);
}

sub OneOrMore {
  my ($self, $p, @o) = @_;
  Grammar::Formal::OneOrMore->new(p => $p, @o);
}

sub ZeroOrMore {
  my ($self, $p, @o) = @_;
  Grammar::Formal::ZeroOrMore->new(p => $p, @o);
}

#####################################################################
# CaseSensitiveString
#####################################################################
package Grammar::Formal::CaseSensitiveString;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Pattern';

has 'value'  => (
  is       => 'ro',
  required => 1,
  isa      => 'Str'
);

#####################################################################
# ASCII-Insensitive string
#####################################################################
package Grammar::Formal::AsciiInsensitiveString;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Pattern';

has 'value'  => (
  is       => 'ro',
  required => 1,
  isa      => 'Str'
);

#####################################################################
# prose values
#####################################################################
package Grammar::Formal::ProseValue;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Pattern';

has 'value'  => (
  is       => 'ro',
  required => 1,
  isa      => 'Str'
);

#####################################################################
# Range
#####################################################################
package Grammar::Formal::Range;
use Modern::Perl;
use Moose;
extends 'Grammar::Formal::Pattern';

has 'min'  => (
  is       => 'ro',
  required => 1,
  isa      => 'Int'
);

has 'max'  => (
  is       => 'ro',
  required => 1,
  isa      => 'Int'
);

# TODO: add check min <= max

#####################################################################
# Character class
#####################################################################
package Grammar::Formal::CharClass;
use Modern::Perl;
use Set::IntSpan;
use Moose;
extends 'Grammar::Formal::Pattern';

has 'spans'  => (
  is       => 'ro',
  required => 1,
  isa      => 'Set::IntSpan'
);

sub from_numbers {
  my ($class, @numbers) = @_;
  my $spans = Set::IntSpan->new([@numbers]);
  return $class->new(spans => $spans);
}

sub from_numbers_pos {
  my ($class, $pos, @numbers) = @_;
  my $spans = Set::IntSpan->new([@numbers]);
  return $class->new(spans => $spans, position => $pos);
}

#####################################################################
# Grammar::Formal
#####################################################################
package Grammar::Formal;
use 5.012000;
use Modern::Perl;
use Moose;

extends 'Grammar::Formal::Grammar';

our $VERSION = '0.20';

1;


__END__

=head1 NAME

Grammar::Formal - Object model to represent formal BNF-like grammars

=head1 SYNOPSIS

  use Grammar::Formal;

  my $g = Grammar::Formal->new;

  my $s1 = Grammar::Formal::CaseSensitiveString->new(value => "a");
  my $s2 = Grammar::Formal::CaseSensitiveString->new(value => "b");
  my $choice = Grammar::Formal::Choice->new(p1 => $s1, p2 => $s2);

  $g->set_rule("a-or-b" => $choice);

=head1 DESCRIPTION

This module provides packages that can be used to model formal grammars
with production rules for non-terminals and terminals with arbitrary
operators and operands. The idea is to have a common baseline format to
avoid transformations between object models. Currently it has enough
features to model IETF ABNF grammars without loss of information (minor
details like certain syntax choices notwithstanding). All packages use
L<Moose>.

=head1 API

  Grammar::Formal::Pattern 
    # Base package for all operators and operands
    has rw user_data # Simple extension point
    has ro parent    # parent node if any

    + Grammar::Formal::Binary
      # Base package for operators with 2 children

      has ro p1 # first child
      has ro p2 # second child

      + Grammar::Formal::Group  # concatenation
      + Grammar::Formal::Choice # alternatives
      + Grammar::Formal::OrderedChoice # ... with preference

    + Grammar::Formal::Unary
      # Base package for operators with 1 child

      has ro p # the child pattern

      + Grammar::Formal::ZeroOrMore # zero or more
      + Grammar::Formal::OneOrMore  # one or more
      + Grammar::Formal::SomeOrMore # min-bounded

        has ro min # minimum number of occurences

      + Grammar::Formal::BoundedRepetition
        # bound repetition

        has ro min # minimum number of occurences
        has ro max # maximum number of occurences

      + Grammar::Formal::Rule
        # grammar production rule

        has ro name # name of the non-terminal symbol

    + Grammar::Formal::Reference
      # Named reference to a non-terminal symbol

      has ro ref # name of the referenced non-terminal
      can expand # returns the associated ::Rule or undef

    + Grammar::Formal::Grammar
      # A grammar pattern with named rules

      has ro rules # Hash mapping rule names to ::Rules
      has ro start # optional start symbol
      can set_rule($name, $value) # set rule $name to ::Rule $rule

    + Grammar::Formal::CaseSensitiveString
      # Case-sensitive sequence of characters

      has ro value # Text string this represents

    + Grammar::Formal::AsciiInsensitiveString
      # Sequence of characters that treats [A-Z] like [a-z]

      has ro value # Text string

    + Grammar::Formal::ProseValue
      # Free form text description, as in IETF ABNF grammars

      has ro value # Prose

    + Grammar::Formal::Range
      # Range between two integers (inclusive)

      has ro min # first integer in range
      has ro max # last integer in range

    + Grammar::Formal::CharClass
      # Set of integers

      has ro spans            # a Set::IntSpan object
      can from_numbers(@ints) # static constructor

=head1 EXPORTS

None.

=head1 TODO

Surely there is a better way to automatically generate better POD?

=head1 AUTHOR / COPYRIGHT / LICENSE

  Copyright (c) 2014 Bjoern Hoehrmann <bjoern@hoehrmann.de>.
  This module is licensed under the same terms as Perl itself.

=cut
