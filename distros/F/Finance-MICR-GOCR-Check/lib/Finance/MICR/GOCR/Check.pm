package Finance::MICR::GOCR::Check;
use strict;
use warnings;
use Finance::MICR::LineParser;
use Finance::MICR::GOCR;
use File::PathInfo;
use Image::Magick;

our $VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /(\d+)/g;

$Finance::MICR::GOCR::Check::DEBUG=0;
sub DEBUG : lvalue { $Finance::MICR::GOCR::Check::DEBUG }






=pod

=head1 NAME

Finance::MICR::GOCR::Check - scan a check scan image file for a valid micr line

=head1 SYNOPSIS

	use Finance::MICR::Check;

	my $c = new Finance::MICR::GOCR::Check({ abs_check => '/path/to/check_CHECK.png });

   $c->found_valid;

=head1 DESCRIPTION

This object oriented module scans a check for a valid micr line.

The present status is pre release.

=head2 PREPPING

It can prep a check if it's turned 90 degrees right (batch scan in Canon scanners produce that).

=head2 SCAN ITERATIONS

The way the module works, after copying the target file to a temp directory, it creates smaller image 
excerpts from the bottom up and feeds it to Finance::MICR::GOCR , tests for validity with Finance::MICR::LineParser.

When a valid match is found it stops. See L<SCAN ITERATION METHODS>.


=head1 METHODS

The main methods you will likely be using are new() and parser().
The other methods are called internally, or can be called to tweak the process.

=cut

sub new {
	my ($class, $self) = (shift, shift);
	$self ||={};

	$self->{on_us_symbol} ||=  'CCc';
	$self->{transit_symbol} ||=  'Aa';
	$self->{dash_symbol} ||=  'DDd';
	$self->{ammount_symbol} ||=  'XxX';
	$self->{MICR_height} ||= 78;
	$self->{MICR_append} ||= '_MICR.png';
	$self->{CHECK_height} ||= 738;	
	$self->{CHECK_width} ||= 1836;	
	$self->{abs_path_gocrdb} ||= '/usr/share/micrdb/';
	bless $self, $class;	
	
	return $self;
}

sub parser {
   my $self = shift;
   return $self->_micr->{parser};
}

=head2 new()


	abs_check

The absolute path to the check file

These are defaults:

		CHECK_height => 738, # pixels tall
		MICR_heigh => 78, # pixels tall
		
Your check images do not need to be exactly 738 pixels tall.
MICR_height is the height of each iteration when we isolate parts of the check image to find the MICR line.
I suggest you leave these alone. But you can set them via the constructor.
The numbers are used to calculate ratios and dimensions.

These parameters are used for Finance::MICR::GOCR, but can be passed via the constructor

		abs_path_gocrdb => $abs_path_gocrdb, # required
		abs_gocr_bin => $abs_gocr_bin,
		s => $s,
		d => $d,

The only required parameter is abs_path_gocrdb
To see more about these parameters, read L<Finance::MICR::GOCR>

These parameters are used for Finance::MICR::LineParser, but can be passed via the constructor


Setting the symbols for Finance::MICR::LineParser, if you do not define these, they are set to these default values via this package:

		on_us_symbol => 'CCc',
		transit_symbol => 'Aa',
		dash_symbol => 'DDd',
		ammount_symbol => 'XxX',

If you do not want these symbols to default, and want to default to the Finance::MICR::LineParser symbols,
you can set these yourself via the constructor.
The included gocr db included in this package will work with those default symbols set by this package.

=head2 parser()

This is what you will do most interaction with.
Returns Finance::MICR::LineParser object.

	my $c = new Finance::MICR::GOCR::Check({ abs_check => '/path/to/check.png' });
	
	my $check_number = $c->parser->check_number;
	
	my $oruting_number = $c->parser->routing_number;

See L<Finance::MICR::LineParser>

=cut


















=head1 SCAN ITERATION METHODS


This calls to scan for a valid micrline inside the check image file provided as argument to constructor.
Returns true or false depending on if the match was valid.
If you want to know more.. you can call the parser.

Note that you don't need to call this subroutine directly. Calling the parser() will do the same.


The following methods trigger a scan if none was run:
	found_valid()
	rescan()







=cut

sub _custom_iteration_is_set {
	my $self = shift;
	$self->{custom_iteration_is_set} ||=0;
	return 	$self->{custom_iteration_is_set};	
}

sub crop_sides {
	my($self,$set) = @_;
	if (defined $set){
		$self->{crop_sides} = $set;	
	}
	$self->{crop_sides} ||= 0.15;
	return $self->{crop_sides};	
}

sub crop_iterations {
	my($self,$set) = @_;
	if (defined $set){
		$self->{crop_iterations} = $set;	
		$self->{custom_iteration_is_set} =1;
	}
	$self->{crop_iterations} ||= 12;
	return $self->{crop_iterations};	
}

sub crop_increment {
	my($self,$set) = @_;
	if (defined $set){
		$self->{crop_increment} = $set;	
		$self->{custom_iteration_is_set} =1;		
	}
	$self->{crop_increment} ||= 5;
	return $self->{crop_increment};	
}

sub scan_iterations_reset {
	my $self = shift;
	$self->{crop_iterations} = undef;
	$self->{custom_iteration_is_set} = undef;
	$self->{crop_increment} = undef;
	return;
}



# build the increment values and elements
# these are the iterations steps we will try
# stops when we find one that produces valid micr
sub scan_iterations {
	my $self = shift;

	my @iterations;
	
	if( $self->_custom_iteration_is_set ){

			my $i =0;
			my $now = 70;
			while ( $i != $self->crop_iterations ){
			
				push @iterations, $now;
				$now =($now + $self->crop_increment);			
				$i++;
			}
			print STDERR "custom iteration is set, steps are [@iterations]\n" if DEBUG;
			printf STDERR "step increment is : %s, number of steps: %s\n", $self->crop_increment, $self->crop_iterations if DEBUG;
		
	}
	
	else {
		
			@iterations = qw(70 75 80 85 90 95 100 105 110 115 120 130 140 150 160 170 180 190 200 210 220 230 240 250 300); # aggressive
			print STDERR "iterations are default, set to [@iterations]\n" if DEBUG;			
	}
		
	return \@iterations;
}

sub rescan {
	my $self = shift;
	$self->{_data}->{_micrdata} = undef;
	return $self->found_valid;
}

sub found_valid {
	my $self = shift;	
	$self->_micr;
	$self->parser->valid or return 0;
	return 1;	
}



=head2 crop_sides()

Percentage to crop sides by when iterating, scanning up for MICR line
default is fifteen percent
number should be 0.15 for 15%

=head2 crop_iterations()

argument is number of iterations to do before giving up on searching for micrline scans.. starts from bottom.. does 5 pix increments.
if no argumetn, returns number of iterations set.
If you give 0, it switches to default, which is 12- max is 25

=head2 crop_increment()

argument is pixel increment per iteration
if no argumetn, returns increment value
If you give 0, it switches to default, which is 5
suggested is min 2, max 8

You must set these values BEFORE you ask for the micr from ocr

=head2 scan_iterations()

returns array ref of what the iterations are set at
dafault are approximately:

	70 75 80 85 90 95 100 105 110 115 120 130 140 150 160 170 180 190 200 210 220 230 240 250 300

That means the first image extract is the micr height from 70 pixels from the bottom, then 75, etc.. Until a valid
micr line is found.

=head2 scan_iterations_reset()

will reset crop_sides, crop_increment, crop_iterations to default values.


=head2 found_valid()

will trigger a scan if none was already ran.
returns boolean if at the last scan parser() returns true for parser->valid()

=head2 rescan()

If you want to change your parameters and rescan.
returns boolean just like found_valid()

Example usage:

	unless( $c->found_valid ){
		
		$c->s(70); # change the spacing for gocr
		$c->d(15); # change the dust size from default of 20 to 15
		
		$c->crop_increment(2); # set more precise iterations, default is 5 or so
		$c->crop_iterations(10); # set less iterations to happen

		$c->rescan;		

		if ($c->found_valid){
			printf STDERR "worked! found: %s\n", $c->parser->micr_pretty;
		}
		
	}




=cut




sub _micr {
	my $self = shift;	
	
	unless( defined $self->{_data}->{_micrdata} ){

		if (DEBUG){	
			printf STDERR __PACKAGE__ ." _micr defining\n
			custom iteration %s
			crop iterations %s
			crop increment %s			
			", 
			$self->_custom_iteration_is_set,
			$self->crop_iterations,
			$self->crop_increment;
		}	
		
		
		my $data = {
			parser => undef,
			height => undef,
			abs_micr => undef,
			raw => undef,
		};


	# get string from where micr line should be
	# it should NOT STOP at first valid.. it should run one more!!! when it gets chopped up it still tries matching!
		my $id = time ;# for development purpose.. disregard, names the micrfiles
		my $last_one_was_valid =0;
		my $stop = 0;

		my $iterations = $self->scan_iterations;
		
		for (@$iterations){ 

			if ($last_one_was_valid){ # then do one more just 2px or 4px up				
				$data->{height} = ($data->{height} + 5);
				$stop =1; #force stop			
			}
			else { # go on as usual			
				$data->{height} = $_;			
			}

			printf STDERR "iterating size [%s]\n",$data->{height} if DEBUG;

			$data->{abs_micr} = $self->_create_micr_im({ MICR_height => $data->{height}, id =>$id  });
			$data->{raw} =	($self->_gocr_raw($data->{abs_micr}) || 'none' );
			$data->{parser} = new Finance::MICR::LineParser({ 
			   string			=> $data->{raw}, 
				transit_symbol	=> $self->{transit_symbol}, 
				on_us_symbol	=> $self->{on_us_symbol},
				dash_symbol		=> $self->{dash_symbol},
				ammount_symbol => $self->{ammount_symbol},
         });

			if(DEBUG){
				print STDERR '[abs_path_gocrdb:'.$self->{abs_path_gocrdb}.']';
				print STDERR '[height:'.$data->{height}.']';
				print STDERR '[abs_micr:'.$data->{abs_micr}.']';
				print STDERR '[raw:'.$data->{raw}."]";
				print STDERR '[height:'.$data->{height}."]\n";				
				print STDERR '[micr_pretty:'.($data->{parser}->micr_pretty || '')."]\n\n";
			}
			
			last if $stop;
			$last_one_was_valid = $data->{parser}->valid;
			last if $data->{parser}->valid;			
			
		}	 
		
		$self->{_data}->{_micrdata} = $data;

		# if it's not valid try something nuts??		
#		$last_one_was_valid =0;
	#	$stop = 0;
		my $data2=$data; # copies or .. what?
		unless ($data2->{parser}->micr_pretty){ 
			print STDERR "iterations will not match, trying something different\n" if DEBUG;
			
			for (qw(90 95 100 105 110 115)){ 

			#	if ($last_one_was_valid){ # then do one more just 2px or 4px up				
			#		$data2->{height} = ($data2->{height} + 5);
				#	$stop =1; #force stop			
			#	}
			#	else { # go on as usual			
					$data2->{height} = $_;			
			#	}


			
				$data2->{abs_micr} = $self->_create_micr_im({ MICR_height => $data2->{height}, id =>"raw_$id"  });
				
				my $db = $self->{abs_path_gocrdb};

				my $gocrbin = File::Which::which('gocr') or die('cant find gocr binary, is it installed?');
				
				   # the -a 80 option is for versions of gocr 0.44, version 0.40 will complain but still work
            my @args = ( $gocrbin, '-a',80,'-m', 256, '-m', 2, '-p', $db, '-s', 80, '-d', 20, '-i', $$data2{abs_micr});
            
            print STDERR "args [@args]\n" if DEBUG;
	         my $output = do { 
               open my $fh, '-|', @args or warn("command [@args], $!");
               local $/;
               <$fh>
            };	
            
				
				$data2->{raw} = $output;
				chomp $data2->{raw};
				
				if ($data2->{raw}=~s/.*(CCc\d{4,}CCc)Ccc(\d{4,})Ccc(\d{4,}CCc).*/$1Aa$2Aa$3/s){
						print STDERR "[$$data2{height}] regexed into shape. " if DEBUG;	
				}
				elsif ($data2->{raw}=~s/.*[Cc]{2,3}(\d{5,})[CcAa]{3,6}(\d{5,})[CcAa]{2,3}(\d{5,})[Cc]{2,3}.*/CCc$1CCcAa$2Aa$3CCc/s){
						print STDERR "[$$data2{height}] regexed into shape, method 2. " if DEBUG;	
					
				}
			
				$data2->{raw} ||= 'none';
				
				$data2->{parser} = new Finance::MICR::LineParser({ 
					string			=> $data2->{raw},
					transit_symbol	=> $self->{transit_symbol}, 
					on_us_symbol	=> $self->{on_us_symbol},
					dash_symbol		=> $self->{dash_symbol},
					ammount_symbol => $self->{ammount_symbol},
				});

				print STDERR "raw is: [$$data2{raw}]\n" if DEBUG;	

				last if $data2->{parser}->valid;
		#		last if $stop;
		#		$last_one_was_valid = $data2->{parser}->valid;
			}	

			
			if ($data2->{parser}->valid){
				print STDERR "something different worked. using that.\n" if DEBUG;			
				$self->{_data}->{_micrdata} = $data2;				
			}
			else {
				print STDERR "still not valid.\n" if DEBUG;
			} 
		}
		
	}

	return $self->{_data}->{_micrdata};
}

sub micr_height {
	my $self = shift;
	return $self->_micr->{height};
}
sub abs_micr {
	my $self = shift;
	return $self->_micr->{abs_micr};
}

sub gocr_raw {
   my $self = shift;
   return $self->_micr->{raw};
}
=head2 abs_micr()

absolute path to micr file what was created. 
after the iterations, the one that closest matched is this file.
This is useful to know if you want to build or increment the gocr database.

=head2 gocr_raw()

the raw ocr output for the micrfile that was last made, 
returns 'none' if none returned.

=head2 micr_height()

the height of the micr file, we try to make 70 80 90 100 110 120 130 and the first to match 
gets used.

=cut



# get raw gocr optical character recognition read from the isolated check micr image
sub _gocr_raw {
	my $self = shift;
   my $abs_path = shift; 
   $abs_path or croak('_gocr_raw() needs abs  path arg, missing.');

	my $gocr = new Finance::MICR::GOCR({ 
			abs_path => $abs_path, # but we give it the micr.pbm file
			abs_path_gocrdb => ($self->{abs_path_gocrdb} or undef ), # will die if undef
			abs_gocr_bin => ($self->{abs_gocr_bin} or undef ),
			s => ($self->{s} or undef),
			d => ($self->{d} or undef),
	});		

	my $gocr_raw = $gocr->out 
			or warn("ERROR: GOCR.pm returns empty for out() on file [$abs_path] Possible causes: empty image? no micr? wrong filetype for gocr?.\n");
   return $gocr_raw;
}

sub _create_micr_im {
	my $self = shift; # by now check is defined
	my $arg = shift; #ref $arg eq 'HASH' or croak('_creat_micr() arg must be hash');
	print STDERR "creating a micr extraction from the image..\n" if DEBUG;
	
	$arg ||= {};
	$arg->{abs_check}		||= $self->f->abs_path;
   $arg->{MICR_height}	||= $self->{MICR_height};
	$arg->{CHECK_height} ||= $self->{CHECK_height};
	$arg->{id} ||= time;
	
	
	$arg->{abs_micr}		||= '/tmp/.'.$$arg{id}.'_'.$$arg{MICR_height}.'_'.time .$self->{MICR_append};

	$arg->{abs_check} or croak('missing abs_check arg, this is the check file to read');
	$arg->{abs_micr} or croak('missing abs_micr arg  this is where you want to output the file');
	$arg->{MICR_height} or croak('missing MICR_height');
	$arg->{CHECK_height} or croak('missing CHECK_height');
	

	my $i = $self->im;

	
	my($cropy,$cropx)=(0,0);
	
	my($h,$w) = $i->Get('height','width');	

	print STDERR "h $h, w $w\n" if DEBUG;


	# crop sides.. how much?
	if ($self->crop_sides){
		print STDERR "cropping sides\n" if DEBUG;
		my $minus = int ($w * $self->crop_sides);# minus 15% width is default (0.15)
		$cropy = int( $minus/2 );
		$w = ($w - $minus); 
	}


	my $target_h =	int ( ($arg->{MICR_height} * $h) / $arg->{CHECK_height} );	$target_h or confess('cant determine target height');
	print STDERR "target h $target_h\n" if DEBUG;
   
	$cropy = ($h-$target_h);
	
	print STDERR "crop y $cropy\n" if DEBUG;
	
	
	my $x = $i->Crop( width => $w, height => 72, x => $cropx,y => $cropy);
	
	warn "$x" if "$x";

	$x =$i->Write($arg->{abs_micr});
	warn "$x" if "$x";

   print STDERR "saved $$arg{abs_micr}\n" if DEBUG;
	return $arg->{abs_micr};
}

sub im { # object containing image magick object already reading the check image
	my $self = shift;
	
	unless( defined $self->{im} ){
		my $i = new Image::Magick;
		$i->Read($self->f->abs_path);
		$self->{im} = $i;
	}
	return $self->{im}->Clone;
}

=head2 im()

returns clone of image magick object that already read check image

=cut






=head1 REPORTING

=cut

sub save_report {
   my $self = shift;
	require YAML;
	YAML::DumpFile( $self->abs_report, $self->_status);	   
   printf STDERR "abs report saved %s\n", $self->abs_report if DEBUG;
   return $self->abs_report;
}

sub _status {
	my $self= shift;
   my $status = {
			is_prepped => $self->is_prepped,
			abs_path => ($self->f->abs_path || undef), 
			_micr => ($self->_micr || undef), 
			LineParser_status => ($self->parser->status || undef),
         is_valid => $self->parser->valid ,   
	};	   
   return $status;
}

sub get_report {
	my $self = shift;
	my $report = File::Slurp::read_file($self->f->abs_loc.'/'.$self->report_filename);
	return $report;
}

sub abs_report {
	my $self = shift;
	my $where = $self->f->abs_loc .'/'.$self->report_filename;
	return $where;
}

sub report_filename {
	my $self = shift;
	my $filename = $self->f->filename.'.report';	
	return $filename;
}

=head2 save_report()

saves report in YAML format about the file 
this is saved as the abs check file appended with .report

=head2 report_filename()

returns filename of report

=head2 abs_report()

abs path to where report should be for this check

=head2 get_report()

get report text

=cut





=head1 CHECK PREPPING METHODS

A check file may be 90 degrees turned right or dimensions may be way off.
This code helps that.

=cut

sub is_prepped {
   my $self = shift;   
	my $i = $self->im;
	my($h,$w) = $i->Get('height','width') or die('cant get height or width');
	if ( $h > $w ) { return 0; }
   return 1;
}

sub prep_check {
   my $self = shift;  
   my $abs_path = shift; $abs_path ||= $self->f->abs_path;

	print STDERR "prep check started for $abs_path\n" if DEBUG;

   my $i = Imager->new();   
   $i->read( file=> $abs_path ) or die($i->errstr);

   # assumes check is top side to the right on a 8.5x11 type surface

   my $rotated=0;
   my $resized=0;

   ### ROTATE ???
	my ($h,$w) = ($i->getheight, $i->getwidth);
	($h and $w ) or die("[h:$h,w:$w] cant be determined, [$abs_path].".$i->errstr);
	print STDERR "h $h, w $w\n" if DEBUG;

	if ($h > $w){ 
      ### h is more then w, turn to the left
		print STDERR "rotating because h is more then w\n" if DEBUG;
		
		my $rot =$i->rotate(right => -90) or die($i->errstr);
		$i = $rot;
		#reset vals
		$h = $i->getheight;
		$w = $i->getwidth;
		$h and $w or die("$w $h, h or w cant be determined");	
      $rotated=1;
	}

   else {
      ### h is not more then w, already prepped???
   }
   
   ### RESIZE ???
	# are the sizes ok within reason??
	my $target_h = int(($self->{CHECK_height} * $w ) / $self->{CHECK_width});	
	### $target_h
	my $margin_of_error = 5; # px
	### $margin_of_error
	my $diff = int($h - $target_h);
	### $diff
	if ( $diff > $margin_of_error  ) { # TODO: is this really working well?
		### diff is greater then margin of error , must resize file.
		
		print STDERR "h to w dimensions larger then margin of error.. resizing\n" if DEBUG;
		
		my $topcrop = ($h-$target_h);

		my $cropped = $i->crop( top=>$topcrop, left=>0) 
			or die("top $topcrop ".$i->errstr);
		$i = $cropped; # replace with new
      $resized=1;

	} 

   else {
      ### did not prep resize, no need
   }


   # save this
   if ($resized or $rotated){
	   $i->write( file => $abs_path ) or die($i->errstr);   
		print STDERR "prepped, wrote to $abs_path\n" if DEBUG;
   } 

   else {
      ### did not need resize or rotation, neither happened.
		print STDERR "no prep was made\n" if DEBUG;
      return 1;
   }

   

	return 1;	
}

=head1 is_prepped()

returns boolean

=head1 prep_check()

argument is optionally abs path to check. will check that it is right side up and write over 
same path file name.

	$c->prep_check;
	
	$c->prep_check('/abs/path/to/check.png');
	
=cut











# File::PathInfo

sub set_check { # called after a rename
	my $self = shift;
	my $abs_check = shift;
	$abs_check or croak("missing abs_check arg");

	my $f = new File::PathInfo;
	$f->set(	$abs_check ) or warn("abs_check [$abs_check] failed to resolve to disk, (could be old index search result or funny filename) - ".$f->errstr) and return 0;
	$self->{_data}->{_check} = $f;
	return 1;
}



sub f {
	my $self = shift;
	unless ( defined  $self->{_data}->{_check} ){
		$self->{abs_check} or croak('need to pass abs_check argument to constructor or use set_check()');
		$self->set_check( $self->{abs_check} ) or die("cant resolve check");
	}
	return $self->{_data}->{_check};
}

=head2 f()

returns check L<File::PathInfo> object

	my $c = new Finance::MICR::GOCR::Check({ abs_check => '/path/to/checkfile.png', abs_path_gocrdb =>'/path/to/my/micrdb' });

	$c->f->abs_path;
	$c->f->abs_loc;
	$c->f->filename;
	$c->f->mtime;

See L<File::PathInfo>

=head2 set_check()

used internally
argument is abs path to check file

=cut










=head1 CAVEATS

This is pre release.

=head1 BUGS

Yes.
Please forward any concerns, suggestions, bugs to AUTHOR.

=head1 SEE ALSO

L<Finance::MICR::GOCR>
L<Finance::MICR::LineParser>

=head1 AUTHOR

Leo Charre leocharre at cpan dot org

=cut


1;









