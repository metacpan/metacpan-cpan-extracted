package Lingua::JA::Romaji::Valid;

use strict;
use warnings;

our $VERSION = '0.03';

my %aliases = (
  loose         => 'ISO3602Loose',
  liberal       => 'Liberal',
  kunrei        => 'ISO3602',
  japanese      => 'ISO3602Strict',
  passport      => 'HepburnPassport',
  railway       => 'HepburnRailway',
  traditional   => 'Hepburn',
  hepburn       => 'HepburnRevised',
  international => 'HepburnRevisedInternational',
);

sub new {
  my ($class, $rule) = @_;
  my $self  = bless {}, $class;

  $rule ||= 'ISO3602Loose';
  $rule = $aliases{$rule} if exists $aliases{$rule};

  my $package = 'Lingua::JA::Romaji::Valid::Rule::'.$rule;
  eval "require $package"; die $@ if $@;
  $self->{rule} = $package->new;

  $self;
}

sub aliases { sort keys %aliases }
sub verbose { shift->{rule}->verbose(@_) }

sub as_romaji {
  my ($self, $word, @extra_filters) = @_;

  return unless defined $word;

  $word = quotemeta lc $word;

  return unless $self->{rule}->_prepare( \$word, @extra_filters );

  my @kanas  = $word =~ /((?:[^aeiou]*)(?:[aeioun]))/g;
  my $got    = join '', @kanas;
  my ($rest) = $word =~ /^$got(.+)/;

  if ( $rest ) {
    # always prohibit consonant ending but 'n'
    warn "consonant ending: $rest" if $self->verbose;
    return;
  }

  foreach my $kana ( @kanas ) {
    return unless $self->{rule}->is_valid( $kana, @extra_filters );
  }
  return 1;
}

sub as_name {
  my ($self, $word, @extra_filters) = @_;

  return unless defined $word;

  $word = quotemeta lc $word;

  push @extra_filters, qw(
    prohibit_initial_n
    prohibit_initial_wo
    prohibit_foreign_kanas
  );
  return unless $self->{rule}->_prepare( \$word, @extra_filters );

  my @kanas  = $word =~ /((?:[^aeiou]*)(?:[aeioun]))/g;
  my $got    = join '', @kanas;
  my ($rest) = $word =~ /^$got(.+)/;

  if ( $rest ) {
    # always prohibit consonant ending but 'n'
    warn "consonant ending: $rest" if $self->verbose;
    return;
  }

  foreach my $kana ( @kanas ) {
    return unless $self->{rule}->is_valid( $kana, @extra_filters );
  }
  return 1;
}

sub as_fullname {
  my ($self, $word, @extra_filters) = @_;

  return unless defined $word;

  $word = quotemeta lc $word;

  # XXX: allow comma separated name: should this be optional?
  my $rule = qr/(?:\\?\s)+|(?:\\?\s)*(?:\\?,)(?:\\?\s)*/;
  my @parts = split $rule, $word;

  # Japanese full name should have both first and last names
  # but not a middle name
  return unless @parts == 2;

  foreach my $part ( @parts ) {
    return unless $self->as_name( $part, @extra_filters );
  }
  return 1;
}

1;

__END__

=head1 NAME

Lingua::JA::Romaji::Valid - see if the string is valid romanization

=head1 SYNOPSIS

    use Lingua::JA::Romaji::Valid;
    my $validator = Lingua::JA::Romaji::Valid->new('liberal');

    # this is valid romanization of 'violin'
    $validator->as_romaji('vaiorin');  # true

    # but this is not valid for a (common) Japanese name
    # as we don't use 'v' for our name, at least usually.
    $validator->as_name('vaiorin');    # false

=head1 DESCRIPTION

This module tells you if the given string looks like valid 
romanization of Japanese words or not. It may be useful
when you want to pick up Japanese persons from a list of
persons from various countries.

Note that, even if this module tells you the word looks like
valid romanization, the word is not always Japanese. (Among
others, Italian nouns with lots of vowels tend to be judged
valid.)

And vice versa. Though there're several ways of romanization,
this module ignores lots of their minor rules to increase
general reliability. So sometimes even your registered name
might be judged invalid, especially if it is rather, eh,
untraditional one.

=head1 METHODS

=head2 new

creates a validator object. You can specify which rule you
want to use through an alias, or a basename of the rule
package (::Rule::<Basename>). See also 'aliases' below.

=head2 as_romaji

sees if the word is valid romanization or not.

=head2 as_name

sees if the word is valid as a name of a Japanese person.
Usually we don't use "v" or "che", to name a few.

=head2 as_fullname

sees if the word is valid as a full name of a Japanese person.
A Japanese person has both first and last names, but doesn't
have a middle name.

=head2 aliases

returns all the aliases available, i.e.:

  liberal       => Liberal
  loose         => ISO3602Loose (default)
  kunrei        => ISO3602
  japanese      => ISO3602Strict
  traditional   => Hepburn
  hepburn       => HepburnRevised
  international => HepburnRevisedInternational
  railway       => HepburnRailway
  passport      => HepburnPassport

=head2 verbose

if set to true, the validator spits warnings when it encounters
broken or banned kana expressions.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

