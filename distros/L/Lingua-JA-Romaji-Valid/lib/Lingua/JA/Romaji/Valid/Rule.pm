package Lingua::JA::Romaji::Valid::Rule;

use strict;
use warnings;
use Lingua::JA::Romaji::Valid::Filter::Word;
use Lingua::JA::Romaji::Valid::Filter::Kana;

my $Verbose;

sub new {
  my $class = shift;
  my $self = bless {}, $class;

  my %valid = ( a => 1, e => 1, i => 1, o => 1, u => 1, n => 1 );
  foreach my $c ( $self->valid_consonants ) {
    if ( length $c == 2 or $c eq 'j' or $c eq 'y' ) {
      foreach my $v ( qw( a o u ) ) {
        $valid{ "$c$v" } = 1;
      }
    }
    else {
      foreach my $v ( qw( a e i o u ) ) {
        $valid{ "$c$v" } = 1;
      }
    }
  }
  foreach my $item ( $self->should_delete ) {
    delete $valid{$item};
  }
  foreach my $item ( $self->should_add ) {
    $valid{$item} = 1;
  }

  $self->{valid} = \%valid;

  $self->{filters} = {
    word => Lingua::JA::Romaji::Valid::Filter::Word->new,
    kana => Lingua::JA::Romaji::Valid::Filter::Kana->new,
  };

  $self;
}

sub valid_consonants { shift->_value( valid_consonants => @_ ) }
sub should_delete    { shift->_value( should_delete    => @_ ) }
sub should_add       { shift->_value( should_add       => @_ ) }
sub filters          { shift->_value( filters          => @_ ) }

sub _value {
  my ($self, $name, @data)  = @_;
  my $class = ref $self || $self;

  no strict 'refs';
  if ( @data ) {
    @{ "$class\::$name" } = @data;
  }
  @{ "$class\::$name" };
}

sub _prepare {
  my ($self, $word_ref, @extra_filters) = @_;

  foreach my $filter ( $self->filters, @extra_filters ) {
    next unless $self->{filters}->{word}->can( $filter );
    unless ( $self->{filters}->{word}->$filter( $word_ref ) ) {
      warn "$filter returned false" if $Verbose;
      return;
    }
  }
  return 1;
}

sub is_valid {
  my ($self, $kana, @extra_filters) = @_;

  foreach my $filter ( $self->filters, @extra_filters ) {
    next unless $self->{filters}->{kana}->can( $filter );
    unless ( $self->{filters}->{kana}->$filter( \$kana ) ) {
      warn "$filter returned false" if $Verbose;
      return;
    }
  }

  my $ret = exists $self->{valid}->{$kana} ? 1 : 0;
  unless ( $ret ) {
    warn "$kana is not valid" if $Verbose;
  }
  return $ret;
}

sub verbose { shift; @_ ? $Verbose = shift : $Verbose }

1;

__END__

=head1 NAME

Lingua::JA::Romaji::Valid::Rule

=head1 SYNOPSIS

  package Lingua::JA::Romaji::Valid::Something
  use base qw( Lingua::JA::Romaji::Valid::Rule );

  my $rule = Lingua::JA::Romaji::Valid::Something->new;
  $rule->is_valid('ka');

=head1 DESCRIPTION

Base class for various rules of romanization.

=head1 METHOD

=head2 new

creates an object to provide rules for the validator.

=head2 is_valid

returns if the kana (first argument) is valid or not.

=head2 valid_consonants

sets and returns the valid consonants for the rule.
Valid kana expressions are prepared with these consonants.

=head2 should_delete

sets and returns exceptional invalid kana expressions for
the rule.

=head2 should_add

sets and returns additional valid kana expressions for
the rule.

=head2 filters

sets and returns filters for the rule.

=head2 verbose

if set to true, the validator spits warnings when it encounters
broken or banned kana expressions.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
