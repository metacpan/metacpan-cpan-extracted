package Image::Imgur;
# Imgur.pm
# simple perl module for uploading pics to imgur.com

use MIME::Base64;
use LWP;
use strict;
use warnings;
use Moose; # a Mouse is fine too

has 'key' => (is => 'rw', isa => 'Str');

# errors:
# 0 -- no api key
# -1 -- problem with the file
sub upload {
	my $self = shift;
	my $image_path = shift;
	return 0 unless($self->key);
	my $res;
	if($image_path =~ /http:\/\//)	{
		$res = $image_path;
	} else {
		my $fh;
		open $fh,"<", $image_path or return -1;
		$res = _read_file($image_path);
	}
	$res = $self->_upload($res);
	return $res;
}


# base64'd image
sub _read_file {
	my $fname = shift;
	my $fh;
	open $fh, "<", $fname or return -1;
	binmode $fh;
	return encode_base64(join("" => <$fh>));
}

# errors: 
# 1000 	 No image selected
# 1001 	Image failed to upload
# 1002 	Image larger than 10MB
# 1003 	Invalid image type or URL
# 1004 	Invalid API Key
# 1005 	Upload failed during process
# 1006 	Upload failed during the copy process
# 1007 	Upload failed during thumbnail process
# 1008 	Upload limit reached
# 1009 	Animated GIF is larger than 2MB
# 1010 	Animated PNG is larger than 2MB
# 1011 	Invalid URL
# 1012 	Could not download the image from that URL
# 9000 	Invalid API request
# 9001 	Invalid response format 
# -3 	Something is really wrong...
# else: image url
sub _upload {
	my $self = shift;
	my $image = shift;
	return undef unless($image);
	my $user_a = LWP::UserAgent->new(agent => "Perl");
	my $res = $user_a->post('http://imgur.com/api/upload.xml', ['image' => $image, 'key' => $self->key]);
	if($res->content =~ /<original_image>(.*?)<\/original_image>/)	{
		return $1;
	} elsif ($res->content =~ /<error_code>(\d+)<\/error_code>/) {
		return $1;
	} else {
		return -3;
	}
}

1;
__END__

=head1 NAME

Image::Imgur - Perl extension for uploading images to http://imgur.com

=head1 SYNOPSIS

  use Image::Imgur;
  my $key = "IMGUR-API-KEY"; # dev key
  # if you don't have imgur api key, you can get one here: http://imgur.com/register/api/
  my $url1 = $img_up->upload('http://i.cdn.turner.com/cnn/.element/img/3.0/global/header/intl/hdr-globe-east.gif');
  my $url2 = $img_up->upload('/usr/local/www/data/host.jpg');

=head1 DESCRIPTION

Image::Imgur intends to make programmatically possible to upload image files to the website http://imgur.com.

The maximum non-animated file size you can upload is 10MB. However, if the image is over 1MB then it will automatically be compressed or resized to 1MB, for better viewing on the net. The maximum animated file size (both GIF and PNG) is 2MB. 

This module uses LWP and Moose (Mouse will work too).
Also you'll need a working internet connection (duh).

=head2 Method Summary

=over 4

=item host($image)

Given an url or a filename uploads the image to imagur.com and returns the url.

=back 

=head1 SEE ALSO

http://imgur.com
L<LWP::UserAgent|LWP::UserAgent>
L<Moose|Moose>

=head1 AUTHOR

D. Frumin, <lt>ohwow@cpan.org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Ivan Ivanov

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
