package Compound;

=head1 NAME

Compound - A XFig file animator class - Compound object

=head1 DESCRIPTION

Compound object - object code in FIG format: 6.
Here are all the attributes of this class:

B<upperleft_corner_x, upperleft_corner_y, lowerright_corner_x,
lowerright_corner_y, arcs, compounds, ellipses, polylines, splines, texts,
center_x, center_y>

=head1 FIG ATTRIBUTES

=over

=item upperleft_corner_x

Fig units

=item upperleft_corner_y

Fig units

=item lowerright_corner_x

Fig units

=item lowerright_corner_y

Fig units

=back

=head1 ADDITIONNAL ATTRIBUTES

=over

=item arcs, compounds, ellipses, polylines, splines, texts

arrays containing every object's name classified by type

=item center_x, center_y

calculated center (Fig units)

=back

=cut

use strict;
use warnings;

# useful classes
use FigAnim::Utils;

# constructor
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    
    $self->{name} = shift; # object's name in comment
    
    #$self->{object_code} = 6;
    $self->{upperleft_corner_x} = shift;
    $self->{upperleft_corner_y} = shift;
    $self->{lowerright_corner_x} = shift;
    $self->{lowerright_corner_y} = shift;
    
    # reference to the FigFile
    $self->{fig_file} = shift;
    
    # arrays containing every object's name classified by type
    $self->{arcs} = [];
    $self->{compounds} = [];
    $self->{ellipses} = [];
    $self->{polylines} = [];
    $self->{splines} = [];
    $self->{texts} = [];
    
    # calculated center
    $self->{center_x} = undef;
    $self->{center_y} = undef;
    
    bless ($self, $class);
    return $self;
}


# methods
sub clone {
    my $self = shift;
    my $obj = new Compound;
    $obj->{$_} = $self->{$_} foreach (keys %{$self});
    return $obj;
}

sub output {
    my $self = shift;
    
    my $fh = shift;
    
    foreach (split(/\n/, $self->{name})) {
	printf $fh "# $_\n";
    }
    
    printf $fh "6 %d %d %d %d\n",
	@$self{'upperleft_corner_x','upperleft_corner_y','lowerright_corner_x',
	       'lowerright_corner_y'};
    
    foreach (@{$self->{arcs}}) {
	$self->{fig_file}->{objects}->{$_}->output($fh);
    }
    
    foreach (@{$self->{compounds}}) {
	$self->{fig_file}->{objects}->{$_}->output($fh);
    }
    
    foreach (@{$self->{ellipses}}) {
	$self->{fig_file}->{objects}->{$_}->output($fh);
    }
    
    foreach (@{$self->{polylines}}) {
	$self->{fig_file}->{objects}->{$_}->output($fh);
    }
    
    foreach (@{$self->{splines}}) {
	$self->{fig_file}->{objects}->{$_}->output($fh);
    }
    
    foreach (@{$self->{texts}}) {
	$self->{fig_file}->{objects}->{$_}->output($fh);
    }
    
    print $fh "-6\n";
}

sub calculateCenter {
    my $self = shift;
    $self->{center_x} = sprintf("%.0f",($self->{upperleft_corner_x} +
					$self->{lowerright_corner_x}) / 2);
    $self->{center_y} = sprintf("%.0f",($self->{upperleft_corner_y} +
					$self->{lowerright_corner_y}) / 2);
}


# objects selectors
sub selectByType {
    my $self = shift;
    my $res = new Compound("",0,0,0,0,$self->{fig_file});
    
    foreach (@_) {
	push @{$res->{$_}}, @{$self->{$_}};
    }
    
    foreach (@{$self->{compounds}}) {
	my $aux = $self->{fig_file}->{objects}->{$_}->selectByType(@_);
	foreach (@_) {
	    push @{$res->{$_}}, @{$aux->{$_}};
	}
    }
    
    return $res;
}

sub selectByPenColor {
    my $self = shift;
    my $res = new Compound("",0,0,0,0,$self->{fig_file});
    
    foreach (@_) {
	my $color = $FigAnim::Utils::colors_codes{$_};
	if (defined $color) {
	    foreach (@{$self->{arcs}}) {
		if ($self->{fig_file}->{objects}->{$_}->{pen_color} == $color){
		    push @{$res->{arcs}}, $_;
		}
	    }
	    foreach (@{$self->{ellipses}}) {
		if ($self->{fig_file}->{objects}->{$_}->{pen_color} == $color){
		    push @{$res->{ellipses}}, $_;
		}
	    }
	    foreach (@{$self->{polylines}}) {
		if ($self->{fig_file}->{objects}->{$_}->{pen_color} == $color){
		    push @{$res->{polylines}}, $_;
		}
	    }
	    foreach (@{$self->{splines}}) {
		if ($self->{fig_file}->{objects}->{$_}->{pen_color} == $color){
		    push @{$res->{splines}}, $_;
		}
	    }
	    foreach (@{$self->{texts}}) {
		if ($self->{fig_file}->{objects}->{$_}->{pen_color} == $color){
		    push @{$res->{texts}}, $_;
		}
	    }
	}
    }
    
    foreach (@{$self->{compounds}}) {
	my $aux = $self->{fig_file}->{objects}->{$_}->selectByPenColor(@_);
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
    my $res = new Compound("",0,0,0,0,$self->{fig_file});
    
    foreach (@_) {
	my $color = $FigAnim::Utils::colors_codes{$_};
	if (defined $color) {
	    foreach (@{$self->{arcs}}) {
		if ($self->{fig_file}->{objects}->{$_}->{fill_color}==$color) {
		    push @{$res->{arcs}}, $_;
		}
	    }
	    foreach (@{$self->{ellipses}}) {
		if ($self->{fig_file}->{objects}->{$_}->{fill_color}==$color) {
		    push @{$res->{ellipses}}, $_;
		}
	    }
	    foreach (@{$self->{polylines}}) {
		if ($self->{fig_file}->{objects}->{$_}->{fill_color}==$color) {
		    push @{$res->{polylines}}, $_;
		}
	    }
	    foreach (@{$self->{splines}}) {
		if ($self->{fig_file}->{objects}->{$_}->{fill_color}==$color) {
		    push @{$res->{splines}}, $_;
		}
	    }
	}
    }
    
    foreach (@{$self->{compounds}}) {
	my $aux = $self->{fig_file}->{objects}->{$_}->selectByFillColor(@_);
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
	    if ((defined $self->{fig_file}->{objects}->{$_}->{$attribute}) &&
		($self->{fig_file}->{objects}->{$_}->{$attribute} eq $value)) {
		push @{$res->{arcs}}, $_;
	    }
	}
	foreach (@{$self->{compounds}}) {
	    if ((defined $self->{fig_file}->{objects}->{$_}->{$attribute}) &&
		($self->{fig_file}->{objects}->{$_}->{$attribute} eq $value)) {
		push @{$res->{compounds}}, $_;
	    }
	}
	foreach (@{$self->{ellipses}}) {
	    if ((defined $self->{fig_file}->{objects}->{$_}->{$attribute}) &&
		($self->{fig_file}->{objects}->{$_}->{$attribute} eq $value)) {
		push @{$res->{ellipses}}, $_;
	    }
	}
	foreach (@{$self->{polylines}}) {
	    if ((defined $self->{fig_file}->{objects}->{$_}->{$attribute}) &&
		($self->{fig_file}->{objects}->{$_}->{$attribute} eq $value)) {
		push @{$res->{polylines}}, $_;
	    }
	}
	foreach (@{$self->{splines}}) {
	    if ((defined $self->{fig_file}->{objects}->{$_}->{$attribute}) &&
		($self->{fig_file}->{objects}->{$_}->{$attribute} eq $value)) {
		push @{$res->{splines}}, $_;
	    }
	}
	foreach (@{$self->{texts}}) {
	    if ((defined $self->{fig_file}->{objects}->{$_}->{$attribute}) &&
		($self->{fig_file}->{objects}->{$_}->{$attribute} eq $value)) {
		push @{$res->{texts}}, $_;
	    }
	}
    }
    
    foreach (@{$self->{compounds}}) {
	my $aux=$self->{fig_file}->{objects}->{$_}->selectByAttributeValue(@_);
	push @{$res->{arcs}}, @{$aux->{arcs}};
	push @{$res->{compounds}}, @{$aux->{compounds}};
	push @{$res->{ellipses}}, @{$aux->{ellipses}};
	push @{$res->{polylines}}, @{$aux->{polylines}};
	push @{$res->{splines}}, @{$aux->{splines}};
	push @{$res->{texts}}, @{$aux->{texts}};
    }
    
    return $res;
}


# animation methods
sub setAttributeValue {
    my $self = shift;
    my $time = shift;
    my $attribute = shift;
    my $value = shift;
    
    foreach (@{$self->{arcs}}) {
	$self->{fig_file}->{objects}->{$_}->setAttributeValue($time,$attribute,
							      $value);
    }
    foreach (@{$self->{compounds}}) {
	$self->{fig_file}->{objects}->{$_}->setAttributeValue($time,$attribute,
							      $value);
    }
    foreach (@{$self->{ellipses}}) {
	$self->{fig_file}->{objects}->{$_}->setAttributeValue($time,$attribute,
							      $value);
    }
    foreach (@{$self->{polylines}}) {
	$self->{fig_file}->{objects}->{$_}->setAttributeValue($time,$attribute,
							      $value);
    }
    foreach (@{$self->{splines}}) {
	$self->{fig_file}->{objects}->{$_}->setAttributeValue($time,$attribute,
							      $value);
    }
    foreach (@{$self->{texts}}) {
	$self->{fig_file}->{objects}->{$_}->setAttributeValue($time,$attribute,
							      $value);
    }
}

sub setPenColor {
    my $self = shift;
    my $time = shift;
    my $color = $FigAnim::Utils::colors_codes{shift};
    if (defined $color) {
	$self->setAttributeValue($time,'pen_color',$color);
    }
}

sub setFillColor {
    my $self = shift;
    my $time = shift;
    my $color = $FigAnim::Utils::colors_codes{shift};
    if (defined $color) {
	$self->setAttributeValue($time,'fill_color',$color);
    }
}

sub hide {
    my $self = shift;
    my $time = shift;
    
    foreach (@{$self->{arcs}}) {
	$self->{fig_file}->{objects}->{$_}->hide($time);
    }
    foreach (@{$self->{compounds}}) {
	$self->{fig_file}->{objects}->{$_}->hide($time);
    }
    foreach (@{$self->{ellipses}}) {
	$self->{fig_file}->{objects}->{$_}->hide($time);
    }
    foreach (@{$self->{polylines}}) {
	$self->{fig_file}->{objects}->{$_}->hide($time);
    }
    foreach (@{$self->{splines}}) {
	$self->{fig_file}->{objects}->{$_}->hide($time);
    }
    foreach (@{$self->{texts}}) {
	$self->{fig_file}->{objects}->{$_}->hide($time);
    }
}

sub show {
    my $self = shift;
    my $time = shift;
    
    foreach (@{$self->{arcs}}) {
	$self->{fig_file}->{objects}->{$_}->show($time);
    }
    foreach (@{$self->{compounds}}) {
	$self->{fig_file}->{objects}->{$_}->show($time);
    }
    foreach (@{$self->{ellipses}}) {
	$self->{fig_file}->{objects}->{$_}->show($time);
    }
    foreach (@{$self->{polylines}}) {
	$self->{fig_file}->{objects}->{$_}->show($time);
    }
    foreach (@{$self->{splines}}) {
	$self->{fig_file}->{objects}->{$_}->show($time);
    }
    foreach (@{$self->{texts}}) {
	$self->{fig_file}->{objects}->{$_}->show($time);
    }
}

sub changeThickness {
    my $self = shift;
    my $beginning = shift;
    my $duration = shift;
    my $thickness = shift;
    
    foreach (@{$self->{arcs}}) {
	$self->{fig_file}->{objects}->{$_}->changeThickness($beginning,
							    $duration,
							    $thickness);
    }
    foreach (@{$self->{compounds}}) {
	$self->{fig_file}->{objects}->{$_}->changeThickness($beginning,
							    $duration,
							    $thickness);
    }
    foreach (@{$self->{ellipses}}) {
	$self->{fig_file}->{objects}->{$_}->changeThickness($beginning,
							    $duration,
							    $thickness);
    }
    foreach (@{$self->{polylines}}) {
	$self->{fig_file}->{objects}->{$_}->changeThickness($beginning,
							    $duration,
							    $thickness);
    }
    foreach (@{$self->{splines}}) {
	$self->{fig_file}->{objects}->{$_}->changeThickness($beginning,
							    $duration,
							    $thickness);
    }
}

sub changeFillIntensity {
    my $self = shift;
    my $beginning = shift;
    my $duration = shift;
    my $intensity = shift;
    
    foreach (@{$self->{arcs}}) {
	$self->{fig_file}->{objects}->{$_}->changeFillIntensity($beginning,
								$duration,
								$intensity);
    }
    foreach (@{$self->{compounds}}) {
	$self->{fig_file}->{objects}->{$_}->changeFillIntensity($beginning,
								$duration,
								$intensity);
    }
    foreach (@{$self->{ellipses}}) {
	$self->{fig_file}->{objects}->{$_}->changeFillIntensity($beginning,
								$duration,
								$intensity);
    }
    foreach (@{$self->{polylines}}) {
	$self->{fig_file}->{objects}->{$_}->changeFillIntensity($beginning,
								$duration,
								$intensity);
    }
    foreach (@{$self->{splines}}) {
	$self->{fig_file}->{objects}->{$_}->changeFillIntensity($beginning,
								$duration,
								$intensity);
    }
}

sub translate {
    my $self = shift;
    my $beginning = shift;
    my $duration = shift;
    my $x = shift;
    my $y = shift;
    my $unit = shift;
    $unit = '' if (!(defined $unit));
    
    my @anim = (16, $self->{name}, $beginning, $duration, $x, $y, $unit);
    push @{$self->{fig_file}->{animations}}, \@anim;
    
    foreach (@{$self->{arcs}}) {
	$self->{fig_file}->{objects}->{$_}->translate($beginning, $duration,
						      $x, $y, $unit);
    }
    foreach (@{$self->{compounds}}) {
	$self->{fig_file}->{objects}->{$_}->translate($beginning, $duration,
						      $x, $y, $unit);
    }
    foreach (@{$self->{ellipses}}) {
	$self->{fig_file}->{objects}->{$_}->translate($beginning, $duration,
						      $x, $y, $unit);
    }
    foreach (@{$self->{polylines}}) {
	$self->{fig_file}->{objects}->{$_}->translate($beginning, $duration,
						      $x, $y, $unit);
    }
    foreach (@{$self->{splines}}) {
	$self->{fig_file}->{objects}->{$_}->translate($beginning, $duration,
						      $x, $y, $unit);
    }
    foreach (@{$self->{texts}}) {
	$self->{fig_file}->{objects}->{$_}->translate($beginning, $duration,
						      $x, $y, $unit);
    }
}

sub rotate {
    my $self = shift;
    my $beginning = shift;
    my $duration = shift;
    my $angle = shift;
    my $c_x = shift;
    my $c_y = shift;
    if (!((defined $c_x) && (defined $c_y))) {
	$c_x = $self->{center_x};
	$c_y = $self->{center_y};
    }
    my $unit = shift;
    $unit = '' if (!(defined $unit));
    
    my @anim = (26, $self->{name},$beginning,$duration,$angle,$c_x,$c_y,$unit);
    push @{$self->{fig_file}->{animations}}, \@anim;
    
    foreach (@{$self->{arcs}}) {
	$self->{fig_file}->{objects}->{$_}->rotate($beginning,$duration,$angle,
						   $c_x,$c_y,$unit);
    }
    foreach (@{$self->{compounds}}) {
	$self->{fig_file}->{objects}->{$_}->rotate($beginning,$duration,$angle,
						   $c_x,$c_y,$unit);
    }
    foreach (@{$self->{ellipses}}) {
	$self->{fig_file}->{objects}->{$_}->rotate($beginning,$duration,$angle,
						   $c_x,$c_y,$unit);
    }
    foreach (@{$self->{polylines}}) {
	$self->{fig_file}->{objects}->{$_}->rotate($beginning,$duration,$angle,
						   $c_x,$c_y,$unit);
    }
    foreach (@{$self->{splines}}) {
	$self->{fig_file}->{objects}->{$_}->rotate($beginning,$duration,$angle,
						   $c_x,$c_y,$unit);
    }
    foreach (@{$self->{texts}}) {
	$self->{fig_file}->{objects}->{$_}->rotate($beginning,$duration,$angle,
						   $c_x,$c_y,$unit);
    }
}

sub scale {
    my $self = shift;
    my $beginning = shift;
    my $duration = shift;
    my $scale = shift;
    my $c_x = shift;
    my $c_y = shift;
    if (!((defined $c_x) && (defined $c_y))) {
	$c_x = $self->{center_x};
	$c_y = $self->{center_y};
    }
    
    my @anim = (36, $self->{name},$beginning,$duration,$scale,$c_x,$c_y);
    push @{$self->{fig_file}->{animations}}, \@anim;
    
    foreach (@{$self->{arcs}}) {
	$self->{fig_file}->{objects}->{$_}->scale($beginning,$duration,$scale,
						  $c_x,$c_y);
    }
    foreach (@{$self->{compounds}}) {
	$self->{fig_file}->{objects}->{$_}->scale($beginning,$duration,$scale,
						  $c_x,$c_y);
    }
    foreach (@{$self->{ellipses}}) {
	$self->{fig_file}->{objects}->{$_}->scale($beginning,$duration,$scale,
						  $c_x,$c_y);
    }
    foreach (@{$self->{polylines}}) {
	$self->{fig_file}->{objects}->{$_}->scale($beginning,$duration,$scale,
						  $c_x,$c_y);
    }
    foreach (@{$self->{splines}}) {
	$self->{fig_file}->{objects}->{$_}->scale($beginning,$duration,$scale,
						  $c_x,$c_y);
    }
    foreach (@{$self->{texts}}) {
	$self->{fig_file}->{objects}->{$_}->scale($beginning,$duration,$scale,
						  $c_x,$c_y);
    }
}


# outputs a SVG element
sub outputSVG {
    my $self = shift;
    my $fh = shift;

    my ($colors) = @_;

    foreach (split(/\n/, $self->{name})) {
	print $fh "<!-- $_ -->\n";
    }
    
    print $fh "<g>\n";

    my @objects = @{$self->{arcs}};
    push @objects, @{$self->{ellipses}};
    push @objects, @{$self->{polylines}};
    push @objects, @{$self->{splines}};
    push @objects, @{$self->{texts}};

    # sorts objects by depth
    @objects =
	sort {
	    if ($self->{fig_file}->{objects}->{$a}->{depth} <
		$self->{fig_file}->{objects}->{$b}->{depth}) {
		return 1;
	    } elsif ($self->{fig_file}->{objects}->{$a}->{depth} ==
		     $self->{fig_file}->{objects}->{$b}->{depth}) {
		return 0;
	    } else {
		return -1;
	    }
    } @objects;

    foreach (@objects) {
	$self->{fig_file}->{objects}->{$_}->outputSVG($fh, $colors);
    }

    foreach (@{$self->{compounds}}) {
	$self->{fig_file}->{objects}->{$_}->outputSVG($fh, $colors);
    }

    print $fh "</g>\n\n";
}


1;
