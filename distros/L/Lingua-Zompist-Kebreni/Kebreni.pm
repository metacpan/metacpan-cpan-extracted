package Lingua::Zompist::Kebreni;

require 5.005;
use strict;
# use warnings;
$^W = 1;
use Carp;

require Exporter;

use vars qw($VERSION @ISA @EXPORT_OK @EXPORT %EXPORT_TAGS);

$VERSION = '0.90';

@ISA = qw(Exporter);

use overload '""' => 'to_string',
             'eq' => sub { $_[0]->to_string eq $_[1] }
             ;

use constant BENEFACTIVE => 00001;
use constant ANTIBEN     => 00002;
use constant VOLITIONAL  => 00004;
use constant PERFECTIVE  => 00010;
use constant DIR2        => 00020;
use constant POLITE      => 00040;
use constant SUBORDINATE => 00100;
use constant SUPPLETIVE  => 00200;
use constant MADE_POLITE => 00400;

%EXPORT_TAGS = ( 'flags' => [ qw(
  &BENEFACTIVE
  &ANTIBEN
  &VOLITIONAL
  &PERFECTIVE
  &DIR3
  &POLITE
  &SUBORDINATE
  &SUPPLETIVE
  &MADE_POLITE
) ] );
$EXPORT_TAGS{'all'} = $EXPORT_TAGS{'flags'};

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = ();


# Constructor. This takes a string and returns a Lingua::Zompist::Kebreni
# object (which is currently represented internally as an hashref).
# Key 'word' is the decomposed form as an arrayref, key 'base' is the
# word in Latin script, and key 'suppletive' is 0 or 1, depending on
# whether the verb currently stores a suppletive polite form.
sub new {
  my $self = shift;
  my $class = ref($self) || $self;
  my $word;
  my $base;
  my $flags;

  if(ref $self) {
    $flags = $self->flags;
    $word = decompose($base = shift);
    if(@_) { $flags |= shift; }
    if(@_) { $base = shift; } # override base for e.g. polite suppletives
  } else {
    $word = decompose($base = shift);
    $flags = shift || 0;
  }

  return bless {
                 word  => $word,
                 base  => $base,
                 flags => $flags,
               }, $class;
}


# return the base word
sub base {
  my $self = shift;

  return $self->{base};
}


# return the flags
sub flags {
  my $self = shift;

  return $self->{flags};
}


# String representation
sub to_string {
  my $self = shift;

  # carp "to_string called";

  # return $self->recompose;

  return recompose($self->{word});
}


# Null operation
sub null {
  return $_[0];
}




# ========================================================
# Verb stuff
# Might factor this out into another package some day

# Kebreni vowels
my %v = map { $_ => 1 } qw(i y u
                           e   o
                             a  );

# Kebreni consonants
my %c = map { $_ => 1 } qw(p    t     c     k
                           b    d           g
                           f    th s  h' s'     h
                           v       z     z'
                           m    n           ng
                                l  r              );

# Voiced versions of consonants
my %voice = ( 'p' => 'b',
              't' => 'd',
              'k' => 'g',
              's' => 'z',
              "s'" => "z'",
            );

# Fronted versions of vowels
my %front = ( 'a' => 'e',
              'o' => 'e',
              'u' => 'y',
              'y' => 'i',
              'i' => 'e',
              'e' => 'e',
            );

# Backed versions of vowels
my %back  = ( 'a' => 'o',
              'e' => 'o',
              'i' => 'y',
              'y' => 'u',
              'u' => 'o',
              'o' => 'o',
            );

# Consonant changes in the subordinating form
my %subord= ( 'm' => 'n', # labials become dentals
              'b' => 't', # b -> d -> t; might as well do it in one step
              'p' => 't',
              'd' => 't', # stops become unvoiced
              'g' => 'k',
              'z' => 's',
              "z'" => "s'",
            );

# Raised version of the vowels
my %raise = ( 'a' => 'e',
              'e' => 'i',
              'o' => 'u',
              'y' => 'y',
              'i' => 'i',
              'u' => 'u',
            );

# Lowered versions of the vowels
my %lower = ( 'i' => 'e',
              'y' => 'e',
              'e' => 'a',
              'o' => 'a',
              'u' => 'o',
              'a' => 'a',
            );



# decompose a word into phonemes
# turns a word into an arrayref; the elements are vowels and consonants
# or consonant clusters.
# consonant clusters are represented by arrayrefs containing consonants
# as elements; other sounds are represented by themselves.
# # Returns a Lingua::Zompist::Kebreni::Verb object
# sub new ($) {
sub decompose {
# my $self = shift;
# my $class = ref($self) || $self;
  my $word = shift;

  # split up -- first try two-letter phonemes, then one-letter ones
  my @phonemes = $word =~ /(th|s'|z'|h'|ng|[ptckiyubdgfsheovzmnalr])/g;

  # merge consonant clusters
  my $i = 0;
  while($i <= $#phonemes) {
    if($c{$phonemes[$i]} && $i < $#phonemes && $c{$phonemes[$i+1]}) {
      $phonemes[$i] = [ $phonemes[$i] ];
      my $j = $i+1;
      while($j <= $#phonemes && $c{$phonemes[$j]}) {
        push @{ $phonemes[$i] }, $phonemes[$j];
        $j++;
      }
      splice @phonemes, $i+1, $j-$i-1;
    }
    $i++;
  }

# return bless \@phonemes, $class;
  return \@phonemes;
}


# make a copy of a word
sub copy ($) {
  # the data structure will only ever be two levels deep
  return [ map { ref $_ ? [ @$_ ] : $_ } @{$_[0]} ];
}


# make a copy of a word
sub clone {
  my $self = shift;

# return bless copy($self), (ref($self) || $self);
  return bless {
                 word  => copy($self->{word}),
                 flags => $self->flags,
                 base  => $self->base,
               }, (ref($self) || $self);
}


# decompose consonant clusters by adding something in the middle
# takes three parameter: the word (an arrayref), the position of the
# consonant cluster (e.g. -2), and the something to add (usually a
# vowel). This will raise the cluster from an arrayref to a normal array
# element status.
# However, if the cluster had more than two consonants, only the last
# consonant is un-clustered.
# # This subroutine should not have to be called from outside the
# # Lingua::Zompist::Kebreni::Verb package
sub add ($$@) {
  my($word, $position, @newstuff) = @_;

  return $word unless ref $word->[$position];

  # Make a copy
  $word = copy $word;

  $position = @$word + $position if $position < 0;

  if(@{$word->[$position]} == 2) {
    splice @$word, $position, 1, $word->[$position]->[0], @newstuff, $word->[$position]->[1];
  } elsif(@{$word->[$position]} > 2) {
    my $lastcons = splice @{$word->[$position]}, -1, 1;
    splice @$word, $position+1, 0, @newstuff, $lastcons;
  }

  return $word;
}


# recompose a word out of the arrayref structure
sub recompose ($) {
  # maximum depth is two levels
  return join '', map { ref $_ ? @$_ : $_ } @{$_[0]};
}


# dump a word from the arrayref form
sub dumpword ($) {
  return join '', map { ref $_ ? '[' . join('',@$_) . ']' : $_ } @{$_[0]};
}


# form the perfective of a word. Expect the arrayref form.
sub perfective ($) {
  my $self = shift->clone;
  my $word = $self->{word};

  if($self->{flags} & POLITE) {
    croak "Can't make a polite form perfective";
  } elsif($self->{flags} & SUBORDINATE) {
    croak "Can't make a subordinate form perfective";
  }

  unless($v{$word->[-1]} && $v{$word->[-3]}) {
    croak "Funny word '" . dumpword($word) . "' does not have vowels in positions -3 and -1!";
  }

  # swap last two vowels
  ($word->[-1], $word->[-3]) = ($word->[-3], $word->[-1]);

  $self->{flags} |= PERFECTIVE;

  return $self;
}


# form the volitional of a word. Expect the arrayref form.
sub volitional ($) {
  my $self = shift->clone;
  my $word = $self->{word};

  if($self->{flags} & PERFECTIVE) {
    croak "Can't make a perfective form volitional";
  } elsif($self->{flags} & POLITE) {
    croak "Can't make a polite form volitional";
  } elsif($self->{flags} & SUBORDINATE) {
    croak "Can't make a subordinate form perfective";
  }

  # vowel-initial verbs form the volitional as if they had initial 'h'
  # see http://www.zompist.com/board/messages/94.html
  # es'u, however, adds 'v' for hysterical raisins
  # XXX TODO FIXME
  if($self->base eq "es'u" && !($self->flags & MADE_POLITE)) {
    unshift @$word, 'v';
  } elsif($v{$word->[0]}) {
    unshift @$word, 'h';
  }

  # voice the initial consonant
  $word->[0] = $voice{$word->[0]} if exists $voice{$word->[0]};

  # add an inital e
  unshift @$word, 'e';

  # switch the first two vowels
  unless($v{$word->[0]} && $v{$word->[2]}) {
    croak "Funny word '" . dumpword($word) . "' does not have vowels in positions 0 and 2!";
  }
  ($word->[0], $word->[2]) = ($word->[2], $word->[0]);

  # final -y becomes -u
  $word->[-1] = 'u' if $word->[-1] eq 'y';

  $self->{flags} |= VOLITIONAL;

  return $self;
}


# Exceptions with separate polite stems
# XXX FIXME TODO
my %polite = ( 'badu' => "seh'epu",
               'tasu' => 'soru',
               "es'u" => 'natu',
              );


# form the polite stem
sub make_polite {
  my $self = shift;

  $self->{flags} |= MADE_POLITE;

  if($polite{$self->base}) {
    return $self->new($polite{$self->base}, SUPPLETIVE, $self->base);
  } else {
    return $self;
  }
}


# form the polite form of a word.
sub polite ($$) {
  my $self = shift->clone;
  my $word = $self->{word};

  if($self->{flags} & SUBORDINATE) {
    croak "Can't make a subordinate form polite";
  }
  unless($self->{flags} & MADE_POLITE) {
    croak "Verb must be prepared with ->make_polite before calling ->polite";
  }

  $self->{flags} |= POLITE;

  # If the form is a suppletive, don't insert -ri-/-ry-.
  return $self if $self->{flags} & SUPPLETIVE;

  # insert -ri- before the last consonant or -ry- if the vowel in the next
  # syllable is a _u_.
  my @insert = ($word->[-1] eq 'u' ? ('r', 'y') : ('r', 'i'));

  # check for -VCV
  unless($v{$word->[-1]} && $v{$word->[-3]}) {
    croak "Funny word '" . dumpword($word) . "' does not have vowels in positions -3 and -1!";
  }
  unless(ref $word->[-2] or $c{$word->[-2]}) {
    croak "Funny word '" . dumpword($word) . "' does not have a consonant in position -2!";
  }

  # is the last consonant a cluster? if so, use add(), otherwise just
  # splice right in
  if(ref $word->[-2]) {
    $word = add $word, -2, @insert;
    $self->{word} = $word;
  } else {
    splice @$word, -2, 0, @insert;
  }

  return $self;
}


# form the benefactive of a word
sub benefactive ($) {
  my $self = shift->clone;
  my $word = $self->{word};

  if($self->{flags} & ANTIBEN) {
    croak "Can't make an antibenefactive from benefactive";
  } elsif($self->{flags} & VOLITIONAL) {
    croak "Can't make a volitional form benefactive";
  } elsif($self->{flags} & PERFECTIVE) {
    croak "Can't make a perfective form benefactive";
  } elsif($self->{flags} & POLITE) {
    croak "Can't make a polite form benefactive";
  } elsif($self->{flags} & SUBORDINATE) {
    croak "Can't make a subordinate form benefactive";
  }

  # check for -VC[uy]
  unless($v{$word->[-1]}) {
    croak "Funny word '" . dumpword($word) . "' does not have a vowel in position -3!";
  }
  unless(ref $word->[-2] or $c{$word->[-2]}) {
    croak "Funny word '" . dumpword($word) . "' does not have a consonant in position -2!";
  }
  unless($word->[-1] eq 'u' or $word->[-1] eq 'y') {
    croak "Funny word '" . dumpword($word) . "' does not end in -u or -y!";
  }

  # front the stem vowel
  # that's the last vowel of the root, according to
  # http://www.zompist.com/board/messages/94.html
  $word->[-3] = $front{$word->[-3]} || '???';

  # Change the final -u (or -y!) to -i
  $word->[-1] = 'i';

  $self->{flags} |= BENEFACTIVE;

  return $self;
}


# form the "(anti)benefactive for the listener"
# assumes that benefactive() or antiben() has already been applied
sub dir2 ($) {
  my $self = shift->clone;

  unless($self->{flags} & BENEFACTIVE or $self->{flags} & ANTIBEN) {
    croak "Can apply -to-listener only to (anti)benefactive forms";
  }

  my $word = $self->{word};

  # check for -VCV
  unless($v{$word->[-1]} && $v{$word->[-3]}) {
    croak "Funny word '" . dumpword($word) . "' does not have vowels in positions -3 and -1!";
  }
  unless(ref $word->[-2] or $c{$word->[-2]}) {
    croak "Funny word '" . dumpword($word) . "' does not have a consonant in position -2!";
  }

  # add -ni- before the final consonant of the root

  # is the last consonant a cluster? if so, use add(), otherwise just
  # splice right in
  if(ref $word->[-2]) {
    $word = add $word, -2, 'n', 'i';
    $self->{word} = $word;
  } else {
    splice @$word, -2, 0, 'n', 'i';
  }

  $self->{flags} |= DIR2;

  return $self;
}


# form the antibenefactive
sub antiben ($) {
  my $self = shift->clone;
  my $word = $self->{word};

  if($self->{flags} & BENEFACTIVE) {
    croak "Can't make a benefactive from antibenefactive";
  } elsif($self->{flags} & VOLITIONAL) {
    croak "Can't make a volitional form antibenefactive";
  } elsif($self->{flags} & PERFECTIVE) {
    croak "Can't make a perfective form antibenefactive";
  } elsif($self->{flags} & POLITE) {
    croak "Can't make a polite form antibenefactive";
  } elsif($self->{flags} & SUBORDINATE) {
    croak "Can't make a subordinate form antibenefactive";
  }

  # check for -VC[uy]
  unless($v{$word->[-1]}) {
    croak "Funny word '" . dumpword($word) . "' does not have a vowel in position -3!";
  }
  unless(ref $word->[-2] or $c{$word->[-2]}) {
    croak "Funny word '" . dumpword($word) . "' does not have a consonant in position -2!";
  }
  unless($word->[-1] eq 'u' or $word->[-1] eq 'y') {
    croak "Funny word '" . dumpword($word) . "' does not end in -u or -y!";
  }

  # back the stem vowel
  # that's the last vowel of the root, according to
  # http://www.zompist.com/board/messages/94.html
  $word->[-3] = $back{$word->[-3]} || '???';

  # Change the final -u (or -y!) to -a
  $word->[-1] = 'a';

  $self->{flags} |= ANTIBEN;

  return $self;
}


# form the subordinating form
sub subordinate ($) {
  my $self = shift->clone;
  my $word = $self->{word};

  # check for -VCV
  unless($v{$word->[-1]} && $v{$word->[-3]}) {
    croak "Funny word '" . dumpword($word) . "' does not have vowels in positions -3 and -1!";
  }
  unless(ref $word->[-2] or $c{$word->[-2]}) {
    croak "Funny word '" . dumpword($word) . "' does not have a consonant in position -2!";
  }

  # move the final vowel of the verb before the consonant

  # is the last consonant a cluster? if so, use add(), otherwise just
  # splice right in
  # use -1 rather than -2 for the position since we'll have spliced off
  # the vowel in position -1 already
  if(ref $word->[-2]) {
    $word = add $word, -1, splice(@$word, -1, 1);
    $self->{word} = $word;
  } else {
    splice @$word, -1, 0, splice(@$word, -1, 1);
  }

  # a labial stop becomes dental, a voiced stop becomes unvoiced
  $word->[-1] = $subord{$word->[-1]} || $word->[-1];

  # Add -te
  push @$word, 't', 'e';

  $self->{flags} |= SUBORDINATE;

  return $self;
}


# make the "one who does" form
sub whodoes ($) {
  my $self = shift->clone;
  my $word = $self->{word};

  splice @$word, -1, 1, 'e', 'u';

  return $self;
}


# make the feminine "one who does" form
sub whodoesf ($) {
  my $self = shift->clone;
  my $word = $self->{word};

  splice @$word, -1, 1, 'e', 'c';

  return $self;
}


# make the "participle"
sub participle ($) {
  my $self = shift->clone;
  my $word = $self->{word};

  # check for -VCV
  unless($v{$word->[-1]} && $v{$word->[-3]}) {
    croak "Funny word '" . dumpword($word) . "' does not have vowels in positions -3 and -1!";
  }
  unless(ref $word->[-2] or $c{$word->[-2]}) {
    croak "Funny word '" . dumpword($word) . "' does not have a consonant in position -2!";
  }

  # change final vowel to -a
  $word->[-1] = 'a';

  # is the last consonant a cluster? if so, use add(), otherwise just
  # splice right in
  if(ref $word->[-2]) {
    $word = add $word, -2, 'i';
    $self->{word} = $word;
  } else {
    splice @$word, -2, 0, ($word->[-3] eq 'i' ? 'e' : 'i');
  }

  return $self;
}


# form the action corresponding to a verb
sub action ($) {
  my $self = shift->clone;
  my $word = $self->{word};

  # check for -VCV
  unless($v{$word->[-1]} && $v{$word->[-3]}) {
    croak "Funny word '" . dumpword($word) . "' does not have vowels in positions -3 and -1!";
  }
  unless(ref $word->[-2] or $c{$word->[-2]}) {
    croak "Funny word '" . dumpword($word) . "' does not have a consonant in position -2!";
  }

  # lower the last root vowel
  $word->[-3] = $lower{$word->[-3]} || '???';

  # add -i
  $word->[-1] = 'i';

  return $self;
}


1;

__END__

=head1 NAME

Lingua::Zompist::Kebreni - Inflect Kebreni verbs

=head1 VERSION

This documentation refers to version 0.90 of Lingua::Zompist::Kebreni,
released on 2002-05-19.

=head1 SYNOPSIS

  use Lingua::Zompist::Kebreni;

  $word = Lingua::Zompist::Kebreni->new('kanu');

  $inflection = $word->perfective;
  $inflection = $word->make_polite->benefactive->polite;

  $base = $word->base;
  $string = $word->to_string; # or use "$word"

=head1 DESCRIPTION

=head2 Overview

This module allows you to inflect Kebreni verbs. Kebreni is a
language spoken on the fictional world of Almea, created by
Mark Rosenfelder. It has a rather "interesting" verbal system
(of which Mark says he's particularly proud).

The module has an object-oriented interface. To use it, first
create an object by calling the C<new> method and passing it
the verb name in traditional orthography -- for example, 'kanu'
or "z'ynu". Use the dictionary form (the imperfective) for this.

Now you can call various methods on this object. Each method,
when successful, will return another object. This is useful becuause
it is often necessary to chain method calls. For example, to form
the volitional benefactive, call the 'benefactive' method on
your verb object and then the 'volitional' method on the return
value of the 'benefactive' method, for example, like this:

  $inflected = $word->benefactive->volitional;

The module also has an overloaded "" function, so if you use a
Lingua::Zompist::Kebreni object in a string context, it will
give you the string representation. So you could print out the
volitional benefactive of 'kanu' like this:

  $inflected = Lingua::Zompist::Kebreni->new('kanu')
                                       ->benefactive
                                       ->volitional;
  print "The inflected form is $inflected\n";

You can also explicitly stringify an object by calling the
C<to_string> method on it.

=head2 Method calling order

You cannot call the object methods in any order. Rather, you must
adhere to the following order when creating complex verb forms:

=over 4

=item 1

make_polite

=item 2

benefactive / antiben

=item 3

volitional

=item 4

perfective

=item 5

dir2

=item 6

polite

=item 7

subordinate

=back

See the individual documentation of each method to find out a
bit more about what it does.

In general, polite and subordinating forms are mutually exclusive
(since only the main, conjugated form of the verb in a clause
will be marked for politeness), but they are presented as separate
steps here because they do not have a close semantic relationship
in the sense that benefactive and antibenefactive forms do (which
are also mutually exclusive).

=head2 Methods

In general, methods return another Lingua::Zompist::Kebreni
object when successful and croak if they have a problem.

=head3 new

This is the constructor for Lingua::Zompist::Kebreni objects.
The most common calling method is as a class method; in this
case, pass it the dictionary form of the verb you wish to
inflect. You can also, optionally, pass in flags which will
become the base flags of the verb. This is hardly ever necessary.

C<new> can also be called as an object method; in this case, it
can take up to three parameters. This is used internally but can
also be used by end-users if desires. The first parameter is,
again, the base verb; the second (optional) is flags which will
be OR'ed into the flags of the object the method is called on;
and the third (also optional) is an explicit base (this is used
for verbs with suppletive polite forms, where the conjugation
base is not the same as the dictionary base; in this case, the
first parameter is the conjugation base and the third is the
dictionary base which will be returned by the C<base> method).

=head3 base

This returns the base (dictionary form) of the current verb.

=head3 flags

This returns the flags of the current verb form. Probably not
very interesting except for developers.

=head3 null

This does nothing; it simply returns the object that it was called
on. This can be useful, for example, if you are constructing a
table of different verb forms by cycling through different
possible inflections. Then instead of, say,

  $word
  $word->perfective
  $word->volitional
  $word->volitional->perfective

you could use

  $word->null->null
  $word->null->perfective
  $word->volitional->null
  $word->volitional->perfective

and have the same number of steps at each turn.

=head3 perfective

Forms the perfective form of a given word, given an imperfective
form.

=head3 volitional

Forms the volitional form of a given word.

=head3 make_polite

If you wish to make the polite form of a verb, you need two
steps. First, you must call C<make_polite> as the first step, and
then you must later call C<polite> at the appropriate point (for
example, after you have formed the volitional perfective, or
whatever form you wanted). The reason for this is that some verbs
have suppletive polite forms, which are substituted right at
the beginning of the conjugation process.

The currently recognised irregular verbs and their supplective
polite base forms are:

  verb    polite

  badu    seh'epu
  tasu    soru
  es'u    natu

=head3 polite

This is used to form the polite form of a verb. The verb form
must have had C<make_polite> called on it in the past.

If the current verb is the suppletive form of another verb, this
operation is a null op[*]. In the interest of generality, it should
always be called, even if the current verb is known to have a
suppletive polite form.

[*] actually, not quite; this method still sets an internal flag 
on the word.

=head3 benefactive

This method forms the benefactive form of a verb. To form
the benefactive-to-listener form, you must later call the
C<ben2> method, which see.

=head3 dir2

This method changes a benefactive or antibenefactive form of
a verb into the benefactive-to-listener or 
antibenefactive-to-listener form of the verb. Note that you do
not, in general, call this method immediately after the
C<benefactive> or C<antiben> method, since C<volitional> and
C<perfective> may come in between as well.

=head3 antiben

This method forms the antibenefactive form of a verb. To form
the antibenefactive-to-listener form, you must later call the
C<ben2> method, which see.

=head3 subordinate

This forms the subordinating form of a given verb.

=head3 whodoes

This forms the "one who does" or "agent" form of a verb. This
method, as well as the following ones, is called on the
dictionary form of the verb (imperfective).

=head3 whodoesf

This forms the feminine "one who does" or "agent" form of a verb.
This method is called on the dictionary form of a verb.

=head3 participle

This method forms a word form that means "that has been Xed",
which is a bit like a past participle. For more information, see
the Kebreni grammar.

=head3 action

Use this method to form the action related to a verb.

=head2 EXPORT

Nothing by default. However, the following flags can be imported
explicitly, either individually or all together using the tag
':flags'. They're mostly for internal use only, however.

  BENEFACTIVE
  ANTIBEN
  VOLITIONAL
  PERFECTIVE
  DIR3
  POLITE
  SUBORDINATE
  SUPPLETIVE
  MADE_POLITE

=head1 DIAGNOSTICS

=over 4

=item "Can apply -to-listener only to (anti)benefactive forms"

You called the C<dir2> method without first calling either of
C<benefactive> or C<antiben>. This makes no sense, as -to-listener
forms only exist for benefactive and antibenefactive forms.

See also L</"Method calling order">.

=item "Can't make a%s form %s"

You apparently tried to call methods in the wrong order.
See L</"Method calling order"> for more information on which
order to call methods in.

=item "Funny word '%s' does not end in -u or -y!"

=item "Funny word '%s' does not have a consonant in position %s!"

=item "Funny word '%s' does not have a vowel in position %s!"

=item "Funny word '%s' does not have vowels in positions %s and %s!"

You apparently called a method on a verb which does not look as
if it has the right form. Check your spelling, or see whether it's
really a Kebreni verb.

=item "Verb must be prepared with ->make_polite before calling ->polite"

Apparently, you wanted to form the polite form of a verb but
forgot to call make_polite right at the beginning.

See also L</"Method calling order">.

=back

=head1 AUTHOR

Philip Newton, <pne@cpan.org>

=head1 SEE ALSO

http://www.zompist.com/kebreni.htm, L<Lingua::Zompist::Cadhinor>,
L<Lingua::Zompist::Verdurian>

=head1 COPYRIGHT AND LICENCE

[This is basically the BSD licence.]

Copyright (C) 2001, 2002 by Philip Newton. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

=over 4

=item *

Redistributions of source code must retain the above copyright notice,
this list of conditions and the following disclaimer.

=item *

Redistributions in binary form must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

=back

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

=cut
