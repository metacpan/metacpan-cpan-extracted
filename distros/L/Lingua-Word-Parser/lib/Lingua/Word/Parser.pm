package Lingua::Word::Parser;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Parse a word into scored known and unknown parts

use strict;
use warnings;

our $VERSION = '0.0900';

use Bit::Vector ();
use DBI ();
use IO::File ();

use Memoize qw(memoize);
memoize('_grouping');
memoize('_rle');



sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = {
        file   => $args{file},
        dbhost => $args{dbhost} || 'localhost',
        dbtype => $args{dbtype} || 'mysql',
        dbname => $args{dbname},
        dbuser => $args{dbuser},
        dbpass => $args{dbpass},
        lex    => $args{lex},
        word   => $args{word},
        known  => {},
        masks  => {},
        combos => [],
        score  => {},
    };
    bless $self, $class;
    $self->_init(%args);
    return $self;
}
sub _init {
    my ($self, %args) = @_;

    # Set the length of our word.
    $self->{wlen} = length $self->{word};

    # Set lex if given data.
    if ( $self->{file} && -e $self->{file} ) {
        $self->_fetch_lex;
    }
    elsif( $self->{dbname} )
    {
        $self->_db_fetch;
    }
}

sub _fetch_lex {
    my $self = shift;

    my $i = 0;

    # Open the given file for reading...
    my $fh = IO::File->new;
    $fh->open($self->{file}, '<') or die "Can't read file: '$self->{file}'";
    for ( <$fh> ) {
        $i++;
        # Split space-separated entries.
        chomp;
        my ($re, $defn) = split /\s+/, $_, 2;
        # Add the entry to the lexicon.
        $self->{lex}{$i} = { defn => $defn, re => qr/$re/ };
    }
    $fh->close;

    return $self->{lex};
}

sub _db_fetch {
    my $self = shift;

    my $dsn;
    if (lc($self->{dbtype}) eq 'sqlite') {
      $dsn = "DBI:$self->{dbtype}:dbname=$self->{dbname};$self->{dbhost}";
    }
    else {
      $dsn = "DBI:$self->{dbtype}:$self->{dbname};$self->{dbhost}";
    }

    my $dbh = DBI->connect( $dsn, $self->{dbuser}, $self->{dbpass}, { RaiseError => 1, AutoCommit => 1 } )
      or die "Unable to connect to $self->{dbname}: $DBI::errstr\n";

    my $sql = 'SELECT id, affix, definition FROM fragment';

    my $sth = $dbh->prepare($sql);
    $sth->execute or die "Unable to execute '$sql': $DBI::errstr\n";

    while( my @row = $sth->fetchrow_array ) {
        my ($id, $part, $defn) = @row;
        $self->{lex}{$id} = { re => qr/$part/, defn => $defn };
    }
    die "Fetch terminated early: $DBI::errstr\n" if $DBI::errstr;

    $sth->finish or die "Unable to finish '$sql': $DBI::errstr\n";

    $dbh->disconnect or die "Unable to disconnect from $self->{dbname}: $DBI::errstr\n";
}


sub knowns {
    my $self = shift;

    # The identifier for the known and masks lists.
    my $id = 0;

    for my $i (values %{ $self->{lex} }) {
        while ($self->{word} =~ /$i->{re}/g) {
            # Match positions.
            my ($m, $n) = ($-[0], $+[0]);
            # Get matched word-part.
            my $part = substr $self->{word}, $m, $n - $m;

            next if $n == $m;   # skip zero-width matches instead of padding the mask

            # Create the part-of-word bitmask.
            my $mask = 0 x $m;                      # Before known
            $mask   .= 1 x ($n - $m);               # Known part
            $mask   .= 0 x ($self->{wlen} - $n);    # After known

            # Output our progress.
#            warn sprintf "%s %s - %s, %s (%d %d), %s\n",
#                $mask,
#                $i->{re},
#                substr($self->{word}, 0, $m),
#                $part,
#                $m,
#                $n - 1,
#                substr($self->{word}, $n),
#            ;

            # Save the known as a member of a list keyed by starting position.
            $self->{known}{$id} = {
                part => $part,
                span => [$m, $n - 1],
                defn => $i->{defn},
                mask => $mask,
            };

            # Save the relationship between mask and id.
            $self->{masks}{$mask} = $id++;
        }
    }

    return $self->{known};
}


sub power {
    my $self = shift;

    # Precompute each mask's [start, end) span once
    my @spans;
    for my $mask (keys %{ $self->{masks} }) {
        $mask =~ /^(0*)(1+)/;
        push @spans, { start => length($1), end => length($1) + length($2), mask => $mask };
    }
    @spans = sort { $a->{start} <=> $b->{start} } @spans;

    # Recursively extend only with spans that don't overlap what's already chosen
    my @combos;
    my $extend;
    $extend = sub {
        my ($from_idx, $chosen) = @_;
        push @combos, [ map { $_->{mask} } @$chosen ] if @$chosen;
        for my $idx ($from_idx .. $#spans) {
            my $span = $spans[$idx];
            next if @$chosen && $span->{start} < $chosen->[-1]{end};
            $extend->($idx + 1, [ @$chosen, $span ]);
        }
    };
    $extend->(0, []);

    $self->{combos} = \@combos;

    # Hand back the "non-overlapping powerset."
    return $self->{combos};
}


sub score {
    my $self = shift;
    my ( $open_separator, $close_separator ) = @_;

    my $parts = $self->score_parts( $open_separator, $close_separator );

    for my $mask ( keys %$parts ) {
        my $familiarity = sprintf "%.2f chunks / %.2f chars", @{ $self->_familiarity($mask) };

        for my $element ( @{ $parts->{$mask} } ) {
            my $score = sprintf "%d:%d chunks / %d:%d chars",
                $element->{score}{knowns}, $element->{score}{unknowns},
                $element->{score}{knownc}, $element->{score}{unknownc};

            my $part = join ', ', @{ $element->{partition} };

            my $defn = join ', ', @{ $element->{definition} };

            push @{ $self->{score}{$mask} }, {
                score       => $score,
                familiarity => $familiarity,
                partition   => $part,
                definition  => $defn,
            };
        }
    }

    return $self->{score};
}

sub _familiarity {
    my ( $self, $mask ) = @_;

    my @chunks = grep { $_ ne "" } split /(0+)/, $mask;

    # Figure out how many chars are only 1s and
    # Figure out how many chunks are made up of 1s:
    my $char_1s = 0;
    my $chunk_1s = 0;
    for my $chunk (@chunks) {
        $char_1s  += $chunk =~ /0/ ? 0 : length($chunk);
        $chunk_1s += $chunk =~ /0/ ? 0 : 1;
    }

    return [ $chunk_1s / @chunks, $char_1s / length($mask) ];
}


sub score_parts {
    my $self = shift;
    my ( $open_separator, $close_separator, $line_terminator ) = @_;

    $line_terminator = '' unless defined $line_terminator;

    # Visit each combination...
    my $i = 0;
    for my $c (@{ $self->{combos} }) {
        $i++;
        my $together = $self->_or_together(@$c);

        # Breakdown knowns vs unknowns and knowncharacters vs unknowncharacters.
        my %count = (
            knowns   => 0,
            unknowns => 0,
            knownc   => 0,
            unknownc => 0,
        );

        for my $x ( reverse sort @$c ) {
            # Run-length encode an "un-digitized" string.
            my $y = _rle($x);
            my ( $knowns, $unknowns, $knownc, $unknownc ) = _grouping($y);
            # Accumulate the counters!
            $count{knowns}   += $knowns;
            $count{unknowns} += $unknowns;
            $count{knownc}   += $knownc;
            $count{unknownc} += $unknownc;
        }

        my ( $s, $m ) = _reconstruct( $self->{word}, $c, $open_separator, $close_separator );

        my $defn = [];
        for my $k ( @$m )
        {
            for my $j ( keys %{ $self->{known} } )
            {
                push @$defn, $self->{known}{$j}{defn} if $self->{known}{$j}{mask} eq $k;
            }
        }

        push @{ $self->{score_parts}{$together} }, {
            score       => \%count,
            partition   => $s,
            definition  => $defn,
            familiarity => $self->_familiarity($together),
        };
    }

    return $self->{score_parts};
}

sub _grouping {
    my $scored = shift;
    my @groups = $scored =~ /([ku]\d+)/g;
    my ( $knowns, $unknowns ) = ( 0, 0 );
    my ( $knownc, $unknownc ) = ( 0, 0 );
    for ( @groups ) {
        if ( /k(\d+)/ ) {
            $knowns++;
            $knownc += $1;
        }
        if ( /u(\d+)/ ) {
            $unknowns++;
            $unknownc += $1;
        }
    }
    return $knowns, $unknowns, $knownc, $unknownc;
}

sub _rle {
    my $scored = shift;
    # Run-length encode an "un-digitized" string.
    $scored =~ s/1/k/g; # Undigitize
    $scored =~ s/0/u/g; # "
    # Count contiguous chars.
    $scored =~ s/(.)\1*/$1 . length(substr($scored, $-[0], $+[0]-$-[0]))/ge;
    return $scored;
}

sub _does_not_overlap {
    my $self = shift;

    # Get our masks to check.
    my ($mask, $check) = @_;

    # Create the bitstrings to compare.
    my $bitmask  = Bit::Vector->new_Bin($self->{wlen}, $mask);
    my $orclone  = Bit::Vector->new_Bin($self->{wlen}, $check);
    my $xorclone = Bit::Vector->new_Bin($self->{wlen}, $check);

    # Compute or and xor for the strings.
    $orclone->Or($bitmask, $orclone);
    $xorclone->Xor($bitmask, $xorclone);

    # Return the "or & xor equivalent sibling."
    return $xorclone->equal($orclone) ? $orclone->to_Bin : 0;
}

sub _or_together {
    my $self = shift;

    # Get our masks to score.
    my @masks = @_;

    # Initialize the bitmask to return, to zero.
    my $result = Bit::Vector->new_Bin($self->{wlen}, (0 x $self->{wlen}));

    for my $mask (@masks) {
        # Create the bitstrings to compare.
        my $bitmask = Bit::Vector->new_Bin($self->{wlen}, $mask);

        # Get the union of the bit strings.
        $result->Or($result, $bitmask);
    }

    # Return the "or sum."
    return $result->to_Bin;
}

sub _reconstruct {
    my ( $word, $masks, $open_separator, $close_separator ) = @_;

    $open_separator  = '<' unless defined $open_separator;
    $close_separator = '>' unless defined $close_separator;

    my $strings  = [];
    my $my_masks = [];

    for my $mask (reverse sort @$masks) {
        my $i = 0;
        my $last = 0;
        my $string  = '';
        for my $m ( split //, $mask ) {
            if ( $m ) {
                $string .= $open_separator unless $last;
                $string .= substr( $word, $i, 1 );
                $last = 1;
            }
            else {
                $string .= $close_separator if $last;
                $string .= substr( $word, $i, 1 );
                $last = 0;
            }
            $i++;
        }
        $string .= $close_separator if $last;
        push @$strings, $string;
        push @$my_masks, $mask;
    }

    return $strings, $my_masks;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::Word::Parser - Parse a word into scored known and unknown parts

=head1 VERSION

version 0.0900

=head1 SYNOPSIS

  use Lingua::Word::Parser;

  # With a database source:
  my $p = Lingua::Word::Parser->new(
    word   => 'abioticaly',
    dbname => 'fragments',
    dbuser => 'akbar',
    dbpass => 's3kr1+',
  );

  # With a file source:
  $p = Lingua::Word::Parser->new(
    word => 'abioticaly',
    file => 'eg/lexicon.dat',
  );

  my $known  = $p->knowns;
  my $combos = $p->power;
  my $score  = $p->score;       # Stringified output
  $score     = $p->score_parts; # "Raw" output

  # The best guess is the last sorted scored set:
  print Dumper $score->{ [ sort keys %$score ]->[-1] };

=head1 DESCRIPTION

A C<Lingua::Word::Parser> breaks a word into known affixes.

A word-part lexicon file must have "regular-expression definition"
lines of the form:

  a(?=\w)        opposite
  ab(?=\w)       away
  (?<=\w)o(?=\w) combining
  (?<=\w)tic     possessing

Please see the included F<eg/lexicon.dat> example file.

A database lexicon must have records as above, but with the column
names, B<id>, B<affix> and B<definition>.  Please see the included
F<eg/word_part.sql> example file.

=head1 METHODS

=head2 new

  $p = Lingua::Word::Parser->new(%arguments);

Create a new C<Lingua::Word::Parser> object.

Arguments and defaults:

  word:   undef
  dbuser: undef
  dbpass: undef
  dbname: undef
  dbtype: mysql
  dbhost: localhost

=head2 knowns

  $known = $p->knowns;

Find the known word parts and their bitstring masks.

=head2 power

  $combos = $p->power;

Find the set of non-overlapping known word parts by considering the power set of
all masks.

=head2 score

  $score = $p->score;
  $score = $p->score( $open_separator, $close_separator);

Score the known vs unknown word part combinations into ratios of characters and
chunks, word familiarity, partitions and definitions.

This method sets the B<score> member to a list of hashrefs with keys:

  partition
  definition
  score
  familiarity

If not given, the B<$open_separator> and B<$close_separator> are '<' and '>' by
default.

=head2 score_parts

  $score_parts = $p->score_parts;
  $score_parts = $p->score_parts( $open_separator, $close_separator );
  $score_parts = $p->score_parts( $open_separator, $close_separator, $line_terminator );

Score the known vs unknown word part combinations into ratios of characters and
chunks, word familiarity, partitions and definitions.

If not given, the B<$open_separator> and B<$close_separator> are '<' and '>' by
default.

The B<$line_terminator> can be any string, like a newline (C<\n> or an HTML
line-break), but is the empty string (C<''>) by default.

=head1 SEE ALSO

L<Lingua::TokenParse> - The predecessor of this module.

L<http://en.wikipedia.org/wiki/Affix> is the tip of the iceberg...

L<https://github.com/ology/Word-Part> a friendly L<Dancer> user interface.

The F<t/*> and F<eg/*> files in this distribution!

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2026 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
