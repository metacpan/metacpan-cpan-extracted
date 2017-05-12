#
package Graphics::VTK::KeyFrame;

use Graphics::VTK;

# KeyFrame.tcl - Keyframes for vtk

# These procs provide a simple (yet powerful) keyframing capability
# for vtk tcl applications
# A keyframe contains a time sorted ordering of methods
# and arguments for an object. Key locations, colors, and
# other parameters are stored and can be interpolated
# at intermediate points.
# The protocol for keyframing is illustrated in the following
# example to keyframe the position of the camera camera1:
# the renderer ren1:
# 1) KeyNew CameraPosition camera1 SetPosition
#    create a keyframe for camera1 that will use the
#    SetPosition method of the camera
# 2) KeyAdd CameraPosition camera1 [camera1 GetPosition]
#    adds the current camera position as a key frame
# 3) Repeat 2, changing the camera position for each step
# 4) KeyRun CameraPosition 30
#    runs key frame for 30 steps. Steps that lie
#    between keyframes are interpolated with Cubic Splines.
# After each step is interpolated, the proc KeyRender
# is invoked. This proc can be redefined by the use to
# do something more sophisticated. The default proc does
# a: renWin Render

############################################
# Create a new keyframe for object and method
#
sub new
{

 my $type = shift;

 my $self = {};
 my $object = shift;
 my $method = shift;
 my $renWin = shift;
 $self->{object} = $object;
 $self->{method} = $method;
 $self->{renWin} = $renWin;
 $self->{'counter'} = 0;
 $self->{'debug'} = 0;
 $self->{'values'} = [];
 $self->{splines} = [];
 bless $self, $type;
}


# Reset the keyframe count to 0
#
sub Reset
{
 my $self = shift;
 $self->{'counter'} = 0;
 print("Resetting Keyframe") if ($self->{'debug'});
}


# Add a new keyframe with supplied position
sub Add{
  my $self = shift;
  my @position = @_;
  my $values = $self->{'values'} ;
  $values->[$self->{counter}] = [@position];
  $self->{counter}++;
};


# Run a keyframe for "frames" frames
#
sub Run
{
 my $self = shift;
 my $frames = shift;
 my $i;
 my $j;
 my $method;
 my $spline;
 my $t;
 $method = $self->{'method'};
 my $values = $self->{'values'};
 my $firstvalue = $values->[0]; 

 # create splines if they do not exist
 my $splines = $self->{splines};
 $j = 0;
 foreach (@$firstvalue){
 	my $spline = $splines->[$j];
	unless( defined($spline)){ 
		$spline = $splines->[$j] = Graphics::VTK::KochanekSpline->new;
	}
	$spline->RemoveAllPoints;
	$j++;
}
 	

 # add points to the splines 

 for ($i = 0; $i < $self->{'counter'}; $i += 1) # go thru each key frame
  {
   for ($j = 0; $j < @{$self->{'values'}[$i]}; $j += 1) # go thru each x/y/z value 
    {
     my $spline = $splines->[$j];
     $spline->AddPoint($i,$self->{'values'}[$i][$j]);
    }
  }

 # evaluate splines at key frames

 for ($i = 0; $i < $frames; $i += 1) # Go thru the specified number of frames
  {
   $t = ($self->{'counter'} - 1) / ($frames - 1) * $i;
   $self->Goto($t);
  }
}

# Goto keyframe #
#
sub Goto
{
 my $self = shift;
 my $t = shift;
 my $j;
 my $method = $self->{method};
 my $object = $self->{object};
 my $splines = $self->{splines};
 my @splineResult;
 for ($j = 0; $j < @{$self->{'values'}[0]}; $j += 1)
  {
   my $spline = $splines->[$j];
   push @splineResult, $spline->Evaluate($t);
  }
  $object->$method(@splineResult);
 #print("$keyCommand") if ($a{'debug'} == 1);
 $self->Render();
}

# Called after keyframe is executed
#
sub Render
{
 my $self = shift;
 my $renWin = $self->{renWin};
 $renWin->Render;
}

1;
