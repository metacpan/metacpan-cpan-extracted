use Test;
BEGIN { plan tests => 1 };
use GD::OrgChart;
use GD;

# This tests inheritance by creating a new drawing function
# that will X out the boxes.
{
  package Foo;
  our @ISA = qw(GD::OrgChart);
  sub DrawBox
  {
    my $self = shift;
    my @b = $self->SUPER::DrawBox(@_);
    my $image = $self->SUPER::Image();
    my $color = $image->colorAllocate(0,0,0);
    $image->line(@b,$color);
    $image->line($b[0],$b[3],$b[2],$b[1],$color);
    return @b;
  }
}

  use IO::File;

  our $NAME = "inherit";

  our $COMPANY;

  # put data into $COMPANY such that it looks like:
  $COMPANY =
    { text => "Gary\nHome Owner", subs => [
      { text => "Tex\nVice President, Back Yard Security", subs => [
        { text => "Ophelia\nGate Watcher" },
        { text => "Cinnamon\nDeck Sitter" },
      ]},
      { text => "Dudley\nVice President, Front Yard Security", subs => [
        { text => "Jax\nBay Window Watcher" },
        { text => "Maisie\nDoor Watcher" },
      ]},
    ]};

  our $FONT = gdGiantFont;

  our $chart = Foo->new({ size => 12, font => $FONT });
  $chart->DrawTree($COMPANY);

  our $fh = IO::File->new("t/$NAME.tmp", "w");
  binmode $fh;	# just in case

  our $image = $chart->Image;
  $fh->print($image->png);
  $fh->close();

  our $status = system "cmp", "-s", "t/$NAME.png", "t/$NAME.tmp";

ok($status == 0);
