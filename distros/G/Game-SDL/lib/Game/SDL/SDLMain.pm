use SDL::Video;
use SDL::Surface;
use SDL::Rect;

### The SDL startup routine class to have a screen video surface :
### (also from sdl.perl.org)

sub new {

	($class, $screen_width, $screen_height) = @_;

	if (not defined($screen_width) and not defined($screen_height)) {
		print "SDLMain : please provide a screen width and height\n";
		exit(0);
	} 

	SDL::init(SDL_INIT_VIDEO);

    	# setting video mode
    	my $screen_surface = SDL::Video::set_video_mode($screen_width,
                                                    $screen_height,
                                                    32,
                                                    SDL_ANYFORMAT);
	$self = { screen_surface => $screen_surface, };

	bless $self, $class;
}

1;
