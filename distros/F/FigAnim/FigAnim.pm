package FigAnim;

use strict;
use warnings;

our $VERSION = '0.1';

# useful classes
use FigAnim::Color;
use FigAnim::Arc;
use FigAnim::Compound;
use FigAnim::Ellipse;
use FigAnim::Polyline;
use FigAnim::Spline;
use FigAnim::Text;
use FigAnim::Utils;
use FigAnim::ConvertSVG;
use FigAnim::ConvertSMIL;
use Math::Trig qw(deg2rad
		  cartesian_to_cylindrical
		  cylindrical_to_cartesian);

# constructor
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    
    $self->{title} = "";
    
    # header
    $self->{version} = undef;
    $self->{orientation} = undef;
    $self->{justification} = undef;
    $self->{units} = undef;
    $self->{papersize} = undef;
    $self->{magnification} = undef;
    $self->{multiple_page} = undef;
    $self->{transparent_color} = undef;
    $self->{resolution} = undef;
    $self->{coord_system} = undef;
    
    # array containing the Color objects
    $self->{colors} = [];
    
    # arrays containing every object's name classified by type
    $self->{arcs} = [];
    $self->{compounds} = [];
    $self->{ellipses} = [];
    $self->{polylines} = [];
    $self->{splines} = [];
    $self->{texts} = [];
    
    # hash containing all the objects (except Color objects)
    # with their names as keys
    $self->{objects} = {};
    
    # number of the current unnamed object
    $self->{num} = 1;
    
    # array containing all the animations
    $self->{animations} = [];
    
    bless ($self, $class);
    return $self;
}


# methods
sub clone {
    my $self = shift;
    my $obj = new FigAnim;
    
    foreach ('title','version','orientation','justification','units',
	     'papersize','magnification','multiple_page','transparent_color',
	     'resolution','coord_system','arcs','compounds','ellipses',
	     'polylines','splines','texts') {
	$obj->{$_} = $self->{$_};
    }
    
    foreach (@{$self->{colors}}) {
	push @{$obj->{colors}}, $_->clone();
    }
    
    foreach (keys %{$self->{objects}}) {
	$obj->{objects}->{$_} = $self->{objects}->{$_}->clone();
	$obj->{objects}->{$_}->{fig_file} = $obj;
    }
    
    return $obj;
}


# parser
sub parseFile {
    my $self = shift;
    my $filename = shift;
    
    open IN, "<$filename" or die "Can't open $filename : $!\n";
    
    $self->parseHeader(\*IN);
    $self->parseObjects(\*IN,$self);
    
    close IN;
}

sub parseHeader {
    my $self = shift;
    my $fh = shift;
    
    my $line = <$fh>;
    return unless ($line =~ /^\#FIG (\d(.\d)*)\n$/);
    $self->{version} = $1;
    $self->{orientation} = nextline($fh);
    $self->{justification} = nextline($fh);
    $self->{units} = nextline($fh);
    $self->{papersize} = nextline($fh);
    $self->{magnification} = nextline($fh);
    $self->{multiple_page} = nextline($fh);
    $self->{transparent_color} = nextline($fh);
    while (($line = nextline($fh)) =~ /^\# /) {
	$line =~ s/\# //;
	$self->{title} .= $line . "\n";
    }
    ($self->{resolution}, $self->{coord_system}) = split / /, $line;
}

sub parseObjects {
    my $self = shift;
    my $fh = shift;
    my $current = shift;
    my ($line, $object_code, $object, @attr);
    my $name = "";
    
    while ($line = nextline($fh)) {
	return if ($line =~ /^-6/);
	
	@attr = split / /, $line;
	$object_code = shift @attr;
	
	if ($object_code eq "0") { # Color
	    $object = new Color(@attr);
	    push @{$self->{colors}}, $object;
	}
	
	elsif ($object_code eq "#") { # Comment
	    $line =~ s/^\# //;
	    $name .= $line . "\n";
	}
	
	elsif ($object_code eq "5") { # Arc
	    if ($attr[11]) { # forward_arrow == 1
		$line = nextline($fh);
		$line =~ s/^[\t ]*//;
		push @attr, (split / /, $line);
	    } else {
		push @attr, (undef,undef,undef,undef,undef);
	    }
	    
	    if ($attr[12]) { # backward_arrow == 1
		$line = nextline($fh);
		$line =~ s/^[\t ]*//;
		push @attr, (split / /, $line);
	    } else {
		push @attr, (undef,undef,undef,undef,undef);
	    }
	    
	    $name =~ s/\n$//;
	    if (($name =~ /^\n*$/) || (defined $self->{objects}->{$name})) {
		$name = sprintf("untitled%04d", $self->{num}++);
	    }
	    $object = new Arc($name,@attr,$self);
	    push @{$current->{arcs}}, $name;
	    $self->{objects}->{$name} = $object;
	    $name = "";
	}
	
	elsif ($object_code eq "6") { # Compound
	    $name =~ s/\n$//;
	    if (($name =~ /^\n*$/) || (defined $self->{objects}->{$name})) {
		$name = sprintf("untitled%04d", $self->{num}++);
	    }
	    $object = new Compound($name,@attr,$self);
	    $object->calculateCenter();
	    push @{$current->{compounds}}, $name;
	    $self->{objects}->{$name} = $object;
	    $name = "";
	    $self->parseObjects(\*IN,$object);
	}
	
	elsif ($object_code eq "1") { # Ellipse
	    $name =~ s/\n$//;
	    if (($name =~ /^\n*$/) || (defined $self->{objects}->{$name})) {
		$name = sprintf("untitled%04d", $self->{num}++);
	    }
	    $object = new Ellipse($name,@attr,$self);
	    push @{$current->{ellipses}}, $name;
	    $self->{objects}->{$name} = $object;
	    $name = "";
	}
	
	elsif ($object_code eq "2") { # Polyline
	    if ($attr[12]) { # forward_arrow == 1
		$line = nextline($fh);
		$line =~ s/^[\t ]*//;
		push @attr, (split / /, $line);
	    } else {
		push @attr, (undef,undef,undef,undef,undef);
	    }
	    
	    if ($attr[13]) { # backward_arrow == 1
		$line = nextline($fh);
		$line =~ s/^[\t ]*//;
		push @attr, (split / /, $line);
	    } else {
		push @attr, (undef,undef,undef,undef,undef);
	    }
	    
	    if ($attr[0] == 5) { # sub_type == 5
		$line = nextline($fh);
		$line =~ s/^[\t ]*//;
		push @attr, (split / /, $line);
	    } else {
		push @attr, (undef,undef);
	    }
	    
	    my $npoints = $attr[14];
	    my(@xnpoints, @ynpoints);
	    until ($npoints == 0) {
		$line = nextline($fh);
		$line =~ s/^[\t ]*//;
		my @points = split / /, $line;
		$npoints -= (scalar(@points) / 2);
		while (@points) {
		    push @xnpoints, (shift @points);
		    push @ynpoints, (shift @points);
		}
	    }
	    
	    $name =~ s/\n$//;
	    if (($name =~ /^\n*$/) || (defined $self->{objects}->{$name})) {
		$name = sprintf("untitled%04d", $self->{num}++);
	    }
	    $object = new Polyline($name,@attr,\@xnpoints,\@ynpoints,$self);
	    $object->calculateCenter();
	    push @{$current->{polylines}}, $name;
	    $self->{objects}->{$name} = $object;
	    $name = "";
	}
	
	elsif ($object_code eq "3") { # Spline
	    if ($attr[10]) { # forward_arrow == 1
		$line = nextline($fh);
		$line =~ s/^[\t ]*//;
		push @attr, (split / /, $line);
	    } else {
		push @attr, (undef,undef,undef,undef,undef);
	    }
	    
	    if ($attr[11]) { # backward_arrow == 1
		$line = nextline($fh);
		$line =~ s/^\t//;
		push @attr, (split / /, $line);
	    } else {
		push @attr, (undef,undef,undef,undef,undef);
	    }
	    
	    my $npoints = $attr[12];
	    my(@xnpoints, @ynpoints);
	    until ($npoints == 0) {
		$line = nextline($fh);
		$line =~ s/^[\t ]*//;
		my @points = split / /, $line;
		$npoints -= (scalar(@points) / 2);
		while (@points) {
		    push @xnpoints, (shift @points);
		    push @ynpoints, (shift @points);
		}
	    }
	    
	    $npoints = $attr[12];
	    my @control_points;
	    until ($npoints == 0) {
		$line = nextline($fh);
		$line =~ s/^[\t ]*//;
		my @points = split / /, $line;
		$npoints -= scalar(@points);
		push @control_points, @points;
	    }
	    
	    $name =~ s/\n$//;
	    if (($name =~ /^\n*$/) || (defined $self->{objects}->{$name})) {
		$name = sprintf("untitled%04d", $self->{num}++);
	    }
	    $object = new Spline($name,@attr,\@xnpoints,\@ynpoints,
				 \@control_points,$self);
	    $object->calculateCenter();
	    push @{$current->{splines}}, $name;
	    $self->{objects}->{$name} = $object;
	    $name = "";
	}
	
	elsif ($object_code eq "4") { # Text
	    my @new_attr = @attr[0..11];
	    my $chaine = "";
	    for (12..(scalar(@attr) - 1)) {
		$chaine .= $attr[$_] . " ";
	    }
	    $chaine =~ s/\\001 $//;
	    push @new_attr, $chaine;
	    
	    $name =~ s/\n$//;
	    if (($name =~ /^\n*$/) || (defined $self->{objects}->{$name})) {
		$name = sprintf("untitled%04d", $self->{num}++);
	    }
	    $object = new Text($name,@new_attr,$self);
	    $object->calculateCenter();
	    push @{$current->{texts}}, $name;
	    $self->{objects}->{$name} = $object;
	    $name = "";
	}
	
	else {
	    
	}
    }
}


# printer
sub writeFile {
    my $self = shift;
    my $filename = shift;
    
    open OUT, ">$filename" or die "Can't open $filename : $!\n";
    
    $self->writeHeader(\*OUT);
    $self->writeObjects(\*OUT);
    
    close OUT;
}

sub writeHeader {
    my $self = shift;
    my $fh = shift;
    
    printf $fh "#FIG %s\n", $self->{version};
    printf $fh "%s\n", $self->{orientation};
    printf $fh "%s\n", $self->{justification};
    printf $fh "%s\n", $self->{units};
    printf $fh "%s\n", $self->{papersize};
    printf $fh "%.2f\n", $self->{magnification};
    printf $fh "%s\n", $self->{multiple_page};
    printf $fh "%d\n", $self->{transparent_color};
    if ($self->{title} ne "") {
	foreach (split(/\n/, $self->{title})) {
	    printf $fh "# $_\n";
	}
    }
    printf $fh "%d %d\n", $self->{resolution}, $self->{coord_system};
}

sub writeObjects {
    my $self = shift;
    my $fh = shift;
    
    foreach (@{$self->{colors}}) {
	$_->output($fh);
    }
    
    foreach (@{$self->{arcs}}) {
	$self->{objects}->{$_}->output($fh);
    }
    
    foreach (@{$self->{compounds}}) {
	$self->{objects}->{$_}->output($fh);
    }
    
    foreach (@{$self->{ellipses}}) {
	$self->{objects}->{$_}->output($fh);
    }
    
    foreach (@{$self->{polylines}}) {
	$self->{objects}->{$_}->output($fh);
    }
    
    foreach (@{$self->{splines}}) {
	$self->{objects}->{$_}->output($fh);
    }
    
    foreach (@{$self->{texts}}) {
	$self->{objects}->{$_}->output($fh);
    }
}


# scheduler
sub generateGif {
    my $self = shift;
    my $file = shift;
    my $speed = shift;
    my $loop = shift;
    my $wait = shift;
    $wait = 0 if (!(defined $wait));
    
    my $length = 1;
    for (my $i=0; $i<scalar(@{$self->{animations}}); $i++) {
	# calculates the number of frames = first frame + number of frames of the each animation
	my $count = sprintf("%.0f",$self->{animations}[$i][2]*$speed) +
	    sprintf("%.0f",$self->{animations}[$i][3]*$speed);
	$length = $count if ($count > $length); # we choose the biggest number of frame
     }
    
    my $last = $self->clone(); # The first frame is the copy of the static image
    for (my $f=0; $f<=$length; $f++) { # for each frame do
	my $current = $last->clone(); # the current frame is the copy of precedent
	for (my $i=0; $i<scalar(@{$self->{animations}}); $i++) { # for each animation do
	    my $firstframe = sprintf("%.0f",$self->{animations}[$i][2]*$speed);
	    my $nbframes = sprintf("%.0f",$self->{animations}[$i][3]*$speed);
	    if (($f > $firstframe) && ($f <= $firstframe+$nbframes)) {
		# if the current frame is inside the current animation do 
		
		if ($self->{animations}[$i][0] == 1) { # changeThickness
		    my $name = $self->{animations}[$i][1];
		    my $inc = $self->{animations}[$i][5];
		    
		    $current->{objects}->{$name}->{thickness} =
			$last->{objects}->{$name}->{thickness} + $inc;
		}
		
		elsif ($self->{animations}[$i][0] == 2) { # changeFillIntensity
		    my $name = $self->{animations}[$i][1];
		    my $inc = $self->{animations}[$i][5];
		    
		    $current->{objects}->{$name}->{area_fill} =
			$last->{objects}->{$name}->{area_fill} + $inc;
		}
		
		elsif ($self->{animations}[$i][0] == 11) { # translate Ellipse
		    my $name = $self->{animations}[$i][1];
		    my $inc_x = $self->{animations}[$i][7];
		    my $inc_y = $self->{animations}[$i][8];
		    
		    $current->{objects}->{$name}->{center_x} =
			$last->{objects}->{$name}->{center_x} + $inc_x;
		    $current->{objects}->{$name}->{center_y} =
			$last->{objects}->{$name}->{center_y} + $inc_y;
		    
		    $current->{objects}->{$name}->{start_x} =
			$last->{objects}->{$name}->{start_x} + $inc_x;
		    $current->{objects}->{$name}->{start_y} =
			$last->{objects}->{$name}->{start_y} + $inc_y;
		    
		    $current->{objects}->{$name}->{end_x} =
			$last->{objects}->{$name}->{end_x} + $inc_x;
		    $current->{objects}->{$name}->{end_y} =
			$last->{objects}->{$name}->{end_y} + $inc_y;
		}
		elsif (($self->{animations}[$i][0] == 12) || # translate
		       ($self->{animations}[$i][0] == 13)) { #  Polyline/Spline
		    my $name = $self->{animations}[$i][1];
		    my $inc_x = $self->{animations}[$i][7];
		    my $inc_y = $self->{animations}[$i][8];
		    
		    for (my $i=0; $i<$current->{objects}->{$name}->{npoints};
			 $i++) {
			$current->{objects}->{$name}->{xnpoints}[$i] =
			    $last->{objects}->{$name}->{xnpoints}[$i] + $inc_x;
			$current->{objects}->{$name}->{ynpoints}[$i] =
			    $last->{objects}->{$name}->{ynpoints}[$i] + $inc_y;
		    }
		    
		    $current->{objects}->{$name}->{center_x} =
			$last->{objects}->{$name}->{center_x} + $inc_x;
		    $current->{objects}->{$name}->{center_y} =
			$last->{objects}->{$name}->{center_y} + $inc_y;
		}
		elsif ($self->{animations}[$i][0] == 14) { # translate Text
		    my $name = $self->{animations}[$i][1];
		    my $inc_x = $self->{animations}[$i][7];
		    my $inc_y = $self->{animations}[$i][8];
		    
		    $current->{objects}->{$name}->{x} =
			$last->{objects}->{$name}->{x} + $inc_x;
		    $current->{objects}->{$name}->{y} =
			$last->{objects}->{$name}->{y} + $inc_y;
		    
		    $current->{objects}->{$name}->{center_x} =
			$last->{objects}->{$name}->{center_x} + $inc_x;
		    $current->{objects}->{$name}->{center_y} =
			$last->{objects}->{$name}->{center_y} + $inc_y;
		}
		elsif ($self->{animations}[$i][0] == 15) { # translate Arc
		    my $name = $self->{animations}[$i][1];
		    my $inc_x = $self->{animations}[$i][7];
		    my $inc_y = $self->{animations}[$i][8];
		    
		    $current->{objects}->{$name}->{center_x} =
			$last->{objects}->{$name}->{center_x} + $inc_x;
		    $current->{objects}->{$name}->{center_y} =
			$last->{objects}->{$name}->{center_y} + $inc_y;
		    
		    $current->{objects}->{$name}->{x1} =
			$last->{objects}->{$name}->{x1} + $inc_x;
		    $current->{objects}->{$name}->{y1} =
			$last->{objects}->{$name}->{y1} + $inc_y;
		    
		    $current->{objects}->{$name}->{x2} =
			$last->{objects}->{$name}->{x2} + $inc_x;
		    $current->{objects}->{$name}->{y2} =
			$last->{objects}->{$name}->{y2} + $inc_y;
		    
		    $current->{objects}->{$name}->{x3} =
			$last->{objects}->{$name}->{x3} + $inc_x;
		    $current->{objects}->{$name}->{y3} =
			$last->{objects}->{$name}->{y3} + $inc_y;
		}
		elsif ($self->{animations}[$i][0] == 16) { # translate Compound
		    my $name = $self->{animations}[$i][1];
		    my $inc_x = $self->{animations}[$i][7];
		    my $inc_y = $self->{animations}[$i][8];
		    
		    $current->{objects}->{$name}->{upperleft_corner_x} =
			$last->{objects}->{$name}->{upperleft_corner_x}+$inc_x;
		    $current->{objects}->{$name}->{upperleft_corner_y} =
			$last->{objects}->{$name}->{upperleft_corner_y}+$inc_y;
		    
		    $current->{objects}->{$name}->{lowerright_corner_x} =
		       $last->{objects}->{$name}->{lowerright_corner_x}+$inc_x;
		    $current->{objects}->{$name}->{lowerright_corner_y} =
		       $last->{objects}->{$name}->{lowerright_corner_y}+$inc_y;
		    
		    $current->{objects}->{$name}->{center_x} =
			$last->{objects}->{$name}->{center_x} + $inc_x;
		    $current->{objects}->{$name}->{center_y} =
			$last->{objects}->{$name}->{center_y} + $inc_y;
		}
		
		elsif ($self->{animations}[$i][0] == 21) { # rotate Ellipse
		    my $name = $self->{animations}[$i][1];
		    my $c_x = $self->{animations}[$i][5];
		    my $c_y = $self->{animations}[$i][6];
		    my $inc_angle = $self->{animations}[$i][8];
		    my ($r,$a);
		    
		    ($r,$a) = cartesian_to_cylindrical(
				  $last->{objects}->{$name}->{center_x}-$c_x,
				  $last->{objects}->{$name}->{center_y}-$c_y,
				  0);
		    ($current->{objects}->{$name}->{center_x},
		     $current->{objects}->{$name}->{center_y}) =
			 cylindrical_to_cartesian($r,$a+$inc_angle,0);
		    $current->{objects}->{$name}->{center_x} += $c_x;
		    $current->{objects}->{$name}->{center_y} += $c_y;
		    
		    ($r,$a) = cartesian_to_cylindrical(
				  $last->{objects}->{$name}->{start_x}-$c_x,
				  $last->{objects}->{$name}->{start_y}-$c_y,
				  0);
		    ($current->{objects}->{$name}->{start_x},
		     $current->{objects}->{$name}->{start_y}) =
			 cylindrical_to_cartesian($r,$a+$inc_angle,0);
		    $current->{objects}->{$name}->{start_x} += $c_x;
		    $current->{objects}->{$name}->{start_y} += $c_y;
		    
		    ($r,$a) = cartesian_to_cylindrical(
				  $last->{objects}->{$name}->{end_x}-$c_x,
				  $last->{objects}->{$name}->{end_y}-$c_y,
				  0);
		    ($current->{objects}->{$name}->{end_x},
		     $current->{objects}->{$name}->{end_y}) =
			 cylindrical_to_cartesian($r,$a+$inc_angle,0);
		    $current->{objects}->{$name}->{end_x} += $c_x;
		    $current->{objects}->{$name}->{end_y} += $c_y;
		    
		    $current->{objects}->{$name}->{angle} =
			$last->{objects}->{$name}->{angle} - $inc_angle;
		}
		elsif (($self->{animations}[$i][0] == 22) || # rotate
		       ($self->{animations}[$i][0] == 23)) { #  Polyline/Spline
		    my $name = $self->{animations}[$i][1];
		    my $c_x = $self->{animations}[$i][5];
		    my $c_y = $self->{animations}[$i][6];
		    my $inc_angle = $self->{animations}[$i][8];
		    my ($r,$a);
		    
		    for (my $i=0; $i<$current->{objects}->{$name}->{npoints};
			 $i++) {
		    ($r,$a) = cartesian_to_cylindrical(
				  $last->{objects}->{$name}->{xnpoints}[$i]
						       - $c_x,
				  $last->{objects}->{$name}->{ynpoints}[$i]
						       - $c_y,
				  0);
		    ($current->{objects}->{$name}->{xnpoints}[$i],
		     $current->{objects}->{$name}->{ynpoints}[$i]) =
			 cylindrical_to_cartesian($r,$a+$inc_angle,0);
		    $current->{objects}->{$name}->{xnpoints}[$i] += $c_x;
		    $current->{objects}->{$name}->{ynpoints}[$i] += $c_y;
		    }
		    
		    ($r,$a) = cartesian_to_cylindrical(
				  $last->{objects}->{$name}->{center_x}-$c_x,
				  $last->{objects}->{$name}->{center_y}-$c_y,
				  0);
		    ($current->{objects}->{$name}->{center_x},
		     $current->{objects}->{$name}->{center_y}) =
			 cylindrical_to_cartesian($r,$a+$inc_angle,0);
		    $current->{objects}->{$name}->{center_x} += $c_x;
		    $current->{objects}->{$name}->{center_y} += $c_y;
		}
		elsif ($self->{animations}[$i][0] == 24) { # rotate Text
		    my $name = $self->{animations}[$i][1];
		    my $c_x = $self->{animations}[$i][5];
		    my $c_y = $self->{animations}[$i][6];
		    my $inc_angle = $self->{animations}[$i][8];
		    my ($r,$a);
		    
		    ($r,$a) = cartesian_to_cylindrical(
				  $last->{objects}->{$name}->{x}-$c_x,
				  $last->{objects}->{$name}->{y}-$c_y,
				  0);
		    ($current->{objects}->{$name}->{x},
		     $current->{objects}->{$name}->{y}) =
			 cylindrical_to_cartesian($r,$a+$inc_angle,0);
		    $current->{objects}->{$name}->{x} += $c_x;
		    $current->{objects}->{$name}->{y} += $c_y;
		    
		    $current->{objects}->{$name}->{angle} =
			$last->{objects}->{$name}->{angle} - $inc_angle;
		    
		    ($r,$a) = cartesian_to_cylindrical(
				  $last->{objects}->{$name}->{center_x}-$c_x,
				  $last->{objects}->{$name}->{center_y}-$c_y,
				  0);
		    ($current->{objects}->{$name}->{center_x},
		     $current->{objects}->{$name}->{center_y}) =
			 cylindrical_to_cartesian($r,$a+$inc_angle,0);
		    $current->{objects}->{$name}->{center_x} += $c_x;
		    $current->{objects}->{$name}->{center_y} += $c_y;
		}
		elsif ($self->{animations}[$i][0] == 25) { # rotate Arc
		    my $name = $self->{animations}[$i][1];
		    my $c_x = $self->{animations}[$i][5];
		    my $c_y = $self->{animations}[$i][6];
		    my $inc_angle = $self->{animations}[$i][8];
		    my ($r,$a);
		    
		    ($r,$a) = cartesian_to_cylindrical(
				  $last->{objects}->{$name}->{center_x}-$c_x,
				  $last->{objects}->{$name}->{center_y}-$c_y,
				  0);
		    ($current->{objects}->{$name}->{center_x},
		     $current->{objects}->{$name}->{center_y}) =
			 cylindrical_to_cartesian($r,$a+$inc_angle,0);
		    $current->{objects}->{$name}->{center_x} += $c_x;
		    $current->{objects}->{$name}->{center_y} += $c_y;
		    
		    ($r,$a) = cartesian_to_cylindrical(
				  $last->{objects}->{$name}->{x1}-$c_x,
				  $last->{objects}->{$name}->{y1}-$c_y,
				  0);
		    ($current->{objects}->{$name}->{x1},
		     $current->{objects}->{$name}->{y1}) =
			 cylindrical_to_cartesian($r,$a+$inc_angle,0);
		    $current->{objects}->{$name}->{x1} += $c_x;
		    $current->{objects}->{$name}->{y1} += $c_y;
		    
		    ($r,$a) = cartesian_to_cylindrical(
				  $last->{objects}->{$name}->{x2}-$c_x,
				  $last->{objects}->{$name}->{y2}-$c_y,
				  0);
		    ($current->{objects}->{$name}->{x2},
		     $current->{objects}->{$name}->{y2}) =
			 cylindrical_to_cartesian($r,$a+$inc_angle,0);
		    $current->{objects}->{$name}->{x2} += $c_x;
		    $current->{objects}->{$name}->{y2} += $c_y;
		    
		    ($r,$a) = cartesian_to_cylindrical(
				  $last->{objects}->{$name}->{x3}-$c_x,
				  $last->{objects}->{$name}->{y3}-$c_y,
				  0);
		    ($current->{objects}->{$name}->{x3},
		     $current->{objects}->{$name}->{y3}) =
			 cylindrical_to_cartesian($r,$a+$inc_angle,0);
		    $current->{objects}->{$name}->{x3} += $c_x;
		    $current->{objects}->{$name}->{y3} += $c_y;
		}
		elsif ($self->{animations}[$i][0] == 26) { # rotate Compound
		    my $name = $self->{animations}[$i][1];
		    my $c_x = $self->{animations}[$i][5];
		    my $c_y = $self->{animations}[$i][6];
		    my $inc_angle = $self->{animations}[$i][8];
		    my ($r,$a);
		    
		    ($r,$a) = cartesian_to_cylindrical(
			  $last->{objects}->{$name}->{upperleft_corner_x}-$c_x,
			  $last->{objects}->{$name}->{upperleft_corner_y}-$c_y,
				  0);
		    ($current->{objects}->{$name}->{upperleft_corner_x},
		     $current->{objects}->{$name}->{upperleft_corner_y}) =
			 cylindrical_to_cartesian($r,$a+$inc_angle,0);
		    $current->{objects}->{$name}->{upperleft_corner_x} += $c_x;
		    $current->{objects}->{$name}->{upperleft_corner_y} += $c_y;
		    
		    ($r,$a) = cartesian_to_cylindrical(
			 $last->{objects}->{$name}->{lowerright_corner_x}-$c_x,
			 $last->{objects}->{$name}->{lowerright_corner_y}-$c_y,
				  0);
		    ($current->{objects}->{$name}->{lowerright_corner_x},
		     $current->{objects}->{$name}->{lowerright_corner_y}) =
			 cylindrical_to_cartesian($r,$a+$inc_angle,0);
		    $current->{objects}->{$name}->{lowerright_corner_x} +=$c_x;
		    $current->{objects}->{$name}->{lowerright_corner_y} +=$c_y;
		    
		    ($r,$a) = cartesian_to_cylindrical(
				  $last->{objects}->{$name}->{center_x}-$c_x,
				  $last->{objects}->{$name}->{center_y}-$c_y,
				  0);
		    ($current->{objects}->{$name}->{center_x},
		     $current->{objects}->{$name}->{center_y}) =
			 cylindrical_to_cartesian($r,$a+$inc_angle,0);
		    $current->{objects}->{$name}->{center_x} += $c_x;
		    $current->{objects}->{$name}->{center_y} += $c_y;
		}
		
		elsif ($self->{animations}[$i][0] == 31) { # scale Ellipse
		    my $name = $self->{animations}[$i][1];
		    my $scale = $self->{animations}[$i][4];
		    my $c_x = $self->{animations}[$i][5];
		    my $c_y = $self->{animations}[$i][6];
		    my @incs_x = @{$self->{animations}[$i][7]};
		    my @incs_y = @{$self->{animations}[$i][8]};
		    my $r_x = $self->{animations}[$i][9];
		    my $r_y = $self->{animations}[$i][10];
		    
		    $current->{objects}->{$name}->{center_x} =
			$last->{objects}->{$name}->{center_x} + $incs_x[0];
		    $current->{objects}->{$name}->{center_y} =
			$last->{objects}->{$name}->{center_y} + $incs_y[0];
		    
		    $current->{objects}->{$name}->{start_x} =
			$last->{objects}->{$name}->{start_x} + $incs_x[1];
		    $current->{objects}->{$name}->{start_y} =
			$last->{objects}->{$name}->{start_y} + $incs_y[1];
		    
		    $current->{objects}->{$name}->{end_x} =
			$last->{objects}->{$name}->{end_x} + $incs_x[2];
		    $current->{objects}->{$name}->{end_y} =
			$last->{objects}->{$name}->{end_y} + $incs_y[2];
		    
		    $current->{objects}->{$name}->{radius_x} =
			$last->{objects}->{$name}->{radius_x} + $r_x;
		    $current->{objects}->{$name}->{radius_y} =
			$last->{objects}->{$name}->{radius_y} + $r_y;
		}
		elsif (($self->{animations}[$i][0] == 32) || # scale
		       ($self->{animations}[$i][0] == 33)) { #  Polyline/Spline
		    my $name = $self->{animations}[$i][1];
		    my $scale = $self->{animations}[$i][4];
		    my $c_x = $self->{animations}[$i][5];
		    my $c_y = $self->{animations}[$i][6];
		    my @incs_x = @{$self->{animations}[$i][7]};
		    my @incs_y = @{$self->{animations}[$i][8]};
		    
		    for (my $i=0; $i<$current->{objects}->{$name}->{npoints};
			 $i++) {
			$current->{objects}->{$name}->{xnpoints}[$i] =
			    $last->{objects}->{$name}->{xnpoints}[$i] +
			    $incs_x[$i];
			$current->{objects}->{$name}->{ynpoints}[$i] =
			    $last->{objects}->{$name}->{ynpoints}[$i] +
			    $incs_y[$i];
		    }
		    
		    $current->{objects}->{$name}->{center_x} =
			$last->{objects}->{$name}->{center_x} +
			$incs_x[$current->{objects}->{$name}->{npoints}];
		    $current->{objects}->{$name}->{center_y} =
			$last->{objects}->{$name}->{center_y} +
			$incs_y[$current->{objects}->{$name}->{npoints}];
		}
		elsif ($self->{animations}[$i][0] == 34) { # scale Text
		    my $name = $self->{animations}[$i][1];
		    my $scale = $self->{animations}[$i][4];
		    my $c_x = $self->{animations}[$i][5];
		    my $c_y = $self->{animations}[$i][6];
		    my @incs_x = @{$self->{animations}[$i][7]};
		    my @incs_y = @{$self->{animations}[$i][8]};
		    my $font_size = $self->{animations}[$i][9];
		    my $height = $self->{animations}[$i][10];
		    
		    $current->{objects}->{$name}->{x} =
			$last->{objects}->{$name}->{x} + $incs_x[0];
		    $current->{objects}->{$name}->{y} =
			$last->{objects}->{$name}->{y} + $incs_y[0];
		    
		    $current->{objects}->{$name}->{center_x} =
			$last->{objects}->{$name}->{center_x} + $incs_x[1];
		    $current->{objects}->{$name}->{center_y} =
			$last->{objects}->{$name}->{center_y} + $incs_y[1];
		    
		    $current->{objects}->{$name}->{font_size} =
			$last->{objects}->{$name}->{font_size} + $font_size;
		    $current->{objects}->{$name}->{height} =
			$last->{objects}->{$name}->{height} + $height;
		}
		elsif ($self->{animations}[$i][0] == 35) { # scale Arc
		    my $name = $self->{animations}[$i][1];
		    my $scale = $self->{animations}[$i][4];
		    my $c_x = $self->{animations}[$i][5];
		    my $c_y = $self->{animations}[$i][6];
		    my @incs_x = @{$self->{animations}[$i][7]};
		    my @incs_y = @{$self->{animations}[$i][8]};
		    
		    $current->{objects}->{$name}->{center_x} =
			$last->{objects}->{$name}->{center_x} + $incs_x[0];
		    $current->{objects}->{$name}->{center_y} =
			$last->{objects}->{$name}->{center_y} + $incs_y[0];
		    
		    $current->{objects}->{$name}->{x1} =
			$last->{objects}->{$name}->{x1} + $incs_x[1];
		    $current->{objects}->{$name}->{y1} =
			$last->{objects}->{$name}->{y1} + $incs_y[1];
		    
		    $current->{objects}->{$name}->{x2} =
			$last->{objects}->{$name}->{x2} + $incs_x[2];
		    $current->{objects}->{$name}->{y2} =
			$last->{objects}->{$name}->{y2} + $incs_y[2];
		    
		    $current->{objects}->{$name}->{x3} =
			$last->{objects}->{$name}->{x3} + $incs_x[3];
		    $current->{objects}->{$name}->{y3} =
			$last->{objects}->{$name}->{y3} + $incs_y[3];
		}
		elsif ($self->{animations}[$i][0] == 36) { # scale Compound
		    my $name = $self->{animations}[$i][1];
		    my $scale = $self->{animations}[$i][4];
		    my $c_x = $self->{animations}[$i][5];
		    my $c_y = $self->{animations}[$i][6];
		    my @incs_x = @{$self->{animations}[$i][7]};
		    my @incs_y = @{$self->{animations}[$i][8]};
		    
		    $current->{objects}->{$name}->{upperleft_corner_x} =
			$last->{objects}->{$name}->{upperleft_corner_x} +
			$incs_x[0];
		    $current->{objects}->{$name}->{upperleft_corner_y} =
			$last->{objects}->{$name}->{upperleft_corner_y} +
			$incs_y[0];
		    
		    $current->{objects}->{$name}->{lowerright_corner_x} =
			$last->{objects}->{$name}->{lowerright_corner_x} +
			$incs_x[1];
		    $current->{objects}->{$name}->{lowerright_corner_y} =
			$last->{objects}->{$name}->{lowerright_corner_y} +
			$incs_y[1];
		    
		    $current->{objects}->{$name}->{center_x} =
			$last->{objects}->{$name}->{center_x} + $incs_x[2];
		    $current->{objects}->{$name}->{center_y} =
			$last->{objects}->{$name}->{center_y} + $incs_y[2];
		}
		
	    } elsif ($f == $firstframe) { # if the current frame is the first frame then initiate increment
		
		if ($self->{animations}[$i][0] == 0) { # setAttributeValue
		    my $name = $self->{animations}[$i][1];
		    my $attribute = $self->{animations}[$i][4];
		    my $value = $self->{animations}[$i][5];
		    
		    $current->{objects}->{$name}->{$attribute} = $value;
		}
		
		elsif ($self->{animations}[$i][0] == 1) { # changeThickness
		    my $name = $self->{animations}[$i][1];
		    my $thickness = $self->{animations}[$i][4];
		    
		    my $firstthick = $current->{objects}->{$name}->{thickness};
		    $self->{animations}[$i][5] =
			($thickness-$firstthick) / $nbframes;
		}
		
		elsif ($self->{animations}[$i][0] == 2) { # changeFillIntensity
		    my $name = $self->{animations}[$i][1];
		    my $intensity = $self->{animations}[$i][4];
		    
		    my $firstinten = $current->{objects}->{$name}->{area_fill};
		    $self->{animations}[$i][5] =
			($intensity-$firstinten) / $nbframes;
		}
		
		elsif (($self->{animations}[$i][0] == 11) ||
		       ($self->{animations}[$i][0] == 12) ||
		       ($self->{animations}[$i][0] == 13) ||
		       ($self->{animations}[$i][0] == 14) ||
		       ($self->{animations}[$i][0] == 15) ||
		       ($self->{animations}[$i][0] == 16)) { # translate
		    my $name = $self->{animations}[$i][1];
		    my $x = $self->{animations}[$i][4];
		    my $y = $self->{animations}[$i][5];
		    my $unit = $self->{animations}[$i][6];
		    
		    if ($unit eq 'in') {
			$self->{animations}[$i][7] = 1200 * $x / $nbframes;
			$self->{animations}[$i][8] = 1200 * $y / $nbframes;
		    } elsif ($unit eq 'cm') {
			$self->{animations}[$i][7] = 450 * $x / $nbframes;
			$self->{animations}[$i][8] = 450 * $y / $nbframes;
		    } elsif ($unit eq 'px') {
			$self->{animations}[$i][7] = 15 * $x / $nbframes;
			$self->{animations}[$i][8] = 15 * $y / $nbframes;
		    } else {
			$self->{animations}[$i][7] = $x / $nbframes;
			$self->{animations}[$i][8] = $y / $nbframes;
		    }		   
		}
		
		elsif (($self->{animations}[$i][0] == 21) ||
		       ($self->{animations}[$i][0] == 22) ||
		       ($self->{animations}[$i][0] == 23) ||
		       ($self->{animations}[$i][0] == 24) ||
		       ($self->{animations}[$i][0] == 25) ||
		       ($self->{animations}[$i][0] == 26)) { # rotate
		    my $name = $self->{animations}[$i][1];
		    my $angle = $self->{animations}[$i][4];
		    
		    if ($self->{animations}[$i][7] eq 'in') { # $unit eq 'in'
			$self->{animations}[$i][5] *= 1200; # $c_x *= 1200
			$self->{animations}[$i][6] *= 1200; # $c_y *= 1200
		    } elsif ($self->{animations}[$i][7] eq 'cm') {
			$self->{animations}[$i][5] *= 450;
			$self->{animations}[$i][6] *= 450;
		    } elsif ($self->{animations}[$i][7] eq 'px') {
			$self->{animations}[$i][5] *= 15;
			$self->{animations}[$i][6] *= 15;
		    }
		    $self->{animations}[$i][7] = ''; # $unit = ''
		    
		    $self->{animations}[$i][8] = deg2rad($angle / $nbframes);
		}
		
		elsif ($self->{animations}[$i][0] == 31) { # scale Ellipse
		    my $name = $self->{animations}[$i][1];
		    my $scale = $self->{animations}[$i][4];
		    my $c_x = $self->{animations}[$i][5];
		    my $c_y = $self->{animations}[$i][6];
		    my (@incs_x,@incs_y);
		    
		    push @incs_x, (($scale-1) * 
				   ($current->{objects}->{$name}->{center_x} -
				    $c_x) / $nbframes);
		    push @incs_y, (($scale-1) * 
				   ($current->{objects}->{$name}->{center_y} -
				    $c_y) / $nbframes);
		    
		    push @incs_x, (($scale-1) * 
				   ($current->{objects}->{$name}->{start_x} -
				    $c_x) / $nbframes);
		    push @incs_y, (($scale-1) * 
				   ($current->{objects}->{$name}->{start_y} -
				    $c_y) / $nbframes);
		    
		    push @incs_x, (($scale-1) * 
				   ($current->{objects}->{$name}->{end_x} -
				    $c_x) / $nbframes);
		    push @incs_y, (($scale-1) * 
				   ($current->{objects}->{$name}->{end_y} -
				    $c_y) / $nbframes);
		    
		    $self->{animations}[$i][7] = \@incs_x;
		    $self->{animations}[$i][8] = \@incs_y;		    
		    
		    $self->{animations}[$i][9] = ($scale - 1) * 
			$current->{objects}->{$name}->{radius_x}  / $nbframes;
		    $self->{animations}[$i][10] = ($scale - 1) * 
			$current->{objects}->{$name}->{radius_y}  / $nbframes;
		}
		elsif (($self->{animations}[$i][0] == 32) || # scale
		       ($self->{animations}[$i][0] == 33)) { #  Polyline/Spline
		    my $name = $self->{animations}[$i][1];
		    my $scale = $self->{animations}[$i][4];
		    my $c_x = $self->{animations}[$i][5];
		    my $c_y = $self->{animations}[$i][6];
		    my (@incs_x,@incs_y);
		    
		    for (my $i=0; $i<$current->{objects}->{$name}->{npoints};
			 $i++) {
			push @incs_x, (($scale-1) * 
				  ($current->{objects}->{$name}->{xnpoints}[$i]
				   - $c_x) / $nbframes);
			push @incs_y, (($scale-1) * 
				  ($current->{objects}->{$name}->{ynpoints}[$i]
				   - $c_y) / $nbframes);
		    }
		    
		    push @incs_x, (($scale-1) * 
				   ($current->{objects}->{$name}->{center_x} -
				    $c_x) / $nbframes);
		    push @incs_y, (($scale-1) * 
				   ($current->{objects}->{$name}->{center_y} -
				    $c_y) / $nbframes);
		    
		    $self->{animations}[$i][7] = \@incs_x;
		    $self->{animations}[$i][8] = \@incs_y;		    
		}
		elsif ($self->{animations}[$i][0] == 34) { # scale Text
		    my $name = $self->{animations}[$i][1];
		    my $scale = $self->{animations}[$i][4];
		    my $c_x = $self->{animations}[$i][5];
		    my $c_y = $self->{animations}[$i][6];
		    my (@incs_x,@incs_y);
		    
		    push @incs_x, (($scale-1) * 
				   ($current->{objects}->{$name}->{x} -
				    $c_x) / $nbframes);
		    push @incs_y, (($scale-1) * 
				   ($current->{objects}->{$name}->{y} -
				    $c_y) / $nbframes);
		    
		    push @incs_x, (($scale-1) * 
				   ($current->{objects}->{$name}->{center_x} -
				    $c_x) / $nbframes);
		    push @incs_y, (($scale-1) * 
				   ($current->{objects}->{$name}->{center_y} -
				    $c_y) / $nbframes);
		    
		    $self->{animations}[$i][7] = \@incs_x;
		    $self->{animations}[$i][8] = \@incs_y;
		    
		    $self->{animations}[$i][9] = ($scale - 1) * 
			$current->{objects}->{$name}->{font_size}  / $nbframes;
		    $self->{animations}[$i][10] = ($scale - 1) * 
			$current->{objects}->{$name}->{height}  / $nbframes;
		}
		elsif ($self->{animations}[$i][0] == 35) { # scale Arc
		    my $name = $self->{animations}[$i][1];
		    my $scale = $self->{animations}[$i][4];
		    my $c_x = $self->{animations}[$i][5];
		    my $c_y = $self->{animations}[$i][6];
		    my (@incs_x,@incs_y);
		    
		    push @incs_x, (($scale-1) * 
				   ($current->{objects}->{$name}->{center_x} -
				    $c_x) / $nbframes);
		    push @incs_y, (($scale-1) * 
				   ($current->{objects}->{$name}->{center_y} -
				    $c_y) / $nbframes);
		    
		    push @incs_x, (($scale-1) * 
				   ($current->{objects}->{$name}->{x1} -
				    $c_x) / $nbframes);
		    push @incs_y, (($scale-1) * 
				   ($current->{objects}->{$name}->{y1} -
				    $c_y) / $nbframes);
		    
		    push @incs_x, (($scale-1) * 
				   ($current->{objects}->{$name}->{x2} -
				    $c_x) / $nbframes);
		    push @incs_y, (($scale-1) * 
				   ($current->{objects}->{$name}->{y2} -
				    $c_y) / $nbframes);
		    
		    push @incs_x, (($scale-1) * 
				   ($current->{objects}->{$name}->{x3} -
				    $c_x) / $nbframes);
		    push @incs_y, (($scale-1) * 
				   ($current->{objects}->{$name}->{y3} -
				    $c_y) / $nbframes);
		    
		    $self->{animations}[$i][7] = \@incs_x;
		    $self->{animations}[$i][8] = \@incs_y;		    
		}
		elsif ($self->{animations}[$i][0] == 36) { # scale Compound
		    my $name = $self->{animations}[$i][1];
		    my $scale = $self->{animations}[$i][4];
		    my $c_x = $self->{animations}[$i][5];
		    my $c_y = $self->{animations}[$i][6];
		    my (@incs_x,@incs_y);
		    
		    push @incs_x, (($scale-1) * 
			    ($current->{objects}->{$name}->{upperleft_corner_x}
			     - $c_x) / $nbframes);
		    push @incs_y, (($scale-1) * 
			    ($current->{objects}->{$name}->{upperleft_corner_y}
			     - $c_y) / $nbframes);
		    
		    push @incs_x, (($scale-1) * 
			   ($current->{objects}->{$name}->{lowerright_corner_x}
			    - $c_x) / $nbframes);
		    push @incs_y, (($scale-1) * 
			   ($current->{objects}->{$name}->{lowerright_corner_y}
			    - $c_y) / $nbframes);
		    
		    push @incs_x, (($scale-1) * 
				   ($current->{objects}->{$name}->{center_x} -
				    $c_x) / $nbframes);
		    push @incs_y, (($scale-1) * 
				   ($current->{objects}->{$name}->{center_y} -
				    $c_y) / $nbframes);
		    
		    $self->{animations}[$i][7] = \@incs_x;
		    $self->{animations}[$i][8] = \@incs_y;		    
		}
		
	    }
	    my $framename = sprintf(".frame%04d",$f);
	    $current->writeFile($framename.".fig");
	    `fig2dev -L gif $framename.fig $framename.gif`;
	    `rm $framename.fig`;
	    $last = $current; # the current frame becomes the last frame
	}
    }
    # possible optimization
    my $delay = 100 / $speed;
    my $final_delay = $delay + $wait * 100;
    my @frames = split /\n/, `ls .frame????.gif`;
    `convert -loop $loop -delay $delay @frames[0..$length-1] -delay $final_delay $frames[$length] $file`;
    `rm @frames`;
}


# objects selectors
sub selectByType {
    my $self = shift;
    my $res = new Compound("",0,0,0,0,$self);
    
    foreach (@_) {
	push @{$res->{$_}}, @{$self->{$_}};
    }
    
    foreach (@{$self->{compounds}}) {
	my $aux = $self->{objects}->{$_}->selectByType(@_);
	foreach (@_) {
	    push @{$res->{$_}}, @{$aux->{$_}};
	}
    }
    
    return $res;
}

sub selectByPenColor {
    my $self = shift;
    my $res = new Compound("",0,0,0,0,$self);
    
    foreach (@_) {
	my $color = $FigAnim::Utils::colors_codes{$_};
	if (defined $color) {
	    foreach (@{$self->{arcs}}) {
		if ($self->{objects}->{$_}->{pen_color} == $color) {
		    push @{$res->{arcs}}, $_;
		}
	    }
	    foreach (@{$self->{ellipses}}) {
		if ($self->{objects}->{$_}->{pen_color} == $color) {
		    push @{$res->{ellipses}}, $_;
		}
	    }
	    foreach (@{$self->{polylines}}) {
		if ($self->{objects}->{$_}->{pen_color} == $color) {
		    push @{$res->{polylines}}, $_;
		}
	    }
	    foreach (@{$self->{splines}}) {
		if ($self->{objects}->{$_}->{pen_color} == $color) {
		    push @{$res->{splines}}, $_;
		}
	    }
	    foreach (@{$self->{texts}}) {
		if ($self->{objects}->{$_}->{pen_color} == $color) {
		    push @{$res->{texts}}, $_;
		}
	    }
	}
    }
    
    foreach (@{$self->{compounds}}) {
	my $aux = $self->{objects}->{$_}->selectByPenColor(@_);
	push @{$res->{arcs}}, @{$aux->{arcs}};
	push @{$res->{ellipses}}, @{$aux->{ellipses}};
	push @{$res->{polylines}}, @{$aux->{polylines}};
	push @{$res->{splines}}, @{$aux->{splines}};
	push @{$res->{texts}}, @{$aux->{texts}};
    }
    
    return $res;
}

sub selectByFillColor {
    my $self = shift;
    my $res = new Compound("",0,0,0,0,$self);
    
    foreach (@_) {
	my $color = $FigAnim::Utils::colors_codes{$_};
	if (defined $color) {
	    foreach (@{$self->{arcs}}) {
		if ($self->{objects}->{$_}->{fill_color} == $color) {
		    push @{$res->{arcs}}, $_;
		}
	    }
	    foreach (@{$self->{ellipses}}) {
		if ($self->{objects}->{$_}->{fill_color} == $color) {
		    push @{$res->{ellipses}}, $_;
		}
	    }
	    foreach (@{$self->{polylines}}) {
		if ($self->{objects}->{$_}->{fill_color} == $color) {
		    push @{$res->{polylines}}, $_;
		}
	    }
	    foreach (@{$self->{splines}}) {
		if ($self->{objects}->{$_}->{fill_color} == $color) {
		    push @{$res->{splines}}, $_;
		}
	    }
	}
    }
    
    foreach (@{$self->{compounds}}) {
	my $aux = $self->{objects}->{$_}->selectByFillColor(@_);
	push @{$res->{arcs}}, @{$aux->{arcs}};
	push @{$res->{ellipses}}, @{$aux->{ellipses}};
	push @{$res->{polylines}}, @{$aux->{polylines}};
	push @{$res->{splines}}, @{$aux->{splines}};
    }
    
    return $res;
}

sub selectByAttributeValue {
    my $self = shift;
    my $res = new Compound("",0,0,0,0,$self);
    my @params = @_;
    
    while (@params) {
	my $attribute = shift @params;
	my $value = shift @params;
	
	foreach (@{$self->{arcs}}) {
	    if ((defined $self->{objects}->{$_}->{$attribute}) &&
		($self->{objects}->{$_}->{$attribute} eq $value)) {
		push @{$res->{arcs}}, $_;
	    }
	}
	foreach (@{$self->{compounds}}) {
	    if ((defined $self->{objects}->{$_}->{$attribute}) &&
		($self->{objects}->{$_}->{$attribute} eq $value)) {
		push @{$res->{compounds}}, $_;
	    }
	}
	foreach (@{$self->{ellipses}}) {
	    if ((defined $self->{objects}->{$_}->{$attribute}) &&
		($self->{objects}->{$_}->{$attribute} eq $value)) {
		push @{$res->{ellipses}}, $_;
	    }
	}
	foreach (@{$self->{polylines}}) {
	    if ((defined $self->{objects}->{$_}->{$attribute}) &&
		($self->{objects}->{$_}->{$attribute} eq $value)) {
		push @{$res->{polylines}}, $_;
	    }
	}
	foreach (@{$self->{splines}}) {
	    if ((defined $self->{objects}->{$_}->{$attribute}) &&
		($self->{objects}->{$_}->{$attribute} eq $value)) {
		push @{$res->{splines}}, $_;
	    }
	}
	foreach (@{$self->{texts}}) {
	    if ((defined $self->{objects}->{$_}->{$attribute}) &&
		($self->{objects}->{$_}->{$attribute} eq $value)) {
		push @{$res->{texts}}, $_;
	    }
	}
    }
    
    
    foreach (@{$self->{compounds}}) {
	my $aux = $self->{objects}->{$_}->selectByAttributeValue(@_);
	push @{$res->{arcs}}, @{$aux->{arcs}};
	push @{$res->{compounds}}, @{$aux->{compounds}};
	push @{$res->{ellipses}}, @{$aux->{ellipses}};
	push @{$res->{polylines}}, @{$aux->{polylines}};
	push @{$res->{splines}}, @{$aux->{splines}};
	push @{$res->{texts}}, @{$aux->{texts}};
    }
    
    return $res;
}


# writes a SVG file
sub writeSVGFile {
    my $self = shift;
    my $filename = shift;
    
    open OUT, ">$filename" or die "Can't open $filename : $!\n";
    
    $self->writeSVGHeader(\*OUT);
    $self->writeSVGObjects(\*OUT);

    print OUT "</svg>\n";
    
    close OUT;
}

# writes SVG header
sub writeSVGHeader {
    my $self = shift;
    my $fh = shift;

    print $fh "<?xml version=\"1.0\"?>\n";
    print $fh "<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.0//EN\"\n";
    print $fh "\"http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd\">\n\n";

    print $fh "<svg ";

    print $fh
	ConvertSVG::papersize_to_units($self->{papersize},
				       $self->{orientation},
				       $self->{magnification},
				       $self->{resolution});
    print $fh ">\n";

    print $fh "<title>";
    print $fh split(/\n/, $self->{title}, 0) if ($self->{title});
    print $fh "</title>\n";

    print $fh "<desc>\n";
    if ($self->{title} ne "") {
	foreach (split(/\n/, $self->{title})) {
	    print $fh "$_\n";
	}
    }
    print $fh "</desc>\n\n";
}

# write SVG objects
sub writeSVGObjects {
    my $self = shift;
    my $fh = shift;

    my @objects;
    push @objects, @{$self->{arcs}};
    push @objects, @{$self->{ellipses}};
    push @objects, @{$self->{polylines}};
    push @objects, @{$self->{splines}};
    push @objects, @{$self->{texts}};

    # sorts objects by depth
    @objects =
	sort {
	    if ($self->{objects}->{$a}->{depth} <
		$self->{objects}->{$b}->{depth}) {
		return 1;
	    } elsif ($self->{objects}->{$a}->{depth} ==
		     $self->{objects}->{$b}->{depth}) {
		return 0;
	    } else {
		return -1;
	    }
	} @objects;

    foreach (@objects) {
	$self->{objects}->{$_}->outputSVG($fh, \@{$self->{colors}});
    }

    foreach (@{$self->{compounds}}) {
	$self->{objects}->{$_}->outputSVG($fh, \@{$self->{colors}});
    }
}


sub generateSMIL {
    my $self = shift;
    my $file = shift;
    
    open OUT, ">$file" or die "Can't open $file : $!\n";

    $self->writeSVGHeader(\*OUT);
    $self->writeSMILObjects(\*OUT);

    print OUT "</svg>\n";

    close OUT;
}

sub writeSMILObjects {
    my $self = shift;
    my $fh = shift;

    # sorts animations by start time
    @{$self->{animations}} =
	sort {
	    if (@$a[2] < @$b[2]) { return -1; }
	    elsif (@$a[2] == @$b[2]) { return 0; }
	    else { return 1; }
	} @{$self->{animations}};

    my @setAttributeValue;
    my @changeThickness;
    my @changeFillIntensity;
    my @translate;
    my @rotate;
    my @scale;

    for (my $i = 0; $i <= $#{$self->{animations}}; $i++) {
	if ($self->{animations}[$i][0] == 0) { # setAttributeValue (0)
	    push @setAttributeValue, $self->{animations}[$i];

	} elsif ($self->{animations}[$i][0] == 1) { # changeThickness (1)
	    push @changeThickness, $self->{animations}[$i];

	} elsif ($self->{animations}[$i][0] == 2) { # changeFillIntensity (2)
	    push @changeFillIntensity, $self->{animations}[$i];

	} elsif (($self->{animations}[$i][0] >= 11) &&
		 ($self->{animations}[$i][0] <= 16)) { # translate (11 - 16)
	    push @translate, $self->{animations}[$i];

	} elsif (($self->{animations}[$i][0] >= 21) &&
		 ($self->{animations}[$i][0] <= 26)) { # rotate (21 - 26)
	    push @rotate, $self->{animations}[$i];

	} elsif (($self->{animations}[$i][0] >= 31) &&
		 ($self->{animations}[$i][0] <= 36)) { # scale (31 - 36)
	    push @scale, $self->{animations}[$i];
	}
    }

    my $i;

    for ($i = 0; $i <= $#setAttributeValue; $i++) {
	my $name = $setAttributeValue[$i][1];
	my $begin = $setAttributeValue[$i][2];
	my $dur = $setAttributeValue[$i][3];
	my $attribute = $setAttributeValue[$i][4];
	my $value = $setAttributeValue[$i][5];

	my $last = $#{$self->{objects}->{$name}->{animations}} + 1;

	$self->{objects}->{$name}->{animations}[$last][0] = 0; # type
	$self->{objects}->{$name}->{animations}[$last][1] = $begin; # begin
	$self->{objects}->{$name}->{animations}[$last][2] = $dur; # dur
	$self->{objects}->{$name}->{animations}[$last][3] = $attribute; # attr
	$self->{objects}->{$name}->{animations}[$last][4] = $value; # value
	$self->{objects}->{$name}->{animations}[$last][5] =
	    \@{$self->{colors}}; # colors
    }

    for ($i = 0; $i <= $#changeThickness; $i++) {
	my $name = $changeThickness[$i][1];
	my $begin = $changeThickness[$i][2];
	my $dur = $changeThickness[$i][3];
	my $to = $changeThickness[$i][4];
	my $from;

	my $j = $i;
	do {
	    $j--;
	} while (($j >= 0) && ($name ne $changeThickness[$j][1]));

	if ($j == -1) {
	    $from = $self->{objects}->{$name}->{thickness};
	} else {
	    $from = $changeThickness[$j][4];
	}

	my $last = $#{$self->{objects}->{$name}->{animations}} + 1;

	$self->{objects}->{$name}->{animations}[$last][0] = 1; # type
	$self->{objects}->{$name}->{animations}[$last][1] = $from; # from
	$self->{objects}->{$name}->{animations}[$last][2] = $to; # to
	$self->{objects}->{$name}->{animations}[$last][3] = $begin; # begin
	$self->{objects}->{$name}->{animations}[$last][4] = $dur; # dur
    }

    for ($i = 0; $i <= $#changeFillIntensity; $i++) {
	my $name = $changeFillIntensity[$i][1];
	my $begin = $changeFillIntensity[$i][2];
	my $dur = $changeFillIntensity[$i][3];
	my $to = $changeFillIntensity[$i][4];
	my $from;

	my $j = $i;
	do {
	    $j--;
	} while (($j >= 0) && ($name ne $changeFillIntensity[$j][1]));

	if ($j == -1) {
	    $from = $self->{objects}->{$name}->{area_fill};
	} else {
	    $from = $changeFillIntensity[$j][4];
	}

	my $last = $#{$self->{objects}->{$name}->{animations}} + 1;

	$self->{objects}->{$name}->{animations}[$last][0] = 2; # type
	$self->{objects}->{$name}->{animations}[$last][1] = $begin; # from
	$self->{objects}->{$name}->{animations}[$last][2] = $dur; # to
	$self->{objects}->{$name}->{animations}[$last][3] = $from; # begin
	$self->{objects}->{$name}->{animations}[$last][4] = $to; # dur
	$self->{objects}->{$name}->{animations}[$last][5] = 
	    $self->{objects}->{$name}->{fill_color}; # color
	$self->{objects}->{$name}->{animations}[$last][6] =
	    \@{$self->{colors}}; # colors
    }

    for ($i = 0; $i <= $#translate; $i++) {
	my $type = $translate[$i][0];
	my $name = $translate[$i][1];
	my $begin = $translate[$i][2];
	my $dur = $translate[$i][3];
	my $x = $translate[$i][4];
	my $y = $translate[$i][5];
	my $unit = $translate[$i][6];

	my $last = $#{$self->{objects}->{$name}->{animations}} + 1;

	$self->{objects}->{$name}->{animations}[$last][0] = $type; # type
	$self->{objects}->{$name}->{animations}[$last][1] = $begin; # begin
	$self->{objects}->{$name}->{animations}[$last][2] = $dur; # dur
	$self->{objects}->{$name}->{animations}[$last][3] = $x; # x
	$self->{objects}->{$name}->{animations}[$last][4] = $y; # y
	$self->{objects}->{$name}->{animations}[$last][5] = $unit; # unit
    }

    for ($i = 0; $i <= $#rotate; $i++) {
	my $type = $rotate[$i][0];
	my $name = $rotate[$i][1];
	my $begin = $rotate[$i][2];
	my $dur = $rotate[$i][3];
	my $angle = $rotate[$i][4];
	my $x = $rotate[$i][5];
	my $y = $rotate[$i][6];
	my $unit = $rotate[$i][7];

	my $last = $#{$self->{objects}->{$name}->{animations}} + 1;

	$self->{objects}->{$name}->{animations}[$last][0] = $type; # type
	$self->{objects}->{$name}->{animations}[$last][1] = $begin; # begin
	$self->{objects}->{$name}->{animations}[$last][2] = $dur; # dur
	$self->{objects}->{$name}->{animations}[$last][3] = $angle; # angle
	$self->{objects}->{$name}->{animations}[$last][4] = $x; # x
	$self->{objects}->{$name}->{animations}[$last][5] = $y; # y
	$self->{objects}->{$name}->{animations}[$last][6] = $unit; # unit
    }

    for ($i = 0; $i <= $#scale; $i++) {
	my $type = $scale[$i][0];
	my $name = $scale[$i][1];
	my $begin = $scale[$i][2];
	my $dur = $scale[$i][3];
	my $factor = $scale[$i][4];
	my $x = $scale[$i][5];
	my $y = $scale[$i][6];

	my $last = $#{$self->{objects}->{$name}->{animations}} + 1;

	$self->{objects}->{$name}->{animations}[$last][0] = $type; # type
	$self->{objects}->{$name}->{animations}[$last][1] = $begin; # begin
	$self->{objects}->{$name}->{animations}[$last][2] = $dur; # dur
	$self->{objects}->{$name}->{animations}[$last][3] = $factor; # factor
	$self->{objects}->{$name}->{animations}[$last][4] = $x; # x
	$self->{objects}->{$name}->{animations}[$last][5] = $y; # y
    }

    $self->writeSVGObjects($fh);
}


# useful functions
sub nextline {
    my $fh = shift;
    if (eof $fh) {
	return;
    }
    
    my $line = <$fh>;
    $line = nextline($fh) if ($line eq "\n");
    chomp $line;
    return $line;
}


1;
__END__

=head1 NAME

FigAnim - A XFig file animator class

=head1 SYNOPSIS

Here is a simple example where we first parse a file "file.fig".
This file is supposed to contain an object named "Square"
(in XFig the name of an object is it's commentary).
Then this object translates according to vector (50px, 25px),
the animation starts at t=0 second and it's duration is 1 second.
In the end we generate an animated GIF file named "anim.gif",
and a SVG+SMIL file named "anim.svg".

    use FigAnim;

    $fig_anim = new FigAnim;
    $fig_anim->parseFile("file.fig");

    $fig_anim->{objects}->{Square}->translate(0, 1, 50, 25, 'px');

    $fig_anim->generateGif("anim.gif", 12, 0);
    $fig_anim->generateSMIL("anim.svg");

=head1 ABSTRACT

FigAnim is a package which takes an existing FIG file
(made by the XFig vector drawing program for example)
and generates animations in animated GIF format and/or in SVG+SMIL format.

=head1 DESCRIPTION

Here are all the methods you can use in the package FigAnim :

B<new(), parseFile(), writeFile(), setAttributevalue(), setPenColor(),
setFillColor(), hide(), show(), changeThickness(), changeFillIntensity(),
scale(), translate(), rotate(), generateGIF(), writeSVGfile(), generateSMIL(),
selectByType(), selectByPenColor(), selectByFillColor(),
selectByAttributeValue()>

The time unit used for every animation is in B<seconds>.

=head2 BASIC COMMANDS

=over

=item new()

Creates a new instance of the class FigAnim.
Every animation B<must> begin with these two lines:

    use FigAnim;
    $fig_anim = new FigAnim;

=item parseFile()

Parses the file given in parameter, for example:

    $fig_anim->parseFile("file.fig");

where "file.fig" is a correct FIG file.

=item writeFile()

Writes a new FIG file from another parsed FIG file.
This method is only used for testing purpose (to test the identity). Example:

    $fig_anim->writeFile("another_file.fig");

=back

=head2 SET

=over

=item setAttributeValue()

This method sets an attribute value of an object at a given time,
without any interpolation. For example, if we have in our FIG file
an object named "Square":

    $fig_anim->{objects}->{Square}->setAttributeValue(3, 'thickness', 2);

sets the attribute "thickness" of object "Square" to 2 at instant t=3 seconds.

=item setPenColor()

Example:

    $fig_anim->{objects}->{Square}->setPenColor(4, 'Green4');

this command modifies the object's pen color to a color called Green4 (in XFig)
at instant t=4s, without any interpolation.

=item setFillColor()

Example:

    $fig_anim->{objects}->{Square}->setFillColor(5, 'Green4');

similar to previous method, but modifies fill color instead of pen color
at t=5s.

=back

=head2 HIDE/SHOW

=over

=item hide()

Example:

    $fig_anim->{objects}->{Square}->hide(3);

this command hides an object named "Square" at instant t=3s.

=item show()

Example:

    $fig_anim->{objects}->{Square}->hide(4);

this command makes an object named "Square" appear at instant t=4s.

=back

=head2 CHANGE

=over

=item changeThickness()

Example:

    $fig_anim->{objects}->{Square}->changeThickness(0, 1, 7);

animates (with linear interpolation)
the thickness of an object named "Square" from time t=0s for a duration of 1s.
The thickness will have a value of 7 at the end of the animation. 

=item changeFillIntensity()

Example:

    $fig_anim->{objects}->{Square}->changeFillIntensity(2, 1, 0);

animates (with linear interpolation)
the fill intensity of an object named "Square" from time t=2s
for a duration of 1s.
The intensity will have a value of 0 at the end of the animation.
The intensity must be a number between 0 (black) and 20
(full saturation of the color).
In the example the object becomes darker and darker until it becomes black.

=item scale()

Example:

    $fig_anim->{objects}->{Arc}->scale(0, 1, 1.2);

scales the object named "Arc" from time t=0s
for a duration of 1s according to scale factor 1.2.
The center of the scale is the center of the object.

=back

=head2 MOVEMENTS

=over

=item translate()

Example:

    $fig_anim->{objects}->{Square}->translate(0, 1, 2, 3, 'in');

translates the object named "Square" from time t=0s
for a duration of 1s according to vector (2in, 3in).
Possible values for units (last parameter) are 'in', 'cm' or 'px'.
Units are Fig units if none specified.

=item rotate()

Example:

    $fig_anim->{objects}->{Arc}->rotate(0, 1, -330);

rotates the object named "Arc" from time t=0s
for a duration of 1s according to rotation angle -330 degrees.
In this case the center of the rotation is the center of the object.

    $fig_anim->{objects}->{Ellipse}->rotate(0, 1, -330, 2, 3,'in');

rotates the object named "Arc" from time t=0s
for a duration of 1s according to rotation angle -330 degrees.
In this case the center of the rotation is point (2in, 3in).
Possible values for units (last parameter) are 'in', 'cm' or 'px'.
Units are Fig units if none specified.

=back

=head2 FILE GENERATION

=over

=item generateGif()

Example:

    $fig_anim->generateGif("anim.gif", 10, 1);

generates an animated GIF file named "anim.gif" with 10 frames per second,
with only one loop (1). If you put a higher number of frames,
the animation will be smoother but will take more time
to be generated and the file size will be bigger.
If you put a lower number of frames, the file will be generated faster
and it's size will be smaller but the animation will be less smooth.

Another example:

    $fig_anim->generateGif("anim.gif", 10, 0, 1);

generates a GIF file named "anim.gif" with 10 frames per second,
with infinite loop (0), and waits for 1s at the end of each loop.
The last parameter is optional, if ommited its value is 0 (no waiting).  

=item writeSVGfile()

Example:
    $fig_anim->writeSVGFile("file.svg");

generates a SVG file named "file.svg" from a FIG file.
This is a graphic filter with no animations.

=item generateSMIL()

Example:

    $fig_anim->generateSMIL("file.svg");

generates a SVG+SMIL file named "file.svg",
it is an animated SVG file with SMIL tags.
For now only the Adobe SVG plugin can display animated SVG+SMIL files.

=back

=head2 SELECT OBJECTS

You can select objects by there type, pen color, fill color or attribute value
and apply an animation to the selected object(s).
Also, you can put as many parameters as you want in each select method
(as you can see in Example2).
You can also apply a selector on a compound object.
Many selectors can be applied successively. 

=over

=item selectByType()

Example1:

    $fig_anim->selectByType("polylines")->hide(1);

hides all objects of type polylines (as defined in XFig) at t=1s.

=item selectByPenColor()

Example2:

    $fig_anim->selectByPenColor("Red", "Blue")->hide(1);

hides all objects with "Red" or "Blue" line (as defined in XFig) at t=1s.

=item selectByFillColor()

Example3:

    $fig_anim->selectByFillColor("White")->hide(1);

hides all objects filled with "White" color (as defined in XFig) at t=1s.

=item selectByAttributeValue()

Example4:

    $fig_anim->selectByAttributeValue("thickness", 1)->hide(1);

hides all objects with thickness value 1 (as defined in XFig) at t=1s.

Example5: multiple selections:

    $fig_anim
    ->selectByPenColor("Red","Blue")
    ->selectByType("polylines")
    ->hide(1);

hides all polylines with "Red" or "Blue" line (as defined in XFig) at t=1s.
=back

=head2 AVAILABLE COLORS

Background, None, Default, Black, Blue, Green, Cyan, Red, Magenta, Yellow,
White, Blue4, Blue3,Blue2, LtBlue, Green4, Green3, Green2, Cyan4, Cyan3, Cyan2,
Red4, Red3, Red2, Magenta4, Magenta3, Magenta2, Brown4, Brown3, Brown2, Pink4,
Pink3, Pink2, Pink, Gold

=head1 SEE ALSO

FigAnim::Arc, FigAnim::Color, FigAnim::Compound, FigAnim::Ellipse,
FigAnim::Polyline, FigAnim::Spline, FigAnim::Text.

=head1 AUTHOR

K. Imakita, E<lt>kzu@wanadoo.frE<gt>;
Q. Lamerand, E<lt>bret.zel@wanadoo.frE<gt>;
F. Perrin, E<lt>fred.per1@free.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by K. Imakita, Q. Lamerand, F. Perrin

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
