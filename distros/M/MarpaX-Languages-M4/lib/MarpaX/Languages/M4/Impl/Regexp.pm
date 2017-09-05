use Moops;

# PODNAME: MarpaX::Languages::M4::Impl::Regexp

# ABSTRACT: M4 Regexp generic implementation

class MarpaX::Languages::M4::Impl::Regexp {

    our $VERSION = '0.020'; # VERSION

    our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

    use MarpaX::Languages::M4::Role::Regexp;
    use MarpaX::Languages::M4::Type::Regexp -all;
    use MooX::HandlesVia;
    use Types::Common::Numeric -all;

    has _regexp_type => (
        is  => 'rwp',
        isa => M4RegexpType
    );

    has _regexp => (
        is  => 'rwp',
        isa => RegexpRef
    );

    has regexp_lpos => (
        is          => 'rwp',
        isa         => ArrayRef,
        handles_via => 'Array',
        handles     => {
            'regexp_lpos_count' => 'count',
            'regexp_lpos_get'   => 'get'
        }
    );

    has regexp_rpos => (
        is          => 'rwp',
        isa         => ArrayRef,
        handles_via => 'Array',
        handles     => {
            'regexp_rpos_count' => 'count',
            'regexp_rpos_get'   => 'get'
        }
    );

    method regexp_compile (ConsumerOf['MarpaX::Languages::M4::Role::Impl'] $impl, M4RegexpType $regexpType, Str $regexpString --> Bool) {

        my $regexp;

        my $hasPreviousRegcomp = exists( $^H{regcomp} );
        my $previousRegcomp = $hasPreviousRegcomp ? $^H{regcomp} : undef;

        try {
            #
            # Some versions of perl warn, some others don't -;
            # We are only interested by real failures.
            #
            no warnings;
            if ( $regexpType eq 'perl' ) {
                #
                # Just make sure this really is perl
                #
                delete( $^H{regcomp} );
                #
                # regexp can be empty and perl have a very special
                # behaviour in this case. Avoid empty regexp.
                #
                $regexp = qr/$regexpString(?#)/sm;
            }
            else {
                use re::engine::GNU 0.024;
                $regexp = qr/$regexpString/sm;
                no re::engine::GNU;
            }

        }
        catch {
            $impl->logger_error( '%s: %s',
                $impl->impl_quote($regexpString), $_ );
        };

        $hasPreviousRegcomp
            ? $^H{regcomp}
            = $previousRegcomp
            : delete( $^H{regcomp} );

        if ( defined($regexp) ) {
            $self->_set__regexp($regexp);
            $self->_set__regexp_type($regexpType);
            return true;
        }
        else {
            return false;
        }
    }

    #
    # Return value is:
    #  -2 if failure (the engine croaked)
    #  -1 if match failed
    # >=0 Position where it matches
    #
    method regexp_exec (ConsumerOf['MarpaX::Languages::M4::Role::Impl'] $impl, Str $string, PositiveOrZeroInt $pos? --> Int) {

        pos($string) = $pos;    # undef is ok
        my $rc = -1;

        #
        # Just make sure this really is perl
        #
        my $hasPreviousRegcomp = exists( $^H{regcomp} );
        my $previousRegcomp = $hasPreviousRegcomp ? $^H{regcomp} : undef;

        #
        # Note: this looks like duplicated code, and it is.
        # But this cannot be avoided because $-/$+ are
        # lexically scoped, and our scope depend on the engine
        #
        try {
            #
            # Some versions of perl warn, some others don't -;
            # We are only interested by real failures.
            #
            no warnings;
            my $regexp = $self->_regexp;
            if ( $self->_regexp_type eq 'perl' ) {
                #
                # Just make sure this really is perl
                #
                delete( $^H{regcomp} );
                #
                # Execute perl engine
                #
                if ( $string =~ m/$regexp/gc ) {
                    #
                    # From profiling point of view this is one of the deepests
                    # method, affecting everything. So we want to have no
                    # penalty whatsoever.
                    #
                    # my @lpos = ();
                    # my @rpos = ();
                    # map { ( $lpos[$_], $rpos[$_] ) = ( $-[$_], $+[$_] ) }
                    #     ( 0 .. $#- );
                    #
                    # $self->_set_regexp_lpos( \@lpos );
                    # $self->_set_regexp_rpos( \@rpos );
                    # $rc = $self->regexp_lpos_get(0);

                    $self->{regexp_lpos} = [ @- ];
                    $self->{regexp_rpos} = [ @+ ];
                    $rc = $-[0];
                }
            }
            else {
                use re::engine::GNU 0.024;
                #
                # Execute re::engine::GNU engine
                #
                if ( $string =~ m/$regexp/gc ) {
                    #
                    # Same remark as before
                    #
                    # my @lpos = ();
                    # my @rpos = ();
                    # map { ( $lpos[$_], $rpos[$_] ) = ( $-[$_], $+[$_] ) }
                    #     ( 0 .. $#- );
                    #
                    # $self->_set_regexp_lpos( \@lpos );
                    # $self->_set_regexp_rpos( \@rpos );
                    # $rc = $self->regexp_lpos_get(0);

                    $self->{regexp_lpos} = [ @- ];
                    $self->{regexp_rpos} = [ @+ ];
                    $rc = $-[0];
                }
                no re::engine::GNU;
            }
        }
        catch {
            my $regexp = $self->_regexp;
            $impl->logger_error( '%s =~ %s: %s', $impl->impl_quote($string),
                "$regexp", $_ );
            $rc = -2;
        };

        $hasPreviousRegcomp
            ? $^H{regcomp}
            = $previousRegcomp
            : delete( $^H{regcomp} );

        return $rc;
    }

    #
    # A perl version of GNU M4's internal
    # substitute routine
    #
    method regexp_substitute (ConsumerOf['MarpaX::Languages::M4::Role::Impl'] $impl, Str $victim, Str $repl --> Str) {
        my $rc         = '';
        my $replPos    = 0;
        my $maxReplPos = length($repl) - 1;
        my $maxIndice  = $self->regexp_lpos_count - 1;
        my %warned     = ();

        while ( $replPos <= $maxReplPos ) {
            my $backslashPos = index( $repl, '\\', $replPos );
            if ( $backslashPos < 0 ) {
                $rc .= substr( $repl, $replPos );
                last;
            }
            $rc .= substr( $repl, $replPos, $backslashPos - $replPos );
            $replPos = $backslashPos;
            my $ch = substr( $repl, ++$replPos, 1 );
            if ( $replPos > $maxReplPos ) {
                $impl->logger_warn( 'trailing %s ignored in replacement',
                    '\\' );
                $warned{undef} = 1;
                last;
            }
            elsif ( $ch eq '0' || $ch eq '&' ) {
                if ( $ch eq '0' ) {
                    if ( !$warned{$ch} ) {
                        $impl->logger_warn('\\0 should be replaced by \\&');
                        $warned{$ch} = 1;
                    }
                }
                $rc .= substr(
                    $victim,
                    $self->regexp_lpos_get(0),
                    $self->regexp_rpos_get(0) - $self->regexp_lpos_get(0)
                );
                ++$replPos;
            }
            elsif ( $ch =~ /[1-9]/ ) {
                if ( $maxIndice < $ch ) {
                    if ( !$warned{$ch} ) {
                        $impl->logger_warn( 'sub-expression %d not present',
                            $ch );
                        $warned{$ch} = 1;
                    }
                }
                else {
                    my $rpos = $self->regexp_rpos_get($ch);
                    if ( $rpos > 0 ) {
                        $rc .= substr( $victim, $self->regexp_lpos_get($ch),
                                  $self->regexp_rpos_get($ch)
                                - $self->regexp_lpos_get($ch) );
                    }
                }
                ++$replPos;
            }
            else {
                $rc .= $ch;
                ++$replPos;
            }
        }

        return $rc;
    }

    with 'MarpaX::Languages::M4::Role::Regexp';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::M4::Impl::Regexp - M4 Regexp generic implementation

=head1 VERSION

version 0.020

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
