#!/usr/bin/perl -w

use Gfsm;
use Encode qw(encode decode);
use Pod::Usage;
use Getopt::Long qw(:config no_ignore_case);
use File::Basename qw(basename);

##======================================================================
## Defaults

our $prog    = basename($0);
our $VERSION = 0.06;

our ($help,$version);

##-- Extraction
our $outfile = '-';

## %ops: ($op => \%opspec, ..)
##  + where %opspec = ( $cost=>$cost_or_undef, (class_(lo|hi)=>$class), labs_(lo|hi)=>\@labids ),
our %ops = (
	    match  => { cost=>0, class_lo=>'<sigma>' },
	    insert => { cost=>1, class_hi=>'<sigma>' },
	    delete => { cost=>1, class_lo=>'<sigma>' },
	    subst  => { cost=>1, class_lo=>'<sigma>', class_hi=>'<sigma>', },
	    double => { cost=>undef, class_lo=>'<sigma>' },
	    undouble => { cost=>undef, class_lo=>'<sigma>' },
	    multiply => { cost=>undef, class_lo=>'<sigma>' },   ##-- iterated doubling
	    unmultiply => { cost=>undef, class_lo=>'<sigma>' }, ##-- iterated undoubling
	    exchange => { cost=>undef, class_lo=>'<sigma>', },  ##-- == "transpose"
	    toupper => { cost=>undef, class_lo=>'<sigma>', },   ##-- upper-case
	    tolower => { cost=>undef, class_lo=>'<sigma>', },   ##-- lower-case
	    ##
	    adjacent_insert_before => { cost=>undef, class_lo=>'<sigma>', class_hi=>'<sigma>' }, ##-- keyboard-adjacent insert (left)
	    adjacent_insert_after  => { cost=>undef, class_lo=>'<sigma>', class_hi=>'<sigma>' }, ##-- keyboard-adjacent insert (right)
	    adjacent_delete_before => { cost=>undef, class_lo=>'<sigma>' }, ##-- keyboard-adjacent deletion (left)
	    adjacent_delete_after  => { cost=>undef, class_lo=>'<sigma>' }, ##-- keyboard-adjacent deletion (right)
	    adjacent_subst    => { cost=>undef, class_lo=>'<sigma>', class_hi=>'<sigma>' }, ##-- keyboard-adjacent substitution
	    adjacent_exchange => { cost=>undef, class_lo=>'<sigma>', },  ##-- == "transpose"
	   );

our $numeric  = 1;
our $max_cost = undef;
our $delayed_action = undef;
our $ed_single = 0;
our $encoding = 'raw';
our $nil = [];

##-- label selection superclasses
our $scl_file = undef; ##-- default: none

##-- auxilliary rules (TAB-separated if any TABs are present on line, otherwise whitespace-separated): COST LO HI (COMMENT?)
our $aux_file  = undef;

##======================================================================
## Command-Line
GetOptions(##-- General
	   'help|h'    => \$help,
	   'version|V' => \$version,

	   ##-- Costs
	   'cost-match|match|m=s'   => sub { $ops{match}{cost}=$_[1] },
	   'cost-insert|insert|i=s' => sub { $ops{insert}{cost}=$_[1] },
	   'cost-delete|delete|d=s' => sub { $ops{delete}{cost}=$_[1] },
	   'cost-substitute|substitute|subst|s=s' => sub { $ops{subst}{cost}=$_[1] },
	   'cost-double|double|2=s' => sub { $ops{double}{cost}=$_[1] },
	   'cost-undouble|undouble|1=s' => sub { $ops{undouble}{cost}=$_[1] },
	   'cost-multiply|multiply|cost-double-n|double-n|2n=s' => sub { $ops{multiply}{cost}=$_[1] },
	   'cost-unmultiply|unmultiply|cost-undouble-n|undouble-n|1n=s' => sub { $ops{unmultiply}{cost}=$_[1] },
	   'cost-exchange|exchange|x|cost-transpose|transpose|t=s' => sub { $ops{exchange}{cost}=$_[1] },
	   'cost-toupper|toupper|upper|u=s' => sub { $ops{toupper}{cost}=$_[1] },
	   'cost-tolower|tolower|lower|l=s' => sub { $ops{tolower}{cost}=$_[1] },
	   'cost-case|case|c=s' => sub { $ops{tolower}{cost}=$ops{toupper}{cost}=$_[1] },
	   ##
	   'cost-adjacent-insert-before|adjacent-insert-before|ainsert-before|aib=s' => sub { $ops{adjacent_insert_before}{cost}=$_[1] },
	   'cost-adjacent-insert-after|adjacent-insert-after|ainsert-after|aia=s'    => sub { $ops{adjacent_insert_after}{cost}=$_[1] },
	   'cost-adjacent-insert|adjacent-insert|ainsert|ai=s' => sub { $ops{adjacent_insert_before}{cost}=$ops{adjacent_insert_after}{cost}=$_[1] },
	   'cost-adjacent-delete-before|adjacent-delete-before|adelete-before|adb=s' => sub { $ops{adjacent_delete_before}{cost}=$_[1] },
	   'cost-adjacent-delete-after|adjacent-delete-after|adelete-after|ada=s' => sub { $ops{adjacent_delete_after}{cost}=$_[1] },
	   'cost-adjacent-delete|adjacent-delete|adelete|ad=s' => sub { $ops{adjacent_delete_before}{cost}=$ops{adjacent_delete_after}{cost}=$_[1] },
	   'cost-adjacent-substitute|adjacent-substitute|asubstitute|asubst|as=s' => sub { $ops{adjacent_subst}{cost}=$_[1] },
	   'cost-adjacent-exchange|adjacent-exchange|aexchange|ax=s' => sub { $ops{adjacent_exchange}{cost}=$_[1] },

	   ##-- Editor Topology
	   'single-operation|single-op|single|so!' => \$ed_single,
	   'multiple-operation|multi-op|multi|mo!'  => sub { $ed_single=!$_[1] },
	   'max-cost|M=s'          => \$max_cost,
	   'delayed-action|delay|da'     => \$delayed_action,
	   'no-delayed-action|no-delayed|nodelay|immediate-action|immediate|ia' => sub { $delayed_action=0; },
	   'aux-rules-file|arf|aux-rules|ar|rules-file|rf|A=s' => \$aux_file, ##-- auxilliary rules
	   'no-aux-rules|nar|no-aux|na|nA' => sub { $aux_file=undef },

	   ##-- Which labels?
	   'adjacent-pairs-file|apf|adjacent-pairs|ap|pairs-file|pf|P=s' => \$pairs_file, ##-- adjacency operations only on these symbol-pairs (symmetric)
	   'superclasses|super|scl|S=s' => \$scl_file,
	   'class-sigma|sigma|C=s' => sub { $_->{class_hi}=$_->{class_lo}=$_[1] foreach (values %ops); },
	   'class-match|cm=s'=> \$ops{match}{class_lo},
	   'class-insert|ci=s' => sub { $ops{insert}{class_hi}=$ops{adjacent_insert_before}{class_hi}=$ops{adjacent_insert_after}{class_hi}=$_[1] },
	   'class-delete|cd=s' => sub { $ops{delete}{class_lo}=$ops{adjacent_delete_before}{class_lo}=$ops{adjacent_delete_after}{class_lo}=$_[1] },
	   'class-subst-lo|csl=s' => sub { $ops{subst}{class_lo}=$ops{adjacent_subst}{class_lo}=$_[1] },
	   'class-subst-hi|csh=s' => sub { $ops{subst}{class_hi}=$ops{adjacent_subst}{class_hi}=$_[1] },
	   'class-subst|cs=s' => sub { $ops{subst}{class_lo}=$ops{subst}{class_hi}=$ops{adjacent_subst}{class_lo}=$ops{adjacent_subst}{class_hi}=$_[1] },
	   'class-double|c2=s' => \$ops{double}{class_lo},
	   'class-undouble|c1=s' => \$ops{undouble}{class_lo},
	   'class-multiply|class-double-n|c2n=s' => \$ops{multiply}{class_lo},
	   'class-unmultiply|class-undouble-n|c1n=s' => \$ops{unmultiply}{class_lo},
	   'class-exchange|cx=s' => sub { $ops{exchange}{class_lo}=$ops{adjacent_exchange}{class_lo}=$_[1] },
	   'class-toupper|class-upper|cu=s' => sub { $ops{toupper}{class_lo}=$_[1] },
	   'class-tolower|class-lower|cl=s' => sub { $ops{tolower}{class_lo}=$_[1] },
	   'class-case|cc=s' => sub { $ops{tolower}{class_lo}=$ops{toupper}{class_lo}=$_[1] },

	   ##-- Which ops?
	   'no-match|nm' => sub { delete $ops{match}{cost} },
	   'no-substitute|no-subst|ns' => sub { delete $ops{subst}{cost} },
	   'no-insert|no-ins|ni'       => sub { delete $ops{insert}{cost} },
	   'no-delete|no-del|nd'       => sub { delete $ops{delete}{cost} },
	   'no-levenshtein|no-lev|nL'  => sub { delete $_->{cost} foreach @ops{qw(match subst insert delete)} },
	   'no-double|no-dbl|n2'       => sub { delete $ops{double}{cost} },
	   'no-undouble|no-undbl|n1'   => sub { delete $ops{undouble}{cost} },
	   'no-multiply|no-double-n|no-dbl-n|n2n'         => sub { delete $ops{multiply}{cost} },
	   'no-unmultiply|no-undouble-n|no-undbl-n|n1n'   => sub { delete $ops{unmultiply}{cost} },
	   'no-exchange|no-xc|nx|no-transpose|no-tr|nt'   => sub { delete $ops{exchange}{cost} },
	   'no-toupper|no-upper|no-u|nu' => sub { delete $ops{toupper}{cost} },
	   'no-tolower|no-lower|no-l|nl' => sub { delete $ops{tolower}{cost} },
	   'no-case|nc' => sub { delete $ops{tolower}{cost}; delete $ops{toupper}{cost} },
	   ##
	   'no-adjacent-insert-before|no-ainsert-before|naib' => sub { delete $ops{adjacent_insert_before}{cost} },
	   'no-adjacent-insert-after|no-ainsert-after|naia' => sub { delete $ops{adjacent_insert_after}{cost} },
	   'no-adjacent-insert|no-ainsert|nai' => sub { delete $_->{cost} foreach @ops{qw(adjacent_insert_before adjacent_insert_after)} },
	   'no-adjacent-delete-before|no-adelete-before|nadb' => sub { delete $ops{adjacent_delete_before}{cost} },
	   'no-adjacent-delete-after|no-adelete-after|nada' => sub { delete $ops{adjacent_delete_after}{cost} },
	   'no-adjacent-delete|no-adelete|nad' => sub { delete $_->{cost} foreach @ops{qw(adjacent_delete_before adjacent_delete_after)} },
	   'no-adjacent-substitute|no-asubst|nas' => sub { delete $ops{adjacent_subst}{cost} },

	   ##-- I/O
	   'encoding|e=s' => \$encoding,
	   'output|o|F=s' => \$outfile,
	  );
$encoding = undef if ($encoding =~ /^(?:raw|bin)$/i);
pod2usage({-exitval=>0, -verbose=>0}) if ($help);

if ($version) {
  print STDERR
    ("${prog} v$VERSION by Bryan Jurish <moocow\@cpan.org>\n",
    );
  exit(0);
}

##======================================================================
## Subs: load superclass labels
our %scl = qw(); ## ($classname => \@class_labids, ...)
sub load_scl_file {
  my $file = shift;
  open(my $fh,"<$file") || die("$0: open failed for .scl file '$file': $!");
  binmode($fh,":encoding($encoding)") if ($encoding);
  my ($class,$labid);
  while (<$fh>) {
    chomp;
    ($class,$labid) = split(/\s+/,$_);
    next if (!defined($class) || !defined($labid));
    push(@{$scl{$class}},$labid);
  }
  close($fh);
  return \%scl;
}

##======================================================================
## Subs: load keyboard-adjacent pairs
our %pairs = qw(); ## ("$lab1 $lab2" => undef, ...)
sub load_pairs_file {
  my ($file,$sym2id,$id2sym) = @_;
  open(my $fh,"<$file") || die("$0: open failed for adjacent-pairs file '$file': $!");
  binmode($fh,":encoding($encoding)") if ($encoding);
  my ($c1,$c2, $l1,$l2);
  while (<$fh>) {
    chomp;
    next if (/^\s*$/ || /^%%/ || /^#/);
    ($c1,$c2) = split(/\s+/,$_,2);
    ($l1,$l2) = @$sym2id{($c1,$c2)};
    next if (!defined($l1) || !defined($l2));
    @pairs{"$l1 $l2","$l2 $l1"} = qw();
  }
  close($fh);
  return \%pairs;
}

##======================================================================
## Subs: load auxilliary rules
our @aux = qw(); ##-- ($rule1={cost=>$cost, lo=>\@labs, hi=>\@labs, comment=>$comment}, ...)
sub load_aux_file {
  my ($file,$sym2id) = @_;
  open(my $fh,"<$file") || die("$0: open failed for auxilliary rules-file '$file': $!");
  binmode($fh,":encoding($encoding)") if ($encoding);
  my ($cost,$lo_str,$hi_str,$lo_labs,$hi_labs,$comment);
  while (<$fh>) {
    chomp;
    next if (/^\s*$/ || /^\s*\#/);
    ($cost,$lo_str,$hi_str,$comment) = /\t/ ? split(/\t/,$_,4) : split(' ',$_,4);
    $lo_labs = parseAuxString($lo_str,$sym2id,"auxilliary rules-file '$file' line $.");
    $hi_labs = parseAuxString($hi_str,$sym2id,"auxilliary rules-file '$file' line $.");
    push(@aux, {cost=>$cost, lo=>$lo_labs, hi=>$hi_labs, comment=>$comment});
  }
  close($fh);
  return \@aux;
}

##-- \@labs = parseAuxString($str,\%sym2id, $src)
sub parseAuxString {
  my ($str,$sym2id,$src) = @_;
  my @syms = map {s/^\[(.*)\]$/$1/; s/\\(.)/$1/g; $_} ($str =~ m{(?:\\.|\[(?:\\.|[^\]])+\]|.)}g);
  my ($lab);
  my @labs = map {
    if (!defined($lab=$sym2id->{$_})) {
      warn("$prog: ignoring unknown symbol `$_' in ".($src//'parseAuxString()'));
      qw();
    } else {
      $lab;
    }
  } @syms;
  return \@labs;
}


##======================================================================
## Main
our $labfile = @ARGV ? shift(@ARGV) : '-';
our $abet = Gfsm::Alphabet->new();
$abet->load($labfile) or die("$prog: load failed for alphabet file '$labfile': $!");

##-- load labels
our $string2id =$abet->asHash;
our $id2string =$abet->asArray;
if ($encoding) {
  $string2id = { map {(decode($encoding,$_)=>$string2id->{$_})} keys %$string2id };
  $_ = decode($encoding,$_) foreach (@$id2string);
}

##-- load superclass labels
if (defined($scl_file)) {
  load_scl_file($scl_file);
} else {
  $scl{'<sigma>'} = [grep {$_!=0} values(%$string2id)];
}

##-- load pairs
if (defined($pairs_file)) {
  load_pairs_file($pairs_file, $string2id,$id2string);
}

##-- load aux rules
if (defined($aux_file)) {
  load_aux_file($aux_file, $string2id);
}

##-- get operand label-id subsets, populate $ops{$OP}{labs_(lo|hi)}
while (($opname,$op)=each(%ops)) {
  next if (!defined($op)); ##-- ignore
  foreach $side (qw(lo hi)) {
    next if (!defined($class=$op->{"class_$side"}));
    die("$0: no superclass '$class' for operation '$opname' side '$side'") if (!defined($labs=$scl{$class}));
    $op->{"labs_$side"} = $labs;
  }
}

##======================================================================
## subs: populate state

## %cost2q = ( $cost=>$qid, ... )
our %cost2q = qw();

## $qid = key2state($key,$is_final)
##  + simple wrapper for $cost2q{$key}=get_or_insert_state();
sub key2state {
  my ($key,$is_final) = @_;
  return $cost2q{$key} if (defined($cost2q{$key}));
  our ($fsm);
  my $q = $cost2q{$key} = $fsm->add_state;
  $fsm->final_weight($q,0) if ($is_final);
  return $q;
}

## $qid = cost2state($cost)
## $qid = cost2state($cost,$IS_DELAYED)
##  + get or insert target state for cost $cost
sub cost2state {
  my ($cost,$delayed) = @_;
  my $key = (
	     ((defined($max_cost) || $delayed) ? $cost : 'no_max')
	     .
	     ($delayed ? ':DELAYED' : '')
	    );
  return $cost2q{$key} if (defined($cost2q{$key}));
  return undef if (defined($max_cost) && $cost > $max_cost);
  return ($ed_single ? 1 : 0) if (!defined($max_cost) && !$delayed);
  return key2state($key, !$delayed);
}

## populate_queue: ($qid=>$cost_at_qid, ...)
our %populate_queue = qw();

## %delayed_arcs_in  = ("${q_src} --${lo}:eps--> ${q_del} <${cost}>"=> undef)
##  + s.t. there exists an arc ${q_src} --${lo}:eps--> ${q_del} <$cost>
our %delayed_arcs_in  = qw();

## %delayed_arcs_out = ("${q_del} --${hi}:eps--> ${q_dst} <0>" => undef)
##  + s.t. there exists an arc ${q_del} --eps:${hi}--> ${q_dst} <0>
our %delayed_arcs_out = qw();

## undef = add_editor_path($fsm, $qid_src, $qid_dst, $lo, $hi, $cost, $FORCE)
##  + add a path in $fsm from $qid_src to $qid_dst on labels ($lo,$hi) with weight $cost
##  + for immediate-action editors (option '-no-delayed-action') or $FORCE true, this is equivalend to $fsm->add_arc(@_)
sub add_editor_path {
  my ($fsm,$q_src,$q_dst,$lo,$hi,$cost, $force) = @_;
  ##-- $force default: check for immediate action or match-operations
  $force = (!$delayed_action || $lo==$hi || $cost==0) if (!defined($force));
  ##
  ##-- force?
  if ($force) {
    $fsm->add_arc($q_src,$q_dst,$lo,$hi,$cost);
    return;
  }
  ##
  ##-- delayed action (insert): get intermediate state
  my $q_del = cost2state($cost,1);
  #  if (!exists($delayed_arcs_in{"${q_src} --${lo}:eps--> ${q_del} <$cost>"})) {
  #    $delayed_arcs_in{"${q_src} --${lo}:eps--> ${q_del} <$cost>"} = undef;
  #    $fsm->add_arc($q_src, $q_del, $lo,0, $cost);
  #  }
  #  if (!exists($delayed_arcs_out{"${q_del} --eps:${hi}--> ${q_dst} <0>"})) {
  #    $delayed_arcs_out{"${q_del} --eps:${hi}--> ${q_dst} <0>"} = undef;
  #    $fsm->add_arc($q_del, $q_dst, 0,$hi, 0);
  #  }
  if (!exists($delayed_arcs_in{"${q_src} --eps:eps--> ${q_del} <$cost>"})) {
    $delayed_arcs_in{"${q_src} --eps:eps--> ${q_del} <$cost>"} = undef;
    $fsm->add_arc($q_src, $q_del, 0,0, $cost);
  }
  if (!exists($delayed_arcs_out{"${q_del} --${lo}:${hi}--> ${q_dst} <0>"})) {
    $delayed_arcs_out{"${q_del} --${lo}:${hi}--> ${q_dst} <0>"} = undef;
    $fsm->add_arc($q_del, $q_dst, $lo,$hi, 0);
  }
}


## undef = populate_state($fsm,$qid,$accumulated_cost)
sub populate_state {
  my ($fsm,$qid,$cost_this) = @_;
  my ($op,$lo,$hi, $q_nxt, $cost_nxt);

  ##-- populate: match
  if (defined($op=$ops{match}) && defined($op->{cost})) {
    $cost_nxt = $cost_this + $op->{cost};
    foreach $lo (@{$op->{labs_lo}}) {
      if (defined($q_nxt = cost2state($cost_nxt))) {
	add_editor_path($fsm, $qid, $q_nxt, $lo,$lo, $op->{cost});
	$populate_queue{$q_nxt}=$cost_nxt;
      }
    }
  }

  ##-- populate: insert
  if (defined($op=$ops{insert}) && defined($op->{cost})) {
    $cost_nxt = $cost_this + $op->{cost};
    foreach $hi (@{$op->{labs_hi}}) {
      if (defined($q_nxt = cost2state($cost_nxt))) {
	add_editor_path($fsm, $qid, $q_nxt, 0,$hi, $op->{cost});
	$populate_queue{$q_nxt}=$cost_nxt;
      }
    }
  }

  ##-- populate: delete
  if (defined($op=$ops{delete}) && defined($op->{cost})) {
    $cost_nxt = $cost_this + $op->{cost};
    foreach $lo (@{$op->{labs_lo}}) {
      if (defined($q_nxt = cost2state($cost_nxt))) {
	add_editor_path($fsm, $qid, $q_nxt, $lo,0, $op->{cost});
	$populate_queue{$q_nxt}=$cost_nxt;
      }
    }
  }

  ##-- populate: substitute
  if (defined($op=$ops{subst}) && defined($op->{cost})) {
    $cost_nxt = $cost_this + $op->{cost};
    foreach $lo (@{$op->{labs_lo}}) {
      foreach $hi (@{$op->{labs_hi}}) {
	next if ($hi==$lo);
	if (defined($q_nxt = cost2state($cost_nxt))) {
	  add_editor_path($fsm, $qid, $q_nxt, $lo,$hi, $op->{cost});
	  $populate_queue{$q_nxt}=$cost_nxt;
	}
      }
    }
  }

  ##-- populate: exchange (transpose)
  if (defined($op=$ops{exchange}) && defined($op->{cost})) {
    $cost_nxt = $cost_this + $op->{cost};
    foreach $lo1 (@{$op->{labs_lo}}) {
      foreach $lo2 (@{$op->{labs_lo}}) {
	next if ($lo1==$lo2);
	if (defined($q_nxt = cost2state($cost_nxt))) {
	  $qid1 = key2state("EXCHANGE:q=$qid,lo1=$lo1,lo2=$lo2",0);
	  add_editor_path($fsm, $qid,  $qid1,  $lo1,$lo2, $op->{cost}, undef);
	  add_editor_path($fsm, $qid1, $q_nxt, $lo2,$lo1, 0,           1);
	  $populate_queue{$q_nxt}=$cost_nxt;
	}
      }
    }
  }

  ##-- populate: double
  if (defined($op=$ops{double}) && defined($op->{cost})) {
    $cost_nxt = $cost_this + $op->{cost};
    foreach $lo (@{$op->{labs_lo}}) {
      if (defined($q_nxt = cost2state($cost_nxt))) {
	$qid1 = key2state("DOUBLE:q=$qid,lo=$lo",0);
	add_editor_path($fsm, $qid,  $qid1,  $lo,$lo, $op->{cost}, undef);
	add_editor_path($fsm, $qid1, $q_nxt,   0,$lo, 0,           1);
	$populate_queue{$q_nxt}=$cost_nxt;
      }
    }
  }

  ##-- populate: undouble
  if (defined($op=$ops{undouble}) && defined($op->{cost})) {
    $cost_nxt = $cost_this + $op->{cost};
    foreach $lo (@{$op->{labs_lo}}) {
      if (defined($q_nxt = cost2state($cost_nxt))) {
	$qid1 = key2state("UNDOUBLE:q=$qid,lo=$lo",0);
	add_editor_path($fsm, $qid,  $qid1,  $lo,$lo, $op->{cost}, undef);
	add_editor_path($fsm, $qid1, $q_nxt, $lo,0,   0,           1);
	$populate_queue{$q_nxt}=$cost_nxt;
      }
    }
  }

  ##-- populate: multiply
  if (defined($op=$ops{multiply}) && defined($op->{cost})) {
    $cost_nxt = $cost_this + $op->{cost};
    foreach $lo (@{$op->{labs_lo}}) {
      if (defined($q_nxt = cost2state($cost_nxt))) {
	$qid1 = key2state("MULTIPLY:q=$qid,lo=$lo",0);
	add_editor_path($fsm, $qid,  $qid1,  $lo,$lo, $op->{cost}, undef);
	add_editor_path($fsm, $qid1, $qid1,    0,$lo, 0,           1);
	add_editor_path($fsm, $qid1, $q_nxt,   0,$lo, 0,           1);
	$populate_queue{$q_nxt}=$cost_nxt;
      }
    }
  }

  ##-- populate: unmultiply
  if (defined($op=$ops{unmultiply}) && defined($op->{cost})) {
    $cost_nxt = $cost_this + $op->{cost};
    foreach $lo (@{$op->{labs_lo}}) {
      if (defined($q_nxt = cost2state($cost_nxt))) {
	$qid1 = key2state("UNMULTIPLY:q=$qid,lo=$lo",0);
	add_editor_path($fsm, $qid,  $qid1,  $lo,$lo, $op->{cost}, undef);
	add_editor_path($fsm, $qid1, $qid1,  $lo,0,   0,           1);
	add_editor_path($fsm, $qid1, $q_nxt, $lo,0,   0,           1);
	$populate_queue{$q_nxt}=$cost_nxt;
      }
    }
  }

  ##-- populate: toupper
  my ($lo_s,$hi_s);
  if (defined($op=$ops{toupper}) && defined($op->{cost})) {
    $cost_nxt = $cost_this + $op->{cost};
    foreach $lo (@{$op->{labs_lo}}) {
      next if (!defined($lo_s = $id2string->[$lo]) || ($hi_s=uc($lo_s)) eq $lo_s
	       ||
	       !defined($hi   = $string2id->{$hi_s}));
      if (defined($q_nxt = cost2state($cost_nxt))) {
	add_editor_path($fsm, $qid,  $q_nxt,  $lo,$hi, $op->{cost}, undef);
	$populate_queue{$q_nxt}=$cost_nxt;
      }
    }
  }

  ##-- populate: tolower
  if (defined($op=$ops{tolower}) && defined($op->{cost})) {
    $cost_nxt = $cost_this + $op->{cost};
    foreach $lo (@{$op->{labs_lo}}) {
      next if (!defined($lo_s = $id2string->[$lo]) || ($hi_s=uc($lo_s)) eq $lo_s
	       ||
	       !defined($hi   = $string2id->{$hi_s}));
      if (defined($q_nxt = cost2state($cost_nxt))) {
	add_editor_path($fsm, $qid,  $q_nxt,  $lo,$hi, $op->{cost}, undef);
	$populate_queue{$q_nxt}=$cost_nxt;
      }
    }
  }

  ##-- populate: adjacency-sensitive operations
  if (%pairs) {

    ##-- populate: adjacent insert before
    if (defined($op=$ops{adjacent_insert_before}) && defined($op->{cost})) {
      $cost_nxt = $cost_this + $op->{cost};
      foreach $lo (@{$op->{labs_lo}}) {
	foreach $hi (@{$op->{labs_hi}}) {
	  next if (!exists $pairs{"$lo $hi"});
	  if (defined($q_nxt = cost2state($cost_nxt))) {
	    $qid1 = key2state("ADJACENT_INSERT_BEFORE:q=$qid,lo=$lo",0);
	    add_editor_path($fsm, $qid,  $qid1,    0,$hi,  $op->{cost}, undef);
	    add_editor_path($fsm, $qid1, $q_nxt, $lo,$lo,            0, 1);
	    $populate_queue{$q_nxt}=$cost_nxt;
	  }
	}
      }
    }

    ##-- populate: adjacent insert after
    if (defined($op=$ops{adjacent_insert_after}) && defined($op->{cost})) {
      $cost_nxt = $cost_this + $op->{cost};
      foreach $lo (@{$op->{labs_lo}}) {
	foreach $hi (@{$op->{labs_hi}}) {
	  next if (!exists $pairs{"$lo $hi"});
	  if (defined($q_nxt = cost2state($cost_nxt))) {
	    $qid1 = key2state("ADJACENT_INSERT_AFTER:q=$qid,lo=$lo",0);
	    add_editor_path($fsm, $qid,  $qid1,  $lo,$lo,    $op->{cost}, undef);
	    add_editor_path($fsm, $qid1, $q_nxt,   0,$hi,              0, 1);
	    $populate_queue{$q_nxt}=$cost_nxt;
	  }
	}
      }
    }

    ##-- populate: adjacent delete before
    if (defined($op=$ops{adjacent_delete_before}) && defined($op->{cost})) {
      $cost_nxt = $cost_this + $op->{cost};
      foreach $lo1 (@{$op->{labs_lo}}) {    ##-- $lo1: to be deleted
	foreach $lo2 (@{$op->{labs_lo}}) {  ##-- $lo2: context
	  next if (!exists $pairs{"$lo1 $lo2"});
	  if (defined($q_nxt = cost2state($cost_nxt))) {
	    $qid1 = key2state("ADJACENT_DELETE_BEFORE:q=$qid,lo2=$lo2",0);
	    add_editor_path($fsm, $qid,  $qid1,  $lo1,0,    $op->{cost}, undef);
	    add_editor_path($fsm, $qid1, $q_nxt, $lo2,$lo2,           0, 1);
	    $populate_queue{$q_nxt}=$cost_nxt;
	  }
	}
      }
    }

    ##-- populate: adjacent delete after
    if (defined($op=$ops{adjacent_delete_after}) && defined($op->{cost})) {
      $cost_nxt = $cost_this + $op->{cost};
      foreach $lo1 (@{$op->{labs_lo}}) {    ##-- $lo1: to be deleted
	foreach $lo2 (@{$op->{labs_lo}}) {  ##-- $lo2: context
	  next if (!exists $pairs{"$lo1 $lo2"});
	  if (defined($q_nxt = cost2state($cost_nxt))) {
	    $qid1 = key2state("ADJACENT_DELETE_AFTER:q=$qid,lo2=$lo2",0);
	    add_editor_path($fsm, $qid,  $qid1,  $lo2,$lo2,    $op->{cost}, undef);
	    add_editor_path($fsm, $qid1, $q_nxt, $lo1,0,                 0, 1);
	    $populate_queue{$q_nxt}=$cost_nxt;
	  }
	}
      }
    }

    ##-- populate: adjacent substitute
    if (defined($op=$ops{adjacent_subst}) && defined($op->{cost})) {
      $cost_nxt = $cost_this + $op->{cost};
      foreach $lo (@{$op->{labs_lo}}) {
	foreach $hi (@{$op->{labs_hi}}) {
	  next if ($lo==$hi || !exists $pairs{"$lo $hi"});
	  if (defined($q_nxt = cost2state($cost_nxt))) {
	    add_editor_path($fsm, $qid, $q_nxt, $lo,$hi, $op->{cost});
	    $populate_queue{$q_nxt}=$cost_nxt;
	  }
	}
      }
    }

    ##-- populate: adjacent exchange (transpose)
    if (defined($op=$ops{adjacent_exchange}) && defined($op->{cost})) {
      $cost_nxt = $cost_this + $op->{cost};
      foreach $lo1 (@{$op->{labs_lo}}) {
	foreach $lo2 (@{$op->{labs_lo}}) {
	  next if ($lo1==$lo2 || !exists $pairs{"$lo1 $lo2"});
	  if (defined($q_nxt = cost2state($cost_nxt))) {
	    $qid1 = key2state("EXCHANGE:q=$qid,lo1=$lo1,lo2=$lo2",0);
	    add_editor_path($fsm, $qid,  $qid1,  $lo1,$lo2, $op->{cost}, undef);
	    add_editor_path($fsm, $qid1, $q_nxt, $lo2,$lo1, 0,           1);
	    $populate_queue{$q_nxt}=$cost_nxt;
	  }
	}
      }
    }
  } ##-- END adjacency-sensitive ops

  ##-- populate: aux rules
  foreach my $auxi (0..$#aux) {
    $op       = $aux[$auxi];
    $cost_nxt = $cost_this + $op->{cost};
    if (defined($q_nxt = cost2state($cost_nxt))) {
      my @arcs = map { [$op->{lo}[$_]//0,$op->{hi}[$_]//0] } (0..($#{$op->{lo}} > $#{$op->{hi}} ? $#{$op->{lo}} : $#{$op->{hi}}));
      my $qcur = $qid;
      foreach my $arci (0..$#arcs) {
	($lo,$hi) = @{$arcs[$arci]};
	$qid1     = ($arci==$#arcs ? $q_nxt : key2state("AUX[$auxi]:q=$qid,lo=>$lo,hi=>$hi",0));
	add_editor_path($fsm, $qcur, $qid1, $lo,$hi, ($arci==0 ? ($op->{cost},undef) : (0,1)));
	$qcur     = $qid1;
      }
      $populate_queue{$q_nxt}=$cost_nxt;
    }
  }

}


##======================================================================
## Create FSM
our $fsm = Gfsm::Automaton->new();
$fsm->is_transducer(1);
$fsm->is_weighted(1);
$fsm->semiring_type($Gfsm::SRTTropical);

our $q0 = $fsm->ensure_state(0);
our $qF = $ed_single ? $fsm->ensure_state(1) : $q0;
$fsm->root($q0);
$fsm->final_weight($qF,0);
%populate_queue = ($q0=>0);
%cost2q = (0=>$q0);

our %q_done = $ed_single ? ($qF=>1) : qw();

while (grep {!exists($q_done{$_})} keys(%populate_queue)) {
  $q = (grep {!exists($q_done{$_})} keys(%populate_queue))[0];
  populate_state($fsm,$q,$populate_queue{$q});
  $q_done{$q} = 1;
  last if ($ed_single);
}

##-- save
$fsm->save($outfile)
  or die("$prog: save failed to gfsm file '$outfile': $!");


__END__

##======================================================================
## Pods
=pod

=head1 NAME

gfsm-make-editor.perl - make a Damerau/Levenshtein style editor FST

=head1 SYNOPSIS

 gfsm-make-editor.perl [OPTIONS] LABELS_FILE

 General Options:
  -help
  -version

 Cost Options:
  -m  , -cost-match  COST         # default=0
  -i  , -cost-insert COST         # default=1
  -d  , -cost-delete COST         # default=1
  -s  , -cost-subst  COST         # default=1
  -x  , -cost-exchange   COST     # default=none
  -2  , -cost-double     COST     # default=none
  -1  , -cost-undouble   COST     # default=none
  -2n , -cost-multiply   COST     # default=none
  -1n , -cost-unmultiply COST     # default=none
  -u  , -cost-toupper COST        # default=none
  -l  , -cost-tolower COST        # default=none
  -c  , -cost-case    COST        # alias for -u=COST -l=COST

 Adjacency-sensitive cost options (with -P PAIRSFILE):
  -aib, -cost-adjacent-insert-before COST	# default=none
  -aia, -cost-adjacent-insert-after  COST	# default=none
  -adb, -cost-adjacent-delete-before COST	# default=none
  -ada, -cost-adjacent-delete-after  COST	# default=none
  -ai , -cost-adjacent-insert        COST	# alias for -aib=COST -aia=COST
  -ad , -cost-adjacent-delete        COST	# alias for -adb=COST -ada=COST
  -as , -cost-adjacent-substitute    COST	# default=none
  -ax , -cost-adjacent-exchange      COST	# default=none

 Editor Topology Options:
  -so , -single / -mo , -multi    # create a single-/multi-operation editor (default: multi-operation)
  -M  , -max-cost COST            # maximum path cost (default: none)
  -da , -delayed-action           # use weighted epsilon moves to delay insert & substitute hypotheses
  -ia , -immediate-action         # don't delay non-match hypotheses (default)
  -A  , -aux-rules AUXFILE        # auxilliary rules (COST LO_STR HI_STR COMMENT?)

 Operation Selection Options:
  -nm , -no-match                 # don't generate match arcs (default:do)
  -ni , -no-insert                # don't generate insertion arcs (default:do)
  -nd , -no-delete                # don't generate deletion arcs (default:do
  -ns , -no-subst                 # don't generate substitution arcs (default:do)
  -nL , -no-levenshtein		  # alias for -nm -ni -nd -ns
  -nx , -no-exchange              # don't generate exchange arcs (default:don't)
  -n2 , -no-double                # don't generate label-doubling arcs (default:don't)
  -n1 , -no-undouble              # don't generate label-undoubling arcs (default:don't)
  -n2n, -no-multiply              # don't generate label-multiplying arcs (default:don't)
  -n1n, -no-unmultiply            # don't generate label-unmultiplying arcs (default:don't)
  -nu , -no-toupper               # don't generate upper-casing arcs (default:don't)
  -nl , -no-tolower               # don't generate lower-casing arcs (default:don't)
  -nc , -no-case                  # alias for -nu -nl

 Operand Selection Options:
  -P  , -adjacent-pairs PAIRSFILE # load adjacent pairs from PAIRSFILE (default: none)
  -S  , -superclasses   SCLFILE   # load lextools(1) superclass labels from SCLFILE
  -C  , -class-sigma      CLASS   # default operaand superclass (default: '<sigma>')
  -cm , -class-match      CLASS   # superclass for match input&output
  -ci , -class-insert     CLASS   # superclass for insert output
  -cd , -class-delete     CLASS   # superclass for delete input
  -csl, -class-subst-lo   CLASS   # superclass for subst input
  -csh, -class-subst-hi   CLASS   # superclass for subst output
  -cs , -class-subst      CLASS   # superclass for subst input&output; aliases '-csl=CLASS -csh=CLASS'
  -cx , -class-exchange   CLASS   # superclass for exchange input&output
  -c2 , -class-double     CLASS   # superclass for double input&output
  -c1 , -class-undouble   CLASS   # superclass for undouble input&output
  -c2n, -class-multiply   CLASS   # superclass for multiply input&output
  -c1n, -class-unmultiply CLASS   # superclass for unmultiply input&output
  -cu , -class-toupper    CLASS   # superclass for upper-casing input
  -cl , -class-tolower    CLASS   # superclass for lower-casing input
  -cc , -class-case       CLASS   # alias for -cu=CLASS -cl=CLASS

 I/O Options:
  -e  , -encoding ENCODING        # specify label-file encoding (default=utf8)
  -o  , -output GFSMFILE          # specify output automaton (default=STDOUT)

=cut

##==============================================================================
## Description
##==============================================================================
=pod

=head1 DESCRIPTION

Not yet written.

=cut

##======================================================================
## Footer
##======================================================================

=pod

=head1 ACKNOWLEDGEMENTS

Perl by Larry Wall.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-2015 by Bryan Jurish

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

perl(1),
Gfsm(3perl)

=cut

