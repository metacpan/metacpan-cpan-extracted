# Copyright (c) 2010-2019 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

package Math::ModInt::ChineseRemainder;

use 5.006;
use strict;
use warnings;
use Math::ModInt qw(mod);
use overload ();

# ----- class data -----

BEGIN {
    require Exporter;
    our @ISA        = qw(Exporter);
    our @EXPORT_OK  = qw(cr_combine cr_extract);
    our $VERSION    = '0.012';
}

use constant _INITIAL_CACHE_SIZE => 1024;

my $cache_size = _INITIAL_CACHE_SIZE;
my %param_cache = ();           # memoizing param arrayrefs, key "m:n"
my @param_fifo  = ();           # list of up to $cache_size keys

# parameter arrayref:
# [
#   ModInt factor for greater modulus,
#   ModInt factor for smaller modulus,
#   greatest common divisor of moduli
# ]

# ----- private subroutines -----

# extended euclidian algorithm to find modulus-specific parameters
# moduli must be in descending order
sub _calculate_params {
    my ($mod_g, $mod_s) = @_;
    my ($g, $s) = ($mod_g, $mod_s);
    my ($gg, $gs, $sg, $ss) = (1, 0, 0, 1);
    while ($s != 0) {
        my $m = $g % $s;
        my $d = ($g - $m) / $s;
        ($g, $gg, $gs, $s,            $sg,            $ss) =
        ($s, $sg, $ss, $m, $gg - $d * $sg, $gs - $d * $ss);
    }
    $ss = abs $ss;
    $sg = abs $sg;
    my $lcm     =            $mod_g * $sg;
    my $coeff_g =           mod($gs * $sg, $lcm);
    my $coeff_s = $coeff_g->new($gg * $ss);
    return ($coeff_g, $coeff_s, $g);
}

# fetch memoized params or calculate them
# moduli must be in descending order
sub _get_params {
    my ($mod_g, $mod_s) = @_;
    my @params;
    if ($cache_size) {
        my $key = "$mod_g:$mod_s";
        if (exists $param_cache{$key}) {
            @params = @{$param_cache{$key}};
        }
        else {
            @params = _calculate_params($mod_g, $mod_s);
            if (@param_fifo >= $cache_size) {
                delete $param_cache{shift @param_fifo};
            }
            push @param_fifo, $key;
            $param_cache{$key} = \@params;
        }
    }
    else {
        @params = _calculate_params($mod_g, $mod_s);
    }
    return @params;
}

# ----- public subroutines -----

sub cr_combine {
    foreach my $arg (@_) {
        return $arg if $arg->is_undefined;
    }
    my @these = sort { $a->modulus <=> $b->modulus } @_;
    return mod(0, 1) if !@these;
    my $this = pop @these;
    while (@these) {
        my $that = pop @these;
        my ($coeff_this, $coeff_that, $gcd) =
            _get_params($this->modulus, $that->modulus);
        if ($gcd != 1 && $this->residue % $gcd != $that->residue % $gcd) {
            return Math::ModInt->undefined;
        }
        $this =
            $coeff_this * $coeff_this->new($this->residue) +
            $coeff_that * $coeff_that->new($that->residue);
    }
    return $this;
}

sub cr_extract {
    my ($this, $desired_modulus) = @_;
    return Math::ModInt->undefined if $this->is_undefined;
    if (0 != $this->modulus % $desired_modulus) {
        return Math::ModInt->undefined;
    }
    my $residue = $this->residue;
    # make sure residue does not exceed the precision of modulus
    if (!ref $desired_modulus && ref $residue) {
        my $as_number = overload::Method($residue, '0+');
        $residue = ($residue % $desired_modulus)->$as_number;
    }
    return mod($residue, $desired_modulus);
}

sub cache_level {
    return scalar @param_fifo;
}

sub cache_flush {
    %param_cache = ();
    @param_fifo  = ();
    return 0;
}

sub cache_size {
    return $cache_size;
}

sub cache_resize {
    my $size = pop;
    $cache_size = $size;
    if ($cache_size < @param_fifo) {
        delete @param_cache{splice @param_fifo, 0, @param_fifo - $cache_size};
    }
    return $cache_size;
}

1;

__END__

=head1 NAME

Math::ModInt::ChineseRemainder - solving simultaneous integer congruences

=head1 VERSION

This documentation refers to version 0.012 of Math::ModInt::ChineseRemainder.

=head1 SYNOPSIS

  use Math::ModInt qw(mod);
  use Math::ModInt::ChineseRemainder qw(cr_combine cr_extract);

  my $a = mod(42, 127);                      # 42 (mod 127)
  my $b = mod(24, 128);                      # 24 (mod 128)
  my $c = cr_combine($a, $b);                # 2328 (mod 16256)
  my $d = cr_extract($c, 127);               # 42 (mod 127)

=head1 DESCRIPTION

The intersection of two or more integer residue classes is either
empty or another integer residue class modulo the least common
multiple of their moduli.  The Chinese remainder theorem states
that this class exists and is in fact unique if those moduli are
pairwise coprime, and explicit methods are known that will find it.
Some of these methods can be extended to arbitrary moduli, resulting
in general algorithms to solve simultaneous modular integer congruences
or prove them to be unsolvable.

Math::ModInt::ChineseRemainder is a Perl implementation of such a
generalized method.  Like Math::ModInt, it should work for moduli
of any size Math::BigInt can handle.

=head2 Calculations

=over 4

=item I<cr_combine>

The subroutine C<cr_combine> takes a list of Math::ModInt objects
(modints) and returns one modint.  The result will be either the
modint representing the common residue subclass of the given modints,
or the undefined modint if no such residue class exists.  The result
will always be defined if no two moduli have a common divisor greater
than 1.  If defined, the result modulus will be the least common
multiple of all moduli.

=item I<cr_extract>

The subroutine C<cr_extract> is a kind of reverse operation of
C<cr_combine> in that it can extract modints with smaller moduli
from a combined modint.  It takes a Math::ModInt object and a new
modulus, and returns a modint reduced to the new modulus, if that
was a divisor of the original modulus, otherwise the undefined
modint.  In terms of residue classes the returned residue class is
the superset of the original one with the given modulus.

=back

=head2 Precomputation cache management

Some calculations performed by C<cr_combine> are only dependent on
the set of moduli involved.  In order to save time when the same
moduli are used again -- which is a fairly typical use case --,
these intermediate results are stored in a cache for later perusal.
A couple of class methods can be used to inspect or change some
aspects of this caching mechanism.

=over 4

=item I<cache_size>

The class method C<cache_size> returns the current maximal number
of slots the cache is configured to use.

=item I<cache_level>

The class method C<cache_level> returns the actual number of slots
currently in use in the cache.

=item I<cache_flush>

The class method C<cache_flush> removes all items currently in the
cache, releasing the memory used for their storage.  It returns 0.

=item I<cache_resize>

The class method C<cache_resize> configures the maximal number of
slots of the cache as the given value, which it also returns.  If
the new size is less than the number of slots already in use, items
in excess of that number are removed immediately.  If the new size
is zero, caching is altogether disabled.

=back

=head1 EXPORT

By default, nothing is exported into the caller's namespace.  The
subroutines C<cr_combine> and C<cr_extract> can be imported explicitly.

The class methods dealing with cache management must always be
qualified with the class name.

=head1 DIAGNOSTICS

There are no diagnostic messages specific to this module.  Operations
with undefined results return the C<undefined> object unless the
UndefinedResult event is trapped (see Math::ModInt::Event).

=head1 SEE ALSO

=over 4

=item *

L<Math::ModInt>

=item *

L<Math::ModInt::Event>

=item *

The subject "Chinese remainder theorem" in Wikipedia.
L<http://en.wikipedia.org/Chinese_remainder_theorem>

=back

=head1 BUGS AND LIMITATIONS

The current implementation is not rigidly optimized for performance.
It does, however, cache some computed values to speed up repeated
calculations with the same set of moduli.  The interface to inspect
and modify this caching behaviour should not be considered final.

=head1 AUTHOR

Martin Becker, E<lt>becker-cpan-mp@cozap.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2019 Martin Becker, Blaubeuren.

This library is free software; you can distribute it and/or modify it
under the terms of the Artistic License 2.0 (see LICENSE file).

=head1 DISCLAIMER OF WARRANTY

This library is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
