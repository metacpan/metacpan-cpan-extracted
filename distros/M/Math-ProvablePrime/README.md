# NAME

Math::ProvablePrime - Generate a provable prime number, in pure Perl

# SYNOPSIS

    #The returned prime will be 512 bits long
    #(i.e., the first and last bits will be 1)
    #and will be an instance of Math::BigInt.
    #
    my $prime = Math::ProvablePrime::find(512);

# DISCUSSION

There’s not much more to say: this module returns a prime number of a
specified bit length.

The specific algorithm is Maurer’s algorithm. The logic in this module
is ported from a Python implementation first posted at
[http://s13.zetaboards.com/Crypto/topic/7234475/1/](http://s13.zetaboards.com/Crypto/topic/7234475/1/).

# PLANNED DEPRECATION

This module will be deprecated once [Math::Prime::Util](https://metacpan.org/pod/Math::Prime::Util) is installable without
a compiler. (There is pure-Perl logic in that distribution; the install
logic just needs to be tweaked.) [Math::Prime::Util](https://metacpan.org/pod/Math::Prime::Util) is faster and has a
maintainer who understands the mathematics behind all of this much better
than I do.

[Math::ProvablePrime](https://metacpan.org/pod/Math::ProvablePrime) is too slow for its
intended purpose (i.e., to provide pure-Perl primes), and really, I don’t have
the mathematical background that would justify its continued maintenance.

If you have any objection, please let me know.

# SPEED

This module is too slow for practical use in pure Perl. If a recognized
alternate backend for [Math::BigInt](https://metacpan.org/pod/Math::BigInt) is available, though, then this module
will use that to achieve reasonable (though still unimpressive) speed.

Recognized alternate backends are (in order of preference):

- [Math::BigInt::GMPz](https://metacpan.org/pod/Math::BigInt::GMPz)
- [Math::BigInt::GMP](https://metacpan.org/pod/Math::BigInt::GMP)
- [Math::BigInt::LTM](https://metacpan.org/pod/Math::BigInt::LTM)
- [Math::BigInt::Pari](https://metacpan.org/pod/Math::BigInt::Pari)

[Math::BigInt::BitVect](https://metacpan.org/pod/Math::BigInt::BitVect) and [Math::BigInt::FastCalc](https://metacpan.org/pod/Math::BigInt::FastCalc) are also
recognized, but these don’t seem to achieve speed that’s practical
for use in, e.g., creation of RSA keys.

# LICENSE

This module is released under the same license as Perl.
