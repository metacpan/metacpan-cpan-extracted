package Geo::GNUPlot;

use strict;
use Carp;
use IO::File;
use vars qw($VERSION $DEBUG);

$VERSION = '0.01';
#$DEBUG = 0;

#-------------------------------------------------------
#New method for Geo::GNUPlot
#Notice that it has a mandatory configuration file argument.
sub new {
	my $self=shift;
	my $option_HR=shift;

	my ($grid_HR, $msg, $grid_file, $map_file, $gnuplot)=undef;

	$grid_file=$option_HR->{'grid_file'};
	$map_file=$option_HR->{'map_file'};
	$gnuplot=$option_HR->{'gnuplot'};
	
	unless (defined $grid_file){
		$msg="new method called without the mandatory grid_file option key!";
		carp $msg,"\n";
		return (undef,$msg);
	}#unless

	unless (defined $map_file){
		$msg="new method called without the mandatory map_file option key!";
		carp $msg,"\n";
		return (undef,$msg);
	}#unless
	
	unless (defined $gnuplot){
		$msg="new method called without the mandatory gnuplot option key!";
		carp $msg,"\n";
		return (undef,$msg);
	}#unless

	$self={};
	bless($self,'Geo::GNUPlot');

	($grid_HR,$msg)=$self->_read_grid($grid_file);
	return (undef,$msg) unless (defined $grid_HR);

	$self->{'grid_HR'}=$grid_HR;
	$self->{'map_file'}=$map_file;
	$self->{'gnuplot'}=$gnuplot;

	return ($self,undef);
}#new
#------------------------------------------------------
#If $track_AR has 2 elements in the first point in the track it is assumed
#the incomming position data is in x,y form.
#Otherwise it is assumed the incomming position data is in
#($long, $long_dir, $lat, $lat_dir) form.
sub plot_track {
	my $self=shift;
	my $track_AR=shift;
	my $output_file=shift;
	my $option_HR=shift;

	my ($success, $error, $xy_data_AR, $radius, $temp_dir, $ppm_file)=undef;
	my ($data_file, $config_file, $msg, $x_range_AR, $y_range_AR)=undef;
	my ($x_pad, $y_pad, $x_scale, $y_scale, $term, $title)=undef;

	#Determine x_pad, y_pad, x_scale, y_scale, and term
	if (defined $option_HR->{'x_pad'}){
		$x_pad=$option_HR->{'x_pad'};
	}
	else {
		$x_pad=0;
	}#if/else
	
	if (defined $option_HR->{'y_pad'}){
		$y_pad=$option_HR->{'y_pad'};
	}
	else {
		$y_pad=0;
	}#if/else

	if (defined $option_HR->{'x_scale'}){
		$x_scale=$option_HR->{'x_scale'};
	}
	else {
		$x_scale=1;
	}#if/else

	if (defined $option_HR->{'y_scale'}){
		$y_scale=$option_HR->{'y_scale'};
	}
	else {
		$y_scale=1;
	}#if/else

	if (defined $option_HR->{'title'}){
		$title=$option_HR->{'title'};
	}
	else {
		$title='Storm Tracking Map';
	}#if/else
	
	if (defined $option_HR->{'term'}){
		$term=$option_HR->{'term'};
	}
	else {
		$term='gif';
	}#if/else

	#Determine names for $data_file and $config_file.
	if (defined $option_HR->{'temp_dir'}){
		$temp_dir=$option_HR->{'temp_dir'};
	}
	else {
		$temp_dir='/tmp/';
	}

	$temp_dir =~ s!/*!/!;
	$data_file=$temp_dir."datafile_$$";
	$config_file=$temp_dir."configfile_$$";

	#Figure out what kind of track was passed.
	#If necessary convert ($long, $long_dir, $lat, $lat_dir) form to xy form.
	if (scalar(@{${$track_AR}[0]}) == 2){
		$xy_data_AR=$track_AR;
	}
	else {
		#Get the track in x,y form as well as check the syntax of the position arrays.
		($xy_data_AR,$error)=$self->_generate_xy_data($track_AR);

		#Abort if _generage_xy_data had a problem.
		return (0,$error) unless (defined $xy_data_AR);
	}#if/else

	#Write out the data file for gnuplot to plot.
	($success, $error)=$self->_write_plot_data_file($xy_data_AR,$data_file);
	return (0,$error) unless ($success);


	($x_range_AR,$y_range_AR,$error)=$self->_get_range({
								x_pad => $x_pad,
								y_pad => $y_pad,
								x_scale => $x_scale,
								y_scale => $y_scale,
								center_point => ${$xy_data_AR}[0],
								});

	return (0, $error) unless ( (defined $x_range_AR) and (defined $y_range_AR) );

	#Write out the config file for gnuplot.
	($success, $error)=$self->_write_plot_config_file({
							'config_file'=>$config_file,
							'data_file'=>$data_file,
							'output'=>$output_file,
							'xrange' => $x_range_AR,
							'yrange' => $y_range_AR,
							'term' => $term,
							'title' => $title,
							});
	return (0,$error) unless ($success);

	#Call gnuplot on the config file.
	($success, $error)=$self->_call_gnuplot($config_file);
	return (0,$error) unless ($success);

	#Erase temporary files
	($success, $error)=$self->_wack_files($data_file, $config_file);
	return (0,$error) unless ($success);

	return (1,undef);

}#plot_track
#-------------------------------------------------------
sub plot_radius_function {
	my $self=shift;
	my $output_file=shift;
	my $output_file2=shift;
	my $option_HR=shift;

	my ($term, $temp_dir)=undef;
	my ($data_file, $data_file2, $config_file, $config_file2, $config_file3, $map_file)=undef;
	my ($gnuplot_script, $gnuplot_script2, $gnuplot_script3)=undef;	
	my ($success, $error)=undef;

	if (defined $option_HR->{'term'}){
		$term=$option_HR->{'term'};
	}
	else {
		$term='gif';
	}#if/else

	#Determine names for $data_file and $config_file.
	if (defined $option_HR->{'temp_dir'}){
		$temp_dir=$option_HR->{'temp_dir'};
	}
	else {
		$temp_dir='/tmp/';
	}

	$temp_dir =~ s!/*!/!;

	$data_file=$temp_dir."datafile_$$";
	$data_file2=$temp_dir."datafile2_$$";

	$config_file=$temp_dir."configfile_$$";
	$config_file2=$temp_dir."configfile2_$$";
	$config_file3=$temp_dir."configfile3_$$";

	$map_file=$self->{'map_file'};

	#######
	#Generate 3d radius data
	($success, $error)=$self->_generate_radius_data_file($data_file);

	########
	#Create a 2d contour file from the 3d data

	$gnuplot_script="set nosurface\nset contour\nset cntrparam levels 15\nset term table\nset output \'$data_file2\'\nsplot \'$data_file\'\n";

	($success,$error)=$self->_make_file($config_file,$gnuplot_script);
	return (0,$error) unless ($success);

	#Call gnuplot on the config file.
	($success, $error)=$self->_call_gnuplot($config_file);
	return (0,$error) unless ($success);


	########
	#Plot the contour ontop of the world map
	$gnuplot_script2 = "set nokey\nset border\nset xtics\nset ytics\nset term $term\n";
	$gnuplot_script2 .= "set output \'$output_file\'\nplot \'$data_file2\' with lines, \'$map_file\' with lines\n";

	($success,$error)=$self->_make_file($config_file2,$gnuplot_script2);
	return (0,$error) unless ($success);

	#Call gnuplot on the config file.
	($success, $error)=$self->_call_gnuplot($config_file2);
	return (0,$error) unless ($success);

	#######
	#Plot the 3d contour plot
	$gnuplot_script3 = "set key\nset hidden\nset border\nset xtics\nset ytics\nset term $term\n";
	$gnuplot_script3 .= "set contour base\nset cntrparam levels 15\nset autoscale\n";
	$gnuplot_script3 .= "set output \'$output_file2\'\nsplot \'$data_file\' with lines\n";

	($success,$error)=$self->_make_file($config_file3,$gnuplot_script3);
	return (0,$error) unless ($success);

	#Call gnuplot on the config file.
	($success, $error)=$self->_call_gnuplot($config_file3);
	return (0,$error) unless ($success);


	########
	#Erase temporary files
	($success, $error)=$self->_wack_files($data_file, $data_file2, $config_file, $config_file2, $config_file3);
	return (0,$error) unless ($success);

	#######
	#All done
	return (1,undef);

}#plot_radius_function
#-------------------------------------------------------
sub _make_file {
	my $self=shift;
	my $filename=shift;
	my $string=shift;

	my ($io, $msg)=undef;

	$io=IO::File->new();
	unless ($io->open(">$filename")){
		$msg = "Had trouble writting to $filename!";
                carp $msg,"\n";
                return (0, $msg);
        }#unless
	$io->print($string);
	$io->close();

	return (1,undef);

}#_make_file
#-------------------------------------------------------
sub _wack_files {
	my $self=shift;
	my @files=@_;

	my ($msg, $file)=undef;

	unless ($DEBUG) {
		foreach $file (@files){
			unless(unlink $file){
				$msg="The $file file could not be erased!";
				carp $msg,"\n";
				return (0,$msg); 
			}#unless
		}#foreach
	}#unless

	return (1, undef);
}#_wack_files
#-------------------------------------------------------
sub _generate_radius_data_file {
	my $self=shift;
	my $data_file=shift;

	my ($io, $x, $y, $radius, $error, $msg)=undef;

	$io=IO::File->new() or croak "Couldn't create new io object!";
	unless ($io->open(">$data_file")){
		$msg="Couldn't open $data_file for writing!";
		carp $msg, "\n";
		return (0, $msg);
	}#unless

	for ($x=-180; $x<=180; $x+=3){
		for ($y=-90; $y<=90; $y+=3){
			($radius, $error)=$self->radius_function([$x, $y]);
                        return (0, $error) unless (defined $radius);
                        $io->print("$x\t$y\t$radius\n");
		}#for
		$io->print("\n");
	}#for	

	$io->close();

	return (1,undef);
}#_generate_radius_data_file
#-------------------------------------------------------
#($x_range_AR,$y_range_AR,$error)=$self->_get_range({
#							x_pad => 1,
#							y_pad => 1,
#							x_scale => 2.5,
#							y_scale => 2.5,
#							center_pont => ${$xy_data_AR}[0]), # or [2,5] 
#							});
sub _get_range {
	my $self=shift;
	my $option_HR=shift;

	my ($radius, $error, $x_pad, $y_pad, $x_scale, $y_scale, $center_point)=undef;
	my ($x_low, $x_high, $y_low, $y_high, $x_center, $y_center, $msg)=undef;

	$x_pad=$option_HR->{'x_pad'};
	$y_pad=$option_HR->{'y_pad'};
	$x_scale=$option_HR->{'x_scale'};
	$y_scale=$option_HR->{'y_scale'};
	$center_point=$option_HR->{'center_point'};
	$x_center=${$center_point}[0];
	$y_center=${$center_point}[1];

	unless ((defined $x_pad) and (defined $y_pad) and
		(defined $x_scale) and (defined $y_scale) and
		(defined $center_point)){
		$msg="_get_range requires valid x_pad, y_pad, x_scale, y_scale, and ";
		$msg .= "center_point keys in its mandatory hash reference argument.  ";
		$msg .= "At least one of these was ill defined!";
		carp $msg, "\n";
		return (undef, undef, $msg);
	}#unless

	#Determine the plot radius.	
	($radius, $error)=$self->radius_function($center_point);

	unless (defined $radius){
		return (undef, undef, $error);
	}

	$y_low=$y_center-$radius*$y_scale-$y_pad;
	if ($y_low < -90){
		$y_low= -90;
	}#if

	$y_high=$y_center+$radius*$y_scale+$y_pad;

	if ($y_high > 90){
		$y_high=90;
	}#if

	$x_low=$x_center-$radius*$x_scale-$x_pad;
	if ($x_low < -180){
		$x_low=180;
	}#if

	$x_high=$x_center+$radius*$x_scale+$x_pad;
	if ($x_high > 180){
		$x_high=180;
	}#if


	return ([$x_low, $x_high],[$y_low, $y_high], undef);

}#_get_range
#-------------------------------------------------------
sub _call_gnuplot {
	my $self=shift;
	my $config_file=shift;

	my ($gnuplot, $msg, $exit_status, $error)=undef;

	$gnuplot=$self->{'gnuplot'};

	unless (-e $gnuplot){
		$msg="Gnuplot executable could not be found at $gnuplot!";
		$msg.="  Examine new method of Geo::GNUPlot!";
		carp $msg,"\n";
		return (0,$msg);
	}#unless

	$exit_status=system("$gnuplot $config_file");
	$error=$!;
	$exit_status=$exit_status/256;
	unless ($exit_status == 0){
		$msg="Execution of gnuplot failed.  Exit status was $exit_status.  Error was $error";
		carp $msg,"\n";
		return (0,$msg);
	}#unless

	return (1,undef);
}#_call_gnuplot
#-------------------------------------------------------
sub _write_plot_config_file {
	my $self=shift;
	my $option_HR=shift;

	my ($io, $msg)=undef;

	$io=IO::File->new();
	unless ($io->open($option_HR->{'config_file'},'w')){
		$msg="Couldn't open ".$option_HR->{'configfile'}." for writting!";
		carp $msg,"\n";
		return (0,$msg);
	}#unless

	#Key option
	if (!defined $option_HR->{'key'}){
		$io->print("set nokey\n");
	}
	elsif ($option_HR->{'key'}){
		$io->print("set key\n");
	}
	else {
		$io->print("set nokey\n");
	}#if/elsif/else

	#Border option
	if (!defined $option_HR->{'border'}){
		$io->print("set border\n");
	}
	elsif ($option_HR->{'border'}){
		$io->print("set border\n");
	}
	else {
		$io->print("set noborder\n");
	}#if/elsif/else

	#Yzeroaxis option
	if (!defined $option_HR->{'yzeroaxis'}){
		$io->print("set yzeroaxis\n");
	}
	elsif ($option_HR->{'yzeroaxis'}){
		$io->print("set yzeroaxis\n");
	}
	else {
		$io->print("set noyzeroaxis\n");
	}#if/elsif/else

	#Xzeroaxis option
	if (!defined $option_HR->{'xzeroaxis'}){
		$io->print("set noxzeroaxis\n");
	}
	elsif ($option_HR->{'xzeroaxis'}){
		$io->print("set xzeroaxis\n");
	}
	else {
		$io->print("set noxzeroaxis\n");
	}#if/elsif/else

	#X and Y range
	if((defined $option_HR->{'xrange'}) and (defined $option_HR->{'yrange'})){
		$io->print("set xrange \[",${$option_HR->{'xrange'}}[0],":",${$option_HR->{'xrange'}}[1],"\]\n");
		$io->print("set yrange \[",${$option_HR->{'yrange'}}[0],":",${$option_HR->{'yrange'}}[1],"\]\n");
	}
	else {
		$io->print("set autoscale\n");
	}#if/else

	#Xtics option
	if (!defined $option_HR->{'xtics'}){
		$io->print("set xtics\n");
	}
	elsif ($option_HR->{'xtics'}){
		$io->print("set xtics\n");
	}
	else {
		$io->print("set noxtics\n");
	}#if/elsif/else

	#Ytics option
	if (!defined $option_HR->{'ytics'}){
		$io->print("set ytics\n");
	}
	elsif ($option_HR->{'ytics'}){
		$io->print("set ytics\n");
	}
	else {
		$io->print("set noytics\n");
	}#if/elsif/else

	if ($option_HR->{'title'}){
		$io->print("set title \'".$option_HR->{'title'}."\'\n");
	}#if

	if (!defined $option_HR->{'output'}){
		$msg="output option to _write_plot_config_file must be set!";
		carp $msg,"\n";
		return (0,$msg);
	}
	elsif ($option_HR->{'output'}){
		$io->print("set output \'".$option_HR->{'output'}."\'\n");
	}#if/elsif

	#set term
	if (defined $option_HR->{'term'}){
		$io->print("set term ",$option_HR->{'term'},"\n");
	}
	else {
		$io->print("set term gif\n");
	}#if/else

	#Check to make sure datafile exists.
	unless ( (defined $option_HR->{'data_file'}) and (-e $option_HR->{'data_file'}) ){
		$msg="data_file option to _write_plot_config_file is not set or the file doesn't exist!";
		carp $msg,"\n";
		return (0,$msg);
	}#unless

	$io->print("plot \'",$self->{'map_file'},"\' with lines 1 2\, \'",
			$option_HR->{'data_file'},"\' using 1:2 with lines 3 4\n");

	$io->close();

	return (1,undef);	
}#_write_plot_config_file
#-------------------------------------------------------
sub _generate_xy_data {
	my $self=shift;
	my $track_AR=shift;

	my ($position_AR, $xy_AR, $error)=undef;
	my @xy_data=();
	
	foreach $position_AR (@{$track_AR}){
		($xy_AR, $error)=$self->_position_to_xy($position_AR);
		return (undef, $error) unless (defined $xy_AR);
		push (@xy_data,$xy_AR);
	}#foreach

	return (\@xy_data,undef);
}#_generate_xy_data
#-------------------------------------------------------
sub _write_plot_data_file {
	my $self=shift;
	my $xy_data_AR=shift;
	my $filename=shift;

	my ($io, $msg, $xy_AR)=undef;

	$io=IO::File->new();
	unless ( $io->open(">$filename") ) {
		$msg="Couldn't open $filename for writting in _write_plot_data_file!";
		carp $msg,"\n";
		return (0,$msg);
	}#unless
	foreach $xy_AR (@{$xy_data_AR}){
		$io->print(join("\t",@{$xy_AR}),"\n");
	}#foreach
	$io->close();

	return (1,undef);
}#_write_plot_data_file
#-------------------------------------------------------
sub _read_grid {
	my $self=shift;
	my $config_file=shift;

	my ($io, $msg, $anon_HR, $y_index, $in_line, $xtics, $ytics, $radius_grid)=undef;
	my ($matches, $i)=undef;
	my @xtics=();
	my @ytics=();
	my @x_array=();
	my $grid_HR={};

	$io=IO::File->new();
	unless($io->open("<$config_file")){
		$msg="Couldn't open $config_file!";
		carp $msg,"\n";
		return (undef, $msg);
	}#unless;

	$y_index=-1;

	while (defined($in_line=$io->getline)){
		chomp $in_line;

		#Watch for comment lines
		next if (($in_line =~ m!^\s*#!) or ($in_line =~ m!^\s*$!));

		unless ($xtics){
			$matches=($in_line=~ m!^xtics\:(.*)!i);
			if ($matches){
				@xtics=split(',',$1);
				$xtics=scalar(@xtics);
				#get rid of any spaces around the numbers.
				map {s!([\d\.]*)!$1!} @xtics;
				if ($self->_is_assending(@xtics)){
					next;
				}
				else {
					$msg="xtics are not in numerically assending order ";
					$msg.="or has undefined values!";
					carp $msg,"\n";
					return (undef,$msg);
				}#if/else
			}
			else {
				next;
			}#if/else
		}#unless

		unless ($ytics){
			$matches=($in_line=~ m!^ytics\:(.*)!i);
			if ($matches){
				@ytics=split(',',$1);
				$ytics=scalar(@ytics);
				#get rid of any spaces around the numbers.
				map {s!([\d\.]*)!$1!} @ytics;
				if ($self->_is_descending(@ytics)){
					next;
				}
				else {
					$msg="ytics are not in numerically descending order ";
					$msg.="or has undefined values!";
					carp $msg,"\n";
					return (undef,$msg);
				}#if/else
			}
			else {
				next;
			}#if/else
		}#unless

		unless ($radius_grid){
			$matches=($in_line=~ m!^radius_grid\:!i);
			$radius_grid=1 if ($matches);
			next;
		}#unless

		@x_array=split("\t",$in_line);
		unless (scalar(@x_array) == $xtics){
			$msg="Badly formed radius_grid!  Too many columns!";
			carp $msg,"\n";
			return (undef,$msg);
		}#unless

		#get rid of any spaces around the numbers.
		map {s!([\d\.]*)!$1!} @x_array;


		#Increment y_index	
		$y_index++;

		#Make sure there are not too many rows.
		if ($y_index >= $ytics){
			$msg="Badly formed radius_grid!  Too many rows!";
			carp $msg, "\n";
			return (undef,$msg);
		}#if

		$anon_HR={};
		for ($i=0; $i<$xtics; $i++){
			$anon_HR->{${xtics}[$i]}=$x_array[$i];
		}#for

		$grid_HR->{${ytics}[$y_index]}=$anon_HR;

	}#while

	return ($grid_HR,undef);

}#_read_grid
#-------------------------------------------------------
#Returns 1 only if all elements of the input array
#are numerically decreasing and defined.
#Returns 0 otherwise.
sub _is_descending {
	my $self=shift;
	my @array=@_;

	my ($last_elem, $elem)=undef;

	foreach $elem (@array){
		return 0 if (!defined $elem);
		if (defined $last_elem){
			if ($elem < $last_elem){
				$last_elem=$elem;
				next;
			}
			else {
				return 0;
			}#if/else
		}
		else{
			$last_elem=$elem;
		}#if/else
	}#foreach
	return 1;
}#_is_descending
#-------------------------------------------------------
#Returns 1 only if all elements of the input array
#are numerically increasing and defined.
#Returns 0 otherwise.
sub _is_assending {
	my $self=shift;
	my @array=@_;

	my ($last_elem, $elem)=undef;

	foreach $elem (@array){
		return 0 if (!defined $elem);
		if (defined $last_elem){
			if ($elem > $last_elem){
				$last_elem=$elem;
				next;
			}
			else {
				return 0;
			}#if/else
		}
		else{
			$last_elem=$elem;
		}#if/else
	}#foreach
	return 1;
}#_is_assending
#-------------------------------------------------------
#If $position_AR has 2 elements it is assumed the incomming position is in x,y form.
#Otherwise it is assumed the incomming position is in ($long, $long_dir, $lat, $lat_dir) form.
sub radius_function {
	my $self=shift;
	my $position_AR=shift;
	
	my ($xkey1, $xkey2, $ykey1, $ykey2, $xy_AR, $x, $y, $msg)=undef;
	my ($grid_HR, $x_delta_from_xkey1, $delta_xkey, $y_delta_from_ykey1, $delta_ykey)=undef;
	my ($f1, $f2, $f3, $f4, $t, $u, $f_interpolated)=undef;

	if (scalar(@{$position_AR}) == 2){
		$xy_AR=$position_AR;
	}
	else {
		#Get the postion in x,y form as well as check the syntax of the referenced position array.
		($xy_AR,$msg)=$self->_position_to_xy($position_AR);

		#Abort if _position_to_xy had a problem. 
		return (undef,$msg) unless (defined $xy_AR);
	}#if/else

	#Determine high and low key values for both the y and the x axis.
	$x=${$xy_AR}[0];
	$y=${$xy_AR}[1];
	
	($xkey1,$xkey2,$ykey1,$ykey2)=$self->_find_grid_square($x,$y);

	#Using equation 3.6.3, 3.6.4, and 3.6.5 on page 117 of
	#Numerical Recipes in Fortran 77 (Second Edition)
	#ISBN 0-521-43064-X

	$grid_HR=$self->{'grid_HR'};

	#Using f instead of y in eq. 3.6.3

	$f1=$grid_HR->{$ykey1}->{$xkey1};
	$f2=$grid_HR->{$ykey1}->{$xkey2};
	$f3=$grid_HR->{$ykey2}->{$xkey2};
	$f4=$grid_HR->{$ykey2}->{$xkey1};

	if ($xkey1 > $x){
		$x_delta_from_xkey1=(180-$xkey1)+$x;
		$delta_xkey=(180-$xkey1)+$xkey2;
	}
	else {
		$x_delta_from_xkey1=$x-$xkey1;
		$delta_xkey=$xkey2-$xkey1;
	}#if/else

	$t=$x_delta_from_xkey1/$delta_xkey;

	if ($ykey1 == $ykey2){
		#deal with infinity problem by just interpolating x values. 
		$f_interpolated=$x_delta_from_xkey1*($f1-$f2)/$delta_xkey + $f1;
		return ($f_interpolated,undef);
	}
	else {
		$y_delta_from_ykey1=$y-$ykey1;
		$delta_ykey=$ykey2-$ykey1;
	}#if/else

	$u=$y_delta_from_ykey1/$delta_ykey;

	$f_interpolated=(1-$t)*(1-$u)*$f1+$t*(1-$u)*$f2+$t*$u*$f3+(1-$t)*$u*$f4;

	return ($f_interpolated,undef);

}#radius_function
#-------------------------------------------------------------------------------
sub _position_to_xy {
	my $self=shift;
	my $position_AR=shift;

	my ($lat, $lat_dir, $long, $long_dir, $msg, $x, $y)=undef;

        #Check the argument for problems.
        ($lat,$lat_dir,$long,$long_dir)=@{$position_AR};
        unless (
                ($lat =~ m!^\d+(\.\d*)?$!) and
                ($long =~ m!^\d+(\.\d*)?$!) and
                ($lat_dir =~ m!^[NS]$!) and
                ($long_dir =~ m!^[WE]$!) and
                (($lat <= 90) and ($lat >= 0)) and
                (($long <= 180) and ($long >= 0))
                ){
                $msg="Bad arguments passed to radius_function!";
                carp $msg,"\n";
                return (undef,$msg);
        }#unless
 
        #Translate longitude and latitude into x,y values.
        if ($lat_dir eq 'N'){
                $y=$lat;
        }
        else {
                $y=-$lat;
        }#if/else
 
        if ($long_dir eq 'E'){
                $x=$long;
        }
        else {
                $x=-$long;
        }#if/else

	return ([$x,$y],undef); 

}#_position_to_xy
#-------------------------------------------------------------------------------
sub _find_grid_square {
	my $self=shift;
	my $x=shift;
	my $y=shift;
 
	my ($xval, $yval, $xkey1, $xkey2, $ykey1, $ykey2)=undef;
	my ($xtics, $ytics, $i, $grid_HR)=undef;
	my @ykeys=();
	my @sorted_ykeys=();
	my @xkeys=();
	my @sorted_xkeys=();
	
	$grid_HR=$self->{'grid_HR'};

	@ykeys=keys %{$grid_HR};
	@sorted_ykeys = sort {$a<=>$b} @ykeys;

	$ytics=scalar(@sorted_ykeys);

	for ($i=0; $i <= $ytics; $i++){
		$yval=$sorted_ykeys[$i];
		if (
			( ($i == $ytics-1) and ($yval <= $y) ) or
			( ($i == 0) and ($yval > $y) )
			){
			$ykey1=$sorted_ykeys[$i];
			$ykey2=$sorted_ykeys[$i];
			last;
		}
		elsif ($yval <= $y){
			$ykey1=$yval;
			next;
		}
		else {
			$ykey2=$yval;
			last;
		}#if/elsif/else
	}#for

	@xkeys=keys %{$grid_HR->{$ykey1}};
	@sorted_xkeys = sort {$a<=>$b} @xkeys;


	$xtics=scalar(@sorted_xkeys);

	for ($i=0; $i <= $xtics; $i++){
		$xval=$sorted_xkeys[$i];
		if (
			( ($i == $xtics-1) and ($xval <= $x) ) or
			( ($i == 0) and ($xval > $x) )
			){
			$xkey1=$sorted_xkeys[$xtics-1];
			$xkey2=$sorted_xkeys[0];
			last;
		} 
		elsif ($xval <= $x){
			$xkey1=$xval;
			next;
		}
		else {
			$xkey2=$xval;
			last;
		}#if/elsif/else
	}#for

	return ($xkey1,$xkey2,$ykey1,$ykey2);

}#_find_grid_square
#-------------------------------------------------------
1;

__END__


=head1 NAME

Geo::GNUPlot - Perl extension for plotting position tracks onto a world map.

=head1 SYNOPSIS

	use Geo::GNUPlot;

	$option_HR={
			'grid_file' => '/home/test/grid_file',
			'map_file' => '/home/test/map_file',
			'gnuplot' => '/usr/local/gnuplot',
			};

	$plot_obj=Geo::GNUPlot->new($option_HR);

	$track_AR=[
			[15, 50], #x,y pair
			[5.3, 10.2],
			[-2, -5]
		  ];

	or
	
	$track_AR=[
			[50, N, 15, E], #latitude, lat. direction, longitude, long. direction
			[10.2, N, 5.3, E],
			[5, S, 2, W]
		  ];

	$output_file='/home/test/plot.gif';

	$plot_option_HR={
			'x_pad' => 2, #default 0
			'y_pad' => 3, #default 0
			'x_scale' => 5, #default 1
			'y_scale' => 4, #default 1
			'title' => 'Example Plot', #default 'Storm Tracking Map'
			'term' => 'gif', #default gif  {any valid gnuplot term argument}
			'temp_dir' => '/home/tmp/', #default '/tmp/'
			};

	#Create the plot.
	($success, $error)=$plot_obj->plot_track($track_AR, $output_file, $plot_option_HR);

	####
	#For diagnostic purposes, create a contour and surface plot of the radius function.

	$contour_plot='/home/test/radius_contour.gif';

	$surface_plot='/home/test/radius_surface.gif';

	#Only the temp_dir, and term option values will be used.
	($success,$error)=$plot_obj->plot_radius_function($contour_plot, $surface_plot, $plot_option_HR);


	####
	#Determine the radius function value at a given position.
	$position_AR=[5.3, 10.2];

	or

	$position_AR=[10.2, N, 5.3, E];

	($function_value, $error)=$plot_obj->radius_function($position_AR);
	
	

=head1 DESCRIPTION

This program plots a set of latitude/longitude pairs as a track
on a world map using gnuplot.  The plot radius is determined by
a user defined radius function.

=head1 IMPLEMENTATION

This program utilizes gnuplot by generating temporary gnuplot
configuration files and then running gnuplot on these files.
The knowledge of what xrange and yrange to use in the gnuplot
configuration files is determined by a user defined radius function,
an x and y padding, and an x and y scaling of the radius function.

The radius function is controlled by user defined node values
on a user defined irregular grid.  Values between the nodes
are computed using two dimensional linear interpolation.  I used
Numerical Recipes in Fortran 77 page 117 equations 3.6.3, 3.6.4, and
3.6.5 as a reference.  It is a simple formula and can be derived
from scratch without too much effort.  If you don't like this approach
then simply override the radius_function method with your own.  Better
yet, provide your improved version to the current maintainer of this
package.  In the event Jimmy Carpenter (myself) is still the maintainer,
offer to take over!

The irregular grid and node values are set in the grid_file file.
An example is shown below:

	#xtics must be numerically ascending
	xtics: -170, -70, -50, -30, -10, 30, 180
	#ytics must be numerically descending
	ytics: 90, 80, 60, 40, 20, 0, -60, -90
	#	
	radius_grid:
	5	4	5	5	8	8	9
	5	4	5	5	8	8	9
	5	4	5	5	8	8	2
	5	6	5	5	6	3	9
	5	4	8	5	8	8	2
	5	3	5	5	7	8	9
	5	4	5	5	8	8	6
	5	4	5	5	8	8	9

To see what this looks like, just cut and paste this example into a file
and generate a contour and surface plot using the plot_radius_function
method.  To see how this function affects the plot window try out
the plot_track method for various positions.

The objective of the radius function approach is to allow the user
to correlate interest level to plot zoom level. In the event you live in
Houston you probably don't care too much about how close a hurricane
is to some small deserted island in the Atlantic Ocean.  Your concern
will be how close the hurricane is to your home in Houston.
It is also possible to create a radius function that insures a plot
of a hurricane in the middle of the Atlantic Ocean has a wide enough
plot window to show some land that provides context.

=head1 CONSTRUCTOR

=over 4

=item new (HASH_REF)

Creates and returns a new C<Geo::GNUPlot> object.  If unsuccessful
it returns an undefined value.  The mandatory hash reference argument
should contain the following keys and associated values:

	grid_file:  contains path to the grid file
	map_file:  contains a 2D map of the world (provided with bundle)
	gnuplot:  contains path to gnuplot executable

=back

=head1 METHODS

=over 4

=item plot_track(TRACK_ARRAY_REF, OUTPUT_FILE, OPTION_HASH_REF)

Creates a plot of the position track provided by the TRACK_ARRAY_REF 
and outputs it to the OUTPUT_FILE filename.  The plot configuration
options are contained in the OPTION_HASH_REF.

The plot_track method returns an array of the form (SUCCESS, ERROR).
SUCCESS indicates if the method successfully generated a plot.
ERROR contains the reason for any failure.  If the method was
successful ERROR will be undefined.

The TRACK_ARRAY_REF is an array of position arrays.  The position
arrays can be either x,y pairs, or an array of the form
(LATTITUDE, LATTITUDE_DIR, LONGITUDE, LONGITUDE_DIR).  The plot
will be centered around the first position in the TRACK_ARRAY_REF.

The OUTPUT_FILE is the full path of the filename to use as output.

The OPTION_HASH_REF contains configuration options for the plot.
The valid option keys, descriptions, and default values are given below.

	x_pad:		Determines the additional X padding for the plot.
			Defaults to 1.

	y_pad:		Determines the additional Y padding for the plot.
			Defaults to 1.

	x_scale:	Scales the radius value returned by the
			radius_function method for use in determining
			the xrange of the plot.
			Defaults to 1.

	y_scale:	Scales the radius value returned by the
			radius_function method for use in determining
			the yrange of the plot.
			Defaults to 1.

	title:		Sets the plot title.
			Defaults to 'Storm Tracking Map'.

	term:		Sets the gnuplot terminal type.  See gnuplot
			documentation for more details.
			Defaults to 'gif'.

	temp_dir:	Sets the directory to use for writing temporary
			configuration and data files.
			Defaults to '/tmp/'.


=item plot_radius_function(CONTOUR_OUTPUT_FILE, SURFACE_OUTPUT_FILE, OPTION_HASH_REF)

Creates a 2D contour and 3D surface plot of the radius function.  This
enables the user to better visualize the radius function and how it is
being interpolated from the provided node values.  The 2D contour plot overlays
the world map provided by the map_file during construction of the
C<Geo::GNUPlot> object.

The CONTOUR_OUTPUT_FILE is the full path of the filename to use for the contour plot.

The SURFACE_OUTPUT_FILE is the full path of the filename to use for the surface plot.

The OPTION_HASH_REF is identical in format to that used for the plot_track method, except
only the temp_dir and term key value pairs are needed or required.

The plot_radius_function method returns an array of the form (SUCCESS, ERROR).
SUCCESS indicates if the method successfully generated the plots.
ERROR contains the reason for any failure.  If the method was
successful ERROR will be undefined.


=item radius_function(POSITION_ARRAY_REF)

Provides direct access to the radius_function internally
used to compute plot window sizes.  This can be useful for
things such as sorting positions by interest level or
debugging changes to the radius function.

The POSITION_ARRAY_REF has the same two possible
forms as each element of the TRACK_ARRAY_REF argument
of the plot_track method.

=back

=cut

=head1 AUTHOR

James Lee Carpenter, Jimmy.Carpenter@chron.com

=head1 SEE ALSO

	Geo::StormTracker
	gnuplot
	perl(1).

=cut

=head1 ADDITIONAL REFERENCES

=over 4

=item gnuplot

	http://www.cs.dartmouth.edu/gnuplot_info.html 
        http://members.theglobe.com/gnuplot/ 
        http://www.geocities.com/SiliconValley/Foothills/6647/

=item linear interpolation

	Numerical Recipes in Fortran 77
	Second Edition
	(The Art of Scientific Computing)
	Authors:  William H. Press
		  William T. Vettering
		  Saul A. Teukolsky
		  Brian P. Flannery
	Pub:  Cambridge University Press
	ISBN:  0-521-43064-X
	Relevant Page:  117

=back

=cut
