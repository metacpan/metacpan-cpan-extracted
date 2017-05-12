# $Id: TokenParse.pm,v 1.20 2004/08/08 01:20:36 gene Exp $

package Lingua::TokenParse;
$VERSION = '0.1601';
use strict;
use warnings;
use Carp;
use Storable;
use Math::BaseCalc;

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $self  = {
        verbose      => 0,
        # The word to parse!
        word         => undef,
        # We need to use this.
        word_length  => 0,
        # Known tokens.
        lexicon      => {},
        # Local lexicon cache file name.
        lexicon_file => '',  # ?: 'lexicon-' . time(),
        # All word parts.
        parts        => [],
        # All possible parts combinations.
        combinations => [],
        # Scored list of the known parts combinations.
        knowns       => {},
        # Definitions of the known and unknown fragments in knowns.
        definitions  => {},
        # Fragment definition separator.
        separator    => ' + ',
        # Known-but-not-defined definition output string.
        not_defined  => '.',
        # Unknown definition output string.
        unknown      => '?',
        # Known trimming regexp rules.
        constraints  => [],
        @_,  # slurp anything else and override defaults.
    };
    bless $self, $class;
    $self->_init();
    return $self;
}

sub _init {
    my $self = shift;
    warn "Entering _init()\n" if $self->{verbose};
    $self->word( $self->{word} ) if $self->{word};
    # Retrieve our lexicon cache if a filename was set.
    $self->lexicon_cache;
}

sub DESTROY {
    my $self = shift;
    # Cache our lexicon if a filename has been given.
    $self->lexicon_cache( $self->{lexicon_file} )
        if $self->{lexicon_file};
}

sub verbose {
    my $self = shift;
    $self->{verbose} = shift if @_;
    return $self->{verbose};
}

sub word {
    # WORD: This method is the only place where word_length is set.
    my $self = shift;
    warn "Entering word()\n" if $self->{verbose};
    if( @_ ) {
        $self->{word} = shift;
        $self->{word_length} = length $self->{word};
        printf "\tword = %s\n\tlength = %d\n",
            $self->{word}, $self->{word_length}
            if $self->{verbose};
    }
    return $self->{word};
}

sub lexicon {
    my $self = shift;
    if( @_ ) {
        $self->{lexicon} = @_ == 1 && ref $_[0] eq 'HASH'
            ? shift
            : @_ % 2 == 0
                ? { @_ }
                : {};
    }
    return $self->{lexicon};
}

sub parts {
    my $self = shift;
    $self->{parts} = shift if @_;
    return $self->{parts};
}

sub combinations {
    my $self = shift;
    $self->{combinations} = shift if @_;
    return $self->{combinations};
}

sub knowns {
    my $self = shift;
    $self->{knowns} = shift if @_;
    return $self->{knowns};
}

sub definitions {
    my $self = shift;
    $self->{definitions} = shift if @_;
    return $self->{definitions};
}

sub separator {
    my $self = shift;
    $self->{separator} = shift if @_;
    return $self->{separator};
}

sub not_defined {
    my $self = shift;
    $self->{not_defined} = shift if @_;
    return $self->{not_defined};
}

sub unknown {
    my $self = shift;
    $self->{unknown} = shift if @_;
    return $self->{unknown};
}

sub constraints {
    my $self = shift;
    $self->{constraints} = shift if @_;
    return $self->{constraints};
}

sub parse {
    my $self = shift;
    warn "Entering parse()\n" if $self->{verbose};
    $self->word( shift ) if @_;
    croak 'No word provided.' unless defined $self->{word};
    croak 'No lexicon defined.' unless keys %{ $self->{lexicon} };
    # Reset our data structures.
    $self->parts([]);
    $self->definitions({});
    $self->combinations([]);
    $self->knowns({});
    # Build new ones based on the word.
    $self->build_parts;
    $self->build_definitions;
    $self->build_combinations;
    $self->build_knowns;
}

sub build_parts {
    my $self = shift;
    warn "Entering build_parts()\n" if $self->{verbose};

    for my $i (0 .. $self->{word_length} - 1) {
        for my $j (1 .. $self->{word_length} - $i) {
            my $part = substr $self->{word}, $i, $j;
            push @{ $self->{parts} }, $part
                unless grep { $part =~ /$_/ }
                    @{ $self->constraints };
        }
    }

    if($self->{verbose}) {
        # XXX This is ugly.
        my $last = 0;
        for my $part (@{ $self->{parts} }) {
            print '',
                ($last ? $last > length( $part ) ? "\n\t" : ', ' : "\t"),
                $part;
            $last = length $part;
        }
        print "\n" if @{ $self->{parts} };
    }
    return $self->{parts};
}

# Save a known combination entry => definition table.
sub build_definitions {
    my $self = shift;
    warn "Entering build_definitions()\n" if $self->{verbose};
    for my $part (@{ $self->{parts} }) {
        $self->{definitions}{$part} = $self->{lexicon}{$part}
            if $self->{lexicon}{$part};
    }
    warn "\t", join( "\n\t", sort keys %{ $self->definitions } ), "\n"
        if $self->{verbose};
    return $self->{definitions};
}

sub build_combinations {
    my $self = shift;
    warn "Entering build_combinations()\n" if $self->{verbose};

    # field size for binary iteration (digits of precision)
    my $y  = $self->{word_length} - 1;
    # total number of zero-based combinations
    my $z  = 2 ** $y - 1;
    # field size for the count
    my $lz = length $z;
    # field size for a combination
    my $m  = $self->{word_length} + $y;
    warn sprintf
        "\tTotal combinations: %d\n\tConstrained combinations:\n",
        $z + 1
        if $self->{verbose};

    # Truth is a single partition character: the lowly dot.
    my $c = Math::BaseCalc->new( digits => [ 0, '.' ] );

    # Build a word part combination for each iteration.
    for my $n ( 0 .. $z ) {
        # Iterate in base two.
        my $i = $c->to_base( $n );

        # Get the binary digits as an array.
        my @i = split //, sprintf( '%0'.$y.'s', $i );

        # Join the character and digit arrays into a partitioned word.
        my $t = '';
        # ..by stepping over the characters and peeling off a digit.
        for( split //, $self->{word} ) {
            # Zero values become ''. Haha!  Truth prevails.
            $t .= $_ . (shift( @i ) || '');
        }

        unless( grep { $t =~ /$_/ } @{ $self->{constraints} } ) {
            # Preach it.
            printf "\t%".$lz.'d) %0'.$y.'s => %'.$m."s\n", $n, $i, $t
                if $self->{verbose};
            push @{ $self->combinations }, $t;
        }
    }

    return $self->{combinations};
}

sub build_knowns {
    my $self = shift;
    return unless scalar keys %{ $self->{lexicon} };
    warn "Entering build_knowns()\n" if $self->{verbose};

    # Save the familiarity value for each "raw" combination.
    for my $combo (@{ $self->{combinations} }) {
        # Skip combinations that have already been seen.
        next if exists $self->{knowns}{$combo};

        my ($sum, $frag_sum, $char_sum) = (0, 0, 0);

        # Get the bits of the combination.
        my @chunks = split /\./, $combo;
        for (@chunks) {
            # XXX Uh.. Magically handle hyphens in lexicon entries.
            ($_, my $combo_seen) = _hyphenate($_, $self->lexicon, 0);

            # Sum the combination familiarity values.
            if ($combo_seen) {
                $frag_sum++;
                $char_sum += length;
            }
        }
# XXX Huh? Why?  Can $_ change or something?
        # Stick our combination back together.
        $combo = join '.', @chunks;

        # Save this combination and its familiarity ratios.
        my $x = $frag_sum / @chunks;
        my $y = $char_sum / $self->{word_length};
        warn "\t$combo: [$x, $y]\n" if $self->{verbose};
        if( $x || $y ) {
            $self->{knowns}{$combo} = [ $x, $y ];
        }
        else {
            delete $self->{knowns}{$combo};
        }
    }

    return $self->{knowns};
}

# Reduce the number of known combinations by concatinating adjacent
# unknowns (and then removing any duplicates produced).

sub learn {
    my ($self, %args) = @_;
    # Get the list of (partially) unknown stem combinations.
    # Loop through each looking in %args or prompting for a definition.
}

# Update the given string with its actual lexicon value and increment
# the seen flag.
sub _hyphenate {
    my ($string, $lexicon, $combo_seen) = @_;

    if (exists $lexicon->{$string}) {
        $combo_seen++ if defined $combo_seen;
    }
    elsif (exists $lexicon->{"-$string"}) {
        $combo_seen++ if defined $combo_seen;
        $string = "-$string";
    }
    elsif (exists $lexicon->{"$string-"}) {
        $combo_seen++ if defined $combo_seen;
        $string = "$string-";
    }

    return wantarray ? ($string, $combo_seen) : $string;
}

sub output_knowns {
    my $self = shift;
    my @out = ();
    my $header = <<HEADER;
Combination [frag familiarity, char familiarity]
Fragment definitions

HEADER

    for my $known (
        reverse sort {
            $self->{knowns}{$a}[0] <=> $self->{knowns}{$b}[0] ||
            $self->{knowns}{$a}[1] <=> $self->{knowns}{$b}[1]
        } keys %{ $self->{knowns} }
    ) {
        my @definition;
        for my $chunk (split /\./, $known) {
            push @definition,
                defined $self->{definitions}{$chunk}
                    ? $self->{definitions}{$chunk}
                        ? $self->{definitions}{$chunk}
                        : $self->{not_defined}
                    : $self->{unknown};
        }

        push @out, sprintf qq/%s [%s]\n%s/,
            $known,
            join (', ', map { sprintf '%0.2f', $_ }
                @{ $self->{knowns}{$known} }),
            join ($self->{separator}, @definition);
    }

    return wantarray ? @out : $header . join "\n\n", @out;
}

# Naive, no locking read/write.  If you run a production environment,
# you know what to do.
sub lexicon_cache {
    my( $self, $file, $value ) = @_;
    warn "Entering lexicon_cache()\n" if $self->{verbose};

    # Set the file and the lexicon_file attribute if we are told to.
    if( $file && $file eq 'lexicon_file' && $value ) {
        $self->{lexicon_file} = $value;
        $file = $value;
    }

    # If there is no file try to use the lexicon_file.
    $file ||= $self->{lexicon_file};
    # Otherwise, bail out!
    warn( "No lexicon cache file set\n" ) and return
        if $self->{verbose} && !$file;

    if( $file ) {
        # Store 'em if you got 'em.
        if( keys %{ $self->{lexicon} } ) {
            warn "store( $self->{lexicon}, $file )\n" if $self->{verbose};
            store( $self->{lexicon}, $file );
        }
        # ..Retrieve 'em if not.
        else {
            warn "retrieve( $file )\n" if $self->{verbose} && -e $file;
            $self->lexicon( retrieve( $file ) ) if -e $file;
        }
    }
}

1;

__END__

=head1 NAME

Lingua::TokenParse - Parse a word into scored, fragment combinations

=head1 SYNOPSIS

  use Lingua::TokenParse;
  my $p = Lingua::TokenParse->new(
    word => 'antidisthoughtlessfulneodeoxyribonucleicfoo',
    lexicon => {
        a    => 'not',
        anti => 'opposite',
        di   => 'two',
        dis  => 'separation',
        eo   => 'hmmmmm',  # etc.
    },
    constraints => [ qr/eo(?:\.|$)/ ], # no parts ending in eo allowed
  );
  print Data::Dumper($p->knowns);

=head1 DESCRIPTION

This class represents a Lingua::TokenParse object and contains
methods to parse a given word into familiar combinations based
on a lexicon of known word parts.  This lexicon is a simple
I<fragment =E<gt> definition> list.

Words like "automobile" and "deoyribonucleic" are composed of
different roots, prefixes, suffixes, etc.  With a lexicon of known
fragments, a word can be partitioned into a list of its (possibly
overlapping) known and unknown fragment combinations.

These combinations can be given a score, which represents a measure of
word familiarity.  This measure is a set of ratios of known to unknown
fragments and letters.

=head1 METHODS

=head2 new

  $p = Lingua::TokenParse->new(
      verbose => 0,
      word => $word,
      lexicon => \%lexicon,
      lexicon_file => $lexicon_file,
      constraints => \@constraints,
  );

Return a new Lingua::TokenParse object.

This method will automatically call the partition methods (detailed
below) if a word and lexicon are provided.

The C<word> can be any string, however, you will want to make sure that
it does not include the same characters you use for the C<separator>,
C<not_defined> and C<unknown> strings (described below).

The C<lexicon> must be a hash reference with word fragments as keys and
definitions as their respective values.

=head2 parse

  $p->parse;
  $p->parse($string);

This method clears the partition lists and then calls all the
individual parsing methods that are detailed below.  If a string
is provided the object's C<word> attribute is reset to that, first.

=head2 build_parts

  $parts = $p->build_parts;

Construct an array reference of the word partitions.

=head2 build_definitions

  $known_definitions = $p->build_definitions;

Construct a table of the definitions of the word parts.

=head2 build_combinations

  $combos = $p->build_combinations;

Compute the array reference of all possible word part combinations.

=head2 build_knowns

  $raw_knowns = $p->build_knowns;

Compute the familiar word part combinations.

This method handles word parts containing prefix and suffix hyphens,
which encode information about what is a syntactically illegal word
combination, which can be used to score (or even throw out bogus
combinations).

=head2 lexicon_cache

  $p->lexicon_cache;
  $p->lexicon_cache( $lexicon_file );
  $p->lexicon_cache( lexicon_file => $lexicon_file );

Backup and retrieve the hash reference of token entries.

If this method is called with no arguments, the object's
C<lexicon_file> is used.  If the method is called with a single
argument, the object's C<lexicon_file> attribute is temporarily
overridden.  If the method is called with two arguments and the first
is the string "lexicon_file" then that attribute is set before
proceeding.

=head1 CONVENIENCE METHOD

=head2 output_knowns

  @known_list = $p->output_knowns;
  print Dumper \@known_list;

  # Look at the "even friendlier output."
  print scalar $p->output_knowns(
      separator   => $separator,
      not_defined => $not_defined,
      unknown     => $unknown,
  );

This method returns the familiar word part combinations in a couple
"human accessible" formats.  Each have familiarity scores rounded to
two decimals and fragment definitions shown in a readable layout

=over 4

=item separator

The the string used between fragment definitions.  Default is a plus
symbol surrounded by single spaces: ' + '.

=item not_defined

Indicates a known fragment that has no definition.  Default is a
single period: '.'.

=item unknown

Indicates an unknown fragment.  The default is the question mark: '?'.

=back

=head1 ACCESSORS

=head2 word

  $p->word($word);
  $word = $p->word;

The actual word to partition which can be any string.

=head2 lexicon

  $p->lexicon(%lexicon);
  $p->lexicon(\%lexicon);
  $lexicon = $p->lexicon;

The lexicon is a hash reference with word fragments as keys and
definitions their respective values.  It can be set with either a
hash or a hash reference.

=head2 parts

  $parts = $p->parts;

The computed array reference of all possible word partitions.

=head2 combinations

  $combinations = $p->combinations;

The computed array reference of all possible word part combinations.

=head2 knowns

  $knowns = $p->knowns;

The computed hash reference of known (non-zero scored) combinations
with their familiarity values.

=head2 definitions

  $definitions = $p->definitions;

The hash reference of the definitions provided for each fragment of
the combinations with the values of unknown fragments set to undef.

=head2 constraints

  $constraints = $p->constraints;
  $p->constraints(\@regexps);

An optional, user defined array reference of regular expressions to
apply when constructing the list of parts and combinations.  This
acts as a negative pruning device, meaning that if a match is
successful, the entry is excluded from the list.

=head1 EXAMPLES

Example code can be found in the distribution C<eg/> directory.

=head1 TO DO

Turn the lame C<output_knowns> method into a sensible XML serializer
(of optionally everything).

Compute the time required for a given parse.

Make a method to add definitions for unknown fragments and call it...
C<learn()>.

Use traditional stemming to trim down the common knowns and see if
the score is the same...

Synthesize a term list based on a thesaurus of word-part definitions.
That is, go in reverse.  Non-trivial!

=head1 SEE ALSO

L<Storable>

L<Math::BaseCalc>

=head1 DEDICATION

For my Grandmother and English teacher Frances Jones.

=head1 THANK YOU

Thank you to Luc St-Louis for helping me increase the speed while
eliminating the exponential memory footprint.  I wish I knew your
email address so I could tell you.  B<lucs++>

=head1 AUTHOR

Gene Boggs E<lt>gene@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2004 by Gene Boggs

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
