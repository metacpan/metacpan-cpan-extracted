package Digest::GOST;

use strict;
use warnings;
use parent qw(Exporter Digest::base);

use XSLoader;

our $VERSION = '0.06';
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION;

XSLoader::load(__PACKAGE__, $XS_VERSION);

our @EXPORT_OK = qw(gost gost_hex gost_base64);


1;

__END__

=head1 NAME

Digest::GOST - Perl interface to the GOST R 34.11-94 digest algorithm

=head1 SYNOPSIS

    # Functional interface
    use Digest::GOST qw(gost gost_hex gost_base64);

    $digest = gost($data);
    $digest = gost_hex($data);
    $digest = gost_base64($data);

    # Object-oriented interface
    use Digest::GOST;

    $ctx = Digest::GOST->new(256);

    $ctx->add($data);
    $ctx->addfile(*FILE);

    $digest = $ctx->digest;
    $digest = $ctx->hexdigest;
    $digest = $ctx->b64digest;

=head1 DESCRIPTION

The C<Digest::GOST> module provides an interface to the GOST R 34.11-94
message digest algorithm.

This interface follows the conventions set forth by the C<Digest> module.

This module uses the default "test" parameters. To use the CryptoPro
parameters, use C<Digest::GOST::CryptoPro>.

=head1 FUNCTIONS

The following functions are provided by the C<Digest::GOST> module. None of
these functions are exported by default.

=head2 gost($data, ...)

Logically joins the arguments into a single string, and returns its GOST
digest encoded as a binary string.

=head2 gost_hex($data, ...)

Logically joins the arguments into a single string, and returns its GOST
digest encoded as a hexadecimal string.

=head2 gost_base64($data, ...)

Logically joins the arguments into a single string, and returns its GOST
digest encoded as a Base64 string, without any trailing padding.

=head1 METHODS

The object-oriented interface to C<Digest::GOST> is identical to that
described by C<Digest>.

=head1 SEE ALSO

L<Digest::GOST::CryptoPro>

L<Digest>

L<Task::Digest>

L<http://en.wikipedia.org/wiki/GOST_(hash_function)>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Digest-GOST>. I will be
notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Digest::GOST

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/digest-gost>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Digest-GOST>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Digest-GOST>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Digest-GOST>

=item * Search CPAN

L<http://search.cpan.org/dist/Digest-GOST/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
