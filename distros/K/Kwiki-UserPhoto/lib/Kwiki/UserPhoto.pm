package Kwiki::UserPhoto;
use Kwiki::Plugin qw(-Base -XXX);
use mixin 'Kwiki::Installer';
our $VERSION = '0.01';

const class_id => 'user_photo';
const class_title => 'User Photo';
const css_file => 'user_photo.css';
const cgi_class => 'Kwiki::UserPhoto::CGI';
const config_file => 'user_photo.yaml';

field 'display_msg';

sub register {
    my $registry = shift;
    $registry->add(widget => 'user_photo',
		   template => 'user_photo_widget.html');
    $registry->add(action => 'user_photo');
}

# Return the url of current user.
sub url {
    my $user = $self->hub->users->current->name;
    my $dir = io->catdir($self->plugin_directory,$user);
    if($dir->exists) {
	for($dir->all) {
	    return $_->name if($_->name =~ /thumb./);
	}
    }
    return $self->config->user_photo_default;
}

sub user_photo {
    my $mode = $self->cgi->run_mode;
    # Valid modes: upload
    $self->$mode if($mode && $self->can($mode));
    $self->render_screen;
}

sub upload {
    require YAML;
    my $username = $self->users->current->name;
    my $file = $self->cgi->uploaded_file;
    return $self->display_msg("You must setup a proper user name to upload your photo") unless($username);
    if($file){
	my $fh = $file->{handle};
	my $newfile = io->catfile($self->plugin_directory, $username, $file->{filename});
	$_->unlink for io->catdir($self->plugin_directory,$username)->assert->all;
	binmode($fh);
	$newfile->assert->print(<$fh>);
	$newfile->close();
	$self->make_thumbnail($newfile,
			      $self->config->user_photo_width,
			      $self->config->user_photo_height,
			     );
    } else {
	$self->display_msg("Please specify a file to upload.");
    }
}

# From Kwiki::Attachments
sub make_thumbnail {
   use File::Basename;

   my ($file,$width,$height) = @_;
   my ($fname, $fpath, $ftype) = fileparse($file, qr(\..*$));
   my $thumb = io->catfile($fpath, "thumb$ftype");
   if (eval { require Imager }) {
      my $found = 0;
      if ($ftype =~ /jpg/i) {
         $found = 1;
      } else {
         for (keys %Imager::format) {
            if ($ftype =~ /$_/oi) {
               $found = 1;
               last;
            }
         }
      }
      if ($found) {
         my $image = Imager->new;
         return unless ref($image);
         $image->read(file=>$file);
         my $thumb_img = $image->scale(xpixels=>$width,ypixels=>$height);
         $thumb_img->write(file=>$thumb);
      }
   } elsif (eval { require Image::Magick }) {
      my $image = Image::Magick->new;
      return unless ref($image);
      if (!$image->Read($file)) {
         if (!$image->Scale(geometry=>"${width}x${height}")) {
            if (!$image->Contrast(sharpen=>"true")) {
               $image->Write($thumb);
            }
         }
      }
   }
}

package Kwiki::UserPhoto::CGI;
use base 'Kwiki::CGI';

cgi 'run_mode';
cgi 'uploaded_file' => qw(-upload);

package Kwiki::UserPhoto;

__DATA__

=head1 NAME

  Kwiki::UserPhoto - User Photo Widget

=head1 SYNOPSIS

  % kwiki -install Kwiki::UserPhoto
  % kwiki -update

=head1 DESCRIPTION

This plugin provide each site user to have a photo uploaded, and displayed on
the widget pane.

=head1 COPYRIGHT

Copyright 2005 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

__config/user_photo.yaml__
user_photo_width: 128
user_photo_height: 128
user_photo_default: user_photo_default.jpg
__template/tt2/user_photo_content.html__
<div class="user_photo">
<p class="message">[% self.display_msg %]</p>
<form method="post" action="[% script_name %]" enctype="multipart/form-data">
<input type="hidden" name="action"   value="user_photo" />
<input type="hidden" name="run_mode" value="upload" />
<input type="file"   name="uploaded_file" />
<input type="submit" name="Upload"   value="Upload" />
</form>
</div>
__template/tt2/user_photo_widget.html__
<div class="user_photo">
<a href="[% script_name %]?action=user_photo"><img src="[% hub.user_photo.url %]" /></a>
</div>
__css/user_photo.css__
.user_photo a { border: none; }
.user_photo img { border: none; }
__user_photo_default.jpg__
/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRofHh0a
HBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAALCABkAGABAREA/8QAHwAAAQUBAQEB
AQEAAAAAAAAAAAECAwQFBgcICQoL/8QAtRAAAgEDAwIEAwUFBAQAAAF9AQIDAAQRBRIhMUEGE1Fh
ByJxFDKBkaEII0KxwRVS0fAkM2JyggkKFhcYGRolJicoKSo0NTY3ODk6Q0RFRkdISUpTVFVWV1hZ
WmNkZWZnaGlqc3R1dnd4eXqDhIWGh4iJipKTlJWWl5iZmqKjpKWmp6ipqrKztLW2t7i5usLDxMXG
x8jJytLT1NXW19jZ2uHi4+Tl5ufo6erx8vP09fb3+Pn6/9oACAEBAAA/APf6KKo6vq1homnTajqV
1HbWkK5eRzgD/E+w5r5z8Z/HzWNRnltfDQ/s+zBwtwygzOPXnIWvK9R13VtYkL6lqd5eMTn/AEid
n/mal0vxPruiTLLpmsX1oykHEU7BTj1GcEexr2LwP8f50nisfFsayRsQov4V2snu6jgj6Y+lfQFp
dQXltHdW00c0Eqh0kRgVYHoQfSp6KKKKRulfJfxe8fy+LfEkthaT50axcpCEPyysODIf1x7fWvNj
yaSilHWvavgR4/k0/VV8K38xayuyTalj/qpepUezc8ev1r6THelooorlfiTrL6D8PdZv4W2zCAxx
kHBDOQuR7jOfwr4rbk0lFFFT2V3NYXsF5buUngkWWNh2ZTkH8xX3ZpV8mqaPZahGMJdQJOoz0DKG
H86uUUUV5t8dUd/hbe7AflniLY9N1fJRpKKKKUda+3PAKsvw78NhwQw0y34P/XNa6KiiisDxtoR8
S+C9V0hDiW4gIi/3xyv6gCviGRGjdkdSrKcFSMEHuKbRRRV/RNJuNd1uy0u1BM11MsS8Zxk8n6Ac
/hX3TZW0VlZQWkAKwwRrEgPZVGB/Kp6KKKRsY5r5q+N/w3l0vU5/FOlW5awuW33aoP8AUyHq2P7r
Hv6/WvF268UlFKBk4r6L+Bfw4m05B4s1aHy55kK2ULj5lQ9ZCOxPb2Oe4r3JaWiiiioriCO5heGa
JJYpFKujgFWB6gg9RXiXjH9ny1vppLzwvcpZO2T9jnyY8+isOV/WvLL/AOD/AI70+ZkfQJpwOj2z
rIp/I5/SrGmfBbx1qUwU6OLNBwZbqVEUfgCWP5GvX/BHwJ0vw/cRahrcy6nep8yxBcQo3rg8t+Ne
uKoXoMU6iiikyKq3mqafp4Jvb62twBn97Kq/zNZ3/CZeGf8AoP6b/wCBKf41p2Wo2epW4uLK6huY
SSBJE4ZSR15FWaKrXl/Z6dam5vbmK3gUgGSVwqjPA5NZh8ZeGR/zH9N/8CV/xq5Z67pOokLZanaX
DHoIplYn8Aav5FLVe9vbawspru7nSC3hQvJK5wEA6kmvm7x78dtV1OaWw8MO2n2KkqboD99N7g/w
D6c+9eQXF5cXcpkuZ5JnJyWkYsT+dQ5r0v4S/E1vBN+9jqRkl0W5bLKoyYJP74HoRwR7A9q+o9J1
zS9ds1u9Lv4LyEjO6Fw2PqOoPsafqer6do1m91qV7BaQKCS8zhfyz1+gr5c+LnxO/wCE1vU07TC6
aLbPvXcMNPJjG4+wyQB7k/TzGnxTSQuHidkYdCpwfzFem+BPjTrvhu4itdWmk1PSjhSkhzLF7qx5
P+6ePTFfTui61Ya/pFvqWmTrcWky5R1/UH0IPGK8H/aB8avPfR+E7OXEMGJrzacbnIyqH6A5x7j0
rwonNJRS5qSG5ntpfMgmkhcdGjYqfzFE1zPcyGSeaSVz1aRyx/M1GTmkopc16/8AAXxi+leJj4eu
JT9i1HmMMeEmA4x6ZHH5V5r4m1Vtc8T6pqjMW+13Ukq5PRSx2j8BgfhWTRRRRRRRRRV3SL5tM1mx
v04e2uI5hj/ZYH+ldF4Q0/RrnTNbvtXiidbNITH5zyBAXfac+WQx4rX/AOEP8N6tLZ3em6hNb2l3
PcxpDICWYRRo3ycZHzM33j0xUFz4L0iwsmubiW/eGNIGW5QoIrsyYBWE+qkn1+6cgVY/4QTR5NWv
rS1bVLhLXUWsJPLMZaEKSDO/GAn5Dg/NWVp/hNNU0K7GmQHUdQttWSBmgYnNuVb59ufulgPm7etb
N14B0S5mnex1Ix7Xv5FtywO6GAuFMbHqcqMg84OR0qtF8PbMwaYst+VurkG3uEDLi1unXdAj+isc
Kx4wc+lRN4CtGsdT8m+P26BSLSFmX/SHiGbjHfAOQpHUo1M1v4fz21oZdIt7++ZbxoHCRbwiiGKQ
Mdo4yZGHP92tKD4a2EmqQQrfS3NubOYztakMy3UQG+MYB4yRjjJqnrvw7NlD5mlR397tvDDKBFuM
MflRPlgBkHLsOQPu9AaoeOfClt4XulhtItQaLey/abhcI+M/dO0A9M8E1x1FFFFFFFFFFFf/2Q==
