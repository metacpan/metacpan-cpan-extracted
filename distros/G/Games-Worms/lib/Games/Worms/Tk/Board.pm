# Time-stamp: "1999-03-03 19:28:39 MST" -*-Perl-*-
package Games::Worms::Tk::Board;
use strict;
use Games::Worms::Board 0.6;
use vars qw($Debug $VERSION %Default @ISA);
@ISA = ('Games::Worms::Board');
use Tk qw/DoOneEvent DONT_WAIT exit/;
$VERSION = "0.60";
$Debug = 0;

#--------------------------------------------------------------------------

sub init {
  my $it = $_[0];
  $Games::Worms::Board::Boards{$it} = $it;
  return;
}

sub _board_cleanup {
  print "I'm cleanup.\n" if $Debug;
  foreach my $board (values %Games::Worms::Board::Boards) {
    print "Destroying $board\n" if $Debug;;
    $board->{'window'}->withdraw;
    $board->destroy;
  };
  %Games::Worms::Board::Boards = ();

  print "about to call Tk::exit\n" if $Debug;
  Tk::exit;
}


sub Seg  { return 'Games::Worms::Tk::Seg' }
sub Node { return 'Games::Worms::Node' }

#--------------------------------------------------------------------------
#sub _exit_zero {
# exit 0;
#}

#--------------------------------------------------------------------------

#sub _about {
#  my $board = shift;
#  my $mw = $board->{'window'} || die "No window?";
#  $mw->Dialog(
#    -title => 'About',
#    -text => "Worms version $Games::Worms::VERSION\n\nSean M. Burke",
#    -bitmap => 'info',
#    -buttons => ["Dismiss"]
#  );
#};

#--------------------------------------------------------------------------

sub window_init {
  my $board = shift;
  my $mw = $board->{'window'} || die "No window?";

  $mw->toplevel->title($Debug ?
    "Worms v$Games::Worms::Tk::VERSION" : 'Worms'
  );

  my $menubar = $mw->Frame;
  $menubar->pack(-side => 'top');
  $menubar->grid(qw/-sticky ew/);
  $menubar->gridColumnconfigure(qw/0 -weight 1/);

  my $about_button = $mw->Dialog(
    -text => "Worms version $Games::Worms::Tk::VERSION\n
Sean M. Burke
<sburke\@netadventure.net>",
    -title => 'About Worms',
    -bitmap => 'info',
    -buttons => ["OK"]
  );
  # $about_button->configure(-wraplength => '6i');

  my $file = $menubar->Menubutton(qw/-text File -underline 0 -menuitems / =>
    [
     [Button    => '~Quit', -command => [ \&_board_cleanup ]],
    ])->grid(qw/-sticky w/); 
  my $about = $menubar->Menubutton(qw/-text About -underline 0 -menuitems/ =>
    [
     [Button    => "~About Worms", -command => [ $about_button => 'Show' ]],
    ])->grid(qw/-row 0 -column 1 -sticky w/); 

  $board->{'canvas'} = $mw->Canvas(
    -background => $board->{'bg_color'},
    -width => $board->{'canvas_width'},
    -height => $board->{'canvas_height'},
  )->grid;

#  my $s = $mw->Frame->pack(-side => 'bottom');
#  $s->Label(-text => "Zaz!!!")
#    ->pack('-side' => 'left', '-anchor' => 'w');

  $board->init_grid;
  $board->refresh_and_draw_grid;
  return;
}


#--------------------------------------------------------------------------

sub worm_status_setup {
  my $board = $_[0];
  my $mw = $board->{'window'} || die "No window?";


  my $c = 1;
  foreach my $worm (@{$board->{'worms'}}) {
    print
      "worm $c\: $worm->{'name'}",
      map(
        (defined($worm->{$_}) && length($worm->{$_}))
         ? ", $_ $worm->{$_}" : '',
        qw(rules color) # attributes of note
      ),
      "\n";
    ++$c;
  }

# feh... get this working some time.
#  my $c = 1;
#  foreach my $worm (@{$board->{'worms'}}) {
#    my $s = $worm->{'status_bar'} = $mw->Frame->pack(-side => 'bottom');
#
#    $s->Label(-text => "$c\: $worm->{'name'}")
#      ->pack('-side' => 'left', '-anchor' => 'w');
#
#    ++$c;
#  }

  return;
}

#--------------------------------------------------------------------------
sub end_game {

  # Replace with something fancier

  my $board = $_[0];
  print "All dead.\n";
  my $c = 1;

  print "      segs eaten\n";
  foreach my $worm (@{$board->{'worms'}}) {
    printf "worm $c\: %7d : $worm->{'name'}\n",
      $worm->segments_eaten;
    ++$c;
  }
  return;
}

#--------------------------------------------------------------------------

sub tick {
  my $board = $_[0];
  $board->{'window'}->update;
  DoOneEvent(DONT_WAIT); # be nice and process XEvents if they arise
  DoOneEvent(DONT_WAIT); # be nice and process XEvents if they arise
}

#--------------------------------------------------------------------------

1;

__END__

