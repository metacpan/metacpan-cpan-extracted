package Inline::Spew;

use 5.006;
use strict;
use warnings;

require Exporter;
require Inline;
require YAML;

our @ISA = qw(Inline Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.02';

sub register {
  return {
	  language => 'Spew',
	  type => 'interpreted',
	  suffix => 'spew',
	 };
}

sub validate {
  ## warn "validate called with:\n", YAML::Dump(@_), "\n\n";
}

sub build {
  my $o = shift;
  my $code = $o->{API}{code};
  my $location = "$o->{API}{location}";

  require File::Basename;
  my $directory = File::Basename::dirname($location);
  $o->mkpath($directory) unless -d $directory;

  my $spew = spew_compile($code);

  YAML::DumpFile($location, $spew);
}

sub load {
  my $o = shift;

  my $sub = do {
    my $s = $o->{CONFIG}{SUB} || "spew";
    unless ($s =~ /::/) {
      $s = $o->{API}{pkg}."::$s";
    }
    $s;
  };
  my $location = $o->{API}{location};
  my @result = YAML::LoadFile($location);

  {
    no strict 'refs';
    *$sub = sub {
      my $start = shift || "START";
      return spew_show($result[0], $start);
    };
  }
}

sub spew_show {
  my ($parsed, $defn) = @_;
  die "missing defn for $defn" unless exists $parsed->{$defn};

  my @choices = @{$parsed->{$defn}{is}};
  my $weight = 0;
  my @keeper = ();
  while (@choices) {
    my ($thisweight, @thisitem) = @{pop @choices};
    $thisweight = 0 if $thisweight < 0; # no funny stuff
    $weight += $thisweight;
    @keeper = @thisitem if rand($weight) < $thisweight;
  }
  my $result;
  for (@keeper) {
    ## should be a list of ids or defns
    die "huh $_ in $defn" if ref $defn;
    if (/^ (.*)/s) {
      $result .= $1;
    } elsif (/^(\w+)$/) {
      $result .= spew_show($parsed, $1);
    } else {
      die "Can't show $_ in $defn\n";
    }
  }
  return $result;
}

BEGIN {

  my $parser;
  my $GRAMMAR = q{
## return hashref
## { ident => {
##     is => [
##       [weight => item, item, item, ...],
##       [weight => item, item, item, ...], ...
##     ],
##     defined => { line-number => times }
##     used => { line-number => times }
##   }, ...
## }
## item is " literal" or ident
## ident is C-symbol or number (internal for nested rules)

{ my %grammar; my $internal = 0; }

grammar: rule(s) /\Z/ { \%grammar; }

## rule returns identifier (not used)
rule: identifier ":" defn {
                push @{$grammar{$item[1]}{is}}, @{$item[3]};
                $grammar{$item[1]}{defined}{$itempos[1]{line}{to}}++;
                $item[1];
        }
        | <error>

## defn returns listref of choices
defn: <leftop: choice "|" choice>

## choice returns a listref of [weight => @items]
choice: weight unweightedchoice { [ $item[1] => @{$item[2]} ] }

## weight returns weight if present, 1 if not
weight: /\d+(\.\d+)?/ <commit> /\@/ { $item[1] } | { 1 }

## unweightedchoice returns a listref of @items
unweightedchoice: item(s)

## item returns " literal text" or "identifier"
item:
        { $_ = extract_quotelike($text) and " " . eval }
        | identifier <commit> ...!/:/ { # must not be followed by colon!
                $grammar{$item[1]}{used}{$itempos[1]{line}{to}}++;
                $item[1]; # non-leading space flags an identifier
        }
        | "(" defn ")" { # parens for recursion, gensym an internal
                ++$internal;
                push @{$grammar{$internal}{is}}, @{$item[2]};
                $internal;
        }
        | <error>

identifier: /[^\W\d]\w*/
};

  sub spew_compile {
    my $source = shift;

    unless ($parser) {
      require Parse::RecDescent;
      $parser = Parse::RecDescent->new($GRAMMAR) or die "internal bad";
    }

    my $parsed = $parser->grammar($source) or die "bad spew grammar";

    for my $id (sort keys %$parsed) {
      next if $id =~ /^\d+$/;       # skip internals
      my $id_ref = $parsed->{$id};
      unless (exists $id_ref->{defined}) {
	die "$id used in @{[sort keys %{$id_ref->{used}}]} but not defined";
      }
      ## unless (exists $id_ref->{used} or $id eq $START) {
      ## warn "$id defined in @{[sort keys %{$id_ref->{defined}}]} but not used";
      ## }
    }    

    return $parsed;
  }
}

1;
__END__
=head1 NAME

Inline::Spew - Inline module for Spew

=head1 SYNOPSIS

  use Inline Spew => <<'SPEW_GRAMMAR';
  START: "the" noun verb
  noun: "dog" | "cat" | "rat"
  verb: "eats" | "sleeps"
  SPEW_GRAMMAR

  my $sentence = spew();

=head1 ABSTRACT

  Inline::Spew is an Inline module for the Spew language.  Spew is a
  random-grammar walker for generating random text strings controlled
  by a grammar.

=head1 DESCRIPTION

Inline::Spew is an Inline module for the Spew language.  Spew is a
random-grammar walker for generating random text strings controlled by
a grammar.

Each Inline invocation defines a single subroutine, named C<spew> by
default.  The subroutine takes a single optional parameter, declaring
the "start symbol" within the spew grammar, defaulting to C<START>.
The grammar is randomly-walked, and the resulting string is returned.

The grammar is very similar to C<Parse::RecDescent>'s grammar
specification.  Each non-terminal provides one or more alternatives,
which consist of sequences of non-terminals and/or terminals.  An
alternative is chosen at random, by default equally weighted.  You can
set weights for the various alternatives easily: see below.  The
chosen non-terminals are expanded recursively until the result is a
sequence of the remaining terminals.

For example, the following invocation randomly returns a character
from the Flintstones:

  use Inline Spew => <<'END';
  START: flintstone_character | rubble_character
  flintstone_character:
    ("fred" | "barney" | "pebbles") " flintstone" | "dino"
  rubble_character:
    ("barney" | "betty" | "bamm bamm") " rubble"
  END
  my $character = spew();
  my $flint = spew("flintstone_character"); # only flintstone

The cost to compile a grammar is roughly a second on a reasonably
speedy machine, so the grammar compilation is cached by the C<Inline>
mechanism.  As long as the source text is not changed (regardless of
the file in which it appears), the compilation can be re-used.

C<Parse::RecDescent> is required for the compilation.  C<YAML> is
required for the saving and restoring of the spew grammar data
structure (and C<Inline> itself).

=head2 INLINE CONFIG PARAMETERS

=over

=item SUB

The name of the subroutine defined by the inline invocation.  Default
is C<spew> in the current package.  A name without colons is presumed
to be in the current package.  A name with colons provides an absolute
path.

=back

=head2 METHODS

=over 4

=item validate

Part of the Inline interface.

=item build

Part of the Inline interface.

=item spew_show

Part of the Inline interface.

=item load

Part of the Inline interface.

=item register

Part of the Inline interface.

=item spew_compile

Part of the Inline interface.

=back

=head2 SPEW GRAMMAR

See C<http://www.stonehenge.com/merlyn/LinuxMag/col04.html> for a detailed
explanation and examples.  Here's the relevent extract:

=over

=item

Non-terminals of the random sentence grammar are C-symbols (same as
Perl identifiers).

=item

Terminals are Perl-style quoted strings, permitting single-quoted or
double-quoted values, even with alternate delimiters, as in
C<qq/foo\n/>.

=item

Generally, a rule looks like:

  non_terminal: somerule1 | somerule2 | somerule3

=item

A rule may have a subrule (a parenthesized part).  For these anonymous
subrules, a non-terminal entry is generated for the subrule, but
assigned a sequentially increasing integer instead of a real name.  In
all other respects, the non-terminal acts identical to a user-defined
non-terminal.  This means that:

  foo: a ( b c | d e ) f | g h

is the same as

  foo: a 1 f | g h
  1: b c | d e

... except that you can't really have a non-terminal named C<1>.

=item

Weights are added by prefixing a choice with a positive floating-point
number followed by an C<@>, as in:

  foo: 5 @ fred | 2 @ barney | 1.5 @ dino | betty

which is five times as likely to pick C<fred> as C<betty> (or a total
of 5 out of 9.5 times).  This is simpler than repeating a grammar
choice multiple times, as I've seen in other similar programs, and
makes available fine-grained ratio definitions.

=back

=head2 EXPORT

None.

=head1 SEE ALSO

The Linux Magazine article at
C<http://www.stonehenge.com/merlyn/LinuxMag/col04.html>.

=head1 SECURITY WARNINGS

Double-quoted strings may contain arbitrary Perl code in subscripts,
executed when the grammar is compiled.  Quoted strings also include
C<``> or C<qx//>, causing shell commands to be executed when the
grammar is compiled.  Adding C<Safe> would be a good thing, and is in
the TODO list.

=head1 AUTHOR

Randal L. Schwartz (Stonehenge Consulting Services, Inc.),
C<< <merlyn@stonehenge.com> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2002, 2003 by Randal L. Schwartz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
