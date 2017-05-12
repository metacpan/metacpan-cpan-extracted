package List::Analyse::Sequence::Analyser::OL::Numbered;

use strict;
use warnings;

sub new {
    return bless {}, shift;
}

sub analyse {
    my $self    = shift;
    my $datum   = shift;

    if( exists $self->{last_num} ) {
        $self->{last_num}++;

        return 1 if $datum =~ /^\s*$self->{last_num}/;
        return;
    }

    ($self->{last_num}) = $datum =~ /^\s*(\d+)/ or return;
    return 1;
}

sub done {1}
1;

__END__

=head1 NAME

List::Analyse::Sequence::Analyser::OL::Numbered - Find ordered lists that are numbered.

=head1 DESCRIPTION

Used as a plugin to List::Analyse::Sequence, this will determine whether your
sequence is numbered in the old fashioned way, i.e. sequentially, starting with
any number and going up.

=head1 SYNOPSIS

    use List::Analyse::Sequence;

    ...

    my $seq = List::Analyse::Sequence->new;
    $seq->use_these_analysers( qw[List::Analyse::Sequence::Analyser::OL::Numbered] );

    $seq->analyse( @stuff );
    my ($result) = $seq->result;

    # Returns undef if no sequences matched.
    if( defined $result ) {
        my $analyser  = $result->[0];

        ...
    }

    ...

List::Analyse::Sequence will return an object of this type when it is finished analysing if
your list was an ordered list and each item began with a sequential number.

Whitespace may exist before each number: otherwise it is not considered numbered.

=head1 METHODS

You won't need to use any of these methods yourself: they are accessed by 
List::Analyse::Sequence.

=head2 new

Creates a new one. This is called by List::Analyse::Sequence and so you probably don't need
to use it directly.

=head2 analyse

Analyses a string for sequentialism with the previous.

=head2 done

We don't do any post-processing in this module.
