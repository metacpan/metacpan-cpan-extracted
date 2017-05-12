package Math::Prime::TiedArray;

use warnings;
use strict;
use Carp;

use base 'Tie::Array';

=head1 NAME

Math::Prime::TiedArray - Simulate an infinite array of prime numbers

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    use Math::Prime::TiedArray;
    tie my @primes, "Math::Prime::TiedArray";

=head1 DESCRIPTION

Allows access to an array of prime numbers, that will be extended as-needed:

    use Math::Prime::TiedArray;

    my @primes;
    tie @primes, "Math::Prime::TiedArray";

    # print the first 100 primes:
    print join ", ", @primes[0..99];

    # print the 200th prime:
    print $primes[199];

    # print all the primes smaller than 500
    while ((my $prime = shift @primes) < 500) {
      print "$prime, ";
    }

=head1 OPTIONS

=head2 precompute => number (default: 1000)

Pre-calculate all primes smaller than 10,000:

    my @primes;
    tie @primes, "Math::Prime::TiedArray", precompute => 10_000;

=head2 cache => path

Use a persistant cache:

    my @primes;
    tie @primes, "Math::Prime::TiedArray", cache => "/path/to/cache.dbm"

=head2 extend_step => number (default: 10)

How many new primes should be calculated when the cache runs out.    

=head2 extend_ceiling => number

Set a limit, triggering an exception (croak) if an attempt is made to find a
prime larger than the ceiling.

=head2 debug => level (defualt: 0)

    Output debug messages:
    0 - none
    1 - progress updates for atkin
    2 - prime calculations
    3 - tie API
    4 - internal progress for atkin

=cut

# Called by: tie @array, "Math::Prime::TiedArray", option => value, options => value
sub TIEARRAY {
    my ( $class, %options ) = @_;

    my $self = { _options => \%options || {}, };

    $self = bless $self, $class;

    $self->_verify_options;
    $self->_init;

    return $self;
}

# retrieve the nth prime, calculating it if needed
sub FETCH {
    my ( $self, $idx ) = @_;
    warn "FETCH(@_)\n" if $self->{_options}{debug} > 2;

    if ( $idx + 1 > $self->{_cache_size} ) {
        $self->EXTEND( $idx + 1 );
    }

    return $self->{_cache}[ $idx + 1 ];
}

# report how many primes have been calculated (scalar @array)
sub FETCHSIZE {
    my ($self) = @_;
    warn "FETCHSIZE(@_) @{$self->{_cache}}\n" if $self->{_options}{debug} > 2;

    return $self->{_cache_size};
}

# we don't allow modifying the list of primes
sub STORE     { croak "Can't modify the list of primes!" }
sub STORESIZE { croak "Can't modify the list of primes!" }

# pretend we allow to shift the next prime, but don't actually modify the array
sub SHIFT {
    my ($self) = @_;
    warn "SHIFT(@_)\n" if $self->{_options}{debug} > 2;

    return $self->FETCH( $self->{_shift_pointer}++ );
}

# need to calculate more primes
sub EXTEND {
    my ( $self, $count ) = @_;
    warn "EXTEND(@_)\n" if $self->{_options}{debug} > 2;

    return if $count <= $self->{_cache_size};

    # we can't be sure what we need to raise the celing to, but we can guess
    # pi(x) < x/(ln(x)-4) for x >= 55
    my $needed = $self->{_options}{extend_step};

    # now that we have an estimate of what the new limit should be, let's try it
    # and if we fail, try harder.
    while ( $self->{_cache_size} < $count ) {
        my $new_limit = $self->{_cache_size} + $needed;
        $new_limit = 55 if ( $new_limit < 55 );
        $new_limit = int( $new_limit / ( log($new_limit) - 4 ) );
        $self->_atkin($new_limit);
        $needed *= 2;
    }
}

# when going out of scope, clean up
sub DESTROY {
    my ($self) = @_;
    warn "DESTROY(@_)\n" if $self->{_options}{debug} > 2;

    if ( $self->{_options}{cache} ) {
        untie $self->{_cache}
          or carp "Failed to untie $self->{_options}{cache}: $!";
    }
}

# verify the options given are known, and are not insane
sub _verify_options {
    my ($self) = @_;

    # reset each iterator
    keys %{ $self->{_options} };
    while ( my ( $key, $value ) = each %{ $self->{_options} } ) {
        if ( $key eq 'precompute' ) {
            carp 'precompute no given a positive integer!'
              unless $value =~ /^\d+$/
              and $value > 0;
        }
        elsif ( $key eq 'cache' ) {
            carp 'cache not writable!' if -e $value and not -w $value;
        }
        elsif ( $key eq 'debug' ) {
            carp 'ignoring invalid debug value!' if $value =~ /\D/;
        }
        elsif ( $key eq 'extend_step' ) {
            carp 'ignoring invalid extend_step value!' if $value =~ /\D/;
        }
        elsif ( $key eq 'extend_ceiling' ) {
            carp 'ignoring invalid extend_ceiling value!' if $value =~ /\D/;
        }
        else {
            carp "ignoring unknown option '$key'";
        }
    }
}

# if needed, connect to the cache and/or precompute values
sub _init {
    my ($self) = @_;

    # default values
    $self->{_options}{debug}       ||= 0;
    $self->{_options}{precompute}  ||= 1000;
    $self->{_options}{extend_step} ||= 10;

    if ( $self->{_options}{cache} ) {
        require DB_File;
        DB_File->import;

        my @cache;
        tie @cache, "DB_File", $self->{_options}{cache},
          &DB_File::O_CREAT | &DB_File::O_RDWR, 0644, $DB_File::DB_RECNO
          or carp "Failed to tie $self->{_cache}: $!";
        $self->{_cache} = \@cache;

        # sanity check a loaded cache, or init an empty cache
        unless ($self->{_cache}
            and ref $self->{_cache} eq 'ARRAY'
            and defined $self->{_cache}[1]
            and $self->{_cache}[1] == 2
            and defined $self->{_cache}[2]
            and $self->{_cache}[2] == 3 )
        {
            carp "invalid or empty cache - initializing...";
            untie @{ $self->{_cache} };
            unlink $self->{_cache};

            tie @cache, "DB_File", $self->{_options}{cache},
              &DB_File::O_CREAT | &DB_File::O_RDWR, 0644, $DB_File::DB_RECNO
              or carp "Failed to tie $self->{_cache}: $!";
            $self->{_cache} = \@cache;

            $self->{_cache}[0] = 3;
            $self->{_cache}[1] = 2;
            $self->{_cache}[2] = 3;
        }
    }
    else {
        $self->{_cache} = [ 3, 2, 3 ];
    }

    # record the largest prime found so far
    $self->{_max_prime} = $self->{_cache}[-1];

    # and store/restore the largest number we counted to
    $self->{_limit} = $self->{_cache}[0];

    # and how many primes we have
    $self->{_cache_size} = $#{ $self->{_cache} };

    # prepopulate the sieve with the known primes
    $self->{_sieve} =
      { map { $_ => 1 } @{ $self->{_cache} }[ 1 .. $self->{_cache_size} ] };

    if (    $self->{_options}{extend_ceiling}
        and $self->{_options}{extend_ceiling} < 7500 )
    {
        $self->{_options}{precompute} = $self->{_options}{extend_ceiling};
    }

    if (    $self->{_options}{precompute}
        and $self->{_options}{precompute} > $self->{_max_prime} )
    {
        $self->_atkin( $self->{_options}{precompute} );
    }

    # a pointer to the next prime to be read by shift
    $self->{_shift_pointer} = 0;
}

# implement the sieve of Atkin - useful to calculating all the primes up to a
# given number: http://en.wikipedia.org/wiki/Sieve_of_Atkin
sub _atkin {
    my ( $self, $limit ) = @_;
    warn "DEBUG2: Calculating primes up to $limit\n"
      if $self->{_options}{debug} > 1;

    return if $limit <= $self->{_limit};

    croak "Cannot extend beyond $self->{_options}{extend_ceiling}!"
      if $self->{_options}{extend_ceiling}
      and $limit > $self->{_options}{extend_ceiling};

    # put in candidate primes:
    # integers which have an odd number of representations by certain
    # quadratic forms

    my $sqrt     = sqrt($limit);
    my $progress = 0;
    foreach my $x ( 1 .. $sqrt ) {
        if ( $self->{_options}{debug} > 0 ) {
            my $x_p = int( $x / $sqrt * 100 / 3 );
            if ( $x_p > $progress ) {
                warn sprintf "DEBUG1: ($limit) %d%%\n", $x_p;
                $progress = $x_p;
            }
        }

        foreach my $y ( 1 .. $sqrt ) {

            warn "DEBUG4: $x, $y\n" if $self->{_options}{debug} > 3;
            my $n = 3 * $x**2 - $y**2;
            if (    $n > $self->{_max_prime}
                and $x > $y
                and $n <= $limit
                and $n % 12 == 11 )
            {
                $self->{_sieve}{$n} = not $self->{_sieve}{$n};
            }

            $n = 3 * $x**2 + $y**2;
            if ( $n > $self->{_max_prime} and $n <= $limit and $n % 12 == 7 ) {
                $self->{_sieve}{$n} = not $self->{_sieve}{$n};
            }

            $n = 4 * $x**2 + $y**2;
            if (    $n > $self->{_max_prime}
                and $n <= $limit
                and ( $n % 12 == 1 or $n % 12 == 5 ) )
            {
                $self->{_sieve}{$n} = not $self->{_sieve}{$n};
            }
        }
    }

    # eliminate composites by sieving
    foreach my $n ( 5 .. $sqrt ) {
        if ( $self->{_options}{debug} > 0 ) {
            my $x_p = 33 + int( $n / $sqrt * 100 / 3 );
            if ( $x_p > $progress ) {
                warn sprintf "DEBUG1: ($limit) %d%%\n", $x_p;
                $progress = $x_p;
            }
        }

        next unless $self->{_sieve}{$n};
        warn "DEBUG4: eliminating multiples of $n**2\n"
          if $self->{_options}{debug} > 3;

        my $k = int($self->{_max_prime}/$n**2) * $n**2;
        while ( $k <= $limit ) {
            $self->{_sieve}{$k} = 0;
            $k += $n**2;
        }
        warn "DEBUG4: done\n" if $self->{_options}{debug} > 3;
    }

    # save the found primes in our cache
    foreach my $n ( 1+$self->{_max_prime} .. $limit ) {
        if ( $self->{_options}{debug} > 0 ) {
            my $x_p = 66 + int( $n / $limit * 100 / 3 );
            if ( $x_p > $progress ) {
                warn sprintf "DEBUG1: ($limit) %d%%\n", $x_p;
                $progress = $x_p;
            }
        }

        next unless $self->{_sieve}{$n};
        warn "DEBUG3: caching new prime $n\n" if $self->{_options}{debug} > 2;
        push @{ $self->{_cache} }, $n;
    }

    $self->{_max_prime} = $self->{_cache}[-1];
    $self->{_cache}[0] = $self->{_limit} = $limit;
    $self->{_cache_size} = $#{ $self->{_cache} };
}

=head1 AUTHOR

Dan Boger, C<< <cpan at peeron.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-math-prime-tiedarray at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Prime-TiedArray>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Prime::TiedArray

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-Prime-TiedArray>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-Prime-TiedArray>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Prime-TiedArray>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-Prime-TiedArray>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2007 Dan Boger, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of Math::Prime::TiedArray
