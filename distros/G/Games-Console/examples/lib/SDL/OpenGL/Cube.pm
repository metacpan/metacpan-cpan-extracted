package SDL::OpenGL::Cube;
use SDL;
use SDL::OpenGL;

my $vertex_array = pack "d24", 
	-0.5,-0.5,-0.5, 0.5,-0.5,-0.5, 0.5,0.5,-0.5, -0.5,0.5,-0.5, # back
	-0.5,-0.5,0.5,  0.5,-0.5,0.5,  0.5,0.5,0.5,  -0.5,0.5,0.5 ;  # front

my $indicies = pack "C24", 	
			4,5,6,7,	# front
			1,2,6,5,	# right
			0,1,5,4,	# bottom
			0,3,2,1,	# back
			0,4,7,3,	# left
			2,3,7,6;	# top

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {};
	bless $self,$class;
	$self;
}

sub draw {
	my ($self) = @_;
	$self->color();
	glEnableClientState(GL_VERTEX_ARRAY());
	glVertexPointer(3,GL_DOUBLE(),0,$vertex_array);
	glDrawElements(GL_QUADS(), 24, GL_UNSIGNED_BYTE(), $indicies);
}

sub color {
	my ($self,@colors) = @_;

	if (@colors) {
		$$self{colored} = 1;
		die "SDL::OpenGL::Cube::color requires 24 floating point color values\n"
			unless (scalar(@colors) == 24);
		$$self{-colors} = pack "f24",@colors;
	}

	if ($$self{colored}) {
		glEnableClientState(GL_COLOR_ARRAY);
		glColorPointer(3,GL_FLOAT,0,$$self{-colors});
	} else {
		glDisableClientState(GL_COLOR_ARRAY);
	}
}


1;

