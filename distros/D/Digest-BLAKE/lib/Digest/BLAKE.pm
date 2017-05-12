package Digest::BLAKE;

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
    blake_224 blake_224_hex blake_224_base64
    blake_256 blake_256_hex blake_256_base64
    blake_384 blake_384_hex blake_384_base64
    blake_512 blake_512_hex blake_512_base64
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

Digest::BLAKE - Perl interface to the BLAKE digest algorithm

=head1 SYNOPSIS

    # Functional interface
    use Digest::BLAKE qw(blake_256 blake_256_hex blake_256_base64);

    $digest = blake_256($data);
    $digest = blake_256_hex($data);
    $digest = blake_256_base64($data);

    # Object-oriented interface
    use Digest::BLAKE;

    $ctx = Digest::BLAKE->new(256);

    $ctx->add($data);
    $ctx->addfile(*FILE);

    $digest = $ctx->digest;
    $digest = $ctx->hexdigest;
    $digest = $ctx->b64digest;

=head1 DESCRIPTION

The C<Digest::BLAKE> module provides an interface to the BLAKE message
digest algorithm. BLAKE is a candidate in the NIST SHA-3 competition.

This interface follows the conventions set forth by the C<Digest> module.

=head1 FUNCTIONS

The following functions are provided by the C<Digest::BLAKE> module. None
of these functions are exported by default.

=head2 blake_224($data, ...)

=head2 blake_256($data, ...)

=head2 blake_384($data, ...)

=head2 blake_512($data, ...)

Logically joins the arguments into a single string, and returns its BLAKE
digest encoded as a binary string.

=head2 blake_224_hex($data, ...)

=head2 blake_256_hex($data, ...)

=head2 blake_384_hex($data, ...)

=head2 blake_512_hex($data, ...)

Logically joins the arguments into a single string, and returns its BLAKE
digest encoded as a hexadecimal string.

=head2 blake_224_base64($data, ...)

=head2 blake_256_base64($data, ...)

=head2 blake_384_base64($data, ...)

=head2 blake_512_base64($data, ...)

Logically joins the arguments into a single string, and returns its BLAKE
digest encoded as a Base64 string, without any trailing padding.

=head1 METHODS

The object-oriented interface to C<Digest::BLAKE> is identical to that
described by C<Digest>, except for the following:

=head2 new

    $blake = Digest::BLAKE->new(256)

The constructor requires the algorithm to be specified. It must be one of:
224, 256, 384, 512.

=head2 algorithm

=head2 hashsize

Returns the algorithm used by the object.

=head1 SEE ALSO

L<Digest>

L<Task::Digest>

L<http://131002.net/blake/>

L<http://en.wikipedia.org/wiki/NIST_hash_function_competition>

L<http://www.saphir2.com/sphlib/>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Digest-BLAKE>. I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Digest::BLAKE

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/digest-blake>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Digest-BLAKE>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Digest-BLAKE>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Digest-BLAKE>

=item * Search CPAN

L<http://search.cpan.org/dist/Digest-BLAKE/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2011 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
