package Image::Ocrad;
use strict;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw() ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw(ocrad);
our $VERSION = '0.01';

sub ocrad {
  my $pbm = shift;
  open(O, "/usr/bin/ocrad $pbm |");
 
  my $line = <O>; 
  chomp $line;
  close(O);

  my @result = split '', $line;
  return @result;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Image::Ocrad - Call ocrad, the GNU Optical Character Recognition utility

=head1 SYNOPSIS

  use Image::Ocrad;
  @characters = ocrad('some.pbm');

=head1 ABSTRACT

  Use GNU ocrad to extract text from a PBM image file.  This module invokes
  ocrad with default options.

=head1 DESCRIPTION

=head2 What it does

  Call's ocrad with the path to a PBM file supplied by the caller, and returns
  a list of characters extracted from the file.

=head2 Functionality not supported

  * inversion of image colors prior to processing
  * image transformations (reflection, rotation, etc)
  * recognition of alternative character sets (default is ascii)
  * extraction of a subset of recognized text

These features are possible by calling ocrad with extra options.  Perhaps I'll
add these features later if they're requested or I need them.

=head2 EXPORT

=item ocrad()

This function accepts a path to a PBM file as input, returns a list of recognized
ascii characters as output.

=head1 SEE ALSO

http://www.gnu.org/software/ocrad/ocrad.html

=head1 TODO

  * XS code to link to an ocrad shared object rather than calling a system binary.
  This requires modifcation of the ocrad build, as it doesn't provide a shared
  object option in the configure/make process
  * Allow the ocrad binary to be installed in other than /usr/bin
  * Better exceptions.  Check that files exist or throw error, etc.

=head1 AUTHOR

Allen Day, E<lt>allenday@ucla.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Allen Day

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
