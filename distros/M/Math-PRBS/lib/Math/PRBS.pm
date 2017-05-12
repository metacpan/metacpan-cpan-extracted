=head1 NAME

Math::PRBS - Generate Pseudorandom Binary Sequences using an Iterator-based Linear Feedback Shift Register

=cut
package Math::PRBS;
use warnings;
use strict;

use version 0.77; our $VERSION = version->declare('0.002');

=head1 SYNOPSIS

    use Math::PRBS;
    my $x3x2  = Math::PRBS->new( taps => [3,2] );
    my $prbs7 = Math::PRBS->new( prbs => 7 );
    my ($i, $value) = $x3x2t->next();
    my @p7 = $prbs7->generate_all();

=head1 DESCRIPTION

This module will generate various Pseudorandom Binary Sequences (PRBS).  This module creates a iterator object, and you can use that object to generate the sequence one value at a time, or I<en masse>.

The generated sequence is a series of 0s and 1s which appears random for a certain length, and then repeats thereafter.

It is implemented using an XOR-based Linear Feedback Shift Register (LFSR), which is described using a feedback polynomial (or reciprocal characteristic polynomial).  The terms that appear in the polynomial are called the 'taps', because you tap off of that bit of the shift register for generating the feedback for the next value in the sequence.

=head1 FUNCTIONS AND METHODS

=head2 Initialization

=over

=item C<$seq = Math::PRBS::new( I<key =E<gt> value> )>

Creates the sequence iterator C<$seq> using one of the C<key =E<gt> value> pairs described below.

=cut

sub new {
    my $class = shift;
    my $self = bless { lfsr => 0, start => 0, i => 0, period => undef, taps => [] }, $class;
    my %pairs;
    %pairs = @_%2 ? () : @_;

=over

=item C<prbs =E<gt> I<n>>

C<prbs> needs an integer I<n> to indicate one of the "standard" PRBS polynomials.

    # example: PRBS7 = x**7 + x**6 + 1
    $seq = Math::PRBS::new( ptbs => 7 );

The "standard" PRBS polynomials implemented are

    polynomial        | prbs       | taps            | poly (string)
    ------------------+------------+-----------------+---------------
    x**7 + x**6 + 1   | prbs => 7  | taps => [7,6]   | poly => '1100000'
    x**15 + x**14 + 1 | prbs => 15 | taps => [15,14] | poly => '110000000000000'
    x**23 + x**18 + 1 | prbs => 23 | taps => [23,18] | poly => '10000100000000000000000'
    x**31 + x**28 + 1 | prbs => 31 | taps => [31,28] | poly => '1001000000000000000000000000000'

=cut

    if( exists $pairs{prbs} )
    {
        my %prbs = (
            7  => [7,6]  ,
            15 => [15,14],
            23 => [23,18],
            31 => [31,28],
        );
        die __PACKAGE__."::new(prbs => '$pairs{prbs}'): standard PRBS include 7, 15, 23, 31" unless exists $prbs{ $pairs{prbs} };
        $self->{taps} = [ @{ $prbs{ $pairs{prbs} } } ];
    }

=item C<taps =E<gt> [ I<tap>, I<tap>, ... ]>

C<taps> needs an array reference containing the powers in the polynomial that you tap off for creating the feedback. Do I<not> include the C<0> for the C<x**0 = 1> in the polynomial; that's automatically included.

    # example: x**3 + x**2 + 1
    #   3 and 2 are taps, 1 is not tapped, 0 is implied feedback
    $seq = Math::PRBS::new( taps => [3,2] );

=cut

    elsif( exists $pairs{taps} )
    {
        die __PACKAGE__."::new(taps => $pairs{taps}): argument should be an array reference" unless 'ARRAY' eq ref($pairs{taps});
        $self->{taps} = [ sort {$b <=> $a} @{ $pairs{taps} } ];     # taps in descending order
        die __PACKAGE__."::new(taps => [@{$pairs{taps}}]): need at least one tap" unless @{ $pairs{taps} };
    }

=item C<poly =E<gt> '...'>

C<poly> needs a string for the bits C<x**k> downto C<x**1>, with a 1 indicating the power is included in the list, and a 0 indicating it is not.

    # example: x**3 + x**2 + 1
    #   3 and 2 are taps, 1 is not tapped, 0 is implied feedback
    $seq = Math::PRBS::new( poly => '110' );

=cut

    elsif( exists $pairs{poly} )
    {
        local $_ = $pairs{poly};    # used for implicit matching in die-unless and while-condition
        die __PACKAGE__."::new(poly => '$pairs{poly}'): argument should be an binary string" unless /^[01]*$/;
        my @taps = ();
        my $l = length;
        while( m/([01])/g ) {
            push @taps, $l - pos() + 1     if $1;
        }
        $self->{taps} = [ reverse sort {$a <=> $b} @taps ];
        die __PACKAGE__."::new(poly => '$pairs{poly}'): need at least one tap" unless @taps;
    } else {
        die __PACKAGE__."::new(".join(',',@_)."): unknown arguments";
    }

    $self->{lfsr} = oct('0b1' . '0'x($self->{taps}[0] - 1));
    $self->{start} = $self->{lfsr};

    return $self;
}

=back

=item C<$seq-E<gt>reset()>

Reinitializes the sequence: resets the sequence back to the starting state.  The next call to C<next()> will be the initial C<$i,$value> again.

=cut

sub reset {
    my $self = shift;
    $self->{lfsr} = $self->{start};
    $self->{i} = 0;
    return $self;
}

=back

=head2 Iteration

=over

=item C<$value = $seq-E<gt>next()>

=item C<($i, $value) = $seq-E<gt>next()>

Computes the next value in the sequence.  (Optionally, in list context, also returns the current value of the i for the sequence.)

=cut

sub next {
    my $self = shift;
    my $newbit = 0;
    my $mask = oct( '0b' . '1'x($self->{taps}[0]) );
    my $i = $self->{i};
    ++ $self->{i};

    $newbit ^= ( $self->{lfsr} >> ($_-1) ) & 1 for @{ $self->{taps} };

    $self->{lfsr} = (($self->{lfsr} << 1) | $newbit) & $mask;

    $self->{period} = $i+1        if $i && !defined($self->{period}) && ($self->{lfsr} eq $self->{start});

    return wantarray ? ( $i , $newbit ) : $newbit;
}

=item C<$seq-E<gt>rewind()>

Rewinds the sequence back to the starting state.  The subsequent call to C<next()> will be the initial C<$i,$value> again.
(This is actually an alias for C<reset()>).

=cut

BEGIN { *rewind = \&reset; }    # alias

=item C<$i = $seq-E<gt>tell_i()>

Return the current C<i> position.  The subsequent call to C<next()> will return this C<i>.

=cut

sub tell_i {
    return $_[0]->{i};
}

=item C<$state = $seq-E<gt>tell_state()>

Return the current internal state of the feedback register.  Useful for debug, or plugging into C<-E<gt>seek_to_state($state)> to get back to this state at some future point in the program.

=cut

sub tell_state {
    return $_[0]->{lfsr};
}

=item C<$seq-E<gt>seek_to_i( $n )>

=item C<$seq-E<gt>ith( $n )>

Moves forward in the sequence until C<i> reaches C<$n>.  If C<i E<gt> $n> already, will internally C<rewind()> first.  If C<$n E<gt> period>, it will stop at the end of the period, instead.

=cut

sub seek_to_i {
    my $self = shift;
    my $n = shift;

    $self->rewind() if $self->{i} > $n;
    $self->next() while(($self->{i} < $n) && !(defined($self->{period}) && ($self->{i} >= $self->{period})));
}

BEGIN { *ith = \&seek_to_i; }   # alias

=item C<$seq-E<gt>seek_to_state( $lfsr )>

Moves forward in the sequence until the internal LFSR state reaches C<$lfsr>.  It will wrap around, if necessary, but will stop once the internal state returns to the starting point.

=cut

sub seek_to_state {
    my $self = shift;
    my $lfsr = shift;
    my $state = $self->{lfsr};

        #local $\ = "\n";
        #local $, = "\t";
        #print STDERR __LINE__, "seek_to_state($lfsr):", $self->{i}, $self->{lfsr};
    $self->next() unless $state == $lfsr;
        #print STDERR __LINE__, "seek_to_state($lfsr):", $self->{i}, $self->{lfsr};
    $self->next() while ($self->{lfsr} != $lfsr) && ($self->{lfsr} != $state);          # Devel::Cover = the coverage hole is because I am testing for a condition that shouldn't be possible: getting back to initial state without ever having
        #print STDERR __LINE__, "seek_to_state($lfsr):", $self->{i}, $self->{lfsr};
}

=item C<$seq-E<gt>seek_forward_n( $n )>

Moves forward in the sequence C<$n> steps.

=cut

sub seek_forward_n {
    my $self = shift;
    my $n = shift;

    $self->next() for 1 .. $n;
}

=item C<$seq-E<gt>seek_to_end()>

=item C<$seq-E<gt>seek_to_end( limit =E<gt> $n )>

Moves forward until it's reached the end of the the period.  (Will start in the first period using C<tell_i % period>.)

If C<limit => $n> is used, will not seek beyond C<tell_i == $n>.

=cut

sub seek_to_end {
    my $self = shift;

    die __PACKAGE__."::generate_to_end(@_) requires even number of arguments, expecting name=>value pairs" unless 0 == @_ % 2;

    my %opts = map lc, @_;  # lowercase name,value pairs for canonical
    my $limit = exists $opts{limit} ? $opts{limit} : 65535;
    $limit = (2 ** $self->{taps}[0] - 1) if lc($limit) eq 'max';
    $self->{i} %= $self->{period}   if defined $self->{period} && $self->{i} > $self->{period};
    while( $self->{i} % $limit ) {
        $self->next();
        $limit = $self->{period} if defined $self->{period} && $self->{period} < $limit;    # pick PERIOD if PERIOD smaller than LIMIT
    }
}

=item C<@all = $seq-E<gt>generate( I<n> )>

Generates the next I<n> values in the sequence, wrapping around if it reaches the end.  In list context, returns the values as a list; in scalar context, returns the string concatenating that list.

=cut

sub generate {
    my ($self, $n) = @_;
    my @ret = ();
    foreach( 1 .. $n ) {
        push @ret, scalar $self->next();    # need to force the scalar version to not push (i,value)
    }
    return wantarray ? @ret : join '', @ret;
}

=item C<@all = $seq-E<gt>generate_all( )>

=item C<@all = $seq-E<gt>generate_all( I<limit =E<gt> $max_i> )>

Returns the whole sequence, from the beginning, up to the end of the sequence; in list context, returns the list of values; in scalar context, returns the string concatenating that list.  If the sequence is longer than the default limit of 65535, or the limit given by C<$max_i> if the optional C<limit =E<gt> $max_i> is provided, then it will stop before the end of the sequence.

=item C<@all = $seq-E<gt>generate_to_end( )>

=item C<@all = $seq-E<gt>generate_to_end( I<limit =E<gt> $max_i> )>

Returns the remaining sequence, from whatever state the list is currently at, up to the end of the sequence; in list context, returns the list of values; in scalar context, returns the string concatenating that list.  The limits work just as with C<generate_all()>.

=cut

sub generate_to_end {
    my $self = shift;

    die __PACKAGE__."::generate_to_end(@_) requires even number of arguments, expecting name=>value pairs" unless 0 == @_ % 2;

    my %opts = map lc, @_;  # lowercase name,value pairs for canonical
    my $limit = exists $opts{limit} ? $opts{limit} : 65535;
    $limit = (2 ** $self->{taps}[0] - 1) if lc($limit) eq 'max';
    # originally, the next block was "$self->rewind() if ($self->{i} && $opts{rewind});", but Devel::Cover complained that not all conditions were tested
    #   so I broke it into the following, which made Devel::Cover happy: note, it doesn't matter whether the i comes before or after rewind
    if ($self->{i}) {
        if( $opts{rewind} ) {
            $self->rewind();
        }
    }
    $self->{i} %= $self->{period}   if defined $self->{period} && $self->{i} > $self->{period};
    my $ret = '';
    while( $self->{i} < $limit ) {
        $ret .= scalar $self->next();    # need to force the scalar version to not push (i,value)
        $limit = $self->{period} if defined $self->{period} && $self->{period} < $limit;    # pick PERIOD if PERIOD smaller than LIMIT
    }
    return wantarray ? split(//, $ret) : $ret;
}

sub generate_all {
    my $self = shift;

    die __PACKAGE__."::generate_all(@_) requires even number of arguments, expecting name=>value pairs" unless 0 == @_ % 2;

    my %opts = @_;
    $opts{rewind} = 1;          # override existing rewind value
    return generate_to_end($self, %opts);
}

=back

=head2 Information

=over

=item C<$i = $seq-E<gt>description>

Returns a string describing the sequence in terms of the polynomial.

    $prbs7->description     # "PRBS from polynomial x**7 + x**6 + 1"

=cut

sub description {
    my $self = shift;
    my $p = '';
    foreach ( reverse sort {$a <=> $b} @{ $self->{taps} } ) {
        $p .= ' + ' if $p;
        $p .= "x**$_";
    }
    return "PRBS from polynomial $p + 1";
}

=item C<$i = $seq-E<gt>taps>

Returns an array-reference containing the list of tap identifiers, which could then be passed to C<-E<gt>new(taps =E<gt> ...)>.

    my $old_prbs = ...;
    my $new_prbs = Math::PRBS->new( taps => $old_prbs->taps() );

=cut

sub taps {
    my @taps = @{ $_[0]->{taps} };
    return [@taps];
}

=item C<$i = $seq-E<gt>period( I<force =E<gt> 'estimate' | $n | 'max'> )>

Returns the period of the sequence.

Without any arguments, will return undef if the period hasn't been determined yet (ie, haven't travelled far enough in the sequence):

    $i = $seq->period();                        # unknown => undef

If I<force> is set to 'estimate', will return C<period = 2**k - 1> if the period hasn't been determined yet:

    $i = $seq->period(force => 'estimate');     # unknown => 2**k - 1

If I<force> is set to an integer C<$n>, it will try to generate the whole sequence (up to C<tell_i E<lt>= $n>), and return the period if found, or undef if not found.

    $i = $seq->period(force => $n);             # look until $n; undef if sequence period still not found

If I<force> is set 'max', it will loop thru the entire sequence (up to C<i = 2**k - 1>), and return the period that was found.  It will still return  undef if still not found, but all sequences B<should> find the period within C<2**k-1>.  If you find a sequence that doesn't, feel free to file a bug report, including the C<Math::PRBS-E<gt>new()> command listing the taps array or poly string; if C<k> is greater than C<32>, please include a code that fixes the bug in the bug report, as development resources may not allow for debug of issues when C<k E<gt> 32>.

    $i = $seq->period(force => 'max');          # look until 2**k - 1; undef if sequence period still not found


=cut

sub period {
    my $self  = shift;
    return $self->{period} if defined $self->{period};              # if period's already computed, use it

    die __PACKAGE__."::period(@_) requires even number of arguments, expecting name=>value pairs" unless 0 == @_ % 2;

    my %opts  = map lc, @_;                                         # lowercase the arguments and make them into a canonical hash
    my $force = exists($opts{force}) ? $opts{force} : 'not';
    return $self->{period} if 'not' eq $force;                      # if not forced, return the undefined period

    my $max = 2**$self->{taps}[0] - 1;                              # if forced, max is 2**k-1
    return $max if $force eq 'estimate';                            # if estimate, guess that period is maximal

    $max = $force   unless $force =~ /[^\d]/;                       # don't change max if force is a string (or negative, or floatingpoint)

    # ... loop thru all, until limit is reached or period is defined
    $self->next while $self->{i}<$max && !defined $self->{period};

    return $self->{period};
}

=item C<$i = $seq-E<gt>oeis_anum>

For known polynomials, return the L<On-line Encyclopedia of Integer Sequences|https://oeis.org> "A" number.  For example, you can go to L<https://oeis.org/A011686> to look at the sequence A011686.

Not all maximum-length PRBS sequences (binary m-sequences) are in OEIS.  Of the four "standard" PRBS (7, 15, 23, 31) mentioned above, only PRBS7 is there, as L<A011686|https://oeis.org/A011686>.  If you have the A-number for other m-sequences that aren't included below, please let the module maintainer know.

    Polynomial                                    | Taps                  | OEIS
    ----------------------------------------------+-----------------------+---------
    x**2 + x**1 + 1                               | [ 2, 1 ]              | A011655
    x**3 + x**2 + 1                               | [ 3, 2 ]              | A011656
    x**3 + x**1 + 1                               | [ 3, 1 ]              | A011657
    x**4 + x**3 + x**2 + x**1 + 1                 | [ 4, 3, 2, 1 ]        | A011658
    x**4 + x**1 + 1                               | [ 4, 1 ]              | A011659
    x**5 + x**4 + x**2 + x**1 + 1                 | [ 5, 4, 2, 1 ]        | A011660
    x**5 + x**3 + x**2 + x**1 + 1                 | [ 5, 3, 2, 1 ]        | A011661
    x**5 + x**2 + 1                               | [ 5, 2 ]              | A011662
    x**5 + x**4 + x**3 + x**1 + 1                 | [ 5, 4, 3, 1 ]        | A011663
    x**5 + x**3 + 1                               | [ 5, 3 ]              | A011664
    x**5 + x**4 + x**3 + x**2 + 1                 | [ 5, 4, 3, 2 ]        | A011665
    x**6 + x**5 + x**4 + x**1 + 1                 | [ 6, 5, 4, 1 ]        | A011666
    x**6 + x**5 + x**3 + x**2 + 1                 | [ 6, 5, 3, 2 ]        | A011667
    x**6 + x**5 + x**2 + x**1 + 1                 | [ 6, 5, 2, 1 ]        | A011668
    x**6 + x**1 + 1                               | [ 6, 1 ]              | A011669
    x**6 + x**4 + x**3 + x**1 + 1                 | [ 6, 4, 3, 1 ]        | A011670
    x**6 + x**5 + x**4 + x**2 + 1                 | [ 6, 5, 4, 2 ]        | A011671
    x**6 + x**3 + 1                               | [ 6, 3 ]              | A011672
    x**6 + x**5 + 1                               | [ 6, 5 ]              | A011673
    x**7 + x**6 + x**5 + x**4 + x**3 + x**2 + 1   | [ 7, 6, 5, 4, 3, 2 ]  | A011674
    x**7 + x**4 + 1                               | [ 7, 4 ]              | A011675
    x**7 + x**6 + x**4 + x**2 + 1                 | [ 7, 6, 4, 2 ]        | A011676
    x**7 + x**5 + x**2 + x**1 + 1                 | [ 7, 5, 2, 1 ]        | A011677
    x**7 + x**5 + x**3 + x**1 + 1                 | [ 7, 5, 3, 1 ]        | A011678
    x**7 + x**6 + x**4 + x**1 + 1                 | [ 7, 6, 4, 1 ]        | A011679
    x**7 + x**6 + x**5 + x**4 + x**2 + x**1 + 1   | [ 7, 6, 5, 4, 2, 1 ]  | A011680
    x**7 + x**6 + x**5 + x**3 + x**2 + x**1 + 1   | [ 7, 6, 5, 3, 2, 1 ]  | A011681
    x**7 + x**1 + 1                               | [ 7, 1 ]              | A011682
    x**7 + x**5 + x**4 + x**3 + x**2 + x**1 + 1   | [ 7, 5, 4, 3, 2, 1 ]  | A011683
    x**7 + x**4 + x**3 + x**2 + 1                 | [ 7, 4, 3, 2 ]        | A011684
    x**7 + x**6 + x**3 + x**1 + 1                 | [ 7, 6, 3, 1 ]        | A011685
    x**7 + x**6 + 1                               | [ 7, 6 ]              | A011686
    x**7 + x**6 + x**5 + x**4 + 1                 | [ 7, 6, 5, 4 ]        | A011687
    x**7 + x**5 + x**4 + x**3 + 1                 | [ 7, 5, 4, 3 ]        | A011688
    x**7 + x**3 + x**2 + x**1 + 1                 | [ 7, 3, 2, 1 ]        | A011689
    x**7 + x**3 + 1                               | [ 7, 3 ]              | A011690
    x**7 + x**6 + x**5 + x**2 + 1                 | [ 7, 6, 5, 2 ]        | A011691
    x**8 + x**6 + x**4 + x**3 + x**2 + x**1 + 1   | [ 8, 6, 4, 3, 2, 1 ]  | A011692
    x**8 + x**5 + x**4 + x**3 + 1                 | [ 8, 5, 4, 3 ]        | A011693
    x**8 + x**7 + x**5 + x**3 + 1                 | [ 8, 7, 5, 3 ]        | A011694
    x**8 + x**7 + x**6 + x**5 + x**4 + x**2 + 1   | [ 8, 7, 6, 5, 4, 2 ]  | A011695
    x**8 + x**7 + x**6 + x**5 + x**4 + x**3 + 1   | [ 8, 7, 6, 5, 4, 3 ]  | A011696
    x**8 + x**4 + x**3 + x**2 + 1                 | [ 8, 4, 3, 2 ]        | A011697
    x**8 + x**6 + x**5 + x**4 + x**2 + x**1 + 1   | [ 8, 6, 5, 4, 2, 1 ]  | A011698
    x**8 + x**7 + x**5 + x**1 + 1                 | [ 8, 7, 5, 1 ]        | A011699
    x**8 + x**7 + x**3 + x**1 + 1                 | [ 8, 7, 3, 1 ]        | A011700
    x**8 + x**5 + x**4 + x**3 + x**2 + x**1 + 1   | [ 8, 5, 4, 3, 2, 1 ]  | A011701
    x**8 + x**7 + x**5 + x**4 + x**3 + x**2 + 1   | [ 8, 7, 5, 4, 3, 2 ]  | A011702
    x**8 + x**7 + x**6 + x**4 + x**3 + x**2 + 1   | [ 8, 7, 6, 4, 3, 2 ]  | A011703
    x**8 + x**6 + x**3 + x**2 + 1                 | [ 8, 6, 3, 2 ]        | A011704
    x**8 + x**7 + x**3 + x**2 + 1                 | [ 8, 7, 3, 2 ]        | A011705
    x**8 + x**6 + x**5 + x**2 + 1                 | [ 8, 6, 5, 2 ]        | A011706
    x**8 + x**7 + x**6 + x**4 + x**2 + x**1 + 1   | [ 8, 7, 6, 4, 2, 1 ]  | A011707
    x**8 + x**7 + x**6 + x**3 + x**2 + x**1 + 1   | [ 8, 7, 6, 3, 2, 1 ]  | A011708
    x**8 + x**7 + x**2 + x**1 + 1                 | [ 8, 7, 2, 1 ]        | A011709
    x**8 + x**7 + x**6 + x**1 + 1                 | [ 8, 7, 6, 1 ]        | A011710
    x**8 + x**7 + x**6 + x**5 + x**2 + x**1 + 1   | [ 8, 7, 6, 5, 2, 1 ]  | A011711
    x**8 + x**7 + x**5 + x**4 + 1                 | [ 8, 7, 5, 4 ]        | A011712
    x**8 + x**6 + x**5 + x**1 + 1                 | [ 8, 6, 5, 1 ]        | A011713
    x**8 + x**4 + x**3 + x**1 + 1                 | [ 8, 4, 3, 1 ]        | A011714
    x**8 + x**6 + x**5 + x**4 + 1                 | [ 8, 6, 5, 4 ]        | A011715
    x**8 + x**7 + x**6 + x**5 + x**4 + x**1 + 1   | [ 8, 7, 6, 5, 4, 1 ]  | A011716
    x**8 + x**5 + x**3 + x**2 + 1                 | [ 8, 5, 3, 2 ]        | A011717
    x**8 + x**6 + x**5 + x**4 + x**3 + x**1 + 1   | [ 8, 6, 5, 4, 3, 1 ]  | A011718
    x**8 + x**5 + x**3 + x**1 + 1                 | [ 8, 5, 3, 1 ]        | A011719
    x**8 + x**7 + x**4 + x**3 + x**2 + x**1 + 1   | [ 8, 7, 4, 3, 2, 1 ]  | A011720
    x**8 + x**6 + x**5 + x**3 + 1                 | [ 8, 6, 5, 3 ]        | A011721
    x**9 + x**4 + 1                               | [ 9, 4 ]              | A011722
    x**10 + x**3 + 1                              | [ 10, 3 ]             | A011723
    x**11 + x**2 + 1                              | [ 11, 2 ]             | A011724
    x**12 + x**7 + x**4 + x**3 + 1                | [ 12, 7, 4, 3 ]       | A011725
    x**13 + x**4 + x**3 + x**1 + 1                | [ 13, 4, 3, 1 ]       | A011726
    x**14 + x**12 + x**11 + x**1 + 1              | [ 14, 12, 11, 1 ]     | A011727
    x**15 + x**1 + 1                              | [ 15, 1 ]             | A011728
    x**16 + x**5 + x**3 + x**2 + 1                | [ 16, 5, 3, 2 ]       | A011729
    x**17 + x**3 + 1                              | [ 17, 3 ]             | A011730
    x**18 + x**7 + 1                              | [ 18, 7 ]             | A011731
    x**19 + x**6 + x**5 + x**1 + 1                | [ 19, 6, 5, 1 ]       | A011732
    x**20 + x**3 + 1                              | [ 20, 3 ]             | A011733
    x**21 + x**2 + 1                              | [ 21, 2 ]             | A011734
    x**22 + x**1 + 1                              | [ 22, 1 ]             | A011735
    x**23 + x**5 + 1                              | [ 23, 5 ]             | A011736
    x**24 + x**4 + x**3 + x**1 + 1                | [ 24, 4, 3, 1 ]       | A011737
    x**25 + x**3 + 1                              | [ 25, 3 ]             | A011738
    x**26 + x**8 + x**7 + x**1 + 1                | [ 26, 8, 7, 1 ]       | A011739
    x**27 + x**8 + x**7 + x**1 + 1                | [ 27, 8, 7, 1 ]       | A011740
    x**28 + x**3 + 1                              | [ 28, 3 ]             | A011741
    x**29 + x**2 + 1                              | [ 29, 2 ]             | A011742
    x**30 + x**16 + x**15 + x**1 + 1              | [ 30, 16, 15, 1 ]     | A011743
    x**31 + x**3 + 1                              | [ 31, 3 ]             | A011744
    x**32 + x**28 + x**27 + x**1 + 1              | [ 32, 28, 27, 1 ]     | A011745

=cut

my %OEIS = (
    join(';', @{ [ 2, 1 ]              } ) => 'A011655',
    join(';', @{ [ 3, 2 ]              } ) => 'A011656',
    join(';', @{ [ 3, 1 ]              } ) => 'A011657',
    join(';', @{ [ 4, 3, 2, 1 ]        } ) => 'A011658',
    join(';', @{ [ 4, 1 ]              } ) => 'A011659',
    join(';', @{ [ 5, 4, 2, 1 ]        } ) => 'A011660',
    join(';', @{ [ 5, 3, 2, 1 ]        } ) => 'A011661',
    join(';', @{ [ 5, 2 ]              } ) => 'A011662',
    join(';', @{ [ 5, 4, 3, 1 ]        } ) => 'A011663',
    join(';', @{ [ 5, 3 ]              } ) => 'A011664',
    join(';', @{ [ 5, 4, 3, 2 ]        } ) => 'A011665',
    join(';', @{ [ 6, 5, 4, 1 ]        } ) => 'A011666',
    join(';', @{ [ 6, 5, 3, 2 ]        } ) => 'A011667',
    join(';', @{ [ 6, 5, 2, 1 ]        } ) => 'A011668',
    join(';', @{ [ 6, 1 ]              } ) => 'A011669',
    join(';', @{ [ 6, 4, 3, 1 ]        } ) => 'A011670',
    join(';', @{ [ 6, 5, 4, 2 ]        } ) => 'A011671',
    join(';', @{ [ 6, 3 ]              } ) => 'A011672',
    join(';', @{ [ 6, 5 ]              } ) => 'A011673',
    join(';', @{ [ 7, 6, 5, 4, 3, 2 ]  } ) => 'A011674',
    join(';', @{ [ 7, 4 ]              } ) => 'A011675',
    join(';', @{ [ 7, 6, 4, 2 ]        } ) => 'A011676',
    join(';', @{ [ 7, 5, 2, 1 ]        } ) => 'A011677',
    join(';', @{ [ 7, 5, 3, 1 ]        } ) => 'A011678',
    join(';', @{ [ 7, 6, 4, 1 ]        } ) => 'A011679',
    join(';', @{ [ 7, 6, 5, 4, 2, 1 ]  } ) => 'A011680',
    join(';', @{ [ 7, 6, 5, 3, 2, 1 ]  } ) => 'A011681',
    join(';', @{ [ 7, 1 ]              } ) => 'A011682',
    join(';', @{ [ 7, 5, 4, 3, 2, 1 ]  } ) => 'A011683',
    join(';', @{ [ 7, 4, 3, 2 ]        } ) => 'A011684',
    join(';', @{ [ 7, 6, 3, 1 ]        } ) => 'A011685',
    join(';', @{ [ 7, 6 ]              } ) => 'A011686',
    join(';', @{ [ 7, 6, 5, 4 ]        } ) => 'A011687',
    join(';', @{ [ 7, 5, 4, 3 ]        } ) => 'A011688',
    join(';', @{ [ 7, 3, 2, 1 ]        } ) => 'A011689',
    join(';', @{ [ 7, 3 ]              } ) => 'A011690',
    join(';', @{ [ 7, 6, 5, 2 ]        } ) => 'A011691',
    join(';', @{ [ 8, 6, 4, 3, 2, 1 ]  } ) => 'A011692',
    join(';', @{ [ 8, 5, 4, 3 ]        } ) => 'A011693',
    join(';', @{ [ 8, 7, 5, 3 ]        } ) => 'A011694',
    join(';', @{ [ 8, 7, 6, 5, 4, 2 ]  } ) => 'A011695',
    join(';', @{ [ 8, 7, 6, 5, 4, 3 ]  } ) => 'A011696',
    join(';', @{ [ 8, 4, 3, 2 ]        } ) => 'A011697',
    join(';', @{ [ 8, 6, 5, 4, 2, 1 ]  } ) => 'A011698',
    join(';', @{ [ 8, 7, 5, 1 ]        } ) => 'A011699',
    join(';', @{ [ 8, 7, 3, 1 ]        } ) => 'A011700',
    join(';', @{ [ 8, 5, 4, 3, 2, 1 ]  } ) => 'A011701',
    join(';', @{ [ 8, 7, 5, 4, 3, 2 ]  } ) => 'A011702',
    join(';', @{ [ 8, 7, 6, 4, 3, 2 ]  } ) => 'A011703',
    join(';', @{ [ 8, 6, 3, 2 ]        } ) => 'A011704',
    join(';', @{ [ 8, 7, 3, 2 ]        } ) => 'A011705',
    join(';', @{ [ 8, 6, 5, 2 ]        } ) => 'A011706',
    join(';', @{ [ 8, 7, 6, 4, 2, 1 ]  } ) => 'A011707',
    join(';', @{ [ 8, 7, 6, 3, 2, 1 ]  } ) => 'A011708',
    join(';', @{ [ 8, 7, 2, 1 ]        } ) => 'A011709',
    join(';', @{ [ 8, 7, 6, 1 ]        } ) => 'A011710',
    join(';', @{ [ 8, 7, 6, 5, 2, 1 ]  } ) => 'A011711',
    join(';', @{ [ 8, 7, 5, 4 ]        } ) => 'A011712',
    join(';', @{ [ 8, 6, 5, 1 ]        } ) => 'A011713',
    join(';', @{ [ 8, 4, 3, 1 ]        } ) => 'A011714',
    join(';', @{ [ 8, 6, 5, 4 ]        } ) => 'A011715',
    join(';', @{ [ 8, 7, 6, 5, 4, 1 ]  } ) => 'A011716',
    join(';', @{ [ 8, 5, 3, 2 ]        } ) => 'A011717',
    join(';', @{ [ 8, 6, 5, 4, 3, 1 ]  } ) => 'A011718',
    join(';', @{ [ 8, 5, 3, 1 ]        } ) => 'A011719',
    join(';', @{ [ 8, 7, 4, 3, 2, 1 ]  } ) => 'A011720',
    join(';', @{ [ 8, 6, 5, 3 ]        } ) => 'A011721',
    join(';', @{ [ 9, 4 ]              } ) => 'A011722',
    join(';', @{ [ 10, 3 ]             } ) => 'A011723',
    join(';', @{ [ 11, 2 ]             } ) => 'A011724',
    join(';', @{ [ 12, 7, 4, 3 ]       } ) => 'A011725',
    join(';', @{ [ 13, 4, 3, 1 ]       } ) => 'A011726',
    join(';', @{ [ 14, 12, 11, 1 ]     } ) => 'A011727',
    join(';', @{ [ 15, 1 ]             } ) => 'A011728',
    join(';', @{ [ 16, 5, 3, 2 ]       } ) => 'A011729',
    join(';', @{ [ 17, 3 ]             } ) => 'A011730',
    join(';', @{ [ 18, 7 ]             } ) => 'A011731',
    join(';', @{ [ 19, 6, 5, 1 ]       } ) => 'A011732',
    join(';', @{ [ 20, 3 ]             } ) => 'A011733',
    join(';', @{ [ 21, 2 ]             } ) => 'A011734',
    join(';', @{ [ 22, 1 ]             } ) => 'A011735',
    join(';', @{ [ 23, 5 ]             } ) => 'A011736',
    join(';', @{ [ 24, 4, 3, 1 ]       } ) => 'A011737',
    join(';', @{ [ 25, 3 ]             } ) => 'A011738',
    join(';', @{ [ 26, 8, 7, 1 ]       } ) => 'A011739',
    join(';', @{ [ 27, 8, 7, 1 ]       } ) => 'A011740',
    join(';', @{ [ 28, 3 ]             } ) => 'A011741',
    join(';', @{ [ 29, 2 ]             } ) => 'A011742',
    join(';', @{ [ 30, 16, 15, 1 ]     } ) => 'A011743',
    join(';', @{ [ 31, 3 ]             } ) => 'A011744',
    join(';', @{ [ 32, 28, 27, 1 ]     } ) => 'A011745',
);
sub oeis_anum {
    my $taps = join ';', @{ $_[0]->{taps} };
    return exists $OEIS{$taps} ? $OEIS{$taps} : undef;
}


=back

=head1 THEORY

A pseudorandom binary sequence (PRBS) is the sequence of N unique bits, in this case generated from an LFSR.  Once it generates the N bits, it loops around and repeats that seqence.  While still within the unique N bits, the sequence of N bits shares some properties with a truly random sequence of the same length.  The benefit of this sequence is that, while it shares statistical properites with a random sequence, it is actually deterministic, so is often used to deterministically test hardware or software that requires a data stream that needs pseudorandom properties.

In an LFSR, the polynomial description (like C<x**3 + x**2 + 1>) indicates which bits are "tapped" to create the feedback bit: the taps are the powers of x in the polynomial (3 and 2).  The C<1> is really the C<x**0> term, and isn't a "tap", in the sense that it isn't used for generating the feedback; instead, that is the location where the new feedback bit comes back into the shift register; the C<1> is in all characteristic polynomials, and is implied when creating a new instance of B<Math::PRBS>.

If the largest power of the polynomial is C<k>, there are C<k+1> bits in the register (one for each of the powers C<k..1> and one for the C<x**0 = 1>'s feedback bit).  For any given C<k>, the largest sequence that can be produced is C<N = 2^k - 1>, and that sequence is called a maximum length sequence  or m-sequence; there can be more than one m-sequence for a given C<k>.  One useful feature of an m-sequence is that if you divide it into every possible partial sequence that's C<k> bits long (wraping from N-1 to 0 to make the last few partial sequences also C<k> bits), you will generate every possible combination of C<k> bits (*), except for C<k> zeroes in a row.  For example,

    # x**3 + x**2 + 1 = "1011100"
    "_101_1100 " -> 101
    "1_011_100 " -> 011
    "10_111_00 " -> 111
    "101_110_0 " -> 110
    "1011_100_ " -> 100
    "1_0111_00 " -> 001 (requires wrap to get three digits: 00 from the end, and 1 from the beginning)
    "10_1110_0 " -> 010 (requires wrap to get three digits: 0 from the end, and 10 from the beginning)

The Wikipedia:LFSR article (see L</REFERENCES>) lists some polynomials that create m-sequence for various register sizes, and links to Philip Koopman's complete list up to C<k=64>.

If you want to create try own polynonial to find a long m-sequence, here are some things to consider: 1) the number of taps for the feedback (remembering not to count the feedback bit as a tap) must be even; 2) the entire set of taps must be relatively prime; 3) those two conditions are necesssary, but not sufficient, so you may have to try multiple polynomials to find an m-sequence; 4) keep in mind that the time to compute the period (and thus determine if it's an m-sequence) doubles every time C<k> increases by 1; as the time increases, it makes more sense to look at the complete list up to C<k=64>), and pure-perl is probably tpp wrong language for searching C<kE<gt>64>.

(*) Since a maximum length sequence contains every k-bit combination (except all zeroes), it can be used for verifying that software or hardware behaves properly for every possible sequence of k-bits.

=head1 REFERENCES

=over

=item * Wikipedia:Linear-feedback Shift Register (LFSR) at L<https://en.wikipedia.org/wiki/Linear-feedback_shift_register>

=over

=item * Article includes a list of some L<maximum length polynomials|https://en.wikipedia.org/wiki/Linear-feedback_shift_register#Some_polynomials_for_maximal_LFSRs>

=item * Article links to Philip Koopman's complete list of maximum length polynomials, up to C<k = 64> at L<https://users.ece.cmu.edu/~koopman/lfsr/index.html>

=back

=item * Wikipedia:Pseudorandom Binary Sequence (PRBS) at L<https://en.wikipedia.org/wiki/Pseudorandom_binary_sequence>

=over

=item * The underlying algorithm in B<Math::PRBS> is based on the C code in this article's L<"Practical Implementation"|https://en.wikipedia.org/w/index.php?title=Pseudorandom_binary_sequence&oldid=700999060#Practical_implementation>

=back

=item * Wikipedia:Maximum Length Sequence (m-sequence) at L<https://en.wikipedia.org/wiki/Maximum_length_sequence>

=over

=item * Article describes some of the properties of m-sequences

=back

=back

=head1 AUTHOR

Peter C. Jones C<E<lt>petercj AT cpan DOT orgE<gt>>

Please report any bugs or feature requests thru the web interface at
L<https://github.com/pryrt/Math-PRBS/issues>

=head1 COPYRIGHT

Copyright (C) 2016 Peter C. Jones

=head1 LICENCE

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1;