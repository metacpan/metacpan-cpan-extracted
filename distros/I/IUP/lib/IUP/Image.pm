package IUP::Image;
use strict;
use warnings;
use base 'IUP::Internal::Element';
use IUP::Internal::LibraryIup;
use Carp;

sub _create_element {
  my ($self, $args, $firstonly) = @_;
  
  my %bpp2bytes_per_pix = ( 8 => 1, 24 => 3, 32 => 4 ); 

  my $bytes_per_pix;
  my $p = delete $args->{pixels};
  my $c = delete $args->{colors};
  my $f = delete $args->{file};
  my $b = (delete $args->{BPP}   ) || 0;
  my $w = (delete $args->{WIDTH} ) || 0;
  my $h = (delete $args->{HEIGHT}) || 0;      
  my $data = '';
  my $ih;  
  
  if ($b) {
    $bytes_per_pix = $bpp2bytes_per_pix{$b};
    carp "Warning: 'BPP' invalid value '$b' (expected: 8 or 24 or 32)" unless $bytes_per_pix;
  }

  if ($f) {
    # load image from file
    $ih = IUP::Internal::LibraryIup::_IupLoadImage($f);
    carp "Warning: file '$f' cannot be loaded!" unless $ih;    
    carp "Warning: ignoring parameter 'pixels' when using parameter 'file'" if $p;
    carp "Warning: ignoring parameter 'colors' when using parameter 'file'" if $c;
    carp "Warning: ignoring parameter 'BPP' when using parameter 'file'" if $b;
    carp "Warning: ignoring parameter 'WIDTH' when using parameter 'file'" if $w;
    carp "Warning: ignoring parameter 'HEIGHT' when using parameter 'file'" if $h;
  }
  elsif (defined $p) {    
    if (ref($p) eq 'ARRAY' && ref($p->[0]) eq 'ARRAY') {
      # ref to array of array refs (2-dims)      
      my $w_tmp = scalar(@{$p->[0]});
      my $h_tmp = scalar(@$p);
      carp "Warning: 'HEIGHT' does not match given 'pixels'" if $h && $h != $h_tmp;
      carp "Warning: 'WIDTH' does not match given 'pixels'" if $w && !$bytes_per_pix && $w != $w_tmp && $w != 3*$w_tmp && $w != 4*$w_tmp;
      carp "Warning: 'WIDTH' + 'BPP' does not match given 'pixels'" if $w && $bytes_per_pix && $w*$bytes_per_pix != $w_tmp;
      $bytes_per_pix ||= ($w>0) ? int($w_tmp/$w) : 1;
      $w ||= ($bytes_per_pix>1) ? int($w_tmp/$bytes_per_pix) : $w_tmp;
      $h ||= $h_tmp;
      my $error_shown;
      for (@$p) {
        if ($w_tmp != scalar @$_ && !$error_shown) {
	  carp "Warning: 'pixels' parameter - invalid data (all lines have to be the same length)";
	  $error_shown++;
	}
        $data .= pack('C*', @$_) if ref($_) eq 'ARRAY';
      }
    }
    elsif (ref($p) eq 'ARRAY') {
      # ref to array (1-dim)
      $data = pack('C*', @$p) if ref($p) eq 'ARRAY';      
    }
    else {
      # assume $p is as a raw image data buffer
      $data = $p;
    }
    
    my $l = length($data); # the raw binary data
    my $pixels = $w * $h;
    if (!$bytes_per_pix && $pixels>0) {
      # we have WIDTH+HEIGHT but not BPP
      if ($l == $pixels) {
        $bytes_per_pix = 1;
      }
      elsif ($l == $pixels * 3) {
        $bytes_per_pix = 3;
      }
      elsif ($l == $pixels * 4) {
        $bytes_per_pix = 4
      }
      else {
        carp "Warning: cannot guess BPP from WIDTH=$w HEIGHT=$h datasize=$l";
      }
    }
    my $size = $pixels * $bytes_per_pix;
    
    if ($size == 0) {
      carp "Warning: zero or undefined image size (check 'WIDTH' and 'HEIGHT')";
    }
    else {      
      if ($l == $size) {
        if ($bytes_per_pix == 4) {
          $ih = IUP::Internal::LibraryIup::_IupImageRGBA($w, $h, $data);
	}
	elsif ($bytes_per_pix == 3) {
          $ih = IUP::Internal::LibraryIup::_IupImageRGB($w, $h, $data);
	}
	else {
          $ih = IUP::Internal::LibraryIup::_IupImage($w, $h, $data);
	}
      }
      else {
        carp "Warning: invalid image data size: $l, expected: $size";
      }
    } 
  }
  else {
    carp "Warning: no or invalid image data";
  }
    
  # we need this before calling SetAttribute
  $self->ihandle($ih);
  
  # handle colors
  if (defined $c && !defined $f) {
    if ($bytes_per_pix == 1) {
      my $i = 0;
      if (ref $c eq 'ARRAY') {
        $self->SetAttribute($i++, $_) for (@$c);
      }
      else {
        my @list = map { unpack("C", $_) } split(//, $c);
        while (@list) {
          my $r = shift @list;
          my $g = shift @list;
          my $b = shift @list;
          last unless defined $r && defined $g && defined $b;
          $self->SetAttribute($i++, "$r $g $b");
        }
      }
    }
    else {
      carp "Warning: ignoring parameter 'colors' by image with 'BPP' 24 or 32" if $c;
    }
  }
  
  return $ih;
}

sub SaveImage {
  #int IupSaveImage(Ihandle* ih, const char* file_name, const char* format); [in C]
  #iup.SaveImage(ih: ihandle, file_name, format: string) -> (ret: boolean) [in Lua]
  my ($self, $filename, $format) = @_;
  return IUP::Internal::LibraryIup::_IupSaveImage($self->ihandle, $filename, $format);
}

sub SaveImageAsText {
  #int IupSaveImageAsText(Ihandle* ih, const char* file_name, const char* format, const char* name); [in C]
  #iup.SaveImageAsText(ih: ihandle, file_name, format[, name]: string) -> (ret: boolean) [in Lua]
  my ($self, $filename, $format, $name) = @_;
  return IUP::Internal::LibraryIup::_IupSaveImageAsText($self->ihandle, $filename, $format, $name);
}

1;
