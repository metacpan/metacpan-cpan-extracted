package Image::DecodeQR;
use strict;
use warnings;
use vars qw($VERSION @ISA);

BEGIN {
    $VERSION = '0.01';
    if ($] > 5.006) {
        require XSLoader;
        XSLoader::load(__PACKAGE__, $VERSION);
    } else {
        require DynaLoader;
        @ISA = qw(DynaLoader);
        __PACKAGE__->bootstrap;
    }
}

1;
__END__

=head1 NAME

Image::DecodeQR - decode QRCode (using libdecodeqr)

=head1 SYNOPSIS

  use Image::DecodeQR;

  my $string = Image::DecodeQR::decode($filename);

=head1 DESCRIPTION

Image::DecodeQR is a simple module to decode QRCode from image file using libdecodeqr.

It is available at: http://trac.koka-in.org/libdecodeqr

=head1 METHODS

=over 4

=item decode($filename)

Decodes QRCode.

=back

=head1 AUTHOR

Jiro Nishiguchi E<lt>jiro@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://trac.koka-in.org/libdecodeqr/>

=cut

