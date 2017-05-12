use Test;
BEGIN { plan tests => 1 };
use GD::OrgChart;
use GD;

  use IO::File;

  our $NAME = "builtin-home";

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

  our $chart = GD::OrgChart->new({ size => 1, font => $FONT });
  $chart->DrawTree($COMPANY);

  our $fh = IO::File->new("t/$NAME.tmp", "w");
  binmode $fh;	# just in case

  our $image = $chart->Image;
  $fh->print($image->png);
  $fh->close();

  our $status = system "cmp", "-s", "t/$NAME.png", "t/$NAME.tmp";

ok($status == 0);
