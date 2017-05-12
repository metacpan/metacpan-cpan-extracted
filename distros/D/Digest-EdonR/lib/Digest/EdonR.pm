package Digest::EdonR;

use strict;
use warnings;
use parent qw(Exporter Digest::base);

our $VERSION = '0.05';
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
    edonr_224 edonr_224_hex edonr_224_base64
    edonr_256 edonr_256_hex edonr_256_base64
    edonr_384 edonr_384_hex edonr_384_base64
    edonr_512 edonr_512_hex edonr_512_base64
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

Digest::EdonR - Perl interface to the Edon-R digest algorithm

=head1 SYNOPSIS

    # Functional interface
    use Digest::EdonR qw(edonr_256 edonr_256_hex edonr_256_base64);

    $digest = edonr_256($data);
    $digest = edonr_256_hex($data);
    $digest = edonr_256_base64($data);

    # Object-oriented interface
    use Digest::EdonR;

    $ctx = Digest::EdonR->new(256);

    $ctx->add($data);
    $ctx->addfile(*FILE);

    $digest = $ctx->digest;
    $digest = $ctx->hexdigest;
    $digest = $ctx->b64digest;

=head1 DESCRIPTION

The C<Digest::EdonR> module provides an interface to the Edon-R message
digest algorithm. Edon-R was a candidate in the NIST SHA-3 competition but
did progress beyond round 1.

This interface follows the conventions set forth by the C<Digest> module.

=head1 FUNCTIONS

The following functions are provided by the C<Digest::EdonR> module. None of
these functions are exported by default.

=head2 edonr_224($data, ...)

=head2 edonr_256($data, ...)

=head2 edonr_384($data, ...)

=head2 edonr_512($data, ...)

Logically joins the arguments into a single string, and returns its EdonR
digest encoded as a binary string.

=head2 edonr_224_hex($data, ...)

=head2 edonr_256_hex($data, ...)

=head2 edonr_384_hex($data, ...)

=head2 edonr_512_hex($data, ...)

Logically joins the arguments into a single string, and returns its EdonR
digest encoded as a hexadecimal string.

=head2 edonr_224_base64($data, ...)

=head2 edonr_256_base64($data, ...)

=head2 edonr_384_base64($data, ...)

=head2 edonr_512_base64($data, ...)

Logically joins the arguments into a single string, and returns its EdonR
digest encoded as a Base64 string, without any trailing padding.

=head1 METHODS

The object-oriented interface to C<Digest::EdonR> is identical to that
described by C<Digest>, except for the following:

=head2 new

    $edonr = Digest::EdonR->new(256)

The constructor requires the algorithm to be specified. It must be one of:
224, 256, 384, 512.

=head2 algorithm

=head2 hashsize

Returns the algorithm used by the object.

=head1 SEE ALSO

L<Digest>

L<Task::Digest>

L<http://www.item.ntnu.no/people/personalpages/fac/danilog/edon-r>

L<http://en.wikipedia.org/wiki/NIST_hash_function_competition>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Digest-EdonR>. I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Digest::EdonR

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/digest-edonr>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Digest-EdonR>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Digest-EdonR>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Digest-EdonR>

=item * Search CPAN

L<http://search.cpan.org/dist/Digest-EdonR/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
