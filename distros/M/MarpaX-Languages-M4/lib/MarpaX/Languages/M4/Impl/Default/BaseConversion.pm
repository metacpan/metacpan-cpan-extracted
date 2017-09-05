use Moops;

# PODNAME: MarpaX::Languages::M4::Impl::Default::BaseConversion

# ABSTRACT: Base conversion util class

class MarpaX::Languages::M4::Impl::Default::BaseConversion {
    use Types::Common::Numeric -all;
    use Bit::Vector;
    use Carp qw/croak/;

    our $VERSION = '0.020'; # VERSION

    our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

    #
    # We handle bases [0..31].
    #

    #
    # Eval: constants for radix and the grammar
    #
    our @nums = ( 0 .. 9, 'a' .. 'z' );
    our %nums = map { $nums[$_] => $_ } 0 .. $#nums;

    # Adaptation of http://www.perlmonks.org/?node_id=27148
    method bitvector_fr_base (ClassName $class: PositiveInt $bits, PositiveInt|Undef $base, Str $input, Bool $binary?) {
                               #
         # Per def the caller is responsabible to make sure input can contain only [0..9a-zA-Z].
         # Thus it is safe to call lc()
         #
         # Note that we use $bits + 1, because Bit::Vector->Multiply() treats its arguments
         # as SIGNED.
         # Therefore we cannot reach the case where all bits would be setted to 1.
         # We resize at the very end.
         #
         #
         # Radix 1, i.e. the unary numeral system is a special case. GNU M4 say that the
         # '1' is used to represent it, leading zeroes being ignored, and all remaining digits
         # must be 1.
         # The "value" is then just a count of them (== unary system).
         #

        if ($binary) {
            return Bit::Vector->new_Bin( $bits, $input );
        }
        if ( $base == 1 ) {
            $input =~ s/^0*//;
            if ( $input =~ /[^1]/ ) {
                croak
                    "radix 1 imposes eventual leading zeroes followed by zero or more '1' character(s)";
            }
            return Bit::Vector->new_Dec( $bits, length($input) );
        }

        my $b = Bit::Vector->new_Dec( $bits + 1, $base );
        my $v = Bit::Vector->new( $bits + 1 );
        my $i = 0;
        for ( lc($input) =~ /./g ) {
            ++$i;
            {
                my $s = $v->Shadow;
                $s->Multiply( $v, $b );
                $v = $s;
            }
            my $num = $nums{$_};
            if ( $num >= $base ) {
                my $range = '';
                if ( $base <= 10 ) {
                    $range = '[0-' . ( $base - 1 ) . ']';
                }
                else {
                    $range = '[0-9';
                    if ( $base == 11 ) {
                        $range .= 'a] (case independant)';
                    }
                    else {
                        $range
                            .= 'a-'
                            . $nums[ $base - 1 ]
                            . '] (case independant)';
                    }
                }
                croak "character '$_' is not in the range $range";
            }
            {
                my $s = $v->Shadow;
                my $n = Bit::Vector->new_Dec( $bits + 1, $num );
                $s->add( $v, $n, 0 );
                $v = $s;
            }
        }
        $v->Resize($bits);
        return $v;
    }

    method bitvector_to_base (ClassName $class: PositiveInt $base, ConsumerOf['Bit::Vector'] $v, Int $min --> Str) {

        my $b = Bit::Vector->new_Dec( $v->Size(), $base );
        $v = $v->Clone();
        #
        # Per construction $base is in the range [1..61]
        #
        my $rep    = '';
        my $s      = '';
        my $signed = ( $v->Sign() < 0 ) ? true : false;
        my $abs;
        if ($signed) {
            $abs = $v->Shadow;
            $abs->Negate($v);
        }
        else {
            $abs = $v;
        }

        if ( $base == 1 ) {
            my $rep = '1' x $abs->to_Dec();
            #
            # Adapt to width
            #
            if ( length($rep) < $min ) {
                $rep = ( '0' x ( $min - length($rep) ) ) . $rep;
            }
            if ($signed) {
                $rep = "-$rep";
            }
            return $rep;
        }

        while ( $abs->to_Dec() ne "0" ) {
            my $mod;
            {
                my $s = $abs->Shadow;
                $abs->Shadow->Divide( $abs, $b, $s );
                $mod = $s;
            }
            #
            # Why abs() ? Because when $v is equal to 2^(n-1), number remains the same.
            #
            $s = $nums[ abs($mod->to_Dec()) ] . $s;
            {
                my $s = $abs->Shadow;
                $s->Divide( $abs, $b, $abs->Shadow );
                $abs = $s;
            }
        }
        if ($signed) {
            $s = "-$s";
        }
        if ( substr( $s, 0, 1 ) eq '-' ) {
            $rep .= '-';
            substr( $s, 0, 1, '' );
        }
        for ( $min -= length($s); --$min >= 0; ) {
            $rep .= '0';
        }
        $rep .= $s;

        return $rep;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::M4::Impl::Default::BaseConversion - Base conversion util class

=head1 VERSION

version 0.020

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
