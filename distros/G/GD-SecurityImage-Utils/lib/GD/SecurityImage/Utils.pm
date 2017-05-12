package GD::SecurityImage::Utils;
use GD::SecurityImage;
use strict;
use vars qw(@EXPORT @ISA $VERSION);
use Exporter;
@ISA = qw/Exporter/;
@EXPORT = ('write_captcha');
$VERSION = sprintf "%d.%02d", q$Revision: 1.2 $ =~ /(\d+)/g;

$GD::SecurityImage::Utils::DEBUG=0;
sub DEBUG : lvalue { $GD::SecurityImage::Utils::DEBUG }


sub find_a_ttf_file {

   my @arg = ('find','/usr/share/fonts/','-type','f', '-image', '"*ttf"');
   my @files = split (/\n/, `@arg`);
   scalar @files or warn("no ttf fount with [@arg]") and return;
   return $files[0];   
}






sub write_captcha {
   my ($abs_out,$opt)=@_;
   if (defined $opt){
      ref $opt eq 'HASH' or croak('must be hash ref');
   }
   $opt||={};

   
   

		# captcha
		$opt->{width}   ||= 140;
		$opt->{height}  ||= 50;
		$opt->{ptsize}  ||= 32;
		$opt->{lines}   ||= 14;
		$opt->{rndmax}  ||= 4;		
		$opt->{font}    ||= undef; #'/var/www/public_html/.icons/luxisr.ttf';
      $opt->{bgcolor} ||= '#dddddd';
   # Create a normal image

   $abs_out=~/[^\/]\.(\w{1,5})$/ or die("abs out $abs_out cant match extension type");
   my $ext = lc($1);   
   $ext eq 'png'
      or $ext eq 'gif'
      or $ext eq 'jpg'
      or $ext eq 'jpeg'
      or die("extension $ext for $abs_out is not an acceptable image format");



   
   my $image = new GD::SecurityImage (
		width   => $opt->{width},
      height  => $opt->{height},
      lines   => $opt->{lines},		
		bgcolor => $opt->{bgcolor},
		ptsize  => $opt->{ptsize},
		rndmax  => $opt->{rndmax}, # TODO change to at least 4 for release
		send_ctobg => 0,
		font    => $opt->{font}, 
		# if the font is not present, or illegible by the uid, the words do not show in the image.
	);
		
   $image->random();
   $image->create('ttf','circle','#113377', '#225599');
	$image->particle(700,6);

   my($image_data, $mime_type, $correct_code) = $image->out();

   

	print STDERR "login captcha mime: $mime_type, random number: $correct_code\n" if DEBUG;
   
   open(OUT,'>',$abs_out) or die;
   binmode OUT;
   print OUT $image_data;

   return $correct_code;
}










1;

__END__

=pod

=head1 NAME

GD::SecurityImage::Utils - generate captcha images and save to file

=head1 SYNOPSIS

Example Usage:


	use GD::SecurityImage::Utils;
	use Cwd;
	
	my $abs_captcha_table_file = cwd().'/t/captcha_table.txt';
	my $abs_font = cwd().'/t/luxisr.ttf';
	unlink $abs_captcha_table_file; # reset it
	
	
	
	# 1) CREATE A LIST OF IMAGES TO CREATE
	my $max = 20; # how many?
	my @abs_captchas;
	while( $max-- ){
	   push @abs_captchas, cwd()."/t/captcha_$max.png";
	}
	
	
	# 2) GENERATE IMAGES AND SAVE CODES
	# save codes in a text file for lookup
	
	open( CAPTCHA_TABLE_FILE, '>>',$abs_captcha_table_file) or die($!);
	
	# for each in the list, make a image, and record the right code
	for my $abs_out ( @abs_captchas ){
	   
	      unlink $abs_out; # just in case
	
	      # create the captcha image and find out what the code is
	      my $correct_code = write_captcha($abs_out,{font=>$abs_font});
	   
	      # save it in the file for later lookups
	      print CAPTCHA_TABLE_FILE "$correct_code=$abs_out\n";
	
	      -f $abs_out or die; # double check ?
	   
	}
	
	close CAPTCHA_TABLE_FILE;




=head1 EXPORTED SUBS

=head2 write_captcha()

argument is absolute file path to write captcha image to, should be a png or jpg format
optional argument is a hash ref with following options

   width    - number, pixels accross
   height   - height, pixels up down, default is 50
   ptsize   - font point size, default is 32
   lines    
   rndmax
   font     - abs path to font file, no default set
   bgcolor

returns correct code for image file

      my $correct_code = write_captca($abs_out);
      
      my $correct_code = write_captca($abs_out, { font => '/abs/path/to.ttf' });

 

=head1 SEE ALSO

GD::SecurityImage

=head1 AUTHOR

Leo Charre

=cut
