package Meta::Widget::Gtk::Sprite;

use 5.006;
use strict;
#use warnings;
use Gtk;
use Gtk::Gdk::ImlibImage;
use Gnome;
#use Data::Dumper;
sub _debug;

#require Exporter;

=head1 NAME

Meta::Widget::Gtk::Sprite - Perl module to do C64 style sprites

=head1 SYNOPSIS

 use Gtk;
 use Gnome;
 init Gnome "test.pl";
 use Meta::Widget::Gtk::Sprite;
 my $mw = new Gtk::Window( "toplevel" );
 my($canvas) = Gnome::Canvas->new() ;
 $mw->add($canvas );
 $canvas->show; 
 my $croot = $canvas->root;
 my $sprites = new Meta::Widget::Gtk::Sprite($croot);
 my $p1 = $sprites->create("./player1.xpm", 100, 0);
 $sprites->slide_to_time($p1,5000, 100, 100);
 my $p2 = $sprites->create("./player2.xpm", 0, 0);
 $sprites->slide_to_speed($p2,10, 100, 100);
 $sprites->set_collision_handler(\&Bang);
 $mw->show;
 Gtk->main;
 sub Bang
   {
     print "Bang!\n";
     exit;
   }


=head1 Description

Sprite is a module to bring back the simple graphics programming of the C64 (hopefully without the lookslikearse component).  You can declare pictures to be 'sprites' on the canvas, and then move them around and crash them into each other.

=head1 NOTE

The canvas is the Gnome::Canvas object.  You have to have a Gtk::Canvas object before starting Sprite.

=head1 METHODS

=over 4

=cut

#our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Sprite ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';


# Preloaded methods go here.

=item new Meta::Widget::Gtk::Sprite( $canvas_root );

The new method takes one argument, the canvas root object for the canvas you want to draw on.

You may obtain the canvas root from your canvas like this:

 my $croot = $canvas->root;


=cut

sub new
	{
		_debug "New sprite manager created";
		my $self = bless {}, ref($_[0]) || $_[0] || __PACKAGE__;
		$self->{sprite} = {};
		$self->{croot} = $_[1];
		$self->{cgroup} = {};
		return $self;
	}
		
=item $sprite_number = $sprites->create("/path/to/filename", 10, 20);

Create will load an image file (right now, only xpm format) from disk and make a sprite out of it.  The two numbers are the x and y position on the canvas.

=cut

sub create
	{
		my ($self, $filename, $x, $y) = @_;
		my $img = Gtk::Gdk::ImlibImage->load_image($filename) || die "Could not load requested tile, $filename.  $!";
		my ( $cg, $cg_index ) = $self->_get_new_cgroup();
		$cg->hide;
		my $imgitem = $cg->new($cg, "Gnome::CanvasImage",
			'image' => $img,
			'x' => $x,
			'y' => $y,
			width => $img->rgb_width,
			height => $img->rgb_height,
		);
		$cg->{x} = $x;
		$cg->{y} = $y;
		$cg->{width} = $img->rgb_width;
		$cg->{height} = $img->rgb_height;
		#$cg->{radius} = sqrt($cg->{width}**2 + $cg->{height}**2)/2;
		$cg->{radius} = ($cg->{width} + $cg->{height})/4;
		$cg->{cx} = $cg->{x} + $cg->{width}/2;
		$cg->{cy} = $cg->{y} + $cg->{height}/2;
		my $index = $self->_add_sprite($cg);
		$cg->{index} = $index;
		return $index;
	}

=item $sprites->show( $sprite_number );

Makes the sprite appear on the canvas

=cut

sub show
	{
		my ($self, $item) = @_;
		$self->{sprite}->{$item}->show;
	}

=item $sprites->hide( $sprite_number );

Make the sprite picture disappear from the canvas.  Note that it can still collide with other sprites.  If you don't want it to hit anything, move it out of the way or ignore it in your own collision handler.

=cut

sub hide
	{
		my ($self, $item) = @_;
		$self->{sprite}->{$item}->hide;
	}


=item $sprites->destroy( $sprite_number );

Completely destroys a sprite.

=cut

sub destroy
	{
	}

sub update_sprite
	{
		my ($self, $item) = @_;
		my $cg = $self->{sprite}->{$item};
		$cg->{cx} = $cg->{x} + $cg->{width}/2;
		$cg->{cy} = $cg->{y} + $cg->{height}/2;
	}
		
		

=item $sprites->move_to( $sprite_number, 10, 20 );

Teleports the sprite named in $sprite_number to the position given immediately.  Contrast slide_to_xxx functions.

=cut

sub move_to
	{
		my ( $self, $index, $x, $y) = @_;
		#_debug "Moving sprite number $index";
		#_debug "Moving sprite with index $index and reef  ", ref( $self->{sprite}->{$index}), "\n";
		return unless (ref( $self->{sprite}->{$index}) =~ /CanvasGroup/i);
		my $deltax = $x-$self->{sprite}->{$index}->{x};
		my $deltay = $y-$self->{sprite}->{$index}->{y};
		$self->{sprite}->{$index}->{x} = $x;
		$self->{sprite}->{$index}->{y} = $y;
		_debug "time: ", time(), " index: $index x: $x, y: $y\n";
		$self->{sprite}->{$index}->move($deltax, $deltay);
		
	}

=item $sprites->slide_to_time( $sprite_number, $time, 10, 20 );

Will make the sprite $sprite_number 'slide' across the canvas to the position 10, 20.  It will take $time seconds to do so.  Slow speeds will appear jerky.

=cut

sub slide_to_time
	{
		my ( $self, $index, $time, $x, $y) = @_;
		if ( $time ==0 )
			{
				#The user really wanted move_to
				$self->move_to($index, $x, $y);
				#Aren't I a nice guy?
				return;
			}
		#$self->velocity($index, 1, 1);
		my $deltax = $x-$self->{sprite}->{$index}->{x};
		my $deltay = $y-$self->{sprite}->{$index}->{y};
		my $distance = sqrt($deltax**2 + $deltay**2);
		my $speed = $distance / $time;
		my $vx  = $deltax / $time*1000;
		my $vy = $deltay / $time*1000;
		$self->velocity($index, $vx, $vy);
		my $larger = (abs($deltax)>abs($deltay)) ? $deltax : $deltay;
		$self->{sprite}->{$index}->{timeout} = $time;
		_debug "Moving sprite $index to $x, $y (distance $distance) at speed $vx, $vy for $time milliseconds\n";
	}
sub _delta
	{
		my ($self, $index, $x, $y) = @_;
		my $deltax = $x-$self->{sprite}->{$index}->{x};
		my $deltay = $y-$self->{sprite}->{$index}->{y};
		return ($deltax, $deltay);
	}

=item $sprites->slide_to_speed( $sprite_number, $speed, 10, 20);

Will 'slide' the sprite $sprite_number to the position 10, 20.  It will move at a speed of $speed pixels per second.

=cut

sub slide_to_speed
	{
		my ( $self, $index, $speed, $x, $y) = @_;
		if ( $speed ==0 )
			{
				#The user really wanted move_to
				$self->move_to($index, $x, $y);
				#Aren't I a nice guy?
				return;
			}
		my ($deltax, $deltay) = $self->_delta($index, $x, $y);
		my $distance = sqrt($deltax**2 + $deltay**2);
		my $time = $distance / $speed;
		my $vx = $deltax / $time;
		my $vy = $deltay / $time;
		_debug "Moving sprite $index to $x, $y at $vx, $vy for $time milliseconds";
		$self->velocity($index, $vx, $vy);
		$self->{sprite}->{$index}->{timeout} = $time * 1000;
	}

=item $sprites->pos( $sprite_number);

Returns the x and y coordinates of $sprite_number

=cut

sub pos
	{
		my ($self, $index) = (shift, shift);
		_debug "Returning position for sprite number $index";
		return $self->{sprite}->{$index}->{x}, $self->{sprite}->{$index}->{y};
	}

=item $sprites->velocity( $sprite_number, 5, 6);

Sets the speed of $sprite_number.  The numbers are the x and y speeds.  Negative numbers will make the sprite go backwards.

=cut

sub velocity
	{
		my ( $self, $index, $vx, $vy) = @_;
		my $larger = abs((abs($vx)>abs($vy)) ? $vx : $vy);
		if ( $larger == 0 ) 
			{
				$self->{sprite}->{$index}->{vx} = 0;
				$self->{sprite}->{$index}->{vy} = 0;
				Gtk->timeout_remove($self->{sprite}->{$index}->{timer});
				return;
			}
		$self->{sprite}->{$index}->{interval} = 1000/$larger;
		$vx /= $larger;
		$vy /= $larger;
		_debug "vx: $vx, vy: $vy interval ", $self->{sprite}->{$index}->{interval}, "\n";
		$self->{sprite}->{$index}->{vx} = $vx;
		$self->{sprite}->{$index}->{vy} = $vy;
		$self->{sprite}->{$index}->{timer} = Gtk->timeout_add( $self->{sprite}->{$index}->{interval}, \&tick, $self, $index);
	}

sub tick
	{	
		#shift;
		my ($self, $i) = @_;
			my $newx = $self->{sprite}{$i}{x} + $self->{sprite}{$i}{vx};
			my $newy = $self->{sprite}->{$i}->{y} + $self->{sprite}->{$i}->{vy};
			if ( $self->{sprite}->{$i}->{timeout} > 0 )
				{
					$self->{sprite}->{$i}->{timeout} -= $self->{sprite}->{$i}->{interval};
					#print "Timeout is ", $self->{sprite}->{$i}->{timeout}, " interval is ", $self->{sprite}->{$i}->{interval}, "\n";
					if ( $self->{sprite}->{$i}->{timeout} < 1 ) 
						{
							$self->velocity($i, 0,0);
						}
				}

			#_debug "Calling move_to from tick loop for sprite number $i\n";
			$self->move_to( $i, $newx, $newy);
			$self->update_sprite( $i );
			$self->check_coll($i) if $self->{collision_handler};
		return 1;
	}

sub check_coll
	{
		my ($self, $item) = @_;
		my $cg = $self->{sprite}->{$item};
		foreach my $si ( keys %{$self->{sprite}} )
			{
				next if ( $si eq $item);
				my $sp = $self->{sprite}->{$si};
				next unless $sp;
				my $centre_dist = sqrt( ($cg->{x} - $sp->{x})**2 +  ($cg->{y} - $sp->{y})**2);
				if ( ($centre_dist - $cg->{radius} -$sp->{radius} ) < 0 )
					{
					  _debug "Collision between $cg->{x}, $cg->{y} radius $cg->{radius}  and $sp->{x}, $sp->{y} radius $sp->{radius}\n";
						&{$self->{collision_handler}}($item, $si);
					}
			}
	}

=item $sprites->set_collision_handler ( \&collision_handler );

Name a function that will be called when two sprites collide.  Note that the collision detection system is extremely crappy right now.  It turns out that it is very difficult to efficiently detect collisions.

Your function will be called like this:

collision_handler( $sprite_number, $sprite_number);

where the two sprite numbers are the two sprites that collided.  Multiple sprites colliding will cause many collision handler callbacks.

Note well that if you set the collision handler Sprite.pm will check every single sprite for collisions every animation loop.  I haven't optimised this, so you will notice a massive slowdown as you add more sprites.

To switch collisions checking off, set the handler to undef:

$sprites->set_collision_handler ( undef );

=cut

sub set_collision_handler
	{
		my ($self, $handler) = @_;
		$self->{collision_handler} = $handler;
	}
		



{
	my $next_sprite=1;
	sub _add_sprite
		{
			my ( $self, $sprite) = @_;;
			$self->{sprite}->{$sprite} = $sprite;;
			#my $ind = $next_sprite;
			#$next_sprite++;
			return $sprite;
		}
}

{
        my $next_group=1;
	sub _get_new_cgroup
		{
			my $self = shift;
			$self->{cgroup}->{$next_group} = $self->{croot}->new($self->{croot}, "Gnome::CanvasGroup");
			my $ref = $self->{cgroup}->{$next_group};
			my $ind = $next_group;
			$next_group++;
			return $ref, $ind;
		}
}

sub _debug
	{
#		print @_, "\n";
	}


																							


1;
__END__

=head1 EXPORT

Nothing.


=head1 AUTHOR

jepri, E<lt>jeremy.price@member.sage-au.org.auE<gt>

=head1 SEE ALSO

L<perl>, man Gnome::reference, man Gtk::reference, Gnome::Canvas.

=cut
