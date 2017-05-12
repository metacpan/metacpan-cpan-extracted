package Image::Leptonica::Func::viewfiles;
$Image::Leptonica::Func::viewfiles::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::viewfiles

=head1 VERSION

version 0.04

=head1 C<viewfiles.c>

   viewfiles.c

     Generate smaller images for viewing and write html
        l_int32    pixHtmlViewer()

=head1 FUNCTIONS

=head2 pixHtmlViewer

l_int32 pixHtmlViewer ( const char *dirin, const char *dirout, const char *rootname, l_int32 thumbwidth, l_int32 viewwidth, l_int32 copyorig )

  pixHtmlViewer()

      Input:  dirin:  directory of input image files
              dirout: directory for output files
              rootname: root name for output files
              thumbwidth:  width of thumb images
                           (in pixels; use 0 for default)
              viewwidth:  maximum width of view images (no up-scaling)
                           (in pixels; use 0 for default)
              copyorig:  1 to copy originals to dirout; 0 otherwise
      Return: 0 if OK; 1 on error

  Notes:
      (1) The thumb and view reduced images are generated,
          along with two html files:
             <rootname>.html and <rootname>-links.html
      (2) The thumb and view files are named
             <rootname>_thumb_xxx.jpg
             <rootname>_view_xxx.jpg
          With this naming scheme, any number of input directories
          of images can be processed into views and thumbs
          and placed in the same output directory.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
