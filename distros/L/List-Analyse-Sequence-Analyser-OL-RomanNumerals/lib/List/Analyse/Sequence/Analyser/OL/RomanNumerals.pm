package List::Analyse::Sequence::Analyser::OL::RomanNumerals;

use strict;
use warnings;

use List::Util qw( first );
use Roman;

our $VERSION = 0.01;

sub new {
    return bless {}, shift;
}

sub analyse {
    my $self    = shift;
    my $datum   = shift;

    use Data::Dumper;
    my %pairs; # For finding multiple possible numerals.

    while ( $datum =~ /\G(.*?)([divxmlc]+)/ig ) {
        my ($prefix, $numeral) = ($1, $2);

        # The prefix should be everything from start of string, which
        # means we have to keep concatenating the previous one
        if( %pairs ){
            # The last prefix we found is the longest one, by definition.
            my $prev_prefix = (sort { length $a <=> length $b } keys %pairs)[-1];
            
            # The last one was not really a number and so remove it.
            delete $pairs{$prev_prefix} unless $pairs{$prev_prefix};

            no warnings 'uninitialized'; # sorry.
            $prefix = $prev_prefix . $pairs{$prev_prefix} . $prefix; 
        }

        if( isroman( $numeral ) ) {
            $pairs{$prefix} = $numeral;
        }
        else {
            # If it was not an actual numeral, use the whole lot, and we will delete it next time.
            $pairs{$prefix . $numeral} = "";
        }
    }

    unless( exists $self->{prefix} ) {
        # No point doing the rest of this sub if we've not done it before.
        if( %pairs ) {
            $self->{prefix} = \%pairs;
            return 1;
        }

        return;
    }
    # Now we have found all potential prefix-numeral combinations we can compare
    # them against the previous set.
    return unless keys %{ $self->{prefix} };

    if (exists $self->{prefix}) {
        for (keys %{ $self->{potential_pairs} }) { 
            delete $self->{prefix}->{$_} unless exists $pairs{$_};
        }

        for my $prefix (keys %{ $self->{potential_pairs} }) {
            my $new_numeral      = $pairs{$prefix};
            my $previous_version = $self->{potential_pairs}->{$prefix};

            if ( arabic( $new_numeral ) != arabic( $previous_version ) + 1 ) {  
                delete $self->{prefix}->{$prefix};
                next;
            }

            $self->{prefix}->{$prefix} = $new_numeral;
        }


        return unless keys %{ $self->{prefix} };
    }
    else {
        $self->{prefix} = \%pairs;
    }

    return 1;
}

sub prefix {
    return shift->{prefix};
}

sub done {
    my $self    = shift;
    my $shortest_prefix = (sort { length $a <=> length $b } keys %{ $self->{prefix} })[-1];

    $self->{last_numer} = $self->{prefixes}->{$shortest_prefix};
    $self->{prefix}     = $shortest_prefix;
}

1;

__END__

=head1 NAME

List::Analyse::Sequence::Analyser::OL::RomanNumerals - Find Roman numeral sequences.

=head1 DESCRIPTION

Used as a plugin to List::Analyse::Sequence, this will determine whether your
sequence contains any Roman numerals.

=head1 SYNOPSIS

    use List::Analyse::Sequence;

    ...

    my $seq = List::Analyse::Sequence->new;
    $seq->use_these_analysers( 'List::Analyse::Sequence::Analyser::OL::RomanNumerals' );

    $seq->analyse( @stuff );
    my ($result) = $seq->result;

    # Returns undef if no sequences matched.
    if( defined $result ) {
        my $roman_analyser  = $result->[0];

        ...
    }

    ...

List::Analyse::Sequence will return an object of this type when it is finished analysing if
your list had a Roman numeral sequence in it.

If a consistent prefix was found, this will be stored and you can get at it with the C<prefix>
method on that object.

=head1 METHODS

=head2 new

Creates a new one. This is called by List::Analyse::Sequence and so you probably don't need
to use it directly.

=head2 analyse

Analyses a string for sequentialism with the previous.

=head2 done

When finished, the shortest prefix found was taken to be the prefix. In the case where
multiple prefixes were found (i.e. multiple sequences) you will therefore only be told
of the first.

=head2 prefix

The consistent prefix that was found in front of your numeral sequence.

=head1 TODO

=over

=item Find some way of pattern-matching the prefix to see if there is a pattern there.

=item Find and report on multiple sequences at once.

=item Allow the use of parentheses, which wikipedia says you can use, so you can.

=back
