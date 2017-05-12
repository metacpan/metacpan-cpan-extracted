package FFMPEG::Effects;

use warnings;
use strict;
use MIME::Base64 ();
use Data::Dumper;

our $VERSION = '1.0';
our $REVISION = '1.0';


=head1 NAME

FFMPEG::Effects - PERL Routines To Simplify ffmpeg Video Filter Usage.

=head1 VERSION

Version 1.0 -- For Use With FFMPEG Release Branch 1.0

=head1 SYNOPSIS

use FFMPEG::Effects;

	my $effect=FFMPEG::Effects->new('debug=1');

	$effect->Help('all');

	$effect->FadeIn('videofile=short.mpg', 
			'size=cif', 
			'framerate=30', 
			'color=cyan', 
			'opacity=70', 
			'fadeinframes=90', 
			'holdframes=31' ); 

	$effect->TitleSplash('size=cif',
			'framerate=30', 
			'color=black', 
			'opacity=100', 
			'fadeinframes=50', 
			'fadeoutframes=50', 
			'holdframes=30', 
			'titleframes=299', 
			'fontcolor=white', 
			'font=Courier', 
			'justify=center' );

	$effect->FadeOut('videofile=short.mpg', 
			'size=cif', 
			'framerate=30', 
			'color=cyan', 
			'opacity=70', 
			'fadeoutframes=56', 
			'holdframes=31' ); 


=head1 USAGE

The Methods Shown Above Are Shown With Their Relevant Arguments.

They Can Be Called With No Arguments And Will Attempt To Produce Useful Output.

Use This Module As In The Examples Above, Sending A List Of Quoted Arguments
To Each Function.

Make a Call to Help() To Find Out More.

=head1 DEPENDENCIES

This Module is Written, and Numbered Against FFMPEG
Release Branches. e.g.: FFMPEG::Effects-1.0 Is Written For Use
With FFMPEG Release Branch 1.0.

The Version Number of This Module Will Always Be The Same As
The FFMPEG Release It Is Written For. Check The $REVISION
Number or Release Date To Make Sure You Have The Latest Version.

This Module Depends On The GhostScript And ImageMagick
Programs. They Must Be Installed And In Your $PATH.

=head1 EXPLANATION

All Functions Listed in the USAGE Section Can Be Called Without
Arguments and Will Attempt To Produce Something Meaningful.

When Particular Arguments To Functions Are Not Relevant 
They Will Be Ignored. 

If A Particular Value Is Needed And It Is Not Specified
A Default Value Will Be Used. The Help() Function
Will List Default Values For Critical Settings.

The TitleSplash() Function Will Create A New Video Based
on the 'textfile=' argument. If no textfile is specified it
will create a single color video segmnent with the opacity
you set, and the pngfile as the background, if any.

The FadeIn() and FadeOut() Methods Operate on A Video
You Specify. See EXAMPLES Below, For More Info.

The Values for The Arguments Listed Below All Apply
To The Output Video File, Except 'videofile', and
'textfile' Which Name Input Files.

=head1 ARGUMENTS

The Methods in FFMPEG::Effects Take The Following Arguments Where Relevant:

	'videofile'      The File Name of The Video File To Be Used As Input
	'size'           Video Image Size -- Can Use 'cif', etc, or <Width>x<Height>
	'framerate'      Output File Frame Rate
	'fadeinframes'   Number of Frames A Fade In Is Spread Over
	'fadeoutframes'  Number of Frames A Fade Out Is Spread Over
	'holdframes'     Number Of Frames Added to Beginning or End of Effect To Increase Its Duration
	'titleframes'    Number of Frames That Title Frame Will Persist
	'color'          The Fade To And Fade From Color
	'opacity'        Final Opacity of Fade Sequence
	'fontcolor'      Text Color Used In Generated Titles
	'justify'        'Left', 'Center', or 'Right' Justify Text In Generated Titles
	'textfile'       ASCII Text File Containing The Content For Generating Titles
	'pngfile'        PNG Image File Used To Underlay Generated Titles
	'font'           Font For Generated Titles. -- 'Helvetica' or 'Courier'

See SIZES, and COLORS below for specifying sizes and colors.


=head1 SIZES

FFMPEG::Effects understands the following Size Specs:

	 "sqcif"  "128x96"
	 "qcif"   "176x144"
	 "cif"    "352x288"
	 "4cif"   "704x576"
	 "16cif"  "1408x1152"
	 "qqvga"  "160x120"
	 "qvga"   "320x240"
	 "vga"    "640x480"
	 "svga"   "800x600"
	 "xga"    "1024x768"
	 "uxga"   "1600x1200"
	 "qxga"   "2048x1536"
	 "sxga"   "1280x1024"
	 "qsxga"  "2560x2048"
	 "hsxga"  "5120x4096"
	 "wvga"   "852x480"
	 "wxga"   "1366x768"
	 "wsxga"  "1600x1024"
	 "wuxga"  "1920x1200"
	 "woxga"  "2560x1600"
	 "wqsxga" "3200x2048"
	 "wquxga" "3840x2400"
	 "whsxga" "6400x4096"
	 "whuxga" "7680x4800"
	 "cga"    "320x200"
	 "ega"    "640x350"
	 "hd480"  "852x480"
	 "hd720"  "1280x720"

 Size Can Be Specified either by common name, or
 by "<Width>x<Height>", as above.

 This Module Has been repeatedly tested  with the sizes above up to
 1920x1200.


=head1 COLORS

Colors are case-insensitive, specified by common name as below:

	'red' 'blue' 'green' 'cyan' 'magenta' 'yellow' 'white' 'grey' 'black'
	
The 'color' argument to methods can be specied as above or
as a Hexadecimal Value like '#RRGGBB' For Red Green And Blue.

The 'fontcolor' Argument is specified by color name as above.


=head1 CAVEATS

1) Unfortunately This Module Nneeds To Convert Videos
To PNG Files To Do Some Of Its Effects. This Can Be 
Slow For Larger Image Sizes.

2) Likewise, This Module Currently Outputs Only .mpg 
Container Format. In FFMPEG This Is The 'mpeg1video' Video Format.
It Will By Convention Transcode Whatever Input Format to 
mpeg1video Output.

3) The Duration Of The Video Is A Necessary Parameter.
If The Internal Timecode of A File Is Broken, The Duration Can 
Not Be Obtained Correctly. Using A Video File As Input 
That Was Concatenated Together From Multiple Files Can
Cause This Problem. For Best Results, Use Single MPEG Video
Files That Were Generated With FFMPEG.

4) Audio Is Not Supported At This Time. FFMPEG::Effects
produces a new video, so the audio from your original
can be added to it after the fact.


=head1 HINTS

1) Small Image Sizes Are Processed VERY Fast. Larger
Ones Become Considerably Slower. Try Prototyping Your
Scenes With Thumbnail Sizes, And When You Have It To
Your Liking, Render It Full-Size. Then You Will Have Time
For Coffee.

2) This Module Uses an Auto-Scaling Algorithm Based on
the Number of Lines, and The Longest Line in the 
'textfile', to Adjust The Font Size In The Video.

3) This Module Was Designed For Working With A Video 
Split Up Into Separate Comparatively Short Scenes.
It Is Intended To Be A Useful Tool For Scripting 
Routine Effects Like Titles And Fades.

4) Beacause of The Complexities Involved In Being Able To 
Specify Video Time In Seconds, This Module Always Deals
With Effects On A Frame-by-Frame Basis.


=head1 EXAMPLES

This Module Ships With The Following Simple Example Scripts:

	FFMPEG-Effects.titlesplash.pl
	FFMPEG-Effects.help.pl
	FFMPEG-Effects.fadeout.pl
	FFMPEG-Effects.fadein.pl


=head1 SUBROUTINES/METHODS

This Module Has The Following Methods Available:

	new()  Instantiate The Class, and Set Debug Level.

	Help() Print Help.

	SetParams()  Set Necessary Parameters To Operate.

	FadeIn()  Fade In From Solid Or Transparent Color To Scene.

	FadeOut()  Fade Out From Scene To Solid Or Transparent Color.

	GetDuration()  Get Duration Seconds Of Video.

	GetStreamInfo()  Get Various Stream Parameters.

	TitleSplash()  Generate A Title From PostScript With Fade In And Out.

	PSTitleFrame() Returns PostScript Title Frame Template.

=cut 


my $ProcData="";
my $FFCommand="";

sub new
{
	my( $class, $debugsetting ) = @_;
	my $debug = 0;

	# Set Useful Values For Those Not Passed In At Runtime
	# And For Internal Variables.
	my $self = { 
				'videofile' => 'FFMPEG-Effect',
				'outputfile' => 'FFMPEG-Effect',
				'size' => '352x288',
				'framerate' => '30',
				'fadeinframes' => '75',
				'fadeoutframes' => '75',
				'holdframes' => '0',
				'titleframes' => '90',
				'color' => 'blue',
				'opacity' => '100',
				'width' => '352',
				'height' => '288',
				'DurationSecs' => '30',
				'aspect' => 'NA',
				'pngfile' => 'none',
				'textfile' => 'FFMPEG-Effect',
				'justify' => 'center',
				'font' => 'Courier',
				'fontsize' => 'not-set',
				'fontcolor' => 'white',
				'debug' => $debug,
				};

	if ( $debugsetting )
	{
		eval("\$".$debugsetting);
		$self->{'debug'} = $debug;

		##### $debugsetting is a string like: 'debug=xxx'
		##### Where 'xxx' can be an integer val, or string description.

		if ($self->{'debug'} != 0)
		{
			print("\n");
			print ("new: $debugsetting \n");
			print Dumper($self) . "\n";
		}
	}

	bless $self, $class;

	return ($self);
}


##### Help() Print Help 
sub Help
{
	my ( $self, @inputargs) = @_;

	my $helphash = { 
					'videofile' => 'The File Name of The Video File To Be Used As Input',
					'size' => 'Video Image Size -- Can Use \'cif\', etc, or \'<width>x<height>\' ',
					'framerate' => 'Output File Frame Rate',
					'fadeinframes' => 'Number of Frames A \'Fade In\' Is Spread Over',
					'fadeoutframes' => 'Number of Frames A \'Fade Out\' Is Spread Over',
					'holdframes' => 'Number Of Frames Added to Beginning or End of Effect To Increase Its Duration',
					'titleframes' => 'Number of Frames That \'Title\' Frame Will Persist',
					'color' => 'The \'Fade To\' And \'Fade From\' Color',
					'opacity' => 'Final Opacity of Fade Sequence',
					'width' => 'Image Size In Width -- Internal Variable, Derived From \'size\'',
					'height' => 'Image Size In Height -- Internal Variable Derived From \'size\'',
					'aspect' => 'Aspect Ratio -- Internal Variable Derived From \'size\'',
					'DurationSecs' => 'Total Duration Of Video In Seconds',
					'fontcolor' => 'Text Color Used In Generated Titles',
					'justify' => 'Left, Center, or Right Justify Text In Generated Titles',
					'textfile' => 'ASCII Text File Containing The Content For Generating Titles',
					'pngfile' => 'PNG Image File Used To Underlay Generated Titles',
					'font' => 'Font For Generated Titles. -- \'Helvetica\' or \'Courier\''
					};


	if ( ( ! @inputargs ) || ( $inputargs[0] eq 'all' ) )
	{
		print("\nHelp for all...\n");

		while( my ($key, $value ) = each(%$helphash) ) 
		{
 			print("\t$key : $value\n");
		}	

		print("\n");
		print("Defaults: \n");
		while( my ($key, $value ) = each(%$self) ) 
		{
 			print("\t$key : $value\n");
		}	
		print("\n");
	}
	else 
	{
		foreach( @inputargs )
		{
			if ( $helphash->{$_}   ) 
			{
	 			print("$_: $helphash->{$_}, \n");
			}
			else
			{
				print("Help -- No Help For: $_ ... Try 'all'\n");

			}
		}
	}

}

##### TestReel()  Generate Test Reel.


sub TestReel
{
	my ( $self, $inputargs) = @_;
	$self->SetParams($inputargs);

	if ($self->{'debug'} != 0)
	{
		print("TestReel:\n");
		print Dumper($self) . "\n";
	}
}


##### SetParams()  Set Necessary Parameters To Operate.
##### Called By Effects Functions To Store Input Arguments


sub SetParams 
{

	my ( $self, @inputargs) = @_;
	my $data="";
	if ($self->{'debug'} != 0)
	{
		print("SetParams:\n");
		print Dumper($self) . "\n";
	}
	
	foreach (@inputargs)
	{
		$data=($_ );
		my @argdata = split( '=', $data);
		my $param = $argdata[0];
		my $val = $argdata[1];
	
		if ( ! $self->{ $param } )
		{
				# print("No Such Parameter -- $param \n");
			$self->{$param} = $val;
		}
		else
		{
				# print("Indata -- $param : $val \n");
			$self->{$param} = $val;
		}
	}
	
	
	my $size = $self->{ 'size' };
	
	if ( $size eq "sqcif" ) { $size="128x96" };
	if ( $size eq "qcif" ) { $size="176x144" };
	if ( $size eq "cif" ) { $size="352x288" };
	if ( $size eq "4cif" ) { $size="704x576" };
	if ( $size eq "16cif" ) { $size="1408x1152" };
	if ( $size eq "qqvga" ) { $size="160x120" };
	if ( $size eq "qvga" ) { $size="320x240" };
	if ( $size eq "vga" ) { $size="640x480" };
	if ( $size eq "svga" ) { $size="800x600" };
	if ( $size eq "xga" ) { $size="1024x768" };
	if ( $size eq "uxga" ) { $size="1600x1200" };
	if ( $size eq "qxga" ) { $size="2048x1536" };
	if ( $size eq "sxga" ) { $size="1280x1024" };
	if ( $size eq "qsxga" ) { $size="2560x2048" };
	if ( $size eq "hsxga" ) { $size="5120x4096" };
	if ( $size eq "wvga" ) { $size="852x480" };
	if ( $size eq "wxga" ) { $size="1366x768" };
	if ( $size eq "wsxga" ) { $size="1600x1024" };
	if ( $size eq "wuxga" ) { $size="1920x1200" };
	if ( $size eq "woxga" ) { $size="2560x1600" };
	if ( $size eq "wqsxga" ) { $size="3200x2048" };
	if ( $size eq "wquxga" ) { $size="3840x2400" };
	if ( $size eq "whsxga" ) { $size="6400x4096" };
	if ( $size eq "whuxga" ) { $size="7680x4800" };
	if ( $size eq "cga" ) { $size="320x200" };
	if ( $size eq "ega" ) { $size="640x350" };
	if ( $size eq "hd480" ) { $size="852x480" };
	if ( $size eq "hd720" ) { $size="1280x720" };
	
	$self->{ 'size' } = $size;
	
	my @sizedata=split(/[xX]/, $size);
	my $width=$sizedata[0];
	my $height=$sizedata[1];
	
	$self->{ 'width' } = $width;
	$self->{ 'height' } = $height;

	my $aspect  =  ($width / $height);

	my  $aspectratio = sprintf("%.2f", $aspect);

	if (  $aspectratio == 1.78 )
	{
		$self->{ 'aspect' } = 'HD';
	}

	if (  $aspectratio  == 1.33 )
	{
		$self->{ 'aspect' } = 'TV';
	}

	if (  $aspectratio  == 1.50 )
	{
		$self->{ 'aspect' } = 'NTSC';
	}

	if ( ! ( ($aspectratio  == 1.33) || ($aspectratio  == 1.78) || ($aspectratio  == 1.50) )  ) 
	{
		$self->{ 'aspect' } = 'OTHER';
	}

	$self->{ 'prec1' } = length( $self->{ 'fadeinframes' } );
	$self->{ 'prec2' } = length( $self->{ 'fadeoutframes' });
	
	
	return();
}

##### FadeIn()  Fade In From Solid Or Transparent Color To Scene.


sub FadeIn  
{

	my ( $self, @inputargs) = @_;
	$self->SetParams(@inputargs);

	if ($self->{'debug'} != 0)
	{
		print("FadeIn:\n");
		print Dumper($self) . "\n";
	}

	my $videofile=$self->{'videofile'};
	my $outputfile = `basename "$videofile" 2>&1`;
	chomp($outputfile);

	my $size=$self->{'size'};
	my $framerate=$self->{'framerate'};
	my $fadeinframes=$self->{'fadeinframes'};
	my $fadeoutframes=$self->{'fadeoutframes'};
	my $holdframes=$self->{'holdframes'};
	my $titleframes=$self->{'titleframes'};
	my $color=$self->{'color'};
	my $opacity=$self->{'opacity'};
	my $width=$self->{'width'};
	my $height=$self->{'height'};
	my $DurationSecs=$self->{'DurationSecs'};
	my $prec1=$self->{'prec1'};
	my $prec2=$self->{'prec2'};
	my $aspect=$self->{'aspect'};

	my $frameno=0;
	my $fade=($opacity / 100);
	my $fadefactor=( ($fade / $fadeinframes) );
	my $fadeval=sprintf("%.2f", $fade);

	my $skipsecs=0;
	my $skip=sprintf("%.2f", $skipsecs);
	my $next=( 1 / $framerate);

	my $nextval=sprintf("%.3f", $next);
	if ($self->{'debug'} != 0)
	{
		print("Skip Seconds: $skip\n");
		print("Next Frame At: $nextval sec.\n\n");
	}

	my $frameindex = $frameno;

	print ("Generating $holdframes Hold Frames...\n");
	for ( $frameno = 1; $frameno <= $holdframes; $frameno++)
	{
		$frameindex = $frameno;
		my $framecount=sprintf("%05d", $frameindex);

		$FFCommand="ffmpeg -y -qmin 1 -qmax 2 -g 0 -i $videofile -r $framerate -s $size -qmin 1 -qmax 2 -g 0 -vframes 1 $outputfile-holdframe-$framecount.png  2>&1";
		$ProcData=`$FFCommand`;
		if ($self->{'debug'} != 0)
		{
			print ("Executing: $FFCommand\n");
			print ("$ProcData\n");
		}
	}

		$FFCommand="ffmpeg -y -qmin 1 -qmax 2 -g 0 -i $outputfile-holdframe-%05d.png -r $framerate -qmin 1 -qmax 2 -g 0 -vf \"color=color=$color\@$fade:size=$size [layer1]; [in][layer1] overlay=0:0\" $outputfile-hold.mpg 2>&1";
		$ProcData=`$FFCommand`;
		if ($self->{'debug'} != 0)
		{
			print ("Executing: $FFCommand\n");
			print ("$ProcData\n");
		}

		$FFCommand="ffmpeg -y -qmin 1 -qmax 2 -g 0 -i $videofile -r $framerate -s $size -qmin 1 -qmax 2 -g 0 -vframes $fadeinframes $outputfile-%05d.png  2>&1";
		$ProcData=`$FFCommand`;
		if ($self->{'debug'} != 0)
		{
			print ("Executing: $FFCommand\n");
			print ("$ProcData\n");
		}

	print ("Generating FadeIn Frames...\n");
	for ( $frameno = 1; $frameno <= $fadeinframes; $frameno++)
	{
		my $framecount=sprintf("%05d", $frameno);
		$frameno=sprintf("%0"."$prec2"."d", "$frameno");
		print("Frame No: $frameno\n");

		$fade=($fade - $fadefactor);

		if ( $frameno == $fadeinframes)
		{
			$fade=0;
		}

		$fadeval=sprintf("%.2f", $fade);
		print("Opacity: $fadeval\n");
		$skip=( $skip + $next );
		$nextval=sprintf("%.3f", $skip);
		print("Next Frame at: $nextval sec.\n\n");

		$FFCommand="ffmpeg -y -qmin 1 -qmax 2 -g 0 -i $outputfile-$framecount.png -r $framerate -vf \"color=color=$color\@$fade:size=$size [layer1]; [in][layer1] overlay=0:0\" -s $size -qmin 1 -qmax 2 -g 0 -vframes 1 $outputfile-$framecount.effect.png  2>&1";
		$ProcData=`$FFCommand`;
		if ($self->{'debug'} != 0)
		{
			print ("Executing: $FFCommand\n");
			print ("$ProcData\n");
		}
	}

	print ("Processing Effect Into Output Video: $outputfile-fadein.mpg\n");
	$FFCommand="ffmpeg -y -qmin 1 -qmax 2 -g 0 -i $outputfile-%05d.effect.png -r $framerate -qmin 1 -qmax 2 -g 0 $outputfile-effect.mpg  2>&1";
	$ProcData=`$FFCommand`;
	if ($self->{'debug'} != 0)
	{
		print ("Executing: $FFCommand\n");
		print ("$ProcData\n");
	}

	$FFCommand="ffmpeg -y -qmin 1 -qmax 2 -g 0 -ss $skip -i $videofile -r $framerate -s $size -qmin 1 -qmax 2 -g 0 $outputfile-remainder.mpg  2>&1";
	$ProcData=`$FFCommand`;
	if ($self->{'debug'} != 0)
	{
		print ("Executing: $FFCommand\n");
		print ("$ProcData\n");
	}

	$FFCommand="ffmpeg -y -g 0 -qmin 1 -qmax 2 -r $framerate -i \"concat:$outputfile-hold.mpg|$outputfile-effect.mpg|$outputfile-remainder.mpg\" -g 0 -qmin 1 -qmax 2 -r $framerate -s $size $outputfile-fadein.mpg 2>&1";
	$ProcData=`$FFCommand`;
	if ($self->{'debug'} != 0)
	{
		print ("Executing: $FFCommand\n");
		print ("$ProcData\n");
	}

	unless ($self->{'debug'} != 0)
	{
		$ProcData=`rm $outputfile-holdframe-?????.png  $outputfile-hold.mpg $outputfile-?????.png $outputfile-?????.effect.png $outputfile-effect.mpg $outputfile-remainder.mpg`;

	}

	$self->{'outputfile'} = "$outputfile-fadein.mpg";

	return;
}


##### FadeOut()  Fade Out From Scene To Solid Or Transparent Color.


sub FadeOut
{
	my ( $self, @inputargs) = @_;
	$self->SetParams(@inputargs);

	if ($self->{'debug'} != 0)
	{
		print("FadeOut:\n");
		print Dumper($self) . "\n";
	}

	my $videofile=$self->{'videofile'};
	my $outputfile = `basename "$videofile" 2>&1`;
	chomp($outputfile);
	
	my $size=$self->{'size'};
	my $framerate=$self->{'framerate'};
	my $fadeinframes=$self->{'fadeinframes'};
	my $fadeoutframes=$self->{'fadeoutframes'};
	my $holdframes=$self->{'holdframes'};
	my $titleframes=$self->{'titleframes'};
	my $color=$self->{'color'};
	my $opacity=$self->{'opacity'};
	my $width=$self->{'width'};
	my $height=$self->{'height'};
	my $DurationSecs=$self->{'DurationSecs'};
	my $prec1=$self->{'prec1'};
	my $prec2=$self->{'prec2'};
	my $aspect=$self->{'aspect'};

	$self->GetDuration();
	$DurationSecs=$self->{'DurationSecs'};
	
	my $frameno=0;
	my $fade=0;
	my $fadefactor=( ( ( $opacity / 100 ) / $fadeoutframes) );
	my $fadeval=sprintf("%.2f", $fade);
	
	
	my $skipsecs=(  (($framerate * $DurationSecs ) - $fadeoutframes) / $framerate  );
	my $skip=sprintf("%.2f", $skipsecs);
	my $next=( 1 / $framerate);
	my $nextval=sprintf("%.3f", $skipsecs);

	my $lastframetime=($skip - $next);
	my $holdframe="";


	my $frontframes=($framerate * $skipsecs);
	my $front=sprintf("%d", $frontframes);

	print ("Preparing Input File...\n");
	print("Duration: $DurationSecs sec.\n");
	$FFCommand="ffmpeg -y -qmin 1 -qmax 2 -g 0 -i $videofile -r $framerate -s $size -g 0 -qmin 1 -qmax 2 -aspect:v $width:$height $outputfile-tmp.mpg  2>&1";
	$ProcData=`$FFCommand`;
	if ($self->{'debug'} != 0)
	{
		print ("Executing: $FFCommand\n");
		print ("$ProcData\n");
	}

	print ("Extracting Pre-Effect Frames...\n");
	$FFCommand="ffmpeg -y -qmin 1 -qmax 2 -g 0 -i $outputfile-tmp.mpg -r $framerate -s $size -vframes $front -g 0 -qmin 1 -qmax 2 $outputfile-front.mpg  2>&1";
	$ProcData=`$FFCommand`;
	if ($self->{'debug'} != 0)
	{
		print ("Executing: $FFCommand\n");
		print ("$ProcData\n");
	}

	print("Skipping To: $skip sec.\n");
	print ("Generating Frames For FadeOut Effect...\n");

	my 	$frameindex = $frameno;
	my $framecount=sprintf("%05d", $frameindex);

	for ( $frameno = 1; $frameno <= $fadeoutframes; $frameno++)
	{
		$frameno=sprintf("%0"."$prec2"."d", "$frameno");
		print("Frame No $frameno\n");

		$frameindex = $frameno;
		$framecount=sprintf("%05d", $frameindex);

		$fade=($fade + $fadefactor);


		if ( $frameno == $fadeoutframes)
		{
			$fade=($opacity / 100 );

			print ("Generating Hold Frames... This Frame Repeated $holdframes Times.\n");
			for ( $holdframe = 1; $holdframe <= $holdframes; $holdframe++)
			{
				$frameindex = $holdframe;
				$framecount=sprintf("%05d", $frameindex);
				$FFCommand="ffmpeg -y -qmin 1 -qmax 2 -g 0 -ss $skip -i $outputfile-tmp.mpg -r $framerate -vf \"color=color=$color\@$fade:size=$size [layer1]; [in][layer1] overlay=0:0\" -s $size -qmin 1 -qmax 2 -g 0 -vframes 1 $outputfile-holdframe-$framecount.png  2>&1";
				$ProcData=`$FFCommand`;
				if ($self->{'debug'} != 0)
				{
					print ("Executing: $FFCommand\n");
					print ("$ProcData\n");
				}

			}
		next;

		}

		$fadeval=sprintf("%.2f", $fade);
		print("Opacity: $fadeval\n");
		$skip=( $skip + $next );
		$nextval=sprintf("%.3f", $skip);
		print("Next Frame At: $nextval\n\n");


		$FFCommand="ffmpeg -y -qmin 1 -qmax 2 -g 0 -ss $skip -i $outputfile-tmp.mpg -r $framerate -vf \"color=color=$color\@$fade:size=$size [layer1]; [in][layer1] overlay=0:0\" -s $size -qmin 1 -qmax 2 -g 0 -vframes 1 $outputfile-effect-$framecount.png  2>&1";
		$ProcData=`$FFCommand`;
		if ($self->{'debug'} != 0)
		{
			print ("Executing: $FFCommand\n");
			print ("$ProcData\n");
		}

	}

	print ("Transcoding To Output File...  $outputfile-fadeout.mpg\n");
	$FFCommand="ffmpeg -y -qmin 1 -qmax 2 -g 0 -i $outputfile-effect-%05d.png -r $framerate -s $size -qmin 1 -qmax 2 -g 0 $outputfile-effect.mpg  2>&1";
	$ProcData=`$FFCommand`;
	if ($self->{'debug'} != 0)
	{
		print ("Executing: $FFCommand\n");
		print ("$ProcData\n");
	}

	$FFCommand="ffmpeg -y -qmin 1 -qmax 2 -g 0 -i $outputfile-holdframe-%05d.png -r $framerate -s $size -qmin 1 -qmax 2 -g 0 $outputfile-hold.mpg  2>&1";
	$ProcData=`$FFCommand`;
	if ($self->{'debug'} != 0)
	{
		print ("Executing: $FFCommand\n");
		print ("$ProcData\n");
	}

	$FFCommand="ffmpeg -y -g 0 -qmin 1 -qmax 2 -r $framerate -i \"concat:$outputfile-front.mpg|$outputfile-effect.mpg|$outputfile-hold.mpg\" -g 0 -qmin 1 -qmax 2 -r $framerate -s $size $outputfile-fadeout.mpg 2>&1";
	$ProcData=`$FFCommand`;
	if ($self->{'debug'} != 0)
	{
		print ("Executing: $FFCommand\n");
		print ("$ProcData\n");
	}

	unless ($self->{'debug'} != 0)
	{
		$ProcData=`rm $outputfile-holdframe-?????.png  $outputfile-hold.mpg $outputfile-tmp.mpg $outputfile-effect-?????.png $outputfile-effect.mpg $outputfile-front.mpg`;
	}

	$self->{'outputfile'} = "$outputfile-fadeout.mpg";
	return;
}


##### Transition()  Transition Between Scenes. TBD


sub Transition
{
	my ( $self, @inputargs) = @_;
	$self->SetParams(@inputargs);

	if ($self->{'debug'} != 0)
	{
		print("Transition");
		print Dumper($self) . "\n";
	}
}


##### GetDuration()  Get Duration Seconds Of Video.


sub GetDuration
{

	my ( $self, @inputargs) = @_;
	$self->SetParams(@inputargs);

	if ($self->{'debug'} != 0)
	{
		print("GetDuration:\n");
		print Dumper($self) . "\n";
	}
	
	my $videofile=$self->{'videofile'};
	
	## Stream Whole File
	# my $VideoData=`ffmpeg  -i $videofile -f null /dev/null 2>&1`;

	## Summary Only 
	my $VideoData=`ffmpeg  -i $videofile  2>&1`;

	if ($self->{'debug'} != 0)
	{
		print $VideoData;
	}
	 
	$VideoData =~ s/\r/\n/g;
	$VideoData =~ s/\n */\n/g;
	my @VideoDataArray=split("\n", $VideoData);
	my $DurationData;

	foreach my $i (0..$#VideoDataArray)
	{
		if ( $VideoDataArray[$i] =~ /Duration/ )
		{
			$DurationData=$VideoDataArray[$i];
		}

	}

	if ($self->{'debug'} != 0)
	{
		print("DurationData--->  $DurationData \n");
	}
	
	$DurationData =~ s/ //g;
	my @DurationArray=split(",", $DurationData);
	
	my @timearray=split(":", $DurationArray[0]);
	my $DurationHMS=$timearray[1] . ":" . $timearray[2] . ":" . $timearray[3];
	
	my $DurationSecs=($timearray[1] * 3600) + ($timearray[2] * 60 ) + $timearray[3];

	$self->{'DurationSecs'} = $DurationSecs;
	
	return($DurationSecs);
}
### End GetDuration


##### GetStreamInfo()  Get Various Stream Parameters.


sub GetStreamInfo
{
	my ( $self, @inputargs) = @_;
	$self->SetParams(@inputargs);

	if ($self->{'debug'} != 0)
	{
		print("GetStreamInfo:\n");
		print Dumper($self) . "\n";
	}


	my $videofile=$self->{'videofile'};
	
	my $StreamInfo = {};
	my $ffmpeg = {};
	my $StreamCount = 0;
	
	my $ProcData=`ffmpeg  -i $videofile  2>&1`;

	if ($self->{'debug'} != 0)
	{
		print ("$ProcData\n");
	}


	$ProcData =~ s/\r/\n/g;
	$ProcData =~ s/\n */\n/g;
	my @ProcDataArray=split("\n", $ProcData);

	foreach my $i (0..$#ProcDataArray)
	{
		if ($self->{'debug'} != 0)
		{
			print("--->> $ProcDataArray[$i]\n");
		}

		if ( $ProcDataArray[$i] =~ /FFmpeg version/ )
		{
			$ProcData=$ProcDataArray[$i];
			my @ProcArray=split(", ", $ProcData);
			$ffmpeg->{'version'} = $ProcArray[0];
			$ffmpeg->{'Copyright'} = $ProcArray[1];
		}

		if ( $ProcDataArray[$i] =~ /built on/ )
		{
			$ProcData=$ProcDataArray[$i];
			my @ProcArray=$ProcData;
			$ffmpeg->{'builton'} = $ProcArray[0];
		}

		if ( $ProcDataArray[$i] =~ /configuration:/ )
		{
			$ProcData=$ProcDataArray[$i];
			my @ProcArray=$ProcData;
			my @dataline = split(": ", $ProcArray[0]);
			$ffmpeg->{'configuration'} = $dataline[1];
		}

		if ( $ProcDataArray[$i] =~ /libav/ )
		{
			$ProcData=$ProcDataArray[$i];
			my @ProcArray=$ProcData;
			my ( $foo ) = ( $ProcArray[0] =~ m/(^.*?) /);
			$ProcArray[0] =~ s/(^.*?) /$foo-/;
			$ProcArray[0] =~ s/ //g;
			my @libav=split('-', $ProcArray[0]);
			$ffmpeg->{$libav[0]} = $libav[1];
		}

		if ( $ProcDataArray[$i] =~ /libsw/ )
		{
			$ProcData=$ProcDataArray[$i];
			my @ProcArray=$ProcData;
			my ( $foo ) = ( $ProcArray[0] =~ m/(^.*?) /);
			$ProcArray[0] =~ s/(^.*?) /$foo-/;
			$ProcArray[0] =~ s/ //g;
			my @libsw=split('-', $ProcArray[0]);
			$ffmpeg->{$libsw[0]} = $libsw[1];
		}

		if ( $ProcDataArray[$i] =~ /Input/ )
		{
			$ProcData=$ProcDataArray[$i];
			my @ProcArray=split(", ", $ProcData);
			$ProcArray[0] =~ s/ //g;
			$ProcArray[2] =~ s/from //g;
			$ProcArray[2] =~ s/://g;
			$ProcArray[2] =~ s/'//g;
			$StreamInfo->{$ProcArray[0]}->{'container'} = $ProcArray[1];
			$StreamInfo->{$ProcArray[0]}->{'source'} = $ProcArray[2];
		}

		if ( $ProcDataArray[$i] =~ /Duration:/ )
		{
			my @dataline = ();
			$ProcData=$ProcDataArray[$i];
			my @ProcArray=split(", ", $ProcData);

			@dataline = split(": ", $ProcArray[0]);
			$StreamInfo->{$dataline[0]} = $dataline[1];

			@dataline = split(": ", $ProcArray[1]);
			$StreamInfo->{$dataline[0]} = $dataline[1];

			@dataline = split(": ", $ProcArray[2]);
			$StreamInfo->{$dataline[0]} = $dataline[1];

			my @timearray=split(":", $StreamInfo->{'Duration'});

			my $DurationSecs=($timearray[0] * 3600) + ($timearray[1] * 60 ) + $timearray[2];

			$StreamInfo->{'DurationSecs'} = $DurationSecs;
		}

		if ( $ProcDataArray[$i] =~ /Stream/ )
		{
			my @dataline = ();
			$ProcData=$ProcDataArray[$i];
			my @ProcArray=split(": ", $ProcData);

			$ProcArray[0] =~ s/ //g;

			@dataline = split("\\[", $ProcArray[0]);
			my $stream = $dataline[0];

			$StreamInfo->{$stream}->{'type'} = $ProcArray[1];

			if ( $StreamInfo->{$stream}->{'type'} =~ /Video/)
			{
				@dataline = split(", ", $ProcArray[2]);
				$StreamInfo->{$stream}->{'codec'} = $dataline[0];
				$StreamInfo->{$stream}->{'colorspace'} = $dataline[1];
				$StreamInfo->{$stream}->{'aspect'} = $dataline[2];
				$StreamInfo->{$stream}->{'bitrate'} = $dataline[3];
				$StreamInfo->{$stream}->{'framerate'} = $dataline[4];
				$StreamInfo->{$stream}->{'tbr'} = $dataline[5];
				$StreamInfo->{$stream}->{'tbn'} = $dataline[6];
				$StreamInfo->{$stream}->{'tbc'} = $dataline[7];

				$StreamCount++;
			}

			if ( $StreamInfo->{$stream}->{'type'} =~ /Audio/)
			{
				@dataline = split(", ", $ProcArray[2]);
				$StreamInfo->{$stream}->{'codec'} = $dataline[0];
				$StreamInfo->{$stream}->{'samplerate'} = $dataline[1];
				$StreamInfo->{$stream}->{'channels'} = $dataline[2];
				$StreamInfo->{$stream}->{'sampletype'} = $dataline[3];
				$StreamInfo->{$stream}->{'bitrate'} = $dataline[4];

				$StreamCount++;
			}

		}

	}

	if ($self->{'debug'} != 0)
	{
		print Dumper($ffmpeg);
		print Dumper($StreamInfo);
	}

	my @StreamInfo=($self->{'framerate'}, $self->{'size'});
	return(@StreamInfo);
}


##### TitleSplash()  Generate A Title From PostScript With Fade In And Out.


sub TitleSplash
{

	my ( $self, @inputargs) = @_;
	$self->SetParams(@inputargs);

	if ($self->{'debug'} != 0)
	{
		print("TitleSplash:\n");
		print Dumper($self) . "\n";
	}
	
	my $textfile=$self->{'textfile'};
	my $outputfile = `basename "$textfile" 2>&1`;
	chomp($outputfile);
	$textfile = `echo $textfile`;
	chomp($textfile);

	if ( ! open(FILE, $textfile) ) 
	{
		$self->{'outputfile'} = 'FFMPEG-Effect';
		$self->{'textfile'} = 'FFMPEG-Effect';
		$outputfile = $self->{'outputfile'};
	}

	my $videofile=$self->{'videofile'};
	my $size=$self->{'size'};
	my $framerate=$self->{'framerate'};
	my $fadeinframes=$self->{'fadeinframes'};
	my $fadeoutframes=$self->{'fadeoutframes'};
	my $holdframes=$self->{'holdframes'};
	my $titleframes=$self->{'titleframes'};
	my $color=$self->{'color'};
	my $opacity=$self->{'opacity'};
	my $width=$self->{'width'};
	my $height=$self->{'height'};
	my $DurationSecs=$self->{'DurationSecs'};
	my $prec1=$self->{'prec1'};
	my $prec2=$self->{'prec2'};
	my $aspect=$self->{'aspect'};
	
	my $gsize = $height . 'x' . $width;

	my $frameno=0;
	my $fadefactor=( ($opacity / $fadeinframes) );
	
	my $fade=($opacity / 100);
	
	### Here is where the main difficulty is:
	### GhostScript seems to be a bit buggy when generating PNG Images.
	### When a PNG Image is successfully generated, the FFMPEG
	### Functions usually will work just fine. 

	if (  ( ! $self->{'pngfile'} ) || ( $self->{'pngfile'} eq 'none' ) )
	{
			$self->PSTitleFrame();
			$ProcData=`gs -dBATCH -dNOPAUSE -sDEVICE=pngalpha -g"$size" -sOutputFile=title.png Title.ps`;
	}
	else 
 	{
 			$self->PSTitleFrame();
			$ProcData=`gs -dBATCH -dNOPAUSE -sDEVICE=pngalpha -g"$size" -sOutputFile=title.png Title.ps`;
 			$ProcData=`convert $self->{'pngfile'} -resize $self->{'size'}!  pngfile.png`;
			$ProcData=`convert pngfile.png title.png -composite -size $size composite.png`;
 			$ProcData=`mv composite.png title.png`;
 	}

	my $skipsecs=0;
	# print("skipsecs: $skipsecs\n");
	my $skip=sprintf("%.2f", $skipsecs);
	my $next=( 1 / $framerate);
	# print("skip: $skip\n");
	# print("nextval: $next\n");
	
	system("convert -size $size xc:$color $color.png");

	my $runtime = ($titleframes * $next);

	$ProcData=`ffmpeg -y -loop 1 -f image2 -i $color.png -t $runtime $outputfile-titlesplash.background.mpg  2>&1 `;
	if ($self->{'debug'} != 0)
	{
		print ("$ProcData\n");
	}

	$ProcData=`ffmpeg -y -i $outputfile-titlesplash.background.mpg -vf "movie=title.png [title]; [in][title] overlay=0:0" -qmin 1 -qmax 2 -g 0 -s $size  titlesplash.mpg  2>&1 `;
	if ($self->{'debug'} != 0)
	{
		print ("$ProcData\n");
	}

	$self->FadeIn("videofile=titlesplash.mpg", "size=$size", "framerate=$framerate", "color=$color", "opacity=$opacity", "fadeinframes=$fadeinframes", "fadeoutframes=$fadeoutframes", "holdframes=$holdframes", "titleframes=$titleframes" );

	$self->FadeOut("videofile=titlesplash.mpg-fadein.mpg", "size=$size", "framerate=$framerate", "color=$color", "opacity=$opacity", "fadeinframes=$fadeinframes", "fadeoutframes=$fadeoutframes", "holdframes=$holdframes", "titleframes=$titleframes" );


	print ("Saving Output As: $outputfile-titlesplash.mpg\n");
	$ProcData=`cp $self->{'outputfile'} $outputfile-titlesplash.mpg 2>&1`;
	unless ($self->{'debug'} != 0)
	{
		$ProcData=`rm $outputfile-titlesplash.background.mpg $color.png title.png titlesplash.mpg titlesplash.mpg-fadein.mpg titlesplash.mpg-fadein.mpg-fadeout.mpg Title.ps 2>&1`;
	}
	return;
}



##### PSTitleFrame() Returns PostScript Title Frame Template.


sub PSTitleFrame {

	my ( $self, @inputargs) = @_;
	$self->SetParams(@inputargs);

	if ($self->{'debug'} != 0)
	{
		print("PSTitleFrame:\n");
		print Dumper($self) . "\n";
	}

	my $height = $self->{'height'};
	my $width = $self->{'width'};
	my $justify = $self->{'justify'};


	my $hscale = ( $height * 10 );	
	my $wscale = ( $width * 10 );	
	
	my $verysmallfontsize = 12;
	my $smallfontsize = 18;
	my $mediumfontsize = 28;
	# my $largefontsize = 43; 
	# my $autofontsize = 310; 
	my $fontsize;

	my $cyan = '0.7777';
	my $magenta = '0.7777';
	my $yellow = '0.7777';
	my $black = '0.0000';


    my $redline = "0.1111 0.7777 0.7777 0.0000 SET_CMYK \n";
    my $blueline = "0.7777 0.7777 0.1111 0.0000 SET_CMYK \n";
    my $greenline = "0.7777 0.1111 0.7777 0.0000 SET_CMYK \n";
    my $cyanline = "0.7777 0.1111 0.1111 0.0000 SET_CMYK \n";
    my $magentaline = "0.1111 0.7777 0.1111 0.0000 SET_CMYK \n";
    my $yellowline = "0.1111 0.1117 0.7777 0.0000 SET_CMYK \n";
    my $blackline = "0.9999 0.9999 0.9999 0.9999 SET_CMYK \n";
	my $whiteline = "0.1051 0.1049 0.1051 0.0000 SET_CMYK \n";
    my $greyline = "0.1111 0.1111 0.1111 0.5000 SET_CMYK \n";


	my $colorline = $redline;
	my $fontline;

	if ( lc($self->{'fontcolor'})  eq 'red' )
	{
		$colorline = $redline;
	}

	if ( lc($self->{'fontcolor'})  eq 'blue' )
	{
		$colorline = $blueline;
	}

	if ( lc($self->{'fontcolor'})  eq 'green' )
	{
		$colorline = $greenline;
	}

	if ( lc($self->{'fontcolor'})  eq 'cyan' )
	{
		$colorline = $cyanline;
	}

	if ( lc($self->{'fontcolor'})  eq 'magenta' )
	{
		$colorline = $magentaline;
	}

	if ( lc($self->{'fontcolor'})  eq 'yellow' )
	{
		$colorline = $yellowline;
	}

	if ( lc($self->{'fontcolor'})  eq 'white' )
	{
		$colorline = $whiteline;
	}

	if ( lc($self->{'fontcolor'})  eq 'grey' )
	{
		$colorline = $greyline;
	}

	if ( lc($self->{'fontcolor'})  eq 'black' )
	{
		$colorline = $blackline;
	}

	if ( lc($self->{'font'})  eq 'helvetica' )
	{
		$fontline = 'HelveticaLarge';
	}

	if ( lc($self->{'font'})  eq 'courier' )
	{
		$fontline = 'CourierLarge';
	}
	else
	{
		$fontline = 'CourierLarge';
	}


	my $titletextfile = $self->{'textfile'};
	$titletextfile = `echo $titletextfile`;
	chomp($titletextfile);
	print "Reading Title Content From: $titletextfile\n";

	if ( ! open(FILE, $titletextfile) ) 
	{
		$self->{'outputfile'} = 'FFMPEG-Effect';
		open(FILE, "+>", "$self->{'outputfile'}.titlesplash.txt");
		print(FILE "This Video\n\nProduced With:\n\nFFMPEG::Effects 1.0\n");
		close(FILE);
		$titletextfile = "$self->{'outputfile'}.titlesplash.txt";
	}

	open(FILE, $titletextfile);
	my $linecount = scalar(grep{/\n/}<FILE>);

	if ($self->{'debug'} != 0)
	{
		print("Line Count in $titletextfile: $linecount \n");
	}

	my $longestline = 0;
	seek( FILE, 0, 0);
	while (<FILE>)
	{
		my $linelength = length($_);
		if ( $linelength > $longestline )
		{
			$longestline = $linelength;
		}
	}
	
	if ( ( ! $self->{'fontsize'}  ) || ( $self->{'fontsize'}  eq 'not-set' )  )  
	{
		$fontsize = ( ( $wscale / 5 ) / $longestline );
	}
	else
	{
		$fontsize = $self->{'fontsize'}; 
	}

	my $pad = ( $fontsize * 2 );

	my $letterheight = ( ( 6.7 * $fontsize ) * 1 );
	my $pct = ( ( $letterheight / $hscale ) * 100 );
	my $factor =  ( ( ( 98 - $pct )  / 100 )  );


	my $linexpos = 0;
	my $lineypos = ( $hscale  * $factor );
	my $yspace = $lineypos;

	my $largefontsize = $fontsize; 

	my $pngdata = "\n";

	my $linespace = 0;
	my $linenumber = 0;
	my $line1text = 'foo';
	my $line1size;
	my $line1ypos = 0;
	my $line1xpos = 0;

	seek( FILE, 0, 0);
	while (<FILE>)
	{
			if ( /./ )
			{
				$linenumber++;

				if ( $linenumber == 1 )
				{
					chomp($_);
					$line1text = $_;
					my $linecharcount = length($_);

	 				use integer;
	 					$largefontsize = $fontsize / 1; 
	 					$fontsize = $fontsize / 1; 
						$line1size = ( 5 * $fontsize * $linecharcount );
	 				no integer;

					$line1ypos = $lineypos;
					$linespace = ( ( $yspace / $linecount ) *  1 );

					if ($justify eq 'left')
					{
						$line1xpos = ( 0 );
						$line1xpos =  ( $line1xpos  + $pad );
					}

					if ($justify eq 'center')
					{
						my $whitespace = ( ( $wscale  ) - ( $line1size ) );
						$line1xpos =  ($whitespace / 2 );
					}

					if ($justify eq 'right')
					{
						$line1xpos = ( 0 );
						my $whitespace = ( ( $wscale  ) - ( $line1size ) );
						$line1xpos =  ( $whitespace - $pad  );
					}

					if ($largefontsize < 1)
					{
						$largefontsize = 1;
					}

				}

				my $line = chomp($_);
				my $linecharcount = length($_);

	 			use integer;
	 				$largefontsize = $fontsize / 1; 
	 				$fontsize = $fontsize / 1; 
					my $linesize = ( 5 * $fontsize * $linecharcount );
	 			no integer;

				if ($justify eq 'left')
				{
					$linexpos = ( 0 );
					$linexpos =  ( $linexpos  + $pad );
				}

				if ($justify eq 'center')
				{
					my $whitespace = ( ( $wscale  ) - ( $linesize ) );
					$linexpos = ($whitespace / 2 );
				}

				if ($justify eq 'right')
				{
					$linexpos = ( 0 );
					my $whitespace = ( ( $wscale  ) - ( $linesize ) );
					$linexpos =  ( $whitespace - $pad );
				}


				my $psdata = 	$colorline.
								"$fontline SETFONT \n".
								"GS \n".
								"n \n".
								"$linexpos $lineypos M \n".
								"($_) $linesize X \n".
								"GR \n".
								"\n";


				$pngdata =  $pngdata . $psdata;

				$lineypos = ( $lineypos - $linespace );
			}
			else
			{ 
				my $linesize = ( 5 * $fontsize * 1 );

				my $psdata = 	$colorline.
								"$fontline SETFONT \n".
								"GS \n".
								"n \n".
								"0 $lineypos M \n".
								"( ) $linesize X \n".
								"GR \n".
								"\n";

				$pngdata =  $pngdata . $psdata;

				$lineypos = ( $lineypos - $linespace );
			}

	}

	close(FILE);



my $titleframe=<<DATA;
%!PS-Adobe-3.0
%%Creator: FFMPEG::Effects
%%Pages: 1
%%DocumentNeededResources: font Helvetica Times-Roman
%%EndComments
%%BeginProlog
/bd { bind def } bind def
/n  { newpath } bd
/L  { lineto } bd
/M  { moveto } bd
/C  { curveto } bd
/RL { rlineto } bd
/MR { rmoveto } bd
/ST { show } bd
/S  { stroke } bd
/SP { strokepath } bd
/GS { gsave } bd
/GR { grestore } bd
/GRAY { setgray } bd
/AXscale { 300 3000 div } bd
/DOSETUP {
      AXscale dup scale
      1 setlinecap
      4 setlinewidth
      1 setlinejoin
      4 setmiterlimit
      [] 0 setdash
} bd
/DOCLIPBOX {
    n 4 2 roll 2 copy M 4 1 roll exch 2 copy L exch pop 2 copy L pop
    exch L closepath clip
} bd
/DOLANDSCAPE {
      90 rotate
      0 exch -1 mul translate
} bd
/UNDOLANDSCAPE {
      0 exch translate
      -90 rotate
} bd
/AXredict 14 dict def
/X {
      AXredict begin
      exch /str exch def
      str stringwidth pop sub
      str length div 0 str ashow
      end
} bd
/FINDFONT {
    { findfont } stopped
    { /Times-Roman findfont } if
} bd
/POINTSCALEFONT { AXscale div scalefont } bd
/DOTSCALEFONT { scalefont } bd
/SETFONT { setfont } bd
/p01 <000e0e0600e0e060> def
/p02 <0f0f0f0ff0f0f0f0> def
/p03 <ff1f1f9ffff1f1f9> def
/p10 <040f0f0e40f0f0e0> def
/p12 <0006060000606000> def
/p13 <ff9f9ffffff9f9ff> def
/p21 <ff0f0f1ffff0f0f1> def


/DEFINEFONTS {
      /HelveticaLarge /Helvetica-Bold FINDFONT $largefontsize POINTSCALEFONT def
      /HelveticaMedium /Helvetica-Bold FINDFONT $mediumfontsize POINTSCALEFONT def
      /HelveticaSmall /Helvetica-Bold FINDFONT $smallfontsize POINTSCALEFONT def
      /HelveticaVerySmall /Helvetica-Bold FINDFONT $verysmallfontsize POINTSCALEFONT def

      /CourierLarge /Courier-Bold FINDFONT $largefontsize POINTSCALEFONT def
      /CourierMedium /Courier-Bold FINDFONT $mediumfontsize POINTSCALEFONT def
      /CourierSmall /Courier-Bold FINDFONT $smallfontsize POINTSCALEFONT def
      /CourierVerySmall /Courier-Bold FINDFONT $verysmallfontsize POINTSCALEFONT def
} def


%%EndProlog
%%BeginSetup
%%IncludeResource: font Helvetica
%%IncludeResource: font Times-Roman

DEFINEFONTS
systemdict /setcmykcolor known
{
       /SET_CMYK { setcmykcolor } bd
}
{
       /SET_CMYK {
       exch .2 mul add
       exch .4 mul add
       exch .3 mul add
       dup 1 gt
       {pop 1} {} ifelse
       1 exch sub setgray
       } bd
}
ifelse
systemdict /colorimage known
{
       /GET_CMYK { currentcmykcolor } bd
}
{
       /GET_CMYK {
       0 0 0 
       1 currentgray sub
       } bd
}
ifelse
systemdict /colorimage known
{
   /COLORIMAGE { false 4 colorimage } bd
       /SELECTBUF { pop } bd
}
{
       /COLORIMAGE { image } bd
       /SELECTBUF { exch pop } bd
}
ifelse
%%EndSetup
%%Page: 1 1
%%BeginPageSetup
save /AXPageSave exch def
DOSETUP
$hscale DOLANDSCAPE
$hscale UNDOLANDSCAPE
%%EndPageSetup

0.9999 0.9960 0.9999 0.0000 SET_CMYK
CourierLarge SETFONT
GS
n
$line1xpos $line1ypos M
($line1text) $line1size X
GR

$pngdata

%%PageTrailer
AXPageSave restore
showpage
%%Trailer
%%EOF
DATA

open (TITLEFILE,  '>', "Title.ps") or  die $!;
print(TITLEFILE $titleframe);
close (TITLEFILE);

	if ($self->{'debug'} != 0)
	{
		print $pngdata;
	}


	return($titleframe); 

}


=head1 AUTHOR

Piero Bugoni, C<< <PBugoni at cpan.org> >>

=head1 BUGS

Please Report Problems Using This Module To The ffmpeg-user 
mailing list. That is The Only Place That Will Be Checked.


=head1 SUPPORT

You can find documentation for this module with the UNIX `man` Command: 

    man FFMPEG::Effects

Otherwise, Search The ffmpeg-user mailing List for References to
This Module.

=head1 ACKNOWLEDGEMENTS

The FFMPEG Development Crew.

=head1 LICENSE AND COPYRIGHT

Copyright 2011-Present Piero Bugoni.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
1; # End of FFMPEG::Effects
