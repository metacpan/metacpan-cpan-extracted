package Image::Xbm2bmp;

use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = '0.02';

sub new {
	my $class = shift;
	my $xbmfilepath = shift;
	my($width,$height,@data);
	eval{
		if(defined($xbmfilepath)){
			($width,$height,@data) = _LoadXbmFile($xbmfilepath);
		}
		else{
			$width = 0;
			$height = 0;
			@data = ();
		}
	};
	if($@){
		die "$@";
	}
	my $self = bless {	_WIDTH=>$width,
						_HEIGHT=>$height,
						_DATA=>[@data]
					}, $class;
	return $self;
}

sub load_xbm_data($$$){
	my($self,$data_ref,$width,$height) = @_;
	eval{
		$self->{_WIDTH} = $width;
		$self->{_HEIGHT} = $height;
		$self->{_DATA} = [@$data_ref];
	};
	if($@){
		die "load_xbm_data failed!:$@";
	}
}

sub to_bmp_file($$){
	my($self,$bmpfilepath) = @_;
	my $BMP_PACK = to_bmp_pack($self);
	open(OUT,">$bmpfilepath") or die "save failed!$!";
	binmode(OUT);
	print OUT $BMP_PACK;
	close(OUT);
}

sub to_bmp_pack($){
	my($self) = shift;
	my($data_ref,$width,$height,@xbm_data,@source_xbm_data);
	$width = $self->{_WIDTH};
	$height = $self->{_HEIGHT};
	$data_ref = $self->{_DATA};
	@source_xbm_data = @$data_ref;

	my($old_row_bytes,$row_bytes);
	if(($width%32)>0){
		$row_bytes = ($width/32)*4+4;
	}
	else{
		$row_bytes = $width/8;
	}
	$old_row_bytes = $width/8;
	if($old_row_bytes==$row_bytes){
		@xbm_data = @source_xbm_data;
	}
	else{
		@xbm_data = _init_array($row_bytes,0x00);
		for(my $c1=0; $c1<$height; $c1++){
			for(my $c2=0; $c2<$old_row_bytes; $c2++){
				$xbm_data[$c1*$old_row_bytes+$c2] = $source_xbm_data[$c1*$old_row_bytes+$c2];
			}
		}
	}
	
	my @Bitmap_File_size =  unpack("C4",pack("C4",(0x3e+$row_bytes*$height)));
	my @Bitmap_Data_Offset = (0x3e,0x00,0x00,0x00);
	my @Bitmap_Header_Size = (0x28,0x00,0x00,0x00);
	my @Bitmap_Width = unpack("C4",pack("C4",$width));
	my @Bitmap_Height = unpack("C4",pack("C4",$height));;
	my @Planes = (0x01,0x00);
	my @Bits_Per_Pixel = (0x01,0x00);
	my @Bitmap_Data_Size = unpack("C4",pack("C4",($row_bytes*$height)));
	my @data = ();
	
	#xbm数据的每个字节需要进行反序和NOT处理
	foreach my $d(@xbm_data){
		my $rd = _reverse_byte($d);
		$rd = _NOT_byte($rd);
		push @data,$rd;
	}
	#xbm数据行需要进行反序处理
	@data = _reverse_ex(\@data,$row_bytes); 

	my @BITMAPFILE = (
	0x42,0x4d,
	(@Bitmap_File_size),
	0x00,0x00,0x00,0x00,
	(@Bitmap_Data_Offset),
	(@Bitmap_Header_Size),
	(@Bitmap_Width),
	(@Bitmap_Height),
	(@Planes),
	(@Bits_Per_Pixel),
	0x00,0x00,0x00,0x00,
	(@Bitmap_Data_Size),
	0xc4,0x0e,0x00,0x00,
	0xc4,0x0e,0x00,0x00,
	0x00,0x00,0x00,0x00,
	0x00,0x00,0x00,0x00,
	0x00,0x00,0x00,0x00,
	0xff,0xff,0xff,0x00,
	(@data)
	);
	return pack('C*',@BITMAPFILE);
}

sub _reverse_byte($){
	my $in = shift;
	my $out = 0x00;
	if($in & 0b10000000){
		$out = $out | 0b00000001;
	}
	if($in & 0b01000000){
		$out = $out | 0b00000010;
	}
	if($in & 0b00100000){
		$out = $out | 0b00000100;
	}
	if($in & 0b00010000){
		$out = $out | 0b00001000;
	}
	if($in & 0b00001000){
		$out = $out | 0b00010000;
	}
	if($in & 0b00000100){
		$out = $out | 0b00100000;
	}
	if($in & 0b00000010){
		$out = $out | 0b01000000;
	}
	if($in & 0b00000001){
		$out = $out | 0b10000000;
	}
	return $out;
}

sub _NOT_byte($){
	my $in = shift;
	my $out = ~$in;
	$out = $out & 0b11111111;
	return $out;
}

sub _reverse_ex($$){
	my($data_ref,$m) = @_;
	if(!defined($data_ref)||!defined $m){
		die "method[_reverse_ex] died!";
	}
	my @sdata = @$data_ref;
	my $len = scalar(@sdata);
	my @tdata= ();
	for(my $n = 0; $n<$len/$m; $n++){
		my $k = $len-$n*$m-$m;
 		$tdata[$k] = $sdata[$n*$m];
		$tdata[$k+1] = $sdata[$n*$m+1];
		$tdata[$k+2] = $sdata[$n*$m+2];
		$tdata[$k+3] = $sdata[$n*$m+3];
	}
	return @tdata;
}

sub _hex_value($){
	my($list) = @_;
	my $value;
	my $h = substr($list,0,1);
	my $l = substr($list,1,1);
	my($h_value,$l_value);
	$h = lc($h);
	$l = lc($l);
	if($h=~/[abcdef]/){
		$h_value = ord($h)-ord('a')+10;
	}
	if($h=~/[0123456789]/){
		$h_value = ord($h)-ord('0');
	}
	if($l=~/[abcdef]/){
		$l_value = ord($l)-ord('a')+10;
	}
	if($l=~/[0123456789]/){
		$l_value = ord($l)-ord('0');
	}
	$value = $h_value*16+$l_value;
	return $value;
}

sub _LoadXbmFile($){
	my $file = shift;
	open(INPUT,$file) or die "Can't load xbm file: $!\n";
	my $buf;
	while(<INPUT>){
		$buf.= $_;
	}
	close(INPUT);
	my @data = ();
	my($height,$width);
	if($buf=~/#define .*width (\d*)/){
		$width=$1;
	}
	if($buf=~/#define .*height (\d*)/){
		$height=$1;
	}
	if($buf=~/{\s*(.*)\s*}/s){
		my $eval_str = qq~\@data=($1);~;
		eval $eval_str;
	}
	return $width,$height,@data;
}

sub _init_array($$){
	my($length,$value) = @_;
	my @array;
	if($length=~/\d/){
		for(my $count=0;$count<$length;$count++){
			$array[$count] = $value;
		}
	}
	else{
		@array = undef;
	}
	return @array;
}


1;
__END__

=head1 NAME

Image::Xbm2bmp - for converting image file from XBM  to BMP.

=head1 SYNOPSIS

  use Image::Xbm2bmp;

  #Create a object from a xbm file
  my $obj = Image::Xbm2bmp->new("/tmp/test.xbm");

  #Create a object from array data
  my $xbm_width = 32;
  my $xbm_height = 24;
  my @xbm_data = (
					0x7c,0x3c,0x7c,0x3c,
					0xfe,0x7c,0xfe,0x7c,
					0xee,0xee,0xee,0xee,
					0xe0,0xee,0x60,0xee,
					0x70,0xfe,0x30,0xfe,
					0x38,0xec,0xe0,0xec,
					0x1c,0xe0,0xee,0xe0,
					0xfe,0x7e,0xfe,0x7e,
					0xfe,0x3c,0x7c,0x3c 
				);
  my $obj = Image::Xbm2bmp->new();
  $obj->load_xbm_data(\@xbm_data,$xbm_width,$xbm_height);

  #Save as a BMP file
  $obj->to_bmp_file("/tmp/test.bmp");
  
  #Or get a packed data
  my $packed_data = $obj->to_bmp_pack();

  open(FILE,">/tmp/test.bmp");
  print FILE $packed_data;
  close(FILE);

  #In CGI script
  print "Content-type: image/bmp\n\n";
  print $obj->to_bmp_pack();

=head1 DESCRIPTION

XBM is a simple image format,we can show a dynamic picture easily
via it,so some CGI use xbm file,but it can't be used in browser at
WindowsXP(sp2),so we need a module to converting it.


=head2 EXPORT

None by default.


=head1 AUTHOR

huang xin 
hx1978@hotmail.com

=head1 SEE ALSO

L<perl>.

=cut
