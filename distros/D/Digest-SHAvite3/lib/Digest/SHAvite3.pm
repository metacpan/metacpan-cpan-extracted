package Digest::SHAvite3;

use strict;
use warnings;
use parent qw(Exporter Digest::base);

use MIME::Base64 ();

our $VERSION = '0.02';
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
    shavite3_224 shavite3_224_hex shavite3_224_base64
    shavite3_256 shavite3_256_hex shavite3_256_base64
    shavite3_384 shavite3_384_hex shavite3_384_base64
    shavite3_512 shavite3_512_hex shavite3_512_base64
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

Digest::SHAvite3 - Perl interface to the SHAvite-3 digest algorithm

=head1 SYNOPSIS

    # Functional interface
    use Digest::SHAvite3 qw(
        shavite3_256 shavite3_256_hex shavite3_256_base64
    );

    $digest = shavite3_256($data);
    $digest = shavite3_256_hex($data);
    $digest = shavite3_256_base64($data);

    # Object-oriented interface
    use Digest::SHAvite3;

    $ctx = Digest::SHAvite3->new(256);

    $ctx->add($data);
    $ctx->addfile(*FILE);

    $digest = $ctx->digest;
    $digest = $ctx->hexdigest;
    $digest = $ctx->b64digest;

=head1 DESCRIPTION

The C<Digest::SHAvite3> module provides an interface to the SHAvite3 message
digest algorithm. SHAvite-3 is a candidate in the NIST SHA-3 competition.

This interface follows the conventions set forth by the C<Digest> module.

=head1 FUNCTIONS

The following functions are provided by the C<Digest::SHAvite3> module. None
of these functions are exported by default.

=head2 shavite3_224($data, ...)

=head2 shavite3_256($data, ...)

=head2 shavite3_384($data, ...)

=head2 shavite3_512($data, ...)

Logically joins the arguments into a single string, and returns its SHAvite3
digest encoded as a binary string.

=head2 shavite3_224_hex($data, ...)

=head2 shavite3_256_hex($data, ...)

=head2 shavite3_384_hex($data, ...)

=head2 shavite3_512_hex($data, ...)

Logically joins the arguments into a single string, and returns its SHAvite3
digest encoded as a hexadecimal string.

=head2 shavite3_224_base64($data, ...)

=head2 shavite3_256_base64($data, ...)

=head2 shavite3_384_base64($data, ...)

=head2 shavite3_512_base64($data, ...)

Logically joins the arguments into a single string, and returns its SHAvite3
digest encoded as a Base64 string, without any trailing padding.

=head1 METHODS

The object-oriented interface to C<Digest::SHAvite3> is identical to that
described by C<Digest>, except for the following:

=head2 new

    $shavite3 = Digest::SHAvite3->new(256)

The constructor requires the algorithm to be specified. It must be one of:
224, 256, 384, 512.

=head2 algorithm

=head2 hashsize

Returns the algorithm used by the object.

=head1 SEE ALSO

L<Digest>

L<Task::Digest>

L<http://www.cs.technion.ac.il/~orrd/SHAvite-3/>

L<http://en.wikipedia.org/wiki/NIST_hash_function_competition>

L<http://www.saphir2.com/sphlib/>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Digest-SHAvite3>. I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Digest::SHAvite3

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/digest-shavite3>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Digest-SHAvite3>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Digest-SHAvite3>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Digest-SHAvite3>

=item * Search CPAN

L<http://search.cpan.org/dist/Digest-SHAvite3/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
