package Lingua::EN::Inflect::Phrase;
our $AUTHORITY = 'cpan:AVAR';
$Lingua::EN::Inflect::Phrase::VERSION = '0.20';
use strict;
use warnings;
use Exporter 'import';
use Lingua::EN::Inflect;
use Lingua::EN::Inflect::Number;
use Lingua::EN::Tagger;
use Lingua::EN::FindNumber '$number_re';
use Lingua::EN::Number::IsOrdinal 'is_ordinal';

=head1 NAME

Lingua::EN::Inflect::Phrase - Inflect short English Phrases

=cut

=head1 SYNOPSIS

  use Lingua::EN::Inflect::Phrase;
  use Test::More tests => 2;

  my $plural   = Lingua::EN::Inflect::Phrase::to_PL('green egg and ham');

  is $plural, 'green eggs and ham';

  my $singular = Lingua::EN::Inflect::Phrase::to_S('green eggs and ham');

  is $singular, 'green egg and ham';

=head1 DESCRIPTION

Attempts to pluralize or singularize short English phrases.

Does not throw exceptions at present, if you attempt to pluralize an already
pluralized phrase, it will leave it unchanged (and vice versa.)

The behavior of this module is subject to change as I tweak the heuristics, as
some things get fixed others might regress. The processing of natural language
is a messy business.

If it doesn't work, please email or submit to RT the example you tried, and
I'll try to fix it.

=head1 OPTIONS

By default, this module prefers to treat words as nouns (sometimes words can be
interpreted as a verb or a noun without context.) This is better for things
such as database table/column names, which is what this module is primarily
for.

This behavior can be switched with the variable C<$prefer_nouns>. The default
is C<1>.

For example:

  {
    local $Lingua::EN::Inflect::Phrase::prefer_nouns = 0;
    is Lingua::EN::Inflect::Phrase::to_S('sources split'), 'source splits';
  }
  {
    local $Lingua::EN::Inflect::Phrase::prefer_nouns = 1;
    is Lingua::EN::Inflect::Phrase::to_S('source splits'), 'source split';
  }

=head1 OPTIONAL EXPORTS

L</to_PL>, L</to_S>

=cut

our @EXPORT_OK = qw/to_PL to_S/;

=head1 SUBROUTINES

=cut

our $prefer_nouns = 1;

my $MAYBE_NOUN       = qr{(\S+)/(?:NN[PS]?|CD|JJ)\b};
my $MAYBE_NOUN_TAG   = qr{/(?:NN[PS]?|CD|JJ)\b};
my $NOUN_OR_VERB     = qr{(\S+)/(?:NN[PS]?|CD|JJ|VB[A-Z]?)\b};
my $NOUN_OR_VERB_TAG = qr{/(?:NN[PS]?|CD|JJ|VB[A-Z]?)\b};
my $VERB_TAG         = qr{/VB[A-z]?\b};

my $PREPOSITION_OR_CONJUNCTION_TAG = qr{/(?:CC|IN)\b};

my $tagger;

sub _inflect_noun {
  my ($noun, $want_plural, $is_plural) = @_;

  my $want_singular = not $want_plural;

  $is_plural = Lingua::EN::Inflect::Number::number($noun) ne 's'
    unless defined $is_plural;

  # fix "people" and "heroes" and a few others
  if ($noun =~ /^(?:people|person)\z/i) {
    return $want_singular ? 'person' : 'people';
  }
  elsif ($noun =~ /^hero(?:es)?\z/i) {
    return $want_singular ? 'hero' : 'heroes';
  }
  elsif ($want_singular && lc($noun) eq 'aliases') {
    return 'alias';
  }
  elsif ($want_singular && lc($noun) eq 'statuses') {
    return 'status';
  }
  elsif (lc($noun) eq 'belongs') {
    return undef;
  }
  elsif ($want_plural && lc($noun) eq 'two') {
    return 'twos';
  }
  elsif ($noun =~ /^[A-Z].+ity\z/) {
    return $want_plural ? ucfirst(Lingua::EN::Inflect::Number::to_PL(lc($noun))) : $noun;
  }
  elsif ($noun =~ /^[A-Z].+ities\z/) {
    return $want_plural ? $noun : ucfirst(Lingua::EN::Inflect::Number::to_S(lc($noun)));
  }

  if ($want_plural && (not $is_plural)) {
    return Lingua::EN::Inflect::Number::to_PL($noun);
  }
  elsif ($want_singular && $is_plural) {
    return Lingua::EN::Inflect::Number::to_S($noun);
  }

  return undef;
}

sub _inflect {
  my ($phrase, $want_plural) = @_;
  my $want_singular = not $want_plural;

# 'a' inflects to 'some', special-case it here
  if ($phrase eq 'a') {
    return $want_singular ? $phrase : 'as';
  }

# Do not tag initial number, if any.
# Regex is from perldoc -q 'is a number'.
  my ($det, $number, $pad, $rest) =
    $phrase =~ m{^(\s*\S+/DET)?(\s*(?:[+-]?)(?=\d|\.\d)\d*(?:\.\d*)?(?:[Ee](?:[+-]?\d+))?)(\s*)(.*)$};

  $_ ||= '' for $det, $pad, $rest;

  my $tagged;
  $tagger ||= Lingua::EN::Tagger->new;

  # force plural unless number is '1'
  if ((grep { defined && length } ($number, $pad, $rest)) == 3) {
    my $tagged_rest = $tagger->get_readable($rest);

    $tagged = $det . $number . $pad . $tagged_rest;

    if ($number =~ /^\s*1(?:\.0*[Ee]?0*)?\z/
        && $tagged_rest !~ m{^(?:\S+/CC|\d)}) {
      $want_plural   = 0;
      $want_singular = 1;
    }
    else {
      $want_plural   = 1;
      $want_singular = 0;
    }
  }
  else {
    $tagged = $tagger->get_readable($phrase);
  }

  # check for phrases like "one something" and force singular,
  # or "one and a half ..." and force plural
  if (my ($det, $number, $conj, $and_zero, $pad, $rest) = $tagged =~ m{
       ^ (\s* \S+/DET)?
       (\s* (?:one|single))/(?:JJ|NN|CD)\b
       (\s*\S+/CC\b)?
       (?:(\s* (?:no|zero))/(?:DET|CD))?
       (\s*)
       (.*)
     }x) {

    $_ ||= '' for $det, $conj, $and_zero, $pad, $rest;

    $tagged = $det . $number . $conj . $and_zero . $pad . $rest;

    if (length $conj && (not $and_zero)) {
      $want_plural   = 1;
      $want_singular = 0;
    }
    elsif (length $rest) {
      $want_plural   = 0;
      $want_singular = 1;
    }
  }
  # handle other numbers as words at the start of the phrase
  # using Lingua::EN::FindNumber
  elsif ($tagged =~ m{^\s*(?:(\S+)/DET)?}
         && (substr $phrase, $+[1]||0) =~ /^\s*$number_re/) {

    $number = (sort { length $a <=> length $b } map $_||'', ($1, $2, $3, $4, $5))[-1];

    if (not is_ordinal($number)) {
      my $tagged_number_re;

      foreach my $num_elem (split /\s+/, $number) {
        $tagged_number_re .= "\Q$num_elem\E/[A-Z]+\\s*";
      }

      my $tagged_number;
      ($tagged_number, $pad, $rest) = $tagged =~ m/($tagged_number_re)(\s*)(.*)/;
      my @tagged_number_pos = ($-[1], $+[1]);

      if (length $rest) {
        substr($tagged, $tagged_number_pos[0], ($tagged_number_pos[1] - $tagged_number_pos[0])) = $number;
        $want_plural   = 1;
        $want_singular = 0;
      }
    }
  }

  my ($noun, $tag);

  # last noun (or verb that could be a noun) before a preposition/conjunction
  # or last noun/verb
  if (   (($noun) = $tagged =~ m|${MAYBE_NOUN} (?! .* ${MAYBE_NOUN_TAG} .* ${PREPOSITION_OR_CONJUNCTION_TAG})
                                 .* ${PREPOSITION_OR_CONJUNCTION_TAG}|x)

      or (($noun) = $tagged =~ m|${MAYBE_NOUN} (?!.*${MAYBE_NOUN_TAG})|x)

      or (($noun) = $tagged =~ m|${NOUN_OR_VERB} (?!.*${NOUN_OR_VERB_TAG} .* ${PREPOSITION_OR_CONJUNCTION_TAG})
                                 .* ${PREPOSITION_OR_CONJUNCTION_TAG}|x)

      or (($noun) = $tagged =~ m|${NOUN_OR_VERB} (?! .* ${NOUN_OR_VERB_TAG})|x)) {

    my @pos = ($-[1], $+[1]);
    my $inflected_noun;

    $inflected_noun = _inflect_noun($noun, $want_plural);

    # check if there is a verb following the noun
    # the verb either needs to be pluarlized or be taken as the noun,
    # depending on the value of $prefer_nouns
    my ($verb) = substr($tagged, $pos[1]) =~ m|^/[A-Z]+\s+(\S+)${VERB_TAG}|;

    my @verb_pos = map $pos[1] + $_, grep defined, ($-[1], $+[1]);

    # the verb may be tagged as a noun unless singularized (pluralized as a noun.)
    if ((not $verb) && (not $prefer_nouns)
        && $tagger->get_readable(_inflect_noun($noun, 1, 0)) =~ $VERB_TAG) {

      # find the preceding noun
      if (my ($preceding_noun) = substr($tagged, 0, $pos[0]) =~ m|${MAYBE_NOUN}\s*\z|) {
        my @preceding_noun_pos = ($-[1], $+[1]);

        $verb           = $noun;
        @verb_pos       = @pos;
        $noun           = $preceding_noun;
        @pos            = @preceding_noun_pos;
        $inflected_noun = _inflect_noun($noun, $want_plural);
      }
    }

    if ($verb) {
      my $plural_verb = Lingua::EN::Inflect::PL_V($verb);

      if ($prefer_nouns) {
        if ($tagger->get_readable($plural_verb) =~ $MAYBE_NOUN
            || ( # noun singular verb plural should be handled as noun noun, unless something follows it,
                 # and only for "VB" not "VBZ" or "VBN"
              $verb eq $plural_verb
              && $tagger->get_readable(_inflect_noun($verb, 1)) =~ $MAYBE_NOUN
              && substr($tagged, $verb_pos[1]) =~ m{^\s*/VB\s*$}
            )) {
          $inflected_noun = _inflect_noun($verb, $want_plural);

          @pos = @verb_pos;
        }
      }
      elsif ($inflected_noun) {
        if ($want_plural) {
          substr($tagged, $verb_pos[0], ($verb_pos[1] - $verb_pos[0])) = $plural_verb;
        }
        elsif ($want_singular) {
          # to singularize a verb we pluralize it as a noun
          my $singular_verb = _inflect_noun($verb, 1, 0);

          substr($tagged, $verb_pos[0], ($verb_pos[1] - $verb_pos[0])) = $singular_verb;
        }
      }
    }

    substr($tagged, $pos[0], ($pos[1] - $pos[0])) = $inflected_noun if $inflected_noun;

    ($phrase = $tagged) =~ s{/[A-Z]+}{}g;
  }
# fallback
  else {
    my $number = Lingua::EN::Inflect::Number::number($phrase);

    if ($want_plural && $number ne 'p') {
      return Lingua::EN::Inflect::Number::to_PL($phrase);
    }
    elsif ($want_singular && $number ne 's') {
      return Lingua::EN::Inflect::Number::to_S($phrase);
    }
  }

  return $phrase;
}

=head2 to_PL

Attempts to pluralizes a phrase unless already plural.

=cut

sub to_PL {
  return _inflect(shift, 1);
}

=head2 to_S

Attempts to singularize a phrase unless already singular.

=cut

sub to_S {
  return _inflect(shift, 0);
}

=head1 BUGS

Please report any bugs or feature requests to C<bug-lingua-en-inflect-phrase at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-EN-Inflect-Phrase>.  I
will be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 REPOSITORY

  git clone git://github.com/rkitover/lingua-en-inflect-phrase.git lingua-en-inflect-phrase

=head1 SEE ALSO

L<Lingua::EN::Inflect>, L<Lingua::EN::Inflect::Number>, L<Lingua::EN::Tagger>

=head1 AUTHOR

rkitover: Rafael Kitover <rkitover@cpan.org>

=head1 CONTRIBUTORS

zakame: Zak B. Elep <zakame@zakame.net>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2018 Rafael Kitover (rkitover@cpan.org).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
# vim:et sts=2 sw=2 tw=0:
