package Games::Go::Referee;

use strict;
use warnings;
use Games::Go::SGF;
use Games::Go::Referee::Node;
use English qw(-no_match_vars);  # Avoids regex performance penalty
use Carp;
our $VERSION = 0.10;

sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = {};
  $self->{_const} = {      # defaults
    size          => 18,   # default board size
    selfcapture   => 0,    # is self capture OK?
    ssk           => 0,    # situational super ko
    passes        => 2,    # number of consecutive passes required to finish play
    hfree         => 0,    # are handicap stones freely placed?
    handicap      => 0,    # the handicap number
    exitonerror   => 0,    # exit on (Go) error if set, or continue if not set
    alternation   => 1,    # flag alternation errors as errors? yes/on
    passcount     => 1,    # flag passcount errors as errors? yes/on
    pointformat   => 'sgf' # can be sgf or gmp
  };
  $self->{_node}        = {}; # contains a Referee::Node object
  $self->{_boardstr}    = {};
  $self->{_nodecount}   = 0;
  $self->{_movecount}   = 0;
  $self->{_passcount}   = 0;
  $self->{_colour}      = 'None';
  $self->{_cellfarm}    = {}; # eg key = 0,12 value = 'o','x', or '.'
  $self->{_errors}      = []; # eg [3][12] where 3 is an error code, 12 the node it happened
  $self->{_prisonersB}  = 0;
  $self->{_prisonersW}  = 0;
  $self->{_sgf}         = {}; # refererence to sgf file
  $self->{_coderef}     = undef;
  $self->{_cellfarm}{','} = ''; # pass is empty
  $self->{_debug}       = 0;
  $self->{_logfile}     = './refereelog.txt';
  bless $self, $class;
  $self->{_node}{0}     = makenode($self, $self->{_colour});
  return $self;
}

sub sgffile{
  my ($self, $sgf_file, $p1, $p2) = @_;
  my $sgf;  
  if (ref($sgf_file) eq 'Games::Go::SGF') {
    $sgf = $sgf_file;
  } else {  
    $sgf = new Games::Go::SGF($sgf_file, $p1, $p2);
    defined $sgf or croak "Bad Go sgf";
  }
  restart($self);
  size($self, $sgf->SZ);
  initrules($self, $sgf->RU);
  $self->{_sgf} = $sgf;
  $self->{_const}{handicap} = $sgf->HA if $sgf->HA;
  my $clicker = 0;
  my $movecount = 0;

  while (my $node = $sgf->move($clicker++)) {
    $movecount = donode($self, $node, $movecount);
  }
  return Games::Go::SGF::getsgf($sgf);
}

sub donode {
  my ($self, $node, $movecount) = @_;
  if (ref($node) eq 'Games::Go::SGF::Node'){
    if (ismove($node) or issetup($node)){
      processtags($self, $node);
      $movecount++;
    }
  } else {
    if (ref($node) eq 'Games::Go::SGF::Variation'){
      dovar($self, $node, $movecount);
    }
  }
  return $movecount
}

sub dovar {
  my ($self, $startpoint, $base) = @_;
  my $v = 0;
  my @vars = $startpoint->variations;

  while (defined $vars[$v]){
    my $basenumber = $base;
    restore($self, $base) unless $v == 0;

    for (@{$vars[$v++]}){
      $basenumber = donode($self, $_, $basenumber);
    }

  }

}

sub _iterboard (&$) {
  my ($sub, $size) = @_;
  for my $y (0..$size){
    for my $x (0..$size){
      $sub->($x, $y);
    }
  }
}

sub size {
  my ($self, $size) = @_;
  my $adjust = 1;
  $size ||= 19;
  $self->{_const}{size} = _numbersetting($self, $size, 'size', $adjust);
  clearboard($self);
  return $self->{_const}{size}
}

sub ruleset { &initrules }

sub debug {
  my $self = shift;
  my $debug = shift;
  $self->{_debug} = $debug if defined $debug and $debug =~ /0|1/;
  return $self->{_debug}
}

sub logfile {
  my $self = shift;
  my $logfile = shift;
  $self->{_logfile} = $logfile if defined $logfile;
  return $self->{_logfile}
}

sub ssk { 
  my $self = shift;
  $self->{_const}{ssk}         = _rulesetting($self, 'ssk', @_);
  return $self->{_const}{ssk}
}

sub alternation { 
  my $self = shift;
  $self->{_const}{alternation} = _rulesetting($self, 'alternation', @_);
  return $self->{_const}{alternation}
}

sub selfcapture { 
  my $self = shift;
  $self->{_const}{selfcapture} = _rulesetting($self, 'selfcapture', @_);
  return $self->{_const}{selfcapture}
}

sub exitonerror { 
  my $self = shift;
  $self->{_const}{exitonerror} = _rulesetting($self, 'exitonerror', @_);
  return $self->{_const}{exitonerror}
}
  
sub passes { 
  my $self = shift;  
  $self->{_const}{passes}      = _numbersetting($self, @_, 'passes', 0);
  return $self->{_const}{passes}
}

sub pointformat {
  my $self = shift;
  if (@_) {
    my $format = shift ;
    if ($format eq 'sgf' or $format eq 'gtp') {
      $self->{_const}{pointformat} = $format;
    } else {
      croak 'Illegal value ', $format if defined $format;
    }
  }
  return $self->{_const}{pointformat}
}

sub _numbersetting {
  my ($self, $value, $rule, $adjust) = @_;
  if ($value =~ /\d+/o and $value > 0) {
    $self->{_const}{$rule} = $value - $adjust;
  } else {
    croak 'Illegal value ', $value
  }
  return $self->{_const}{$rule}
}

sub _rulesetting {
  my $self = shift;
  my $rule = shift;

  if (@_) {
    my $switch = shift;
    for ($switch) {
      if ($switch eq 'on') {
        $self->{_const}{$rule} = 1;
        last;
      }
      if ($switch eq 'off') {
        $self->{_const}{$rule} = 0;
        last;
      }
      croak 'Unknown setting';
    }
  }
  return $self->{_const}{$rule}
}

sub play {
  my ($self, $colour, $ab) = @_;
  croak 'Illegal move format' unless checkmove($self, $ab);
  if (($colour eq 'B') or ($colour eq 'W')) {
    $self->{_errors} = [];
    $self->{_node}{++$self->{_nodecount}} = makenode($self, $colour, $ab);
    move($self, $colour, $ab);
  } else {
    croak 'Colour not recognised';
  }
  return errorcode($self);
}

sub setup {
  my ($self, $type, $ablist) = @_;
  for ($type) {
    if (',AB,AW,AE,' =~ /,($_),/) {
      $self->{_errors} = [];
      $self->{_node}{++$self->{_nodecount}} = makenode($self, 'None');
      for (split (',', $ablist)){ changecell($self, $1, $_) }
      last;
    }
    croak 'Setup type not recognised';
  }
  return errorcode($self);
}

sub handicap {
  my ($self, $number) = @_;
  if ($number =~ /[2-9]/o){
    if ($self->{_const}{hfree}){
      $self->{_const}{handicap} = $number;
    } else {
      if ($self->{_const}{size} == 18){
        my @hpoints  = ('dp','pd','pp','dd','jj','dj','pj','jd','jp');
        splice @hpoints, 4, 1 if $number % 2 == 0;
        splice @hpoints, $number;
        setup($self, 'AB', join ',', @hpoints);
      }
    }
  } else {
    croak 'Handicap not allowed';
  }
  return errorcode($self);
}

# return true if a co-ordinate pair is a legal move

sub islegal {
  my ($self, $colour, $point) = @_;
  my $res = play($self, $colour, $point);
  myprint ($self, $colour, $point, 'has legality:', $res) if $self->{_debug};
  restore($self, -1);
  return $res?0:1
}

# return a list of the co-ordinates of all legal moves

sub legal {
  my ($self, $colour) = @_;
  my @legallist;

  _iterboard {
    my ($x, $y) = @_;
    if ($self->{_cellfarm}{$x.','.$y} eq '.') {
      my $point = insertpoints($self, $x, $y);
      push @legallist, $point unless play($self, $colour, $point);
      restore($self, -1);
    }
  } $self->{_const}{size};

  return @legallist;
}

# return a list of the co-ordinates of all illegal moves

sub illegal {
  my ($self, $colour) = @_;
  my @illegallist;

  _iterboard {
    my ($x, $y) = @_;
    if ($self->{_cellfarm}{$x.','.$y} eq '.') {
      my $point = insertpoints($self, $x, $y);
      push @illegallist, $point if play($self, $colour, $point);
      restore($self, -1);
    }
  } $self->{_const}{size};

  return @illegallist;
}

# return true if $colour (ie 'B' or 'W') has a legal move, otherwise return false

sub haslegal {
  my ($self, $colour) = @_;
  my $exit = 0;
  my $size = $self->{_const}{size};
  for my $y (0..$size){
    for my $x (0..$size){
      if ($self->{_cellfarm}{$x.','.$y} eq '.') {
        $exit = 1 unless play($self, $colour, insertpoints($self, $x, $y));
        restore($self, -1);
        return 1 if $exit;
      }
    }
  }
  return 0;
}

# return a ':' seperated list of the co-ordinates of any captured stones

sub captures {
  my ($self, $id) = @_;
  $id ||= $self->{_nodecount};
  my $s = '';
  my $capsref = $self->{_node}{$id}->captures;
  if ($capsref) {
    my @delstones = @{$capsref};
    my $seperator = ':';
    for my $i (0..$#delstones) {
      $seperator = '' if $i == $#delstones;
      $s .= insertpoints($self, ($delstones[$i][0]), ($delstones[$i][1])).$seperator;
    }
  }
  return $s
}

# restore the game to that at move $howmany
# if $howmany is negative, go back that number of moves.

sub restore{
  my ($self, $howmany) = @_;
  croak 'Cannot restore to ', $howmany if (abs($howmany) > $self->{_nodecount});
  $howmany += $self->{_nodecount} if ($howmany < 0);
  boardrestore($self, $howmany);
  deletenodes($self, $howmany);
  $self->{_nodecount} = $howmany;
  my $node = $self->{_node}{$howmany};
  $self->{_movecount} = $node->movecount;
  $self->{_colour}    = $node->colour;
  $self->{_passcount} = $node->passcount;
  return
}

# return the board as a string

sub showboard{
  my $self = shift;
  my $h;
  my $size = $self->{_const}{size};
  _iterboard {
    my ($x, $y) = @_;
    $h .= $self->{_cellfarm}{$x.','.$y};
    $h .= "\n" if $x == $size;
  } $size;
  $h .= "\n";
  return $h;
}

# return a section of the board as a string

sub getboardsection{
  my ($self, $ox, $oy, $size) = @_;
  my $h;
  _iterboard {
    my ($x, $y) = @_;
    my $xnew = $x + $ox;
    my $ynew = $y + $oy;
    $h .= $self->{_cellfarm}{$xnew.','.$ynew} || '-';
  } $size;
  return $h;
}

# get contents of a point

sub point{
  my ($self, $ab, $y) = @_;
  ($ab, $y) = extractpoints($self, $ab) unless defined($y);
  return $self->{_cellfarm}{$ab.','.$y};
}

# get contents of a point at a particular move

sub nodepoint{
  my ($self, $id, $x, $y) = @_;
  my $positionref = $self->{_node}{$id}->board;
  return substr($$positionref, ($y * ($self->{_const}{size} + 1)) + $x, 1)
}

# get the co-ordinates of move number '$counter'

sub getmove {
  my ($self, $counter) = @_;
  my $node = $self->{_node}{$counter};
  return $node->colour, $node->point if defined $node;
}

#restore the board position to that of move number $id

sub boardrestore{
  my ($self, $id) = @_;
  myprint ($self, 'Restoring to', $id) if $self->{_debug};
  my $positionref = $self->{_node}{$id}->board;
  my $size = $self->{_const}{size};
  _iterboard {
    my ($x, $y) = @_;
    $self->{_cellfarm}{$x.','.$y} = substr($$positionref, ($y*($size+1))+ $x, 1);
  } $size;
}

sub deletenodes {
  my ($self, $upperB) = @_;
  for (keys %{$self->{_node}}) {
    if ($_ > $upperB) {
      my $board = $self->{_node}{$_}->board;
      delete $self->{_boardstr}{$$board} if defined $board;
      delete $self->{_node}{$_};
    }
  }
}

#save the board position as a reference to a string

sub store{
  my $self = shift;
  my $h = '';
  _iterboard {
    my ($x, $y) = @_;
    die 'Undefined Value'."$!\n" unless defined $self->{_cellfarm}{$x.','.$y};
    $h .= $self->{_cellfarm}{$x.','.$y};
  } $self->{_const}{size};
  return \$h;
}

# Change the value of a cell

sub put_cell{
  my ($self, $where, $what) = @_;
  if ($what ne '.' and $self->{_cellfarm}{$where} ne '.'){
    return 1
  } else {
    $self->{_cellfarm}{$where} = $what;
    return 0
  }
}

sub delete_group{
  my ($self, @mygroup) = @_;
  for (0..$#mygroup) {
    put_cell($self, $mygroup[$_][0].','.$mygroup[$_][1], '.');
  }
}

# return a list of the points solidly connected to x,y

sub block{
  my ($self, $x, $y, $c, $group) = @_;
  unless (offboard($self->{_const}{size}, $x, $y)) {
    my $key = "$x,$y";
    if ($self->{_cellfarm}{$key} eq $c) {
      $group->{$key} = undef; # create a hash key
      my @directions = ([1,0],[0,1],[-1,0],[0,-1]);

      for (0..3) {
        my $xx = $directions[$_][0] + $x;
        my $yy = $directions[$_][1] + $y;
        unless (exists($group->{"$xx,$yy"})) {
          $group = block($self, $xx, $yy, $c, $group);
        }
      }

    }
  }
  return $group;
}

sub libertycheck{
  my ($self, $x, $y, $c, $haslibs, $group) = @_;
  unless ($haslibs or offboard($self->{_const}{size}, $x, $y)) {
    my $key = "$x,$y";
    my $cellcontents = $self->{_cellfarm}{$key};
    if ($cellcontents eq $c) {
      $group->{$key} = undef;
      my @directions = ([1,0],[0,1],[-1,0],[0,-1]);

      for (0..3) {
        my $xx = $directions[$_][0] + $x;
        my $yy = $directions[$_][1] + $y;
        unless (exists($group->{"$xx,$yy"})) {
          ($haslibs, $group) = libertycheck($self, $xx, $yy, $c, $haslibs, $group);
        }
      }

    } else {
      $haslibs = $cellcontents eq '.';
    }
  }
  return $haslibs, $group;
}

sub checkforcaptures{
  my ($self, $x, $y, $colour, $type) = @_;
  my $capturedSomething = 0;
  my @directions = ($type eq 'self') ? ([0,0]) : ([1,0],[0,1],[-1,0],[0,-1]);
  my @deletedstones;

  for (0..$#directions) {
    my $xdir = $directions[$_][0]+$x;
    my $ydir = $directions[$_][1]+$y;
    my ($haslibs, $points) = libertycheck($self, $xdir, $ydir, $colour, 0, {});
    if (keys(%{$points}) and not $haslibs) {
      my $pointsref = getpoints($points);
      delete_group($self, @{$pointsref});
      push @deletedstones, @{$pointsref};
      $capturedSomething = 1;
    }
  }

  return $capturedSomething, \@deletedstones
}

# main move handler and error detector

sub processmove{
  my ($self, $colour, $ab) = @_;
  my $id = $self->{_nodecount};
  my $c = ($colour eq 'W')?'o':'x';
  my $noderef = \$self->{_node}{$id};
  my $move = $self->{_movecount};
  if (defined $self->{_coderef}) {
    my $rank = $colour.'R';
    myprint ($self, 'learning from move', $id)  if $self->{_debug};
    $self->{_coderef}->learn($colour, $ab, $self, $move, $self->{_sgf}->$rank);
  }
  if ($colour eq $self->{_colour} and $self->{_const}{alternation}){
    unless ($id <= $self->{_const}{handicap} and $self->{_const}{hfree}) {
      adderror($self, 7, $move);
      return if $self->{_const}{exitonerror}
    }
  }
  $self->{_colour} = $colour;
  my $size = $self->{_const}{size};
  if (ispass($self, $ab)) {
    $$noderef->passcount(++$self->{_passcount});
    $$noderef->board(store($self));
  } else {
    if ($self->{_passcount} >= $self->{_const}{passes} and $self->{_const}{passcount}) {
      adderror($self, 8, $move);
      return if $self->{_const}{exitonerror};
    }
    $self->{_passcount} = 0;
    $$noderef->passcount(0);
    my ($x, $y) = extractpoints($self, $ab);
    if (offboard($size, $x, $y)) {
      adderror($self, 1, $move);
      return if $self->{_const}{exitonerror};
    } else {
      if (put_cell($self, "$x,$y", $c)) {
        adderror($self, 2, $move);
        return if $self->{_const}{exitonerror};
      }
      my ($captured, $delstonesref, $error) = checkbothcaptures($self, $x, $y, $c, 1);
      my $ctype = '_prisoners'.$colour;
      $self->{$ctype} += @$delstonesref;
      if ($error) {
        adderror($self, 5, $move);
        return if $self->{_const}{exitonerror};
      }
      $$noderef->captures($delstonesref) if $captured;
      my $board = store($self);
      if (exists $self->{_boardstr}{$$board}) {
        if ($self->{_const}{ssk}) {
            adderror($self, 6, $move);
            return if $self->{_const}{exitonerror};
        } else {
          adderror($self, 6, $move);
          return if $self->{_const}{exitonerror};
        }
      } else {
        $self->{_boardstr}{$$board} = $colour;
      }
      $$noderef->board($board); # store the board in a Node as a string
      myprint ($self, 'Node id', $id)  if $self->{_debug};      
      myprint ($self, showboard($self)) if $self->{_debug};
    }
  }
  return 1
}

# change a value in cellfarm
# used when AB, AW, and AE tags found

sub changecell{
  my ($self, $colour, $point) = @_;
  my $c;
  SWITCH:for ($colour) {
    if ($_ eq 'AW') {$c = 'o'; last}
    if ($_ eq 'AB') {$c = 'x'; last}
    $c = '.';
  }
  my $id = $self->{_nodecount};
  my ($x, $y) = extractpoints($self, $point);
  my $size = $self->{_const}{size};
  if (offboard($size, $x, $y)) {
    adderror($self, 9, $id);
  } else {
    adderror($self, 4, $id) if (put_cell($self, "$x,$y", $c));
    unless ($c eq '.'){
      my ($capturedSomething, undef) = checkbothcaptures($self, $x, $y, $c, 0);
      if ($capturedSomething) {
        adderror($self, 5, $id);
        return if $self->{_const}{exitonerror};
      }
    }
    $self->{_node}{$id}->board(store($self));
  }
}

sub checkbothcaptures {
  my ($self, $x, $y, $c, $movetype) = @_;
  my $myerror = 0;
  my $reversec = ($c eq 'o')?'x':'o'; # reverse colours
  my ($capturedsomething, $delstonesref) = checkforcaptures($self, $x, $y, $reversec, 'opponents');
  unless ($capturedsomething){
    ($capturedsomething, $delstonesref) = checkforcaptures($self, $x, $y, $c, 'self');
    $myerror = 1 if ($capturedsomething and not $self->{_const}{selfcapture});
  }
  return $capturedsomething, $delstonesref, $myerror;
}

sub move {
  my $self = shift;
  $self->{_movecount}++;
  return processmove($self, @_);
}

sub processtags {
  my ($self, $sgfnode) = @_;
  $self->{_node}{++$self->{_nodecount}} = makenode($self, $sgfnode->colour, $sgfnode->move);

  for (split (',',$sgfnode->tags)){
    if (($_ eq 'B') or ($_ eq 'W')) {
      return unless move($self, $sgfnode->colour, $sgfnode->move);
      next;
    }
    if (',AB,AW,AE,' =~ /,($_),/) {
      my $tag = $1;
      for (split (',', $sgfnode->$tag)) {
        if ( $_ =~ /(..):(..)/) {
          my $arrayref = generaterectangle($self, $1, $2);
          for (@$arrayref) {changecell($self, $tag, $_)};
        } else {
          changecell($self, $tag, $_);
        }
      }
      next;
    }
  }

  return 1
}

sub generaterectangle {
  my ($self, $topleft, $bottomright) = @_;
  my @pointlist;
  my ($tx, $ty) = extractpoints($self, $topleft);
  my ($bx, $by) = extractpoints($self, $bottomright);
  for my $x ($tx..$bx) {
    for my $y ($ty..$by) {
      push @pointlist, insertpoints($self, $x, $y);
    }
  }
  return \@pointlist;
}

# list all the stones of a particular colour

sub liststones {
  my ($self, $colour) = @_;
  my $stone = ($colour eq 'B') ? 'x' : 'o';
  my %hash;
  _iterboard {
    my ($x, $y) = @_;
    if ($self->{_cellfarm}{$x.','.$y} eq $stone) {
      $hash{$x.','.$y} = undef;
    }
  } $self->{_const}{size};
  return \%hash
}

# list all the live stones of a particular colour
# (as the set of all blocks adjacent to their opponent's illegal moves)

sub listalive {
  my ($self, $colour) = @_;

  # turn off alternation and passcount errors temporarily
  $self->{_const}{passcount} = 0;
  $self->{_const}{alternation} = 0;
  # first get the list of illegal moves for the other player
  my @illegallist = illegal($self, swapcolour($self, $colour));
  my $points = {};
  my $stone = ($colour eq 'B') ? 'x' : 'o';

  # now get the blocks attached to those illegal points
  for (@illegallist) {
    my ($x, $y) = extractpoints($self, $_);
    my @directions = ([1,0],[0,1],[-1,0],[0,-1]);
    for (0..3) {
      my $xdir = $directions[$_][0]+$x;
      my $ydir = $directions[$_][1]+$y;
      $points = block($self, $xdir, $ydir, $stone, $points);
    }
  }
  $self->{_const}{passcount} = 1;
  $self->{_const}{alternation} = 1;
  return $points
}

# list the dead stones of a particular colour
# (as the difference between their alive list
# and their total list)

sub listdead {
  my ($self, $colour) = @_;
  my $allref = liststones($self, $colour);
  my $aliveref = listalive($self, $colour);
  my @dead = ();
  for (keys %$allref) {
    push @dead, $_ unless exists $aliveref->{$_};
  }
  @dead = map {
    /(.*),(.*)/;
    insertpoints($self, $1, $2) 
  } @dead;
  return \@dead
}

# list all the dead stones on the board
# (as the union of the Black and White
# dead stone list)

sub listalldead {
  my ($self) = @_;
  my $bdead = listdead($self, 'B');
  my $wdead = listdead($self, 'W');
  my @dead = (@$bdead, @$wdead);
  return \@dead
}

sub ismove {
  testnode(shift, ',B,W,') ? return 1 : return 0
}

sub issetup {
  testnode(shift, ',AB,AW,AE,') ? return 1 : return 0
}

sub testnode{
  my ($sgfnode, $type) = @_;
  if ($sgfnode->tags){
    for (split (',',$sgfnode->tags)){
      if ($type =~ /,$_,/) {
        return 1;
      }
    }
  }
  return 0
}

sub restart {
  my $self = shift;
  $self->{_node}        = {};
  $self->{_boardstr}    = {};
  $self->{_nodecount}   = 0;
  $self->{_movecount}   = 0;
  $self->{_passcount}   = 0;
  $self->{_colour}      = 'None';
  $self->{_cellfarm}    = {};
  $self->{_errors}      = [];
  $self->{_prisonersB}  = 0;
  $self->{_prisonersW}  = 0;
  $self->{_sgf}         = {};
  $self->{_node}{0}     = makenode($self, $self->{_colour});
}

sub initrules {
  my $self = shift;
  my $rules = uc(shift);

  $rules = ($rules) ? $rules : 'Japanese';
  $self->{_const}{selfcapture} = 1 if ($rules =~ /^NZ|^NEW ZEALAND|^ING|^GOE/);
  $self->{_const}{ssk}         = 1 if ($rules =~ /^AGA/);
  $self->{_const}{passes}      = 4 if ($rules =~ /^ING|^GOE/);
  $self->{_const}{hfree}       = 1 if ($rules =~ /^NZ|^NEW ZEALAND|^ING|^GOE|^CHINESE/);
}

sub makenode {
  my ($self, $colour, $point) = @_;
  return new Games::Go::Referee::Node($self->{_movecount}+1, $self->{_passcount}, $colour, $point);
}

sub errors {
  my ($self) = @_;
  my $errorhash = {
    1 => 'Not a board co-ordinate at move ',
    2 => 'Point already occupied at move ',
    3 => 'Illegal setup at node ',
    4 => 'Point already occupied at node ',
    5 => 'Illegal self-capture at move ',
    6 => 'Board repetition at move ',
    7 => 'Alternation error at move ',
    8 => 'Play over at move ',
    9 => 'Not a board co-ordinate at node ',
   10 => 'Board repetition at node ',
  };
  my @array = @{$self->{_errors}};
  my @return;
  for (0..$#array){
    my $ecode = $self->{_errors}[$_][0];
    push @return, join '', $errorhash->{$ecode}, $self->{_errors}[$_][1], "\n";
  }
  return @return
}

sub errorcode {
  my $self = shift;
  my @array = @{$self->{_errors}};
  my $ecode = undef;
  for (0..$#array){
    $ecode = $self->{_errors}[$_][0];
    last;
  }
  return defined($ecode)? $ecode: 0;
}

sub adderror {
  my ($self, $ecode, $place) = @_;
  push @{$self->{_errors}}, [$ecode, $place];
}

# empty board

sub clearboard{
  my $self = shift;
  $self->{_cellfarm} = {};
  _iterboard {
    my ($x, $y) = @_;
    $self->{_cellfarm}{$x.','.$y} = '.';
  } $self->{_const}{size};
  $self->{_node}{0}->board(store($self));
  return
}

sub checkmove { # check move is OK according to format
  my ($self, $string) = @_;
  myprint ($self, 'Checking move', $string) if $self->{_debug};
  return 1 if ispass($self, $string);
  if ($self->{_const}{pointformat} eq 'sgf') {
    return issgf($string)
  } else {
    return isgmp($string)
  }
}

sub ispass {
  my ($self, $move) = @_;
  if ($self->{_const}{pointformat} eq 'sgf') {
    return 1 if not defined $move;
    if (($move eq '') or ($move eq 'tt' and $self->{_const}{size} < 19)) {
      return 1
    }
  } else {
    if ('pass' eq lc $move) {
      return 1
    }
  }
}

sub issgf { # assuming not a pass
  shift =~ /^[a-z]{2}$/i;
}

sub isgmp { # assuming not a pass
  shift =~ /^[a-z]([1-9]\d?)$/i and 1 <= $1 and $1 <= 25;
}

sub getpoints { # extract points from a hash key eg '10,1'
  my $pointsref = shift;
  my @points;
  for (keys(%{$pointsref})) {
    /(.*),(.*)/;
    push @points, [$1,$2];
  }
  return \@points
}

sub extractpoints { # convert points from an sgf or gmp string to a pair of numbers
  my ($self, $string) = @_;
  my $pass = ispass($self, $string);
  return '','' if $pass;
  if ($self->{_const}{pointformat} eq 'sgf') {
    return fromsgf($string, $pass)
  } else {
    return fromgtp($self, $string)
  }
}

sub insertpoints { # convert a pair of numbers to an sgf or gmp string
  my ($self, $x, $y) = @_;
  if ($self->{_const}{pointformat} eq 'sgf') {
    return tosgf($x, $y)
  } else {
    return togtp($self, $x, $y)
  }
}

sub fromsgf {
  my ($string) = @_;
  my $x = index(aZ(), substr($string,0,1));
  my $y = index(aZ(), substr($string,1,1));
  return $x,$y;
}

sub fromgtp {
  my ($self, $string) = @_;
  my $a = index aZnoi(), lc substr $string, 0, 1;
  my $y = substr $string, 1;
  return $a, $self->{_const}{size} - $y + 1;
}

sub togtp {
  my ($self, $x, $y) = @_;
  return 'pass' if $x eq '' and $y eq '';
  join '', uc(substr(aZnoi(), $x, 1)), $self->{_const}{size} - $y + 1
}

sub tosgf {
  return '' if $_[0] eq '' and $_[1] eq '';
  join '', substr(aZ(), $_[0], 1), substr(aZ(), $_[1], 1)
}

sub offboard {
  0 > $_[1] or $_[1] > $_[0] or 0 > $_[2] or $_[2] > $_[0];
}

sub swapcolour {
  return ($_[1] eq 'B') ? 'W' : 'B'
}

sub aZ { 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ' }

sub aZnoi {
  my $str = aZ();
  $str =~ s/i//;
  return $str
}

sub myprint {
  my $self = shift;
  my @messages = @_;
  if (exists $messages[0]) {
	  open(LOG, ">>", $self->{_logfile}) or die 'Can\'t open'.$self->{_logfile}."\n";
		  print LOG (join ' ', @messages, "\n");
	  close(LOG);
  }
}

1;

=head1 NAME

Games::Go::Referee - Check the moves of a game of Go for rule violations.

=head1 SYNOPSIS

Analyse a file:

  use Games::Go::Referee;
  my $referee = new Games::Go::Referee();
  $referee->sgffile('file.sgf');
  print $referee->errors;

or

Analyse move by move:

  use Games::Go::Referee;
  my $referee = new Games::Go::Referee();
  $referee->size(19);
  $referee->ruleset('AGA');
  $referee->play('B','ab');
  $referee->restore(-1) if $referee->errors;


=head1 DESCRIPTION

Check a game of Go for rules violations, against a specific rule set.

=head2 General use

Games::Go::Referee can be used in two ways; to analyse an sgf file, or to check plays 
move by move.

If checking a file, the file will be completely read, and any errors found can be displayed
later using the errors method. Any illegal plays found are 'allowed' (ie play is assumed to
continue as if they were legal). The rule set to be used will be read from the RU sgf
property in the file, alternatively various rules can be set manually.

If checking move by move, it may be necessary to specify the size and rule set to be
used before starting.

There are basically two rules that can be set: self-capture allowed/disallowed and
situational superko (ssk) on/off. If ssk is off, positional superko is assumed.

The following errors are reported:

    Not a board co-ordinate
    Point already occupied
    Illegal setup           (if the setup caused a capture to occur)
    Illegal self-capture
    Board repetition
    Alternation error       (two Black moves in a row for example)
    Play over               (play continues when the game is over)

=head1 METHODS

=head2 ruleset

The ruleset method sets the rule set to be used. If a file is being checked,
the value of the sgf property RU will be used. If that is not found, Japanese rules
are assumed.

    $referee->ruleset('AGA');

=head2 size

The size method sets the size of the board to be used. If a file is being checked,
the value of the sgf property SZ will be used. If that is not found, the board is 
assumed to be 19 x 19.

    $referee->size(19);


=head2 ssk

The ssk method sets or unsets whether the situational superko rule is being used.
ssk can be turned on only by using this method, or by specifying 'AGA' via the
ruleset method.

    $referee->ssk('on');
    $referee->ssk('off');

=head2 selfcapture

The selfcapture method sets or unsets whether self-capture (aka suicide) is
allowed or not. selfcapture can be turned on only by using this method, or by
specifying New Zealand or Ing via the rulset method.

    $referee->selfcapture('on');
    $referee->selfcapture('off');

=head2 passes

The passes method sets the number of consecutive passes required to end the game.
The default value is 2. If the Ing ruleset is being used, this value becomes 4.

    $referee->passes(3);

=head2 setup

For move by move analysis, the following two methods are availale.

The setup method is used to place preliminary stones on the board.

Setup types (the first argument) are 'AB', 'AW' and 'AE'. Each use of setup can
only use one of these types.

Setup points (the second argument) are a list of sgf style board co-ordinates.

    $referee->setup('AW','ii,jj,gh');
    $referee->setup('AB','aa,bb');

If the setup creates group with no liberties, an error is reported. The method
returns true if an error was found, otherwise false.

=head2 handicap

The handicap method takes as its argument a number from 2 to 9

    $referee->handicap(3);

This method can be used as a convenient way of placing handicap stones, provided
the board size is 19, and the rules indicate that handicap placement is fixed
(ie neither Ing, AGA nor Chinese).

If handicap placement is fixed, but the board size is not 19, use the setup method.

If handicap placement is not fixed, the handicap method should still be used as then
the appropriate number of black consecutive plays will be allowed.

=head2 play

Play a move.

Play types (the first argument) are 'B' or 'W'. Each use of play can
only use one of these types.

The point played (the second argument) is a single sgf style co-ordinate (or '' for a pass.)

    $referee->play('B','pd');

The method returns true if an error was found, otherwise false.

=head2 haslegal

$referee->haslegal($colour); # $colour must be 'B' or 'W'

Returns true if $colour (ie 'B' or 'W') has a legal move, otherwise returns false.
Usage example -

    while ($referee->haslegal($colour)){
      my $point = getmove();
      $referee->play($colour, $point);
      if ($referee->errors) {
        $referee->restore(-1);
      } else {
        $colour = ($colour eq 'B') ? 'W' : 'B';
      }
    }

=head2 legal

my @points = $referee->legal($colour); # $colour must be 'B' or 'W'

Returns an array of a player's legal move co-ordinates.

Usage example -

    my @legalpoints = $referee->legal($colour);
    while ($#legalpoints >= 0){
      # play a random legal move
      $referee->play($colour, @points[int(rand($#legalpoints))]);
      $colour = ($colour eq 'B') ? 'W' : 'B';
      @legalpoints = $referee->legal($colour);
    }

=head2 errors

    print $referee->errors;

Lists any errors occurring either in the file analysed, or as a result of the previous
move/setup.

=head2 sgffile

  $referee->sgffile('file.sgf');

or

  my $sgf = new Games::Go::SGF('file.sgf');
  $referee->sgffile($sgf);

Specify an sgf file to be analysed.

=head1 TODO

Score?

=head1 BUGS/CAVEATS

The move number of a reported error is one too large if it occurs in a variation.
Putting setup stones within a file (not just the first node) can cause problems. For example,
after some stones have been added like this, who is next to play? This needs to be known for
situational superko. Currently no look-ahead is done to see who, in fact, played next.

Natural Superko - if I understood the difference between this and SSK, I might put it in.

Ko-pass moves, game resumption ... my head hurts.

=head1 AUTHOR (version 0.01)

DG

=cut
