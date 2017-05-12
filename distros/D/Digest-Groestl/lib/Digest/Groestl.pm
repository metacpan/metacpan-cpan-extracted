package Digest::Groestl;

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
    groestl_224 groestl_224_hex groestl_224_base64
    groestl_256 groestl_256_hex groestl_256_base64
    groestl_384 groestl_384_hex groestl_384_base64
    groestl_512 groestl_512_hex groestl_512_base64
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

Digest::Groestl - Perl interface to the Groestl digest algorithm

=head1 SYNOPSIS

    # Functional interface
    use Digest::Groestl qw(groestl_256 groestl_256_hex groestl_256_base64);

    $digest = groestl_256($data);
    $digest = groestl_256_hex($data);
    $digest = groestl_256_base64($data);

    # Object-oriented interface
    use Digest::Groestl;

    $ctx = Digest::Groestl->new(256);

    $ctx->add($data);
    $ctx->addfile(*FILE);

    $digest = $ctx->digest;
    $digest = $ctx->hexdigest;
    $digest = $ctx->b64digest;

=head1 DESCRIPTION

The C<Digest::Groestl> module provides an interface to the Groestl message
digest algorithm. Groestl is a candidate in the NIST SHA-3 competition.

This interface follows the conventions set forth by the C<Digest> module.

=head1 FUNCTIONS

The following functions are provided by the C<Digest::Groestl> module. None
of these functions are exported by default.

=head2 groestl_224($data, ...)

=head2 groestl_256($data, ...)

=head2 groestl_384($data, ...)

=head2 groestl_512($data, ...)

Logically joins the arguments into a single string, and returns its Groestl
digest encoded as a binary string.

=head2 groestl_224_hex($data, ...)

=head2 groestl_256_hex($data, ...)

=head2 groestl_384_hex($data, ...)

=head2 groestl_512_hex($data, ...)

Logically joins the arguments into a single string, and returns its Groestl
digest encoded as a hexadecimal string.

=head2 groestl_224_base64($data, ...)

=head2 groestl_256_base64($data, ...)

=head2 groestl_384_base64($data, ...)

=head2 groestl_512_base64($data, ...)

Logically joins the arguments into a single string, and returns its Groestl
digest encoded as a Base64 string, without any trailing padding.

=head1 METHODS

The object-oriented interface to C<Digest::Groestl> is identical to that
described by C<Digest>, except for the following:

=head2 new

    $groestl = Digest::Groestl->new(256)

The constructor requires the algorithm to be specified. It must be one of:
224, 256, 384, 512.

=head2 algorithm

=head2 hashsize

Returns the algorithm used by the object.

=head1 SEE ALSO

L<Digest>

L<Task::Digest>

L<http://www.groestl.info/>

L<http://en.wikipedia.org/wiki/NIST_hash_function_competition>

L<http://www.saphir2.com/sphlib/>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Digest-Groestl>. I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Digest::Groestl

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/digest-groestl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Digest-Groestl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Digest-Groestl>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Digest-Groestl>

=item * Search CPAN

L<http://search.cpan.org/dist/Digest-Groestl/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2011 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
