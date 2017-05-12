use Lego::Ldraw;
use Lego::Ldraw::Display;
use OpenGL qw/ :all /;
use Tk;

$, = " "; $\ = " ";

my $l = Lego::Ldraw->new_from_file($ARGV[0]);
my $point = 'camera';

$d = Lego::Ldraw::Display->new(300, 400, $l);

$d->bindspec(GLUT_KEY_UP,        GLUT_ACTIVE_SHIFT, sub { shift->move($point, 's', 'p', -12) });
$d->bindspec(GLUT_KEY_DOWN,      GLUT_ACTIVE_SHIFT, sub { shift->move($point, 's', 'p', +12) });
$d->bindspec(GLUT_KEY_LEFT,      GLUT_ACTIVE_SHIFT, sub { shift->move($point, 's', 't', -12) });
$d->bindspec(GLUT_KEY_RIGHT,     GLUT_ACTIVE_SHIFT, sub { shift->move($point, 's', 't', +12) });
$d->bindspec(GLUT_KEY_PAGE_UP,   GLUT_ACTIVE_SHIFT, sub { shift->move($point, 's', 'r', +12) });
$d->bindspec(GLUT_KEY_PAGE_DOWN, GLUT_ACTIVE_SHIFT, sub { shift->move($point, 's', 'r', -12) });

$d->bindspec(GLUT_KEY_UP,        sub { shift->move($point, 'x', 'y', -12) });
$d->bindspec(GLUT_KEY_DOWN,      sub { shift->move($point, 'x', 'y', +12) });
$d->bindspec(GLUT_KEY_LEFT,      sub { shift->move($point, 'x', 'x', -12) });
$d->bindspec(GLUT_KEY_RIGHT,     sub { shift->move($point, 'x', 'x', +12) });
$d->bindspec(GLUT_KEY_PAGE_UP,   sub { shift->move($point, 'x', 'z', +12) });
$d->bindspec(GLUT_KEY_PAGE_DOWN, sub { shift->move($point, 'x', 'z', -12) });

$d->bindspec(GLUT_KEY_INSERT,    sub { $camera->Contents(join ' ', @{ shift->{camera} }) } );
$d->bindspec(GLUT_KEY_INSERT,    GLUT_ACTIVE_SHIFT, sub { $lookat->Contents(join ' ', @{ shift->{lookat} }) } );

$MW = MainWindow->new;

$MW->bind( '<KeyPress>' => sub
    {
        my($c) = @_;
        my $e = $c->XEvent;
        my( $x, $y, $k ) = ( $e->x, $e->y, $e->K );
	for ($k) {
	  /^c$/ && do { $point = "camera"; last };
	  /^l$/ && do { $point = "lookat"; last };

	  /^x$/ && do { $move = "x"; last };
	  /^s$/ && do { $move = "s"; last };

	  /^Up$/ && do { $d->move($point, $move, 'y', -12); last };
	  /^Down$/ && do { $d->move($point, $move, 'y', +12); last };

	  /^Left$/ && do { $d->move($point, $move, 'x', -12); last };
	  /^Right$/ && do { $d->move($point, $move, 'x', +12); last };

	  /^Prev$/ && do { $d->move($point, $move, 'z', +12); last };
	  /^Next$/ && do { $d->move($point, $move, 'z', -12); last };

	  /^Insert$/ && do { $point = "lookat"; last };
	  /^Delete$/ && do { $point = "lookat"; last };

	}
    } );

$frame = $MW->Frame(-borderwidth => 1, -relief => 'groove')->pack;

$frame->Radiobutton(-variable => \$point, -text => 'Camera', -value => 'camera')->pack(-side => 'left');
$frame->Radiobutton(-variable => \$point, -text => 'Look at', -value => 'lookat')->pack(-side => 'left');;

$frame = $MW->Frame(-borderwidth => 1, -relief => 'groove')->pack;

$frame->Radiobutton(-variable => \$move, -text => 'Axial', -value => 'x')->pack(-side => 'left');
$frame->Radiobutton(-variable => \$move, -text => 'Spheric', -value => 's')->pack(-side => 'left');;

$camera = $MW->Text(-width => 16, -height => 1, -state => 'normal');
$lookat = $MW->Text(-width => 16, -height => 1, -state => 'normal');
$camera->pack;
$lookat->pack;

$idle = sub { die unless $MW; $MW->update };

$d->init($idle);
