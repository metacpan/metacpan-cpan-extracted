#!/usr/bin/perl -w

use Gfsm;
use Pod::Usage;
use Getopt::Long qw(:config no_ignore_case);
use File::Basename qw(basename);

##======================================================================
## Defaults

our $prog    = basename($0);
our $VERSION = 0.01;

our ($help,$version);

##-- options: I/O
our $outfile = '-';
our $zlevel  = -1;

##-- options: topology
our $acceptor = 0;
our $epsilon  = 1;
our $randomize_lo = 0;

our $n_states = 8; ##-- advisory only
our $n_labels = 2; ##-- including epsilon, if specified

our $w_min = 0;
our $w_max = 0;

our $d_min = 0;
our $d_max = 8;

our $n_xarcs  = 0; ##-- number of cross-arcs (non-cyclic)
our $n_carcs  = 0; ##-- number of cyclic arcs
our $n_uarcs  = 0; ##-- number of random arcs (cyclic or non-cyclic)
our $cl_min    = 1;     ##-- minimum cycle length (including cyclic arc; should be >= 1)
our $cl_max    = undef; ##-- maximum cycle length (default=$d_max+1)

our $seed = undef;
our $sort = 'none'; ##-- state-sort mode (pre -xarcs)

##======================================================================
## Command-Line
GetOptions(##-- General
	   'help|h'    => \$help,
	   'version|V' => \$version,

	   ##-- Topology
	   'seed|srand|r=i'  => \$seed,
	   'acceptor|fsa|A!' => \$acceptor,
	   'transducer|fst|T!' => sub { $acceptor=!$_[1]; },
	   'randomize-inputs|randomize-lower|ri|rl|i!' => \$randomize_lo,

	   'epsilon|eps|e!' => \$epsilon,

	   'n-labels|labels|l=i' => \$n_labels,
	   'n-states|states|q=i' => \$n_states,

	   'min-weight|wmin|w=f' => \$w_min,
	   'max-weight|wmax|W=f' => \$w_max,

	   'min-depth|dmin|d=i' => \$d_min,
	   'max-depth|dmax|D=i' => \$d_max,

	   'breadth-first-sort|bfs' => sub { $sort='bfs' },
	   'depth-first-sort|dfs'   => sub { $sort='dfs' },
	   'no-sort|nosort|ns' => sub { $sort='none' },

	   'n-xarcs|xarcs|xa|x=i' => \$n_xarcs,
	   'n-carcs|carcs|ca|c|n-cycles|ncycles=i' => \$n_carcs,
	   'n-uarcs|uarcs|ua|u|a=i' => \$n_uarcs,
	   'min-cycle-length|clmin|y=i'  => \$cl_min,
	   'max-cycle-length|clmax|Y=i'  => \$cl_max,

	   ##-- I/O
	   'output|o|F=s' => \$outfile,
	   'compress|z=i' => \$zlevel,
	  );

pod2usage({-exitval=>0, -verbose=>0}) if ($help);

if ($version) {

  print STDERR
    ("${prog} v$VERSION by Bryan Jurish <moocow\@cpan.org>\n",
    );
  exit(0);
}

##======================================================================
## Subs

##--------------------------------------------------------------
## $n = max_trie_states($n_labels, $depth_max)
sub max_trie_states {
  my ($na,$dmax) = @_;
  ##-- loop form
  ## : $n_labels==2 --> 0:1 1:3 2:7 3:15 4:31 5:63 6:127 7:255 8:511 9:1023 10:2047
  ## : $n_labels==3 --> 0:1 1:4 2:13 3:40 4:121 5:364 6:1093 7:3280 8:9841 9:29524 10:88573
  ## : $n_labels==4 --> 0:1 1:5 2:21 3:85 4:341 5:1365 6:5461 7:21845 8:87381 9:349525 10:1398101
  if (0) {
    my $nq = 0;
    foreach (0..$dmax) {
      $nq += $na**$_;
    }
    return $nq;
  }
  ##-- closed form; see e.g.:
  ##     http://mathworld.wolfram.com/Repunit.html
  ##     http://oeis.org/A000225 ($n_labels==2)
  ##     http://oeis.org/A003462 ($n_labels==3)
  ##     http://oeis.org/A002450 ($n_labels==4)
  ##     http://mathworld.wolfram.com/MersenneNumber.html ($n_labels==2)
  return ($na**($dmax+1)-1)/($na-1);
}

##======================================================================
## Main


##--------------------------------------------------------------
our ($fsm,$l_min,$q);
sub init_fsm {
  srand($seed) if (defined($seed));

  ##-- sanity checks
  my $nq_max = max_trie_states($n_labels,$d_max);
  if ($n_states > $nq_max) {
    warn("$prog: cannot generate fsm with n_states > M_{d_max+1}^(n_labels) = (n_labels^(d_max+1)-1)/(n_labels-1); setting -n-states=$nq_max\n");
    $n_states = $nq_max;
  }

  $fsm = Gfsm::Automaton->newTrie();
  $fsm->is_transducer(!$acceptor);
  $fsm->is_weighted(1);
  $fsm->semiring_type($Gfsm::SRTTropical);

  $l_min = $epsilon ? 0 : 1;
}
init_fsm();

##--------------------------------------------------------------
our $finals = {}; ##-- $qid => undef
our ($nq);
sub gen_spine {
  ##-- generate base trie
  my (@lo,@hi,$len,$q);
  while ($fsm->n_states() < $n_states) {
    $len = $d_min+int(rand(1+$d_max-$d_min));
    @lo = map {$l_min+int(rand($n_labels))} (1..$len);
    $q = $fsm->add_path(\@lo, \@hi, 0);
    $finals->{$q} = undef;
  }

  ##-- mark unsorted (avoid "smart" arc insertion)
  $fsm->sort_mode(Gfsm::ASMNone());
  $nq = $fsm->n_states();

  ##-- maybe sort
  $sort = '' if (!defined($sort));
  if ($sort eq 'bfs') {
    $fsm->statesort_bfs();
  } elsif ($sort eq 'dfs') {
    $fsm->statesort_dfs();
  }
}
gen_spine();


##--------------------------------------------------------------
## \@qpaths = qpaths($fsm);  ##-- scalar context
## (\@qpaths,$maxdepth) = qpaths($fsm); ##-- list context
##  + s.t. $qpaths->[$q] = pack('L*', $q0,$q1,...,$q)
##  + gets state "addresses"; used to generate guaranteed cyclic arcs

#*qpaths = \&qpaths_v0;
sub qpaths_v0 {
  ##-- init qpaths()
  my $fsm = shift;
  my $qpaths = [''];
  my $rfsm = $fsm->reverse();
  my $ai = Gfsm::ArcIter->new();
  my ($ri,@p,$q);
  my $dmax = 0;
  foreach $q (keys %$finals) {
    @p = ($q);
    for ($ai->open($rfsm,$q); $q != 0; $ai->open($rfsm,$q)) {
      unshift(@p,($q=$ai->target));
    }
    $dmax = $#p if ($#p >= $dmax);
    foreach $ri (1..$#p) {
      $q = $p[$ri];
      next if (defined($qpaths->[$q]));
      $qpaths->[$q] = pack('L*', @p[0..$ri]);
    }
  }
  return wantarray ? ($qpaths,$dmax) : $qpaths;
}

*qpaths = \&qpaths_v1;
sub qpaths_v1 {
  ##-- init qpaths(), using arcpaths() function
  my $fsm = shift;
  my $qpaths = [''];
  my $apaths = $fsm->arcpaths();
  my ($ap,@qp,$qi);
  my $dmax = 0;
  my $arc_ignore_size = $Gfsm::arc_size - length(pack('LL',0,0));
  foreach $ap (@$apaths) {
    #@qp = (0,map {$_->[1]} Gfsm::unpack_arcpath($ap)); ##-- [src,dst,lo,hi,w],...
    @qp = (0,unpack("(x4Lx${arc_ignore_size})*", $ap));
    pop(@qp);
    $dmax = $#qp if ($#qp >= $dmax);
    foreach $qi (1..$#qp) {
      next if (defined($qpaths->[$qp[$qi]]));
      $qpaths->[$qp[$qi]] = pack('L*', @qp[0..$qi]);
    }
  }
  return wantarray ? ($qpaths,$dmax) : $qpaths;
}


##--------------------------------------------------------------
##-- introduce cycles
sub gen_cycles {
  return if ($n_carcs <= 0);
  $cl_min = 1        if ($cl_min <= 0);
  $cl_max = $d_max+1 if (!defined($cl_max) || $cl_max<=0);
  my ($qpaths,$dmax) = qpaths($fsm);
  if ($cl_min >= ($dmax+1)) {
    warn("$prog: requested minimum cycle length $cl_min too large for spine with depth $dmax, using -clmin=".($dmax+1));
    $cl_min = $dmax+1;
  }
  my ($nc, $q,@qp,$qpi_max,$qpi_min, $r,$a);
  for ($nc=0; $nc<$n_carcs; ) {
    $q  = int(rand($nq));
    @qp = unpack('L*',$qpaths->[$q]);
    $qpi_max = @qp-$cl_min;                       ##-- potential cycle-target states r with len(r-*->q)+1 >= min_cycle_len
    $qpi_min = @qp>$cl_max ? (@qp-$cl_max) : 0;   ##-- potential cycle-target states r with len(r-*->q)+1 <= max_cycle_len
    next if ($qpi_min > $qpi_max);                ##-- potential infloop!
    $r = $qp[$qpi_min+int(rand(1+$qpi_max-$qpi_min))];
    $a = $l_min+int(rand($n_labels));
    $fsm->add_arc($q,$r, $a,$a,0);
    ++$nc;
  }
}
gen_cycles();

##--------------------------------------------------------------
##-- add non-cyclic arcs
sub gen_xarcs {
  for ($i=0; $i<$n_xarcs; ++$i) {
    $q = int(rand($nq-1));
    $r = 1 + $q + int(rand($nq-$q-1));
    $a = $l_min+int(rand($n_labels));
    $fsm->add_arc($q,$r, $a,$a, 0);
  }
}
gen_xarcs();

##--------------------------------------------------------------
##-- add arbitrary arcs
sub gen_uarcs {
  for ($i=0; $i<$n_uarcs; ++$i) {
    $q = int(rand($nq));
    $r = int(rand($nq));
    $a = $l_min+int(rand($n_labels));
    $fsm->add_arc($q,$r, $a,$a, 0);
  }
}
gen_uarcs();

##--------------------------------------------------------------
##-- generate upper arc labels
sub gen_upper_labels {
  return if ($acceptor);
  my $ai = Gfsm::ArcIter->new();
  for ($q=0; $q < $fsm->n_states(); ++$q) {
    for ($ai->open($fsm,$q); $ai->ok(); $ai->next()) {
      $ai->upper($l_min+int(rand($n_labels)));
    }
  }
}
gen_upper_labels();

##--------------------------------------------------------------
##-- generate weights
sub gen_weights {
  ($w_min,$w_max) = sort ($w_min,$w_max);
  my $w_rng = $w_max-$w_min;
  return if ($w_min==$w_max && $w_max==0);

  my $ai = Gfsm::ArcIter->new();
  for ($q=0; $q < $fsm->n_states(); ++$q) {
    $fsm->final_weight($q,$w_min+($w_rng>0 ? rand($w_rng) : 0)) if ($fsm->is_final($q));
    for ($ai->open($fsm,$q); $ai->ok(); $ai->next()) {
      $ai->weight($w_min+($w_rng>0 ? rand($w_rng) : 0));
      $ai->upper($l_min+int(rand($n_labels))) if (!$acceptor);
    }
  }
}
gen_weights();



##--------------------------------------------------------------
##-- randomize lower arc labels
sub randomize_lower_labels {
  return if (!$randomize_lo);
  my $ai = Gfsm::ArcIter->new();
  for ($q=0; $q < $fsm->n_states(); ++$q) {
    for ($ai->open($fsm,$q); $ai->ok(); $ai->next()) {
      $ai->lower($l_min+int(rand($n_labels)));
    }
  }
}
randomize_lower_labels();

#$fsm->renumber_states();
#$fsm->statesort_bfs();
#$fsm->statesort_dfs();

##-- dump
$fsm->save($outfile,$zlevel)
  or die("$prog: save failed to gfsm file '$outfile': $!");


__END__

##======================================================================
## Pods
=pod

=pod

=head1 NAME

gfsm-random-trie.perl - create a random trie-based FSM

=head1 SYNOPSIS

 gfsm-random-trie.perl [OPTIONS]

 General Options:
  -help
  -version

 Topology Options:
  -seed SEED                # random seed (default: none)
  -acceptor , -transducer   # build FSA or FST (default=-transducer)
  -epsilon  , -noepsilon    # do/don't include epsilon (zero) labels (default=-epsilon)
  -randomize-lower          # randomize lower (input) labels (default: don't)
  -n-labels=NA              # alphabet size (default=2)
  -n-states=NQ              # target number of states (default=8; output is s.t. NQ <= |Q| < NQ+DMAX)
  -min-weight=W             # minimum weight (default=0)
  -max-weight=W             # maximum weight (default=0)
  -min-depth=DMIN           # minimum spine path length (default=0)
  -max-depth=DMAX           # maximum spine path length (default=8)
  -bfs , -dfs , -nosort     # state-sort to apply before adding arcs (default:-nosort)
  -n-xarcs=N                # number of guaranteed acyclic arcs added to spine (default=0)
  -n-carcs=N                # number of guaranteed  cyclic arcs added to spine (default=0)
  -n-uarcs=N                # number of unrestricted random arcs added to spine (default=0)
  -min-cycle-length=YMIN    # minimum cycle length for guaranteed cyclic arcs (default=0)
  -max-cycle-length=YMAX    # maximum cycle length for guaranteed cyclic arcs (default=DMAX)

 I/O Options:
  -compress=ZLEVEL          # zlib compression level
  -output=GFSMFILE          # output automaton

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

Bryan Jurish E<lt>moocow@cpan.org<gt>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Bryan Jurish

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=head1 SEE ALSO

perl(1),
Gfsm(3perl)

=cut

