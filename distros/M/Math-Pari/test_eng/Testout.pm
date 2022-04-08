#! perl
# 	$rcs = ' $Id: testout.t,v 1.2 1997/09/22 10:13:37 ilya Exp ilya $ ' ;

use strict;
use Math::Pari qw(:DEFAULT pari_print :all);
use vars qw($x $y $z $k $t $q $a $u $i $j $l $name $other $n);
die "Need a path to a testout file" unless @ARGV;

my $file = CORE::shift;
my(@tests, %seen, $current_num, $userfun, $installed, $skip_gnuplot, %not_yet_defined, $printout, $intests, $rest, $popped);
{
  open TO, "< $file" or die "open `$file': $!";
  local $/ = "\n? ";
  @tests = <TO>;
  close TO or die "close: $!";
}

my $mess = '';
$mess = CORE::shift @tests if @tests and $tests[0] !~ /^\?/; # Messages
my @skip_fun;
my $skip_fun_rx = qr/(?!)/;
my $matched_par;
$matched_par = qr[[^()]*(?:\((??{$matched_par})\)[^()]*)*];		# arbitrary string with ( and ) matching
my %ourvars;
my $ourvars_rx = qr/(?!)/;
my $skipvars_rx = qr/(?!)/;

my $can_matrix = eval {PARImat_tr([[3]]) == matrix(1, 1, my $x, my $y, sub{3})} ;	# after 2.3.5, but before support
my $or_matrix = (not $can_matrix and "|matrix");
my $or_matrix_out = (not $can_matrix and " (or matrix())");

(my $ifile = $file) =~ s[(?<=/test/)(32|64)/][in/];
{
  open FROM, '<', $ifile or die "open `$file': $!";
  local $/;
  $intests = <FROM>;
  close FROM or die "close: $!";
}
my $pref;
($pref = $intests) =~ s/^(\\e|default\(echo,[^\n]*\n)(.*)//ms and CORE::length $pref and $rest = $2;

$popped++, pop @tests if ($tests[-1] || 0) =~ /^\\q/;

my $skip_eval = (Math::Pari::pari_version_exp() >= 2004002);
my $use_dollars_in_argsign = $skip_eval;

if ($pref =~ /^\s*\\\\\s*package:(.*)/m) {
  print "1..0 # skipped: package dependency: $1\n";
  @tests = ();
} elsif (my $tests = @tests) {
  $tests +=  !!$rest;
  print "1..$tests\n";
} elsif ($rest) {
  print "1..1\nnot ok 1 # no tests found in `$file', but input has echo enabled\n";
  warn "unexpected format of GP/PARI test output file: echo enabled, but no echoed lines";
} else {	# no echoed lines expected
  print "1..0 # skipped: command-line echoing is not enabled in the test file `$ifile'\n";
}

# prec($3 || $1, 1) if $mess =~ /.*realprecision = (\d+) significant digits( \((\d+) digits displayed\))?/; # take the latest one
if ($rest) {	# 'define'
  (my $Pref = $pref) =~ s/^(.*)$/### $1/mg ;
  print("# The following `? ' are the output from parse_as_gp() for\n$Pref");
  my $Err;
  eval { parse_as_gp $pref, sub ($) {"main::".CORE::shift}, 'echo'; 1}
    or $Err = $@;
  $current_num++;
  if (defined $Err) {  #  failed to process, but do emit the expected-for-test output
    print "not ok $current_num # in no-echo group err=$Err\n";
  } else {
    print "ok $current_num # Skipping translation to Math::Pari (no-echo group done in PARI, see above)\n";
  }
}
$rest ||= $intests;

#Math::Pari::dumpStack,allocatemem(8e6),Math::Pari::dumpStack if $file =~ /intnum/; # Due to our allocation policy we need more?


$| = 1;		# Need to list loop variables used by the code:
my @seen = qw(Euler Pi I getrand a x xx y z k t q u j l n v p e s
	      name other mhbi a2 a1 a0 b0 b1
	      acurve bcurve ccurve cmcurve tcurve mcurve ma mpoints);
my @VARS = map "\$$_", @seen;
eval 'use vars @VARS; 1' or die "use vars: $@";
@seen{@seen}  = (' ', ' ', ' ', ' ', ('$') x 100);
$seen{oo} = ' ' if Math::Pari::pari_version_exp >= 2009000;
for (@seen) {
  no strict 'refs';
  $$_ = PARI($_) unless $seen{$_} eq ' ';
}
$seen{'random'} = ' ';
my $DEFAULT = undef;

# Some of these are repeated below (look for XXXX), since they cause
# an early interpretation of unquoted args
@not_yet_defined{qw(
    type
  )} = (1) x 10000;

if ($file =~ /plot|graph|all/) {
  if ($ENV{MP_NOGNUPLOT}) {
    $skip_gnuplot = 1;
  } else {
    eval { link_gnuplot() };
    if ($@ =~ m%^Can't locate Term/Gnuplot.pm in \@INC%) {
      print STDERR "# Can't locate Term/Gnuplot.pm in \@INC, ignoring plotting\n";
      @not_yet_defined{qw(
	plotbox plotcolor plotcursor plotdraw ploth plothraw plotinit plotlines
	plotmove plotpoints plotrline plotrmove plotrpoint psdraw psploth
	psplothraw plotscale
	plotkill
      )} = (1) x 10000;
      $skip_gnuplot = 1;
    } elsif ($@) {
      die $@;
    }
  }
}

my $started = 0;

main_loop:
while (@tests) {
  $_ = CORE::shift @tests;
  #print "Doing `$_'";
  1 while s/^\\\\.*\n//;	# Comment
  my $bad = /^\\(?!p[bs]?\s*\d)/;		# \precision =
  my $wasbadprint = /\b(plot)\b/;
  my $wasprint = /\b((|p|tex)print(tex)?|plot)\b/;
  s/\s*\n\?\s*\Z// or not $popped or die "Not terminated: `$_'\n";
  s/\A(\s*\?)+\s*//;
#  s/[^\S\n]+$//gm;
  s/\A(.*)\s*; $ \s*(\w+)\s*\(/$1;$2(/mx; # Continuation lines of questions
  # Special-case tests nfields-3 and intnum-23 with a wrapped question:
  s/\A(p2=.*\d{10})\n(7\n)/$1$2/;
  s/\n(?=\/\w)//;
  s/\A(.*)\s*$//m or die "No question: `$_'\n";
  my $in = $1;
  1 while s/^\n//;		# Before warnings
  1 while s/^\s*\*+\s*warning.*\n?//i; # skip warnings
  if (s/^\s*\*+\s*(.*)//) {		# error
    process_error($in,$_,$1);
    next;
  }
  process_test($in, 'noans', []), next if /^$/; # Was a void
#  s/^%\d+\s*=\s*// or die "Malformed answer: $_" unless $bad or $wasprint;
  if ($_ eq '' or $wasprint) {	# Answer is multiline
#    @ans = $_ eq '' ? () : ($_) ;
#    while (<>) {
#      last if /^\?\s+/;
#      next if /^$/;
#      chomp;
#      push @ans, $_;
#    }
    my @ans = split "\n";
    if ($wasbadprint) {
      process_print($in, @ans);
    } elsif ($wasprint) {
      process_test($in, 'print', [@ans]);
    } else {
      process_test($in, 0, [@ans]);
    }
    next main_loop;
  }
  if ($bad) {
    process_set($in, $_);
  } else {
    process_test($in, 0, [$_]);
  }
}

sub format_matrix {
  my $in = CORE::shift;
  my @in = split /;/, $in;
  'PARImat_tr([[' . join('], [', @in) . ']])';
}

sub format_vvector {
  my $in = CORE::shift;
  $in =~ s/~\s*$//;
  "PARIcolL($in)";
}

sub re_format {			# Convert PARI output to a regular expression
  my $in = join "\n", @_;
  $in = quotemeta $in;
  $in =~ s/\\\]\\\n\\\n\\\[/\\s*;\\s*/g; # row separator
  $in =~ s/\\\n/\\s*/g;
  $in =~ s/\\[ \t]/,?\\s*/g;
  # This breaks a lot of linear.t tests
  ### Allow for rounding 3999999 <=> 40000000, but only after . or immediately before it
  ##$in =~ s/([0-8])((?:\\\.)?)(9+(\\s\*9+)?)(?![+\d])/$n=$1+1;"($1$2$3|$n${2}0+)"/ge;
  ##$in =~ s/([1-9])((?:\\\.)?)(0+(\\s\*0+)?)(?![+\d])/$n=$1-1;"($1$2$3|$n${2}9+)"/ge;
  ##$in =~ s/(\d{8,})([1-8])(?![+\d()]|\\s\*)/$n=$2-1;$m=$2+1;$1."[$2$n$m]\\d*"/ge;
  $in
}

sub mformat {
  # if not matrix, join with \t
  return join("\t", @_) unless @_ > 1 and $_[0] =~ /^\[/;
  @_ = grep {!/^$/} @_;		# remove empty lines
  return join("\t", @_) if grep {!/^\s*\[.*\]\s*$/} @_;	# Not matrix
  #return join("\t", @_) if grep {!/^\s*\([^,]*,\s*$/} @_; # Extra commas
  map {s/^\s*\[\s*(.*?)\s*\]\s*$/$1/} @_;
  my @arr = map { join ', ', split } @_;
  '[' . join('; ', @arr) . ']';
}

sub mformat_transp {
  return join("\t", @_) unless @_ > 1 and $_[0] =~ /^\[/;
  @_ = grep {!/^$/} @_;
  return join("\t", @_) if grep {!/^\s*\[.*\]\s*$/} @_;	# Not matrix
  #return join("\t", @_) if grep {!/^\s*\([^,]*,\s*$/} @_; # Extra commas
  map {s/^\s*\[(.*)\]\s*$/$1/} @_;
  my @arr = map { [split] } @_;
  my @out;
  my @dummy = ('') x @{$arr[0]};
  for my $ind (0..$#{$arr[0]}) {
    for my $subarr (@arr) {
      @$subarr > $ind or $subarr->[$ind] = '';
    }
    push @out, join ', ', map {$_->[$ind]} @arr;
  }
  '[' . join('; ', @out) . ']';
}

sub massage_floats {
  my $in = CORE::shift;
  my $pre = CORE::shift || "16g";
  $in =~ s/(.\d*)\s+e/$1E/gi;	# 1.74 E-78
  $in =~ s/\b(\d+\.\d*(e[-+]?\d+)?|\d{10,})\b/sprintf "%.${pre}", $1/gei;
  $in;
}

sub o_format {
  my ($var,$power) = @_;
  return " PARI('O($var^$power)') " if defined $power;
  return " PARI('O($var)') ";
}

sub process_cond {
  my ($what, $cond, $then, $else, $initial) = @_;
  die if $initial =~ /Skip this/;
  # warn "Converting `$in'\n`$what', `$cond', `$then', `$else'\n";
  if (($what eq 'if') ne (defined $else)) {
    return "Skip this `$initial'";
  } elsif ($what eq 'if') {
    return "( ($cond) ? ($then) : ($else) )";
  } else {
    return "do { $what ($cond) { $then } }";
  }
}

sub nok_print {
  my ($n, $in) = (CORE::shift, CORE::shift);
  print(@_), return unless $ENV{AUTOMATED_TESTING};
  warn("# in = `$in'\n", @_);
  print("not ok $n\n");
}

sub update_seen ($) {
  my $seen_now = CORE::shift;
  @seen{keys %$seen_now} = values %$seen_now;
#  my @VARS = map "\$$_", keys %$seen_now;
#  eval 'use vars @VARS; 1' or die "use vars: $@";
}

sub pre_update_seen ($) {
  my $sym = CORE::shift;
#  @seen{keys %$seen_now} = values %$seen_now;
#  my @VARS = map "\$$_", keys %$seen_now;
  eval "use vars '\$$sym'; 1" or die "use vars: $@";
}

sub subify_iterators ($$) {
  my($pre, $code, $subargs, $subdecl) = (CORE::shift, CORE::shift, '', '');
  if ($use_dollars_in_argsign) {
    $subargs = ' ($) ';
    if ($pre =~ /^(v?vector|fordiv|sumdiv|plothexport)\(/) {
      $pre =~ /^\w+\s*\([^,]*,\s*([\$\w]+)\s*,/ or die "Cannot find iterator variable in `$pre\{\{\{$code\}\}\}'";
      $subdecl = "my $1 = CORE::shift;"
    } else {
      $pre =~ /^\w+\s*\(\s*([\$\w]+)\s*,/ or die "Cannot find iterator variable in `$pre\{\{\{$code\}\}\}'";
      $subdecl = "my $1 = CORE::shift;"
    }
  }
#	      /$1 sub$subargs\{$2}/xg;
  "$pre sub$subargs\{$subdecl$code\}";
}

sub filter_res ($) { # In PARI’s Mod() output there is an extra space comparing to ours
  my $r = CORE::shift;
  $r =~ s/(\bmatrix\([^\s,]+)\s+/$1,/g;
#  	warn "### ->\t$r\n";
  return $r unless $r =~ /\bMod\(/;
  $r =~ s/,\s+/,/g;
  return $r;
}

my $prev;
sub process_test {
  my ($in, $noans, $out) = @_;
#	warn("<<<$in>>>, $noans, <<<@$out>>>");
  my($IN, $res, $rres, $rout) = $in;
  my $ini_time = time;
  my $doprint;
  $doprint = 1 if $noans eq 'print';
  my $was_prev = $prev;
  undef $prev;
  $current_num++;
  # First a trivial processing:
  $in =~ s/^\s*gettime\s*;//;		# Starting lines of tests...
  $in =~ s/\b(\d+|[a-z]+\(\))\s*\\\s*(\d+(\^\d+)?)/ gdivent($1,$2)/g; # \
  $in =~ s/\b(\d+)\s*\\\/\s*(\d+)/ gdivround($1,$2)/g; # \/
  $in =~ s/\b(\w+)\s*!/ ifact($1)/g; # !
  $in =~ s/,\s*(?=,)/, \$DEFAULT /g;	# Default arguments?
  $in =~ s/^default\(realprecision,(.*)\)/\\p $1/; # Some cases of default()
  $in =~ s/^default\(realbitprecision,(.*)\)/\\pb $1/; # Some cases of default()
  $in =~ s/^default\(seriesprecision,(.*)\)/\\ps $1/; # Some cases of default()
  $in =~ s/(\w+)\s*\\(\w+(\s*\^\s*\w+)?)/gdivent($1,$2)/g; # random\10^8
  $in =~ s/%(?!\s*[\[_\w])/\$was_prev/g; # foo(%)
  $in =~ s/\b(for)\s*\(\s*(\w+)=/&$1($2,/g; # for(x=1,13,print(x))
  $in =~ s/
	    ^
	    (
	      \(
		(?:
		  [^(,)]+
		  (?=
		    [(,)]
		  )
		|
		  \( [^()]* \)
		)*		# One level of parenths supported
	      \)
	    )
	    ' $
	  /deriv$1/x; # ((x+y)^5)'
  if ($in =~ /^\\p\s*(\d+)/) {
    prec("$1");
  } elsif ($in =~ /^\\pb\s*(\d+)/) {		# \\ for division unsupported
    bprec("$1");
  } elsif ($in =~ /^\\ps\s*(\d+)/) {		# \\ for division unsupported
    sprec("$1");
  } elsif ($in =~ /\\/) {		# \\ for division unsupported
    $current_num--;
    process_error($in, $out, '\\');
  } elsif ($in =~ /^(\w+)\s*\([^()]*\)\s*=/ and 0) { # XXXX Not implemented yet
    $current_num--;
    process_definition($1, $in);
  } elsif ($in =~ /!(?![\(\w])|\'/) {	# Factorial (unless in !foo())
    print "# `$in'\nok $current_num # Skipping (ifact/deriv)\n";
  } else {
    # work with "^", need to treat differently inside o()
    $in =~ s/\^/^^^/g;
    $in =~ s/\bo\(([^()^]*)(\^\^\^([^()]*))?\)/ o_format($1,$3) /gei;
    $in =~ s/\^\^\^/**/g;	# Now treat it outside of O()
    $in =~ s/\[([^\[\];]*;[^\[\]]*)\]/format_matrix($1)/ge; # Matrix
    $in =~ s/\[([^\[\];]*)\]\s*~/format_vvector($1)/ge; # Vertical vector
 eval {
    1 while $in =~ s/
	      \b (if|while|until) \(
	      (
		(?:
		  [^(,)]+
		  (?=
		    [(,)]
		  )
		|
		  \( [^()]* \)
		)*		# One level of parenths supported
	      )
	      ,
	      (
		(?:
		  [^(,)]+
		  (?=
		    [(,)]
		  )
		|
		  \( [^()]* \)
		)*		# One level of parenths supported
	      )
	      (?:
		,
		(
		  (?:
		    [^(,)]+
		    (?=
		      [(,)]
		    )
		  |
		    \( [^()]* \)
		  )*		# One level of parenths supported
		)
              )?
	      \)
	    /process_cond($1, $2, $3, $4, $in)/xge; # if(a,b,c)
 };
    my $RET;
    if ($in =~ /\[[^\]]*;/) {	# Matrix
      print "# `$in'\nok $current_num # Skipping (matrix notation)\n";
      $RET = 1;
    } elsif ($in =~ /Skip this `(.*)'/) {
      print "# `$1'\nok $current_num # Skipping (runaway conversion)\n";
      $RET = 1;
    } elsif ($in =~ /&for\s*\([^\)]*$/) {	# Special case
      print "# `$in'\nok $current_num # Skipping (runaway input line)\n";
      $RET = 1;
    } elsif ($in =~ /(^|[\(=,])%/) {
      print "# `$in'\nok $current_num # Skipping (history notation)\n";
      $RET = 1;
    } elsif ($in =~ /\b(get(heap|stack)|Total time spent.*gettime)\b/) {
      print "# `$in'\nok $current_num # Silently skipping: meaningless for Math::Pari\n";
      $RET = 1;
    } elsif ($in =~ /
		      (
			\b
			( if | goto | label | input | break
			  # | while | until
                          | gettime | default
                        )
			\b
		      |
			(\w+) \s* \( \s* (?: (?!\d)\w+ \s* (?:, \s* (?!\d)\w+ \s* )* )? \) \s* =(?!=)
		      |
			\b install \s* \( \s* (\w+) \s* , [^()]* \)
		      |
			\b
			(
			  my _
			)?
			(?: p? print $or_matrix ) \(
			( \[ | (1 ,)? PARImat )
		      |	  # Too many parens: will not be wrapped in sub{...}
		      	\b forprime .* \){5}
		      )
		    /x) {
      if (defined $3) {
	print "# User function `$3'.\n";
      }
      if (defined $4) {
	if (defined $installed) {
	  $installed .= "|$4";
	} else {
	  $installed = $4;
	}
	print "# Installed function `$4'.\n";
      }
      if ($1 eq 'default' and $in =~ /^default\s*\(\s*echo\s*,\s*0\s*\)\s*(;\s*)?$/) {	# See the test 'ff' - but this is not present in the OUTPUT!!!???
        if ($rest =~ s/\A.*?^default\s*\(\s*echo\s*,\s*0\s*\)\s*(;\s*)?$//ms) {        # Try to matchin in $rest:
          if ($rest =~ s/\A(.*?)^default\s*\(\s*echo\s*,\s*(?!0\b)\S[^\n]*\)\s*(;\s*)?$//ms) {
	    (my $Pref = my $cmd = "$1") =~ s/^(.*)$/### $1/mg ;
	    if ($cmd =~ /(?:^|;)\s*(?:print|error)\(/ or $userfun and $cmd =~ / \b ($userfun) \s* \( /x) {
	      my $with = '';
	      if ($cmd =~ /^\s*(\w+)\s*\($matched_par\)\s*=(?!=)/) {
	        $with = "with a user function $1() ";
		if (defined $userfun) {
		  $userfun .= "|$1";
		} else {
		  $userfun = $1;
		}
	      }
	      print "${Pref}ok $current_num # Skipping (no-echo group ${with}containing print() or error() or a converted-to-Perl variable)\n";
	    } else {
              print("# The following `? ' are the output from parse_as_gp() for\n$Pref");
              my $Err;
              eval { parse_as_gp $cmd, sub ($) {"main::".CORE::shift}, 'echo'; 1}
                or $Err = $@;
              # next		# fail to process, but do emit the expected-for-test output
              if (defined $Err) {
                print "# `$in'\nnot ok $current_num # in no-echo group err=$Err\n";
              } else {
                print "# `$in'\nok $current_num # Skipping translation to Math::Pari (no-echo group done in PARI, see above)\n";
              }
	    }
	    $RET = 1;
          } else {
            warn("Cannot find a matching echo-on command in input file"),
          }
        } else {
          warn("Cannot find a matching echo-off command in input file"),
        }
      } else {
        # It is not clear why changevar gives a different answer in GP
        print "# `$in'\nok $current_num # Skipping (converting test for '$1' needs additional work)\n";
        $RET = 1;
      }
    } elsif ($userfun
	     and $in =~ / \b ($userfun) \s* \( /x) {
      print "# `$in'\nok $current_num # Skipping (user function containing print() or error() $or_matrix_out or a converted-to-Perl variable)\n";
      $RET = 1;
    } elsif ($installed
	     and $in =~ / \b ($installed) \s* \( /x) {
      print "# `$in'\nok $current_num # Skipping (installed function)\n";
      $RET = 1;
#    } elsif ($in =~ / \b ( sizebyte ) \b /x
#	     and $file !~ /will_fail/) {
#      # XXXX Will result in a wrong answer, but we moved these tests to a different
#      print "# `$in'\nok $current_num # Skipping (would fail, checked in different place)\n";
#      $RET = 1;
    } elsif ($in =~ /\b(nonesuch now|nfisincl$or_matrix)\b/) {
      print "# `$in'\nok $current_num # Skipping (possibly FATAL $1)\n";
      $RET = 1;
    } elsif ($in =~ /\$?\b($skipvars_rx)\b/) {
      print "# `$in'\nok $current_num # Skipping (a variable `$1' was possibly defined in a skipped statement)\n";
      $RET = 1;
    } elsif ($in =~ $skip_fun_rx) {
      print "# `$in'\nok $current_num # Skipping (see a PARI function $1() calling print() or error())\n";
      $RET = 1;
    }
    # Convert transposition
    $in =~ s/(\$?\w+(\([^()]*\))?|\[([^\[\]]+(?=[\[\]])|\[[^\[\]]*\])*\])~/mattranspose($1)/g;
    # Convert strings with a simple word
    $in =~ s/("\w+")/'$1'/g unless $in =~ /\b(my_)?print\b/;	# XXX Silly ad hoc trick (temporary???)
    if ($in =~ /~/) {
      print "# `$in'\nok $current_num # Skipping (transpose notation)\n";
      $RET = 1;
    }
    if ($in =~ /->/) {
      print "# `$in'\nok $current_num # Skipping (-> notation)\n";
      $RET = 1;
    }
    if ($RET) {
      while ($in =~ /(?:^|;)\$?(\w+)=(?!=)/g) {
        $skipvars_rx .= "|$1";
      }
    }
    if ($RET and $in =~ /(?:^|;)\$?(\w+)\([^()]*\)=(?!=)/) {
      my $n = $1;
      if ($in =~ /\b(print|error|$ourvars_rx)\b/) {
	push @skip_fun, $n;
	my $rx = join '|', @skip_fun;
	$skip_fun_rx = qr/\b($rx)\(/;
	if ($1 eq 'print') {
	  print "# NOT doing PARI-eval: print() seen\n";
	} else {
	  print "# NOT doing PARI-eval: variable `$1' converted to Perl before was seen\n";
	}
	if (defined $userfun) {
	  $userfun .= "|$n";
	} else {
	  $userfun = $n;
	}
	return;
      }
      print "# doing PARI-eval of a function `$n' instead\n";
      PARI $IN;
	no strict 'refs';
      *$n = Math::Pari::__wrap_PARI_macro $n;
    }
    return if $RET;
    if ($in =~ /^\s*alias\s*\(\s*(\w+)\s*,\s*(\w+)\s*\)$/) {
      print "# Aliasing `$1' ==> `$2'\nok $current_num\n";
      no strict 'refs';
      *$1 = \&{$2};
      return;
    }
    if ($in !~ /\w\(/) { # No function calls
      # XXXX Primitive!
      # Constants: (.?) eats following + or - (2+3 ==> PARI(2)+PARI(3))
      $in =~ s/(^|\G|\W)([-+]?)(\d+(\.\d*)?(?:e-?\d+)?)(.?)/$1 $2 PARI($3) $5/gi;
      # Big integer constants:
      $in =~ s/\bPARI\((\d{10,})\)/PARI('$1')/g;
    } elsif ($in =~ /\b(elllseries|binomial|mathilbert|intnum|intfuncinit|intfuncinit)\b/) { # high precision needed?
      # XXXX Primitive!
      # Substitute constants where they are not arguments to functions,
      # (except small half-integers, which should survive conversion)
      $in =~ s/(^|\G|\W)([-+]?)(?!\d{0,6}\.5\b)(\d+\.\d*(?:e-?\d+)?)/$1 $2 PARI('$3') /gi;
      # Bug in GP???  Too sensitive to precision of 4.5 in intfuncinit(t=[-oo, 4.5],[oo, 4.5], gamma(2+I*t)^3, 1);
      $in =~ s/(^|\G|\W)([-+]?)(\d+\.\d*(?:e-?\d+)?)/$1 $2 PARI('$3') /gi
	if $in =~ /intfuncinit/;
      # Big integer constants:
      $in =~ s/\bPARI\((\d{10,})\)/PARI('$1')/g;
    } else {
      # Substitute big integer constants
      $in =~ s/(^|\G|\W)(\d{10,}(?!\.\d*(?:e-?\d+)?))(.?)/$1 PARI('$2') $3/gi;
      # Substitute division
	$in =~ s/(^|[\-\(,\[=+*\/])(\d+)\s*\/\s*(\d+)(?=$|[*+\-\/\),\]])/$1 PARI($2)\/PARI($3) /g;
    }
    my %seen_now;
    # Substitute i= in loop commands
    if ($in !~ /\b(hermite|mathnf|until)\s*\(/) { # Special case, not loop-with-=
      $in =~ s/([\(,])(\w+)=(?!=)/ $seen_now{$2} = '$'; "$1$2," /ge;
    }
    # Substitute print
    $in =~ s/\b(|p|tex)print(tex|)\(/ 'my_' . $1 . $2 . 'print(1,' /ge;
    $in =~ s/\b(|p|tex)print1\(/ 'my_' . $1 . 'print(0,'/ge;
    if ($skip_eval and $in =~ /\beval\(/g) { # eval($y)
      print("# `$in'\nok $current_num # Skipping: eval's signature C is not supported yet\n"), return;
    }
    $in =~ s/\b(eval|shift|sort)\(/&$1\(/g; # eval($y)
    # Special case -oo (with $oo=[PARI(1)] done earlier;
    # Having $oo defined without external PARI tests conversions; but it'sn't overloaded in older PARI
    $in =~ s/-oo\b/- PARI(\$oo)/ if $seen_now{oo} or Math::Pari::pari_version_exp < 2009000;
    # Recognize variables and prepend $ in assignments
    # s/\b(direuler\s*\(\s*\w+\s*),/$1=/;	# direuler
    $in =~ s/\bX\b/PARIvar("X")/g if $in =~ /\bdireuler\b/;
    $in =~ s/(^\s*|[;(]\s*)(?=(\w+)\s*=\s*)/$seen_now{$2} = '$'; pre_update_seen($2); $1 . '$'/ge; # Assignment
    if ($in =~ /\.((?!\d|(?<=\d\.)e-?\d)\w+(?![\w"]))/) {
      print("# `$in'\nok $current_num # Skipping: methods not supported yet (.$1)\n"), return;
    }
    if ($in =~ /(?<!\|)\|\s*\$?\w+\s*<-/) {
      print("# `$in'\nok $current_num # Skipping: |var<- not supported yet\n"), return;
    }
    # Prepend $ to variables (not before '^' - inside of 'o(x^17)'):
    $in =~ s/(^|[^\$])\b([a-zA-Z]\w*)\b(?!\s*[\(^])/
      		($1 || '') . ($seen{$2} || $seen_now{$2} || '') . $2
	/ge;
    # Skip if did not substitute variables:
    while ($in =~ /(^|[^\$])\b([a-zA-Z]\w*)\b(?!\s*[\{\(^])/g) {
      print("# `$in'\nok $current_num # Skipping: variable `$2' was not set\n"), return
	unless $seen{$2} and $seen{$2} eq ' ' or $in =~ /\"/;
      # Let us hope that lines which contain '"' do not contain unset vars
    }
    # Simplify for the following conversion:
    $in =~ s/\brandom\(\)/random/g;
    # Sub-ify sum,prod,intnum* sumnum etc, psploth, ploth etc
    my $oneArg = qr/(?:			# 3 levels of parentheses supported
                      [^(,)\[\]]+
                      (?=
                        [(,)\[\]]
                      )
                    |
                      \(		# One level of parenths
                      (?:
                        [^()]+
                        (?=
                          [()]
                        )
                      |
                        \(	# Second level of parenths
                          (?:
                            [^()]+
                            (?=
                              [()]
                            )
                            | \( [^()]* \) # Third level of parens
                          )*
                        \)	# Second level of parenths ends
                      )*
                      \)
                    |
                      \[		# One level of brackets
                      (?:
                        [^\[\]]+
                        (?=
                          [\[\]]
                        )
                      |
                        \[ [^\[\]]+ \] # Second level of brackets
                      )*
                      \]
                    )*		# 3 levels of parenths supported
		  /x;
    1 while
      $in =~ s/ (
		  \b
		  (?:
                    (?:		# For these, sub{}ify the fourth argument
                      sum
                    |
                      intnum(?!init\b)\w*
                    |
                      intfuncinit
                    |
                      int\w*inv
                    |
                      intcirc\w*
                    |
                      sumnum(?!init\b)\w*
                    |
                      forprime
                    |
                      psploth
                    |
                      ploth
                    |
                      prod (?: euler )?
                    |
                      direuler
                    )  \s*
		    \(  (?: $oneArg [=,] ){3}	# $x,1,100
		  | (?:				# For these, sub{}ify the third argument
                      sumalt
                    |
                      prodinf
                    )  \s*
		    \(  (?: $oneArg [=,] ){2}	# $x,1
		  | (?:				# For these, sub{}ify the fifth argument
                      plothexport
                    )  \s*
		    \(  (?: $oneArg [=,] ){4}	# "ps",$x,100
		  | (			# 2: For these, sub{}ify the last argument
                      solve
                    |
                      (?:
                        post
                      )?
                      ploth (?! raw (?:export)? \b | sizes \b | export \b ) \w+
                    |
                      # sum \w*
                      sum (?! alt | num (?:init)? \b) \w+
                    |
                      v? vector v?
                    |
                      matrix
                    |
                      intgen
                    |
                      intopen
                    |
                      for \w*
                    )  \s*
		    \(  (?: $oneArg , )*		# "ps",$x,1,100; do not accept "=" after the iterator variable
		  )
		)				# end group 1
		(?!\s*sub(?:\s*\(\$*\))?\s*\{)	# Skip already converted...
		( $oneArg )			# 3: This follows after a comma on toplevel
		(?(2) (?= \) ) | (?= [),] ) )
	      /subify_iterators("$1","$3")/xge;
    # Convert 10*20 to integer
    $in =~ s/(\d+)(?=\*\*\d)/ PARI($1) /g;
    # Convert blah[3], blah()[3] to blah->[-1+3]
    $in =~ s/([\w\)])\[/$1 -> [-1+/g;
    # Fix [,3] converted to [-1+,3]
    $in =~ s/\[-1\+,/\[-1+/g;
    # Fix [2,3] converted to [-1+2,3]
    $in =~ s/\[(-1\+[^,\[\]\(\)]+),([^\(\)\[\]]+)\]/\[-1+$2\]\[$1\]/g;
    # Workaround for &eval test:
    $in =~ s/\$y=\$x;&eval\b(.*)/PARI('y=x');&eval$1;\$y=\$x/;
    $in =~ s/\$yy=\$xx;&eval\b(.*)/PARI('yy=xx');&eval$1;\$yy=\$xx/;
    # Workaround for hardly-useful support for &:
    if ($in =~ s/([,\(]\s*)&(\$(\w+)\s*)(?=[,\)])/$1$2/) {
      #$in = qq(\$$3 = PARI "'$3"; \$OUT = do { $in }; \$$3 = PARI "$3"; \$OUT)
    }
    # Workaround for kill:
    $in =~ s/^kill\(\$(\w+)\);/kill('$1');\$$1=PARIvar '$1';/;
    # Workaround for plothsizes:
    $in =~ s/\bplothsizes\(/safe_sizes(/;
    # XXXX Silly workaround for `my' (probably a side effect of replacing "var=" by "var," in iterators???)
    $in =~ s/(?<=\bmy\(\$)(\w+),(?=\w+\()/$1)=(/g;
    print "# eval", ($noans ? "-$noans" : '') ,": $in\n";
    $printout = '';
    my $have_floats = ($in =~ /\d+\.\d*|\d{10,}/
		       or $in =~ /\b( ellinit|zeta|bin|comprealraw|frac|
				      lseriesell|powrealraw|legendre|suminf|
				      forstep )\b/x);
    my $newvars;
    $ourvars{$1}++ or $newvars++ while $in =~ /(?<!my )\$(\w+)\s*=(?!=)/g;
    if ($newvars) {
      $ourvars_rx = join '|', sort keys %ourvars;
      $ourvars_rx = qr($ourvars_rx);
    }
    # Remove the value from texprint:
    # pop @$out if $in =~ /texprint/ and @$out == 2;
    my $pre_time = time() - $ini_time;
    $res = eval "$in";
    my $run_time = time() - $ini_time - $pre_time;
    $rres = $res;
    $rres = pari_print $res if defined $res and ref $res;
    my $re_out;
    if ($doprint) {
      if ($in =~ /my_texprint/) { # Special-case, assume one wrapped with \n
	$rout = join "", @$out, "\t";
      } else {
	$rout = join "\t", @$out, "";
      }
      if ($have_floats) {
	$printout = massage_floats $printout, "14f";
	$rout = massage_floats $rout, "14f";
      }
      # New wrapping code gets in the way:
      $printout =~ s/\s+/ /g;
      $rout =~ s/\t,/,/g;
      $rout =~ s/\s+/ /g;

      $rout =~ s/,\s*/, /g;
      $printout =~ s/,\s*/, /g;
      $rout =~ s/\s*([-+])\s*/ $1 /g;
      $printout =~ s/\s*([-+])\s*/ $1 /g;
    } else {
      # Special-case several tests in all.t
      if (($have_floats or $in =~ /^(sinh?|solve)\b/) and ref $res) {
	# do it the hard way: we cannot massage floats before doing wrapping
	$rout = mformat @$out;
	if (defined $rres and $rres !~ /\n/) {
	  $rout =~ s/\]\s*\[/; /g;
	  $rout =~ s/\[\s+/[/g;
	  $rout =~ s/,\n/, \n/g; # Spaces were removed
	  $rout =~ s/\n//g;	# Long wrapped text
	}
	if ($rout =~ /\[.*[-+,;]\s/ or $rout =~ /\bQfb\b/) {
	  $rout =~ s/,*\s+/ /g;
	  $rres =~ s/,*\s+/ /g if defined $res;
	  $rres =~ s/,/ /g if defined $res;		# in 2.2.10 ", "
	  $rout =~ s/;\s*/; /g;				# in 2.2.10 "; "
	  $rres =~ s/;\s*/; /g if defined $res;		# in 2.2.10 "; "
	}
	if ($in =~ /\b(zeta|bin|comprealraw|frac|lseriesell|powrealraw|pollegendre|legendre|suminf|ellinit)\b/) {
	  $rres = massage_floats $rres, "14f";
	  $rout = massage_floats $rout, "14f";
	} else {
	  $rres = massage_floats $rres;
	  $rout = massage_floats $rout;
	}
	$rout =~ s/\s*([-+])\s*/$1/g;
	$rres =~ s/\s*([-+])\s*/$1/g if defined $res;
      } else {
	$re_out = re_format @$out;
#	$rout = mformat @$out;
#	if (defined $rres and $rres !~ /\n/) {
#	  $rout =~ s/\]\s*\[/; /g;
#	  $rout =~ s/,\n/, \n/g; # Spaces were removed
#	  $rout =~ s/\n//g;	# Long wrapped text
#	}
#	if ($rout =~ /\[.*[-+,;]\s/) {
#	  $rout =~ s/,*\s+/ /g;
#	  $rres =~ s/,*\s+/ /g if defined $res;
#	}
#	$rout =~ s/\s*([-+])\s*/$1/g;
#	$rres =~ s/\s*([-+])\s*/$1/g if defined $res;
      }
    }

    if ($@) {
      if ($@ =~ /^Undefined subroutine &main::(\w+)/
	  and $not_yet_defined{$1}) {
	print "# in='$in'\nok $current_num # Skipped: `$1' is known to be undefined\n";
      } elsif ($@ =~ /high resolution graphics disabled/
	       and 0 >= Math::Pari::have_graphics()) {
	print "# in='$in'\nok $current_num # Skipped: graphic is disabled in this build\n";
      } elsif ($@ =~ /pari_daemon without waitpid & setsid is not yet implemented/) {
	print "# in='$in'\nok $current_num # Skipped: graphic (pari_daemon) is disabled in this build\n";
      } elsif ($@ =~ /gnuplot-like plotting environment not loaded yet/
	       and $skip_gnuplot) {
	print "# in='$in'\nok $current_num # Skipped: Term::Gnuplot is not loaded\n";
      } else {			# XXXX Parens needed???
	nok_print( $current_num, $in, "not ok $current_num # in='$in', err='$@'\n" );
      }
      return;
    }
    my $cmp;
    if (defined $rres and defined $re_out) {
      for my $how (0,'Mat') {
        my $RR = $rres;
        $RR =~ s/\bMat\(($matched_par)\)/[$1]/g if $how;
        $cmp = eval { $RR =~ /^$re_out$/ };
        if ($@ and $@ =~ /regexp too big/) {
          print "ok $current_num # Skipped: $@\n";
          update_seen \%seen_now;
          $prev = $res;
          return;
        }
        last if $cmp
      }
    }
    my $post_time = time() - $ini_time - $pre_time - $run_time;
    if (not $noans and defined $re_out
	     and (not defined $rres or not $cmp)) {
      $out->[0] =~ s/\n/\t/g;	# @$out usually has 1 elt
      nok_print $current_num, $in, "not ok $current_num # in='$in'\n#    out='", $rres, "', type='", ref $res,
      "'\n# pari==='", join("\t", @$out), "'\n# re_out='$re_out'\n";
    } elsif (not $noans and defined $re_out) {
      print "ok $current_num #  run_time=$run_time, post_time=$post_time, pre_time=$pre_time\n";
      update_seen \%seen_now;
      $prev = $res;
    } elsif (not $noans and (not defined $rres or filter_res $rres ne filter_res $rout)) {
      nok_print $current_num, $in, "not ok $current_num # in='$in'\n#    out='", $rres, "', type='", ref $res,
      "'\n# expect='$rout'\n";
    } elsif ($doprint and $printout ne $rout) {
      nok_print $current_num, $in, "not ok $current_num # in='$in'\n# printout='", $printout,
      "'\n#   expect='$rout', type='", ref $res,"'\n";
    } else {
      print "ok $current_num #  run_time=$run_time, post_time=$post_time, pre_time=$pre_time\n";
      update_seen \%seen_now;
      $prev = $res;
    }
  }
}

sub process_error {
  my ($in, $out, $error) = @_;
  $current_num++;
  print("# `$in'\nok $current_num # Skipping: test producing PARI error unsupported yet (err=$error)\n");
}

sub process_definition {
  my ($name, $def) = @_;
  $current_num++;
  eval "PARI('$def');  import Math::Pari $name;";
  if ($@) {
    chomp $@;
    print("not ok $current_num # definition: `$def' error `$@'\n");
  } else {
    print("# definition $current_num: `$def'\nok $current_num\n");
  }
}

sub process_set {
  my ($in, $out) = @_;
  return process_test("setprecision($1)", 'noans', []) if $in =~ /^\\p\s*(\d+)$/;
  $current_num++;
  print("# `$in'\nok $current_num # Skipping setting test\n");
}

sub process_print {
  my ($in, @out) = @_;
  $current_num++;
  print("# $current_num: `$in'\nok $current_num # Skipping plot() - can't test it yet\n");
}

sub process_multi {
  my ($in, $out) = @_;
  my @out = @$out;
  $current_num++;
  print("# `$in'\nok $current_num # Skipping multiline\n");
}

sub my_print {
  my $nl = CORE::shift;
  @_ = map {(ref) ? (pari_print $_) : $_} @_;
  $printout .= join '', @_;
  $printout .= "\t" if $nl;
  return;
}

sub my_pprint {
  my $nl = CORE::shift;
  @_ = map {(ref) ? (pari_pprint $_) : $_} @_;
  $printout .= join '', @_;
  $printout .= "\t" if $nl;
  return;
}

sub my_texprint {
  my $nl = CORE::shift;
  @_ = map {(ref) ? (pari_texprint $_) : $_} @_;
  $printout .= join '', @_;
  $printout .= "\t" if $nl;
  return;
}

sub prec {
  setprecision($_[0]);
  print "# Setting precision to $_[0] digits.\n";
  print "ok $current_num\n" unless $_[1];
}
sub bprec {
  PARI("default(realbitprecision,$_[0])");		# setbitprecision($_[0]);
  print "# Setting bitprecision to $_[0] bits.\n";
  print "# bitprecision: res=", PARI("default(realbitprecision)"),"\n";
  print "ok $current_num\n" unless $_[1];
}
sub sprec {
  setseriesprecision($_[0]);
  print "# Setting series precision to $_[0] digits.\n";
  print "ok $current_num\n";
}

# *Need* to convert to PARI, otherwise the arithmetic will propagate
# the values to floats

sub safe_sizes { eval {plothsizes()} or PARI [1000,1000,20,20,20,20]}
