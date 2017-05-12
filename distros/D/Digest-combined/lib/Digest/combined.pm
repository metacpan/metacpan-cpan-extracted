### combined.pm --- Digest::combined implementation  -*- Perl -*-
## See below for the POD documentation.

### Ivan Shmakov, Gisle Aas, 2012
## This code is in the public domain.

### Code:

package Digest::combined;

use strict;
use base 'Digest::base';
use vars qw ($VERSION);

$VERSION = "0.1";

require Digest;

sub new {
    my $class = shift;
    my $self
        = bless [ map {
                      Digest->new (ref ($_) ? @$_ : $_)
                          or die ()
                  } @_ ], $class;
    return $self;
}

sub reset {
    my $self = shift;
    for (@$self) {
        $_->reset;
    }
}

sub clone {
    my $self = shift;
    bless [ map { $_->clone or die () } @$self ], ref ($self);
}

sub add {
    my $self = shift;
    for (@$self) { $_->add (@_); }
}

sub digests {
    my $self = shift;
    die unless wantarray;
    map $_->digest, @$self;
}

sub digest {
    my $self = shift;
    my $separator = shift;
    $separator = ""
        unless (defined ($separator));
    return join ($separator, $self->digests);
}

1;

__END__

=head1 NAME

Digest::combined E<mdash> Calculate multiple message digests
simultaneously

=head1 SYNOPSIS

  my $combined
    = Digest::combined->new ("Algo-1", [ $algo_2, @args_2 ], ...);
  my $debian_digests
    = Digest::combined->new (qw (SHA-256 SHA-1 MD5));

=head1 DESCRIPTION

Certain catalogues and protocols out there allow (or require) one to
list several digests for a single file (or, rather, an octet sequence),
provided that these are of different E<ldquo>kinds.E<rdquo> Consider,
S<e. g.>, the C<magnet:> URI schema, or Debian's
E<ldquo>PackagesZ<>E<rdquo> database:

    Package: beep
    ...
    Filename: pool/main/b/beep/beep_1.2.2-22_amd64.deb
    Size: 24036
    MD5sum: dec6eb5a0eb38f4ac85e24d653c01916
    SHA1: 15df36acc29d696c91cf432986e3bbd99761eada
    SHA256: 869fc8d7d8e3d0cba191ea430e8a32426cc29efeb54e0b55af49c3fea90cddf0

The C<Digest::combined> module is intended to provide a simple and
convenient interface for such a task.

=head1 INTERFACE

=over 4

=item C<< my $ctx = Digest::combined->new ($algo_1, ...); >>

Construct and return an object encapsulating the state of all the
message digest algorithms requested.

Each of the algorithms (C<$algo_1>, etc.) is specified either as scalar,
which is passed unaltered to C<Digest->new ()>, or as a reference to the
list of arguments to be passed to C<Digest->new ()>.

Please note that thanks to the magic of the latter, the following
contexts are essentially equivalent:

    my $c_1
        = Digest::combined->new (qw (SHA-256 SHA-1 MD5))
        or die ();

    my $c_2
        = Digest::combined->new (["SHA", 256], ["SHA", 1], "MD5")
        or die ();

Note also that the current implementation makes this constructor
E<ldquo>safeZ<>E<rdquo> in that it either succeeds or raises an
exception (S<i. e.>, I<dies>.)  However, the later versions of the code
may choose to return C<undef> in the case of failure instead.

=item C<< $ctx->add ($data); >>

=item C<< $ctx->add ($chunk_1, $chunk_2, ...); >>

=item C<< $ctx->clone (); >>

=item C<< my $digest = $ctx->digest (); >>

=item C<< my $digest = $ctx->digest ($delimiter); >>

=item C<< $ctx->reset (); >>

These method behave just like their counterparts for individual message
digests.  Namely, they append to the message the digest is calculated
for, create a copy of the message digest algorithms' state, return
(I<destructively>) the concatenated calculated binary digest for the
message, and reset the state of all the message digest algorithms
combined within the context, respectively.  (Please refer to the
L<Digest> module documentation for the details.)

The C<add>, C<digest>, and C<reset> methods assume that the respective
methods for all the algorithms combined within the context always
succeed, and always succeed in turn.

Note that the current implementation makes the C<clone> method
E<ldquo>safeZ<>E<rdquo> in that it either succeeds or raises an
exception (S<i. e.>, I<dies>.)  However, the later versions of the code
may choose to return C<undef> in the case of failure instead.

=item C<< my @digests = $ctx->digests (); >>

Return (I<destructively>) the individual calculated binary digests for
the message.

This method assumes that the C<digest> method for all the algorithms
combined within the context always succeed, and always succeeds in turn.

=head1 SEE ALSO

L<Digest>

L<http://en.wikipedia.org/wiki/Cryptographic_hash_function>

=head1 AUTHOR

Ivan Shmakov <oneingray@gmail.com>

Based on the code suggested by Gisle Aas <gisle@aas.no>
(L<CPAN RT ticket #76044|https://rt.cpan.org/Public/Bug/Display.html?id=76044>.)

The Digest::combined code is in the public domain.

=cut

### Emacs trailer
## Local variables:
## coding: us-ascii
## fill-column: 72
## indent-tabs-mode: nil
## ispell-local-dictionary: "american"
## End:
### combined.pm ends here
