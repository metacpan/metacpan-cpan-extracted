#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  fdimage.pl
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2007 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: /perl/IO-DiskImage-Floppy/bin/fdimage.pl 317 2007-01-17T15:40:00.952820Z hio  $
# -----------------------------------------------------------------------------
use strict;
use warnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use IO::DiskImage::Floppy;

caller or IO::DiskImage::Floppy->run(@ARGV);

# -----------------------------------------------------------------------------
# End of Script.
# -----------------------------------------------------------------------------
__END__

=encoding utf8

=for stopwords
	YAMASHINA
	Hio
	ACKNOWLEDGEMENTS
	AnnoCPAN
	CPAN
	RT

=head1 NAME

fdimage.pl - manipulate fdd (FAT12) image.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

 $ fdimage.pl [options] image-file [files...]
 
	options:
	  --create           create new image
	  -a|--append file   append file
	  -l|--list          list files contained in image
	  -x|--extract       extract file from image

=head1 LIMITATIONS

 - directories are not implemented yet.
 - delete entrty is not imelemented yet.

=head1 AUTHOR

YAMASHINA Hio, C<< <hio at cpan.org> >>

=head1 SEE ALSO

L<IO::DiskImage::Floppy>

=cut

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
