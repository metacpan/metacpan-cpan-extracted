package Image::Magick::Info;

use strict;
use warnings;
use Carp;

require Image::Magick;

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw(Exporter);

our @EXPORT_OK = qw( get_info );

our $VERSION = '0.03';

my $im = new Image::Magick;

sub get_info{
  my ($filename, @info ) = @_;

  if( ref $filename eq "GLOB" || ref $filename eq "IO::File" ){
    $im->Read( FILE => $filename );
  }else{
    $im->Read( $filename );
  }
  
  my $ret;
  
  foreach my $i ( @info ){
    eval {
      $ret->{$i} = $im->get( $i );
    };

    if( $@ ){
      warn $@;
    }  
  }
  
  return $ret;
}


1;
__END__


=head1 NAME

Image::Magick::Info - Retreive image attributes with Image::Magick.

=head1 SYNOPSIS

  use Image::Magick::Info qw( get_info );

  my $info = get_info("/users/aroth/Desktop/photo.jpg", ("filesize","width","height") );
  my $info = get_info( $FILE_HANDLE, ("filesize") );
  my $info = get_info( \*FILE, ("width","height") );


=head1 DESCRIPTION

This module is a thin wrapper over ImageMagick's getAttribute() function. There are
faster modules out there (which don't rely on ImageMagick) that you may want to check
out (see 'SEE ALSO'). 

=head1 METHOD

get_info( filename|filehandle, attributes )

=head2 PARAMETERS

'filename' is the path of the source image (or a filehandle).

'attributes' is a list of attributes you wish to retreive. 

A comprehensive list of all possible attributes can be found here at http://imagemagick.org/script/perl-magick.php#get_attributes. Some of the more common are:

 filesize
 width
 height
 format
 mime

=head2 RETURNS

get_info() returns a hashref of the image attributes. Example:

 $VAR1 = {
           'height' => 98,
           'colors' => 2568,
           'filesize' => 17159,
           'width' => 101
         };
        

=head1 EXPORT

get_info( filename, array_of_attributes )

=head1 SEE ALSO

L<Image::Size>

L<Image::Info>

L<Image::Magick::Thumbnail::Fixed>

L<Image::Magick::Brand>

=head1 AUTHOR

Adam Roth, E<lt>aroth@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Adam Roth

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut


L<Image::Info>

L<Image::Magick::Thumbnail::Fixed>

L<Image::Magick::Brand>

=head1 AUTHOR

Adam Roth, E<lt>aroth@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Adam Roth

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
