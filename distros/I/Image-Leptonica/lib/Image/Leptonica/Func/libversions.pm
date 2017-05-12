package Image::Leptonica::Func::libversions;
$Image::Leptonica::Func::libversions::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::libversions

=head1 VERSION

version 0.04

=head1 C<libversions.c>

  libversions.c

       Image library version number
           char      *getImagelibVersions()

=head1 FUNCTIONS

=head2 getImagelibVersions

char * getImagelibVersions (  )

  getImagelibVersions()

      Return: string of version numbers (e.g.,
               libgif 5.0.3
               libjpeg 8b
               libpng 1.4.3
               libtiff 3.9.5
               zlib 1.2.5
               webp 0.3.0

  Notes:
      (1) The caller has responsibility to free the memory.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
