package IO::Pager::Perl;
our $VERSION = '1.01';

use strict;
use warnings;
use Term::Cap;

#Signal handling, only needs to be set once, and does not have access to object
my($SP, $RT) = $|;
local $SIG{INT} = local $SIG{QUIT} = \&done; 

#Stubs for ReadKey functions that we fill in with code refs if it's not loaded
sub ReadMode;
sub ReadKey;

sub new {
  my $class = shift;
  my %param = @_;
  local $ENV{TERM} = $ENV{TERM};

  my %dims = get_size(cols =>$param{cols} ||80,
		      rows =>$param{rows} ||25,
		      speed=>$param{speed}||38400);
  $dims{rows}--;

  #screen is vt100 compatible but does not list sf?!
  #No matter, it's only used for workaround mode.
  if( $ENV{TERM} eq 'screen' && $ENV{TERMCAP} !~ /sf/ ){
    $ENV{TERM} = 'vt100';
  }

#cm=>cup, ce=>el, cl=>clear, sf=>ind, sr=>ri
#md=>bold, me=>sgr0, mr=>rev, us=>smul
  #Speed is mostly useless except Term::Cap expects it?
  my $t = Term::Cap->Tgetent({ OSPEED => $param{speed} });
  eval{ $t->Trequire(qw/cm ce cl sf sr/) };
  my $dumb = $@ ? 1 : 0;

  my %primitives = (
		    # if the entries don't exist, nothing bad will happen
		    BLD   => $t->Tputs('md'), # Bold
		    ULN   => $t->Tputs('us'), # Underscore
		    REV   => $t->Tputs('mr'), # Reverse
		    NOR   => $t->Tputs('me'), # Normal
		   );


  my $text = delete($param{text}) if defined($param{text});

  my $me = bless {
		  # default values
		  _cursor => 0,		_end => 0,	   _left => 0,
		  _term  => $t,		_dumb => $dumb,    _txtN => 0,
		  _search => '',	_statCols => 0,    _lineNo=>[0],
		  lineNo => 0,		pause => 0,	   #pause=>"\cL" #more
		  raw => 0,		statusCol => 0,	   squeeze=>0,
		  visualBeep=>0,	wrap=>0,
		  %dims,

		  # if the termcap entries don't exist, nothing bad will happen
		  %primitives,
		  #UI Composites
		  MENU    => $primitives{BLD}.$primitives{REV},	# popup menus
		  HILT    => $primitives{BLD}.$primitives{ULN},	# search entry
		  SRCH    => $primitives{BLD}.$primitives{ULN},	# search entry

		  # user supplied values override
		  %param,
		 }, $class;

  $me->add_text($text) if defined $text;

  $me->{_I18N}={
		status=>		'',
		404=>		'Not Found',
		top=>		'Top',
		bottom=>	'Bottom',
		prompt=>	"<h>=help \000<space>=down <b>=back <q>=quit",
		continue=>	'press any key to continue',
		help=>		<<'EOH'
 q         quit             \000 h       help
 r C-l     refresh          \000                         
 /         search           \000 ?       search backwards
 n P       next match       \000 p N     previous match
 space C-v page down        \000 b M-v   page up
 enter     line down        \000 y       line up
 d         half page down   \000 u       half page up
 g <       goto top         \000 G >     goto bottom
   <-      scroll left      \000  ->     scroll right
 #         Line numbering   \000 \d+\n   jump to line \d+
EOH
	       };
  $me->{_fnc} = {
		 'q' => \&done,		'h' => \&help,
		 '/' => \&search,	'?' => \&hcraes,
		 'n' => \&next_match,	'P' => \&prev_match,
		 'p' => \&prev_match,	'N' => \&prev_match,
		 'r' => \&refresh,	"\cL" => \&refresh,
		 ' ' => \&downpage,	"\cC" => \&downpage,
		 "\n"=> \&downline,	"\e[B" => \&downline,
		 'd' => \&downhalf,	'u' => \&uphalf,
		 'b' => \&uppage,	"\ev" => \&uppage,
		 'y' => \&upline,	"\e[A" => \&upline,
		 '<' => \&to_top,
		 '>' => \&to_bott,	'$' => \&to_bott,
		 "\e[D" => \&move_left,	"\e[C" => \&move_right,	
		 '#' => \&toggle_numbering,
		 '/(\d+)/'=>1 #jump to line
		};

    $me->{_end} = $me->{rows} - 1;
  
  $SIG{WINCH} = sub{ $me->resize() };

  $me;
}

sub resize {
  my $me = shift;
  my %dims = get_size();
  $dims{rows}--;
  $me->{$_} = $dims{$_} foreach keys %dims;

  $me->{_end} = $me->{rows} - 1;

  $me->refresh();
  $me->prompt();

  $me->{WINCH}->() if ref($me->{WINCH}) eq 'CODE';
}

sub get_size {
  my %dims = @_;

  if( defined($Term::ReadKey::VERSION) ){
    Term::ReadKey->import();
    local $SIG{__WARN__} = sub{};
    my @Tsize = Term::ReadKey::GetTerminalSize(*STDOUT);
    @dims{'rows','cols'} = @Tsize[1,0];
    $dims{speed} ||= (Term::ReadKey::GetSpeed())[1];
  }
  else{
    *ReadMode = sub{
      if( $_[0] == 3 ){
	system('stty -icanon -echo min 1'); }
      elsif( $_[0] == 0 ){
	system('stty icanon echo'); }
    };
    *ReadKey = sub{ getc() };

    #Can we get better defaults?
    if( `stty` =~ /speed/ ){
      @dims{'rows','cols'} = ($1-1,$2-1) if `stty size` =~ /^(\d+)\s+(\d+)$/;
      $dims{speed} = $1 if `stty speed` =~ /^(\d+)$/;
    }
    else{
      $dims{rows} = `tput lines`  || $dims{rows};
      $dims{cols} = `tput cols`   || $dims{cols};
    }
  }
  return %dims;
}


sub add_text {
  return unless defined($_[1]);
  my $me = shift;

  #Stringify
  local $_ = join('', @_);

  #Terminated?
  my $LF = do{ chomp(local $_=$_) };

  #Squeeze #XXX handle with logical lines display?
  s/\n{2,}/\n\n/g if $me->{squeeze};

  #Split on new lines, preserving internal blanks
  my @F = split(/\n/, $_, -1);

  if( $me->{wrap} ){
    #Two expressions to avoid lame single-use warning
    local $Text::Wrap::columns;
    $Text::Wrap::columns = $me->{cols} -
      ( $me->{_statCols} = ($me->{lineNo} ? 9 : $me->{statusCol} ? 1 : 0) );

    my $lines = scalar(@F);
    my $extraSum=0;
    for( my $i=0; $i<$lines; $i++ ){
      $me->{_lineNo}->[$i+$me->{_txtN}] = $me->{_txtN}+$i+1-$extraSum;
      if( defined($F[$i]) && length($F[$i]) > $me->{cols} ){
	my @G = split/\n/, wrap('', '', $F[$i]);
	my $extras = scalar(@G);
	splice(@F, $i, 1, @G);

	#Repeat real line number for logical folded lines
	$me->{_lineNo}->[$i+$me->{_txtN}+$_] =
	  $me->{_txtN}+$i+1-$extraSum foreach 1..$extras-1;

	$i += $extras-1;
	$lines += $extras;
	$extraSum+=$extras-1;
      }
    }
  }
  #Remove the extra record from the trailing new line
  pop @F if $LF;

  #Handle partial lines in case sysread is used further up the stack
  push(@F, undef) unless $LF;
  if( $me->{_txtN} && !defined($me->{_text}->[-1]) ){
    pop @{$me->{_text}};
    $me->{_text}->[-1] .= shift @F;
  }

  #Store text, and refresh screen if content would fit in window
  my $shown = $me->{_txtN};
  push @{$me->{_text}}, @F;
  $me->{_txtN} = @{ $me->{_text} }; #-1;

  $me->refresh() if $shown <= $me->{rows};
}

sub more {
  my $me = shift;
  my %param = @_;
  $RT = $me->{RT} = $param{RT};

  if( $me->{wrap} ){
    eval "use Text::Wrap";
    $me->dialog("Text::Wrap unavailable, disabling wrap mode\n\n$@") if $@;
  }
  if( $@ or not $me->{wrap} ){
    sub wrap {@_}
  }
  
  ReadMode 3; #cbreak
  $| = 1;

  if( $me->{_dumb} ){
    $me->dumb_mode();
  }
  else{
    print $me->{NOR};

    while( 1 ){
      $me->prompt();					# status line

      my $exit;
      my $q = ReadKey($param{RT});
      # Catch arrow keys. NOTE: Escape would enter this too
      #...requiring an extra input if no ReadKey
      if( defined($q) and ord($q) == 27 ){
	$q.=ReadKey(0);
	$q.=ReadKey(0) if $q eq "\e[";
      }
      if( defined($q) and $q =~ /\d/ and $me->{_fnc}->{'/(\d+)/'} ){
	$me->{_I18N}{status} = $q;
	$me->prompt();
	while( defined($_ = ReadKey(0)) ){
	  last unless /\d/;
	  $q .= $_;
	  $me->{_I18N}{status} = $q;
	  $me->prompt();
	}
	#Commit on enter, anything else aborts
	if( $_ eq "\n" ){
	  $q<$me->{_txtN} ? $me->jump($q) : $me->to_bott();
	}
	$me->{_I18N}{status} = '';
	next;
      }

      if( defined $q ){
	my $f = $me->{_fnc}->{$q} || \&beep;
	# $me->{_I18N}{status} = $q;			#input debugging
	$exit = ref($f->($me));
      }

      return 1 if $param{RT} or $exit;
    }
    }
  $me->done();
}
*less = \&more; *page = \&more;
#Avid lame single-use warning
my $foo = \&less; $foo = \&page;


#ACCESSORS
sub I18N {
  my($me, $msg, $text) = @_;
  $me->{_I18N}{$msg} = $text if defined($text);
  $me->{_I18N}{$msg};
}

BEGIN{
  #Install generic accessors
  no strict 'refs';
  foreach my $method ( qw(eof lineNo pause raw statusCol visualBeep) ){
    *{$method} = sub{ $_[0]->{$method}=$_[1] if defined($_[1]);
		      $_[0]->{$method} }
  }
  foreach my $method ( qw(rows cols speed fold squeeze) ){
    *{$method} = sub{ $_[0]->{$method}}
  }
}

#HELPERS
sub add_func {
  my $me = shift;
  my %param = @_;
  while( my($k, $v) = each %param ){
    $me->{_fnc}{$k} = $v;
  }
}

sub beep {
  print "\a";
  print $_[0]->{_term}->Tputs('vb') if $_[0]->{visualBeep};
}

# display a prompt, etc
sub prompt {
  my $me = shift;
  $me->{_txtN} ||= 0;

  my $end= $me->{_cursor} + $me->{rows};

  my $pct = $me->{_txtN} > $end ? $end/($me->{_txtN}) : 1;
  my $pos = $me->{_cursor} ?
    ($pct==1 ? $me->{_I18N}{bottom} : 'L'.$me->{_cursor}) :
	       $me->{_I18N}{top};
  $pos .= 'C'.$me->{_left} if $me->{_left};
  my $p = sprintf "[tp] %d%% %s %s", 100*$pct, $pos, $me->{_I18N}{status};

  print $me->{_term}->Tgoto('cm', 0, $me->{rows});	# bottom left
  print $me->{_term}->Tputs('ce');			# clear line
  my $prompt = $me->{_I18N}{prompt};
  my $pN = $me->{cols} - 2 - length($p) - length($me->{_I18N}{prompt});
  $p .= ' ' x ($pN > 1 ? $pN : 1);
  $prompt = $pN>2 ? $prompt : do {$prompt =~ s/\000.+//; $prompt };
  print $me->{REV};					# reverse video
  print $p,"  ", $prompt;  				# status line
  print $me->{NOR};					# normal video
}

sub done {
  ReadMode 0;
  print "\n";
  $| = $SP || 0;
  #Did we exit via signal or prompt?
  $RT ? die : return \"foo";
}

# provide help to user
sub help {
  my $me = shift;
  my $help = $me->{_I18N}{help};
  my $cont = $me->{_I18N}{continue};

  if( $me->max_width( split/\n/, $help ) > $me->{cols} ){
    #Split help in half horizontally for narrow dispays
    my $help2 = $help;
    $help2 =~ s/\000.*//mg;
    $help  =~ s/.*\000//mg;
    my $padding = $me->max_width($cont) / 2;  
    $me->dialog( $help2 . "\n" . (' 'x$padding) . $cont );
  }
  else{
    $help =~ y/\000//d;
  }
  my $padding = $me->max_width($cont) / 2;  
  $me->dialog( $help . "\n" . (' 'x$padding) . $cont );
}

sub dialog {
  my($me, $msg, $timeout) = @_;
  $msg = defined($msg) ? $msg : '';
  $timeout = defined($timeout) ? $timeout : 0;
  $me->disp_menu( $me->box_text($msg) );
  $timeout ? sleep($timeout) : getc();
  $me->remove_menu();
}

sub max_width {
  my $me = shift;
  my $width = 0;
  foreach (@_){ $width = length($_) if length($_) > $width };
  return $width;
}

# put a box around some text
sub box_text {
  my $me  = shift;
  my @txt = split(/\n/, $_[0]);
  my $width = $me->max_width(@txt);

  my $b = '+' . '=' x ($width + 2) . '+';
  my $o = join('', map { "| $_" . (' 'x($width-length($_))) ." |\n" } @txt); 
  "$b\n$o$b\n";
}

# display a popup menu (or other text)
sub disp_menu {
  my $me = shift;
  my $menu = shift;

  $me->{_menuRows} = @{[split /\n/, $menu]};
  print $me->{_term}->Tgoto('cm',0,$me->{rows} - $me->{_menuRows});	# move
  print $me->{MENU};					# set color
  my $x = $me->{_term}->Tgoto('RI',0,4);		# 4 transparent spaces
  $menu =~ s/^\s*/$x/gm;
  print $menu;
  print $me->{NOR};					# normal color
}

# remove popup and repaint
sub remove_menu {
  my $me = shift;

#XXX now fails if at bottom of text

  my $s = $me->{rows} - $me->{_menuRows};

  #Allow wipe of incomplete/paused output.
  #XXX "Bug" in that we get an extra chunk of output after menu closing
  my $pause = $me->{pause};
  $me->{pause} = '';

  $me->I18N('status', $s."..".$me->rows()); $me->prompt();

  # Fractional restoration instead of full refresh
  foreach my $n ($s .. $me->{rows}){
    print $me->{_term}->Tgoto('cm', 0, $n);		# move
    print $me->{_term}->Tputs('ce');			# clear line
    $me->line($n);
  }

  #Reset pause
  $me->{pause} = $pause;
}

# refresh screen
sub refresh {
  my $me = shift;

  print $me->{_term}->Tputs('cl');			# home, clear
  for my $n (0 .. $me->{rows} -1){
    print $me->{_term}->Tgoto('cm', 0, $n);		# move
    print $me->{_term}->Tputs('ce');			# clear line
    $me->line($n+$me->{_cursor});			# XXX w/o cursor messy
 							# after menu & refresh
  }
}

sub line {
  my $me = shift;
  my $n  = shift;
  local $_ = $me->{_text}[$n]||'';

  #!! ORDER OF OPERATIONS ON OUTPUT PROCESSING AND DECORATION MATTERS

  #Breaks?
  my $pause =1 if length($me->{pause}) && defined && /$me->{pause}/;

  #Crop if no folding
  my $len = length();
  unless( $me->{wrap} ){
    $_ = ($len-$me->{_statCols}) < $me->{_left} ? '' : substr($_,
	       $me->{_statCols}  + $me->{_left},$me->{cols}-$me->{_statCols});
    if( $len - $me->{_left} > $me->{cols} ){
      substr($_, -1, 1, "\$");
    }
  }

  #Cook control characters
  unless( $me->{raw} ){
    #XXX Specially protect escape sequences, so we can wrap controls in REV?
    s/(?=[\000-\010\013-\037])/^/g;
    tr/\000-\010\013-\037/@A-HK-Z[\\]^_/;
  }

  #Search
  my $matched = (s/($me->{_search})/$me->{SRCH}$1$me->{NOR}/g) if
    $me->{_search} ne '';

  #Line numbering & search status
  my $info = $me->{statusCol} && !$me->{lineNo} ?
    ($matched ? '*' : ' ') :''; 
  $info = sprintf("% 8s", 
		  $me->{wrap} ? ($me->{_lineNo}->[$n]||-1) : 
				(defined($me->{_text}[$n]) ? $n+1 : '')
		 ) if $me->{lineNo};
  $_ = ($me->{statusCol} && $matched ? $me->{REV} : '').
    $info.
      ($me->{statusCol} && $matched ? $me->{NOR} : '').
	($me->{lineNo} ? ' ' : '').
	  $_;

  print;

  if( $pause ){
    $me->{_end} = $n;					#Advance past pause
    no warnings 'exiting'; last;
  }
}

sub down_lines {
  my $me = shift;
  my $n  = shift;
  my $t  = $me->{_term};

  for (1 .. $n){
    if( $me->{_end} >= $me->{_txtN}-1 ){
      exit if $me->{eof};
      &beep; last; }
    else{
      if( length($me->{pause}) && $me->{_end} < $me->{rows}-1 ){
	print $t->Tgoto('cm', 0, $me->{_end}+1 ); }	# move
      else{
	# why? because some terminals have bugs...
	print $t->Tgoto('cm', 0, $me->{rows} );		# move
	print $t->Tputs('sf');				# scroll
	print $t->Tgoto('cm', 0, $me->{rows} - 1);	# move
      }

      print $t->Tputs('ce');				# clear line
      $me->line( ++$me->{_end} );
      $me->{_cursor}++;
    }
  }
}
sub downhalf {  $_[0]->down_lines( $_[0]->{rows} / 2 ); }
sub downpage {  $_[0]->down_lines( $_[0]->{rows} ); }
sub downline {  $_[0]->down_lines( 1 ); }

sub up_lines {
  my $me = shift;
  my $n  = shift;

  for (1 .. $n){
    if( $me->{_cursor} <= 0 ){
      &beep; last;
    }else{
      print $me->{_term}->Tgoto('cm',0,0);	# move
      print $me->{_term}->Tputs('sr');		# scroll back
      $me->line( --$me->{_cursor} );
      $me->{_end}--;
    }
  }

  print $me->{_term}->Tgoto('cm',0,$me->{rows});		# goto bottom
}
sub uppage {  $_[0]->up_lines( $_[0]->{rows} ); }
sub upline {  $_[0]->up_lines( 1 ); }
sub uphalf {  $_[0]->up_lines( $_[0]->{rows} / 2 ); }

sub to_top {  $_[0]->jump(0); }

sub to_bott {
  my $me = shift;
  $me->jump( $me->{rows}>$me->{_txtN} ? 0 : $me->{_txtN}-$me->{rows} );
}

sub jump {
  my $me = shift;

  $me->{_cursor} = shift;
  $me->{_end}   = $me->{_cursor} + $me->{rows}; # - 1;
  $me->refresh();
}

sub move_right {
  my $me = shift;

  $me->{_left} += 8;
  $me->refresh();
}

sub move_left {
  my $me = shift;

  $me->{_left} -= 8;
  $me->{_left} = 0 if $me->{_left} < 0;
  $me->refresh();
}

sub hcraes{  $_[0]->search(1); }
sub search {
  my $me = shift;
  $me->{_hcraes} = shift || 0;

  # get pattern
  (my($prev), $me->{_search}) = ($me->{_search}, '');

  print $me->{_term}->Tgoto('cm', 0, $me->{rows});	# move bottom
  print $me->{_term}->Tputs('ce');			# clear line
  print $me->{HILT};					# set color
  print $me->{_hcraes} ? '?' : '/';

  while(1){
    my $l = ReadKey();
    last if $l eq "\n" || $l eq "\r";
    if( $l eq "\e" || !defined($l) ){
      $me->{_search} = '';
      last;
    }
    if( $l eq "\b" || $l eq "\177" ){ #Why not octothorpe? || $l eq '#' ){
      print "\b \b" if $me->{_search} ne '';
      substr($me->{_search}, -1, 1, '');
      next;
    }
    print $l;
    $me->{_search} .= $l;
  }
  print $me->{NOR};					# normal color
  print $me->{_term}->Tgoto('cm', 0, $me->{rows});	# move bottom
  print $me->{_term}->Tputs('ce');			# clear line
  return if $me->{_search} eq '';

  $me->{_search} = '(?i)'.$me->{_search} unless
    $me->{_search} ne lc($me->{_search});

  $me->{_search} = $prev if $me->{_search} eq '/' && $prev;

  for my $n ( $me->{_cursor} .. $me->{_txtN} -1){	#XXX why offset needed?
    next unless $me->{_text}[$n] =~ /$me->{_search}/i;
 
    $me->{_cursor} = $n;
    $me->{_cursor} = 0 if $me->{_txtN} < $me->{rows}; # - 1;
    $me->{_end}    = $me->{_cursor} + $me->{rows}; # - 1;

    #Special jump if match is on last screen
    if( $me->{_cursor} + $me->{rows} > $me->{_txtN} - 1 && $me->{_cursor} ){
      my $x = $me->{_cursor} + $me->{rows} - $me->{_txtN};
      $x = $me->{_cursor} if $x > $me->{_cursor};
      $me->{_cursor} -= $x;
      $me->{_end}   -= $x;
    }

    $me->refresh();
    return;
  }
  # not found
  &beep;
  $me->dialog($me->{_I18N}{404}, 1);

  return;
}

sub prev_match{  $_[0]->next_match('anti'); }
sub next_match{
  my $me = shift;
  return unless defined($me->{_txtN}) and defined($me->{_search});

  my $mode=shift;
  if( defined($mode) and $mode ='anti' ){
    $mode = not $me->{_hcraes};
  }
  else{
    $mode = $me->{_hcraes};
  }

  my $i = $mode ? ($me->{_cursor}||0)-1 : ($me->{_cursor})+1;
  my $matched=0;
  for( ;
       $mode ? $i>0 : $i< $me->{_txtN};
       $mode ? $i-- : $i++ ){
    $matched = $me->{_text}[$i] =~ /$me->{_search}/;
    last if $matched;
  }
  $matched ? $me->jump($i) : &beep;
}

sub toggle_numbering{
  my $me = shift;
  $me->{lineNo} = not $me->{lineNo};
  $me->refresh();
}

sub dumb_mode {
  my $me = shift;
  my $end = 0;

  while(1){
    for my $i (1 .. $me->{rows} ){
      last if $end >= $me->{_txtN};
      print $me->{_text}[$end++], "\n";
    }
 
    print "--more [dumb]-- <q> quit";
    my $a = getc();
    print "\b \b"x15;

    return if $a eq 'q';
    return if $end >= $me->{_txtN};
  }
}

1;
__END__
=pod

=head1 NAME

IO::Pager::Perl - Page text a screenful at a time, like more or less

=head1 SYNOPSIS

    use Term:ReadKey; #Optional, but recommended
    use IO::Pager::Perl;

    my $t = IO::Pager::Perl->new( rows => 25, cols => 80 );
    $t->add_text( $text );
    $t->more();

=head1 DESCRIPTION

This is a module for paging through text one screenful at a time.
It supports the features you expectcusing the shortcuts you expect.

IO::Pager::Perl is an enhanced fork of L<Term::Pager>.

=head1 USAGE

=head2 Create the Pager

    $t = IO::Pager::Perl->new( option => value, ... );

If no options are specified, sensible default values will be used.
The following options are recognized, and shown with the default value:

=over 4

=item I<rows> =E<gt>25?

The number of rows on your terminal.  The terminal is queried directly
with Term::ReadKey if loaded or C<stty> or C<tput>, and if these fail
it defaults to 25.

=item I<cols> =E<gt>80?

The number of columns on your terminal. The terminal is queried directly
with Term::ReadKey if loaded or C<stty> or C<tput>, and if these fail it
defaults to 80.

=item I<speed> =E<gt>38400?

The speed (baud rate) of your terminal. The terminal is queried directly
with Term::ReadKey if loaded or C<stty>, and if these fail it defaults to
a sensible value.

=item I<eof> =E<gt>0

Exit at end of file.

=item I<fold> =E<gt>1

Wrap long lines.

=item I<lineNo> =E<gt>0

If true, line numbering is added to the output.

=item I<pause> =E<gt>0

If defined, the pager will pause when the this character sequence is
encountered in the input text. Set to ^L i.e; "\cL" to mimic traditional
behavior of L<more/1>.

=item I<raw> =E<gt>0

Pass control characters from input unadulterated to the terminal.
By default, chracters other than tab and newline will be converted
to caret notation e.g; ^@ for null or ^L for form feed.

=item I<squeeze> =E<gt>0

Collapse multiple blank lines into one.

=item I<statusCol> =E<gt>0

Add a column with markers indicating which row match a search expression.

=item I<visualBeep> =E<gt>0

Flash the screen when beeping.

=back

=head3 Accessors

There are accessors for all of the above properties, however those for
rows, cols, speed, fold and squeeze are read only.

  #Is visualBeep set?
  $t->visualBeep();

  #Enable line numbering
  $t->lineNo(1);

=head2 Adding Text

You will need some text to page through. You can specify text as
as a parameter to the constructor:

    text => $text

Or even add text later:

    $t->add_text( $text );

If you wish to continuously add text to the pager, you must setup your own
event loop, and indicate to C<more> that it should relinquish control e.g;

    eval{
        while( $t->more(RT=>.05) ){
          ...
          $t->add_text("More text to page");
        }
    };

The eval block captures the exception thrown upon termination of the pager
so that your own program may continue. The I<RT> parameter indicates that
you wish to provide content in real time. This value is also passed to
L<Term::ReadKey/ReadKey> as the maximum blocking time per keypress and
should be between 0 and 1, with larger values trading greater interface
responsiveness for slight delays in output. A value of -1 may also be used
to request non-blocking polls, but likely will not behave as you would hope.

NOTE: If Term::ReadKey is not loaded but RT is true, screen updates will only
occur on keypress.

=head2 Adding Functionality and Internationalization (I18N)

It is possible to extend the features of IO::Pager::Perl by supplying the
C<add_func> method with a hash of character keys and callback values to be
invoked upon matching keypress; where \c? represents Control-? and \e?
represents Alt-? The existing pairings are:

	'h' => \&help,
	'q' => \&done,
	'r' => \&refresh,       #also "\cL"
	"\n"=> \&downline,      #also "\e[B"
	' ' => \&downpage,      #also "\cv"
	'd' => \&downhalf,
	'b' => \&uppage,        #also "\ev"
	'y' => \&upline,        #also "\e[A"
	'u' => \&uphalf,
	'g' => \&to_top,        #also '<'
	'G' => \&to_bott,       #also '>'
	'/' => \&search,
	'?' => \&hcraes,        #reverse search
	'n' => \&next_match,    #also 'P'
	'p' => \&prev_match,    #also 'N'
	"\e[D" => \&move_left,
	"\e[C" => \&move_right,
	'#' => \&toggle_numbering,

And a special sequence of a number followed by enter analogous to:

	'/(\d+)/'   => \&jump(\1)        

if the value for that key is true.

The C<dialog> method may be particularly useful when enhancing the pager.
It accepts a string to display, and an optional timeout to sleep for
before the dialog is cleared. If the timeout is missing or 0, the dialog
remains until a key is pressed.

    my $t = IO::Pager::Perl->new();
    $t->add_text("Text to display");
    $t->add_func('!'=>\&boo);
    $t->more();

    sub boo{ my $self = shift; $self->dialog("BOO!", 1); }

Should you add additional functionality to your pager, you will likely want
to change the contents of the help dialog or possibly the status line. Use the
C<I18N> method to replace the default text or save text for your own interface.

    #Get the default help text
    my $help = $t->I18N('help');

    #Minimal status line
    $t->I18N('prompt', "<h> help");

Current text elements available for customization are:

    404      - search text not found dialog
    bottom   - prompt line end of file indicator
    continue - text to display at the bottom of the help dialog
    help     - help dialog text, a list of keys and their functions
    prompt   - displayed at the bottom of the screen
    status   - brief message to include in the status line
    top      - prompt line start of file indicator

I<status> is intended for sharing short messages not worthy of a dialog
e.g; when debugging. You will need to call the C<prompt> method after
setting it to refresh the status line of the display, then void I<status>
and call C<prompt> again to clear the message.

=head3 Scalability

The help text will be split in two horizontally on a null character if the
text is wider than the display, and shown in two sequential dialogs.

Similarly, the status text will be cropped at a null character for narrow
displays.

=head1 CAVEATS

=head2 UN*X

This modules currently only works in UN*X-like environment.

=head2 Performance

For simplicity, the current implementation loads the entire message to view
at once; thus not requiring a distinction between piped contents and files.
This may require significant memory for large files.

=head2 Termcap

This module uses Termcap, which has been deprecated the Open Group,
and may not be supported by your operating system for much longer.

If the termcap entry for your ancient esoteric terminal is wrong or
incomplete, this module may either fill your screen with unintelligible
gibberish, or drop back to a feature-free mode.

Eventually, support for Terminfo may also be added.

=head2 Signals

IO::Pager::Perl sets a global signal handler for I<SIGWINCH>, this is the
only way it can effectively detect and accommodate changes in terminal size.
If you also need notification of this signal, the handler will trigger any
callback assigned to the I<WINCH> attribute of the C<new> method.

=head1 ENVIRONMENT

IO::Pager::Perl checks the I<TERM> and I<TERMCAP> variables.

=head1 SEE ALSO

L<IO::Pager>, L<Term::Cap>, L<Term::ReadKey>,
L<termcap(5)>, L<stty(1)>, L<tput(1)>, L<less(1)>

=head1 AUTHORS

    Jerrad Pierce jpierce@cpan.org

    Jeff Weisberg - http://www.tcp4me.com

=head1 LICENSE

This software may be copied and distributed under the terms
found in the Perl "Artistic License".

A copy of the "Artistic License" may be found in the standard
Perl distribution.
 
=cut
