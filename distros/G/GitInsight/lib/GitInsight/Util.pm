package GitInsight::Util;
use base 'Exporter';
use GitInsight::Obj -strict;
use Time::Local;
use PDL::LiteF;
use PDL::Lite;
use PDL::Stats;
use PDL::Ops;

# EVENTS LABELS:
use constant NO_CONTRIBUTIONS     => 0;
use constant FEW_CONTRIBUTIONS    => 1;
use constant NORMAL_CONTRIBUTIONS => 2;
use constant MORE_CONTRIBUTIONS   => 3;
use constant HIGH_CONTRIBUTIONS   => 4;

# LABEL ARRAY:
our @CONTRIBS = (
    NO_CONTRIBUTIONS,     FEW_CONTRIBUTIONS,
    NORMAL_CONTRIBUTIONS, MORE_CONTRIBUTIONS,
    HIGH_CONTRIBUTIONS
);

our %CA_COLOURS = (
    +NO_CONTRIBUTIONS()     => [ 238, 238, 238 ],
    +FEW_CONTRIBUTIONS()    => [ 214, 230, 133 ],
    +NORMAL_CONTRIBUTIONS() => [ 140, 198, 101 ],
    +MORE_CONTRIBUTIONS()   => [ 68,  163, 64 ],
    +HIGH_CONTRIBUTIONS()   => [ 30,  104, 35 ]
);

# LABEL DIMENSION, STARTING TO 0

use constant LABEL_DIM => 4;    # D:5 0 to 4

our @EXPORT    = qw(info error warning);
our @EXPORT_OK = (
    qw(markov_prob markov gen_m_mat dim gen_trans_mat markov_list LABEL_DIM wday label prob label_step
        ),
    @EXPORT
);
our @wday = qw/Mon Tue Wed Thu Fri Sat Sun/;

# to compute
our %LABEL_STEPS = (
    +NO_CONTRIBUTIONS()     => 0,
    +FEW_CONTRIBUTIONS()    => 0,
    +NORMAL_CONTRIBUTIONS() => 0,
    +MORE_CONTRIBUTIONS()   => 0,
    +HIGH_CONTRIBUTIONS()   => 0,
);

sub info {
    print "[info] - @_  \n";
}

sub error {
    print STDERR "[error] - @_  \n";
}

sub warning {
    print "[warning] - @_  \n";
}

sub wday {    # 2014-03-15 -> DayName  ( Dayname element of @wday )
    my ( $mday, $mon, $year ) = reverse( split( /-/, shift ) );
    return
        $wday[ ( localtime( timelocal( 0, 0, 0, $mday, $mon - 1, $year ) ) )
        [6] - 1 ];
}

sub gen_trans_mat {
    my $no_day_stats = shift || 0;
    return zeroes scalar(@CONTRIBS), scalar(@CONTRIBS)
        if ($no_day_stats);
    my $h = {};
    $h->{$_} = zeroes scalar(@CONTRIBS), scalar(@CONTRIBS) for @wday;
    return $h;
}

sub gen_m_mat {
    my $label = shift;
    my $h = zeroes( scalar(@CONTRIBS), 1 );
    $h->slice("$label,0") .= 1;
    return $h;
}

sub markov {
    my $a   = shift;
    my $b   = shift;
    my $pow = shift || 1;
    return ( $pow != 1 ) ? $a x (powering($b,$pow)) : $a x $b;
}

sub powering($){
    my $a=shift->copy;
    my $pow=shift;
     $a=$a x $a  for 1..$pow-1;
     return $a;
}

sub markov_list {
    my $a   = shift;
    my $b   = shift;
    my $pow = shift || 1;
    return [ list( &markov( $a, $b, $pow ) ) ];

}

sub markov_prob {
    my $a      = shift;
    my $b      = shift;
    my $pow    = shift || 1;
    my $markov = &markov( $a, $b, $pow );
    my $index  = maximum_ind($markov)->at(0);
    return ( $index, $markov->slice("$index,0")->at( 0, 0 ) );
}

sub label {
    return NO_CONTRIBUTIONS if ( $_[0] == 0 );
    return FEW_CONTRIBUTIONS
        unless ( $_[0] > $LABEL_STEPS{ +FEW_CONTRIBUTIONS() } );
    return NORMAL_CONTRIBUTIONS
        unless ( $_[0] > $LABEL_STEPS{ +NORMAL_CONTRIBUTIONS() } );
    return MORE_CONTRIBUTIONS
        unless ( $_[0] > $LABEL_STEPS{ +MORE_CONTRIBUTIONS() } );
    return HIGH_CONTRIBUTIONS;
}

sub label_step {
    my @commits_count = @_;

#Each cell in the graph is shaded with one of 5 possible colors. These colors correspond to the quartiles of the normal distribution over the range [0, max(v)] where v is the sum of issues opened, pull requests proposed and commits authored per day.
#XXX: next i would implement that in pdl
    $LABEL_STEPS{ +FEW_CONTRIBUTIONS() }
        = $commits_count[ int( scalar @commits_count / 4 ) ];
    $LABEL_STEPS{ +NORMAL_CONTRIBUTIONS() }
        = $commits_count[ int( scalar @commits_count / 2 )];
    $LABEL_STEPS{ +MORE_CONTRIBUTIONS() }
        = $LABEL_STEPS{ +HIGH_CONTRIBUTIONS() }
        = $commits_count[ 3 * int( scalar @commits_count / 4 ) ];

    # &info("FEW_CONTRIBUTIONS: ".$LABEL_STEPS{ +FEW_CONTRIBUTIONS() });
    # &info("NORMAL_CONTRIBUTIONS: ".$LABEL_STEPS{ +NORMAL_CONTRIBUTIONS() });
    # &info("MORE_CONTRIBUTIONS: ".$LABEL_STEPS{ +MORE_CONTRIBUTIONS() });
}

sub prob {
    my $x = zeroes(100)->xlinvals( 0, 1 );  # 0 padding from 0->1 of 100 steps
    return $x->index(    #find the index within the matrix probs
        maximum_ind(     #takes the maximum index of the funct
            pdf_beta( $x, ( 1 + $_[1] ),
                ( 1 + $_[0] - $_[1] ) )    #y: happens vs not happens
        )
    );
}

1;

__END__

=encoding utf-8

=head1 NAME

GitInsight::Util - A set of functions that uses PDL to produce stats

=head1 SYNOPSIS

    use GitInsight::Util qw(prob label);
    my $prob = prob(100,50); #gives probability using pdf_beta of PDL

=head1 DESCRIPTION

This package contains some functions that uses PDL to do some scientific calculations.

=head1 EXPORTED FUNCTIONS

=head2 prob()

calculate the probability using bayesian inference (C<pdf_beta> of PDL::Stats).
requires two argument, the total number of trials and the watched events that actually matched.

=head2 wday()

Requires a date in string, with this format:

    my $day=wday("2014-03-15")
    #$day is Tue

returns the weekday of the given date

=head2 gen_trans_mat()

Accept an argument, 1 or 0, 1 enable no_day_stats, and it causes to return an empty zero padded piddle.
If the argument is 0 it returns an hashref wich keys are the wdays that contains empty padded zero piddle

=head2 gen_m_mat()

Given a label number as argument, it generates a zero padded matrix of 1 row and of n columns as the label available, with having a 1 only set at the specified label. (used for calculating the prediction)

=head2 markov

requires 3 arguments: the matrix that selects the state (generated by C<gen_m_mat>), the transiction matrix, and the power that must be applied at the transition matrix.
It returns a PDL piddle containing the probability for each next state

=head2 markov_list

requires 3 arguments: the matrix that selects the state (generated by C<gen_m_mat>), the transiction matrix, and the power that must be applied at the transition matrix.
It returns a Perl list containing the probability for each next state.

=head2 markov_prob

requires 3 arguments: the matrix that selects the state (generated by C<gen_m_mat>), the transiction matrix, and the power that must be applied at the transition matrix.
It returns the maximum probability between the future states.

=head2 label

requires 1 argument: the number of commit to be assigned the appropriate label
It returns the assigned label

=head2 label_step

requires an array composed by [0,n] where n is the maximum commit count ever had in a day of the contribution calendar.
it sets the internal data structure to be able to call C<label()>

=head2 info/error/warning

Just used to print the output to the terminal:

    info "All ok"
    error "Something bad happened"
    warning "uh oh!"

=head1 AUTHOR

mudler E<lt>mudler@dark-lab.netE<gt>

=head1 COPYRIGHT

Copyright 2014- mudler

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<GitInsight>, L<PDL>, L<PDL::Stats>

=cut
