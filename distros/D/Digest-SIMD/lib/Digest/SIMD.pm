package Digest::SIMD;

use strict;
use warnings;
use parent qw(Exporter Digest::base);

use MIME::Base64 ();

our $VERSION = '0.04';
$VERSION = eval $VERSION;

eval {
    require XSLoader;
    XSLoader::load(__PACKAGE__, $VERSION);
    1;
} or do {
    require DynaLoader;
    DynaLoader::bootstrap(__PACKAGE__, $VERSION);
};

our @EXPORT_OK = qw(
    simd_224 simd_224_hex simd_224_base64
    simd_256 simd_256_hex simd_256_base64
    simd_384 simd_384_hex simd_384_base64
    simd_512 simd_512_hex simd_512_base64
);

sub add_bits {
    my ($self, $data, $bits) = @_;
    if (2 == @_) {
        return $self->_add_bits(pack('B*', $data), length $data);
    }
    return $self->_add_bits($data, $bits);
}


1;

__END__

=head1 NAME

Digest::SIMD - Perl interface to the SIMD digest algorithm

=head1 SYNOPSIS

    # Functional interface
    use Digest::SIMD qw(simd_256 simd_256_hex simd_256_base64);

    $digest = simd_256($data);
    $digest = simd_256_hex($data);
    $digest = simd_256_base64($data);

    # Object-oriented interface
    use Digest::SIMD;

    $ctx = Digest::SIMD->new(256);

    $ctx->add($data);
    $ctx->addfile(*FILE);

    $digest = $ctx->digest;
    $digest = $ctx->hexdigest;
    $digest = $ctx->b64digest;

=head1 DESCRIPTION

The C<Digest::SIMD> module provides an interface to the SIMD message
digest algorithm. SIMD is a candidate in the NIST SHA-3 competition.

This interface follows the conventions set forth by the C<Digest> module.

=head1 FUNCTIONS

The following functions are provided by the C<Digest::SIMD> module. None
of these functions are exported by default.

=head2 simd_224($data, ...)

=head2 simd_256($data, ...)

=head2 simd_384($data, ...)

=head2 simd_512($data, ...)

Logically joins the arguments into a single string, and returns its SIMD
digest encoded as a binary string.

=head2 simd_224_hex($data, ...)

=head2 simd_256_hex($data, ...)

=head2 simd_384_hex($data, ...)

=head2 simd_512_hex($data, ...)

Logically joins the arguments into a single string, and returns its SIMD
digest encoded as a hexadecimal string.

=head2 simd_224_base64($data, ...)

=head2 simd_256_base64($data, ...)

=head2 simd_384_base64($data, ...)

=head2 simd_512_base64($data, ...)

Logically joins the arguments into a single string, and returns its SIMD
digest encoded as a Base64 string, without any trailing padding.

=head1 METHODS

The object-oriented interface to C<Digest::SIMD> is identical to that
described by C<Digest>, except for the following:

=head2 new

    $simd = Digest::SIMD->new(256)

The constructor requires the algorithm to be specified. It must be one of:
224, 256, 384, 512.

=head2 algorithm

=head2 hashsize

Returns the algorithm used by the object.

=head1 SEE ALSO

L<Digest>

L<Task::Digest>

L<http://www.di.ens.fr/~leurent/simd.html>

L<http://en.wikipedia.org/wiki/NIST_hash_function_competition>

L<http://www.saphir2.com/sphlib/>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Digest-SIMD>. I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Digest::SIMD

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/digest-simd>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Digest-SIMD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Digest-SIMD>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Digest-SIMD>

=item * Search CPAN

L<http://search.cpan.org/dist/Digest-SIMD/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
