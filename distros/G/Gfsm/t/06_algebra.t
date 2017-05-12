# -*- Mode: CPerl -*-

$TEST_DIR = './t';
#use lib qw(../blib/lib ../blib/arch); $TEST_DIR = '.'; # for debugging

# load common subs
do "$TEST_DIR/common.plt"
  or die("could not load $TEST_DIR/common.plt");

plan(test => 18);

# load modules
use Gfsm;

## unopok($opname)
## unopok($opname,\%opts)
##  + %opts:
##     base=>$basename, ##-- default=$opname
##     args=>\@args,    ##-- op arguments: default: none
##     inplace=>$bool,  ##-- output fsm is input fsm
##  + $basename defaults to "$opname"
##  + unary operation test
##    - compiles fsm from "${basename}-in.tfst"
##    - calls $result = $fsm->${opname}(@{$opts->{args}});
##    - saves temporary to "${basename}-got.tfst"
##    - checks equivalence of "${basename}-got.tfst" with "${basname}-out.tfst"
sub unopok {
  my ($opname,$opts) = @_;
  $opts->{base} = $opname if (!defined($opts->{base}));
  $opts->{args} = [] if (!defined($opts->{args}));

  my $fsm = Gfsm::Automaton->new();
  $fsm->compile("$TEST_DIR/$opts->{base}-in.tfst")
    or die("could not compile '$TEST_DIR/$opts->{base}-in.tfst': $!");

  my $sub = $fsm->can($opname)
    or die("no method for op '$opname'!");

  my $out = $sub->($fsm,@{$opts->{args}});
  $out = $fsm if ($opts->{inplace});
  die("no output fsm for op '$opname'!") if (!$out);

  #$out->is_transducer(1);
  $out->print_att("$TEST_DIR/$opts->{base}-got.tfst");
  ufileok("$TEST_DIR/$opts->{base}-got.tfst", "$TEST_DIR/$opts->{base}-out.tfst");
  #unlink("$opts->{base}-got.tfst");
}

## binopok($opname)
## binopok($opname,\%opts)
##  + %opts:
##     base=>$basename, ##-- default=$opname
##     args=>\@args,        ##-- op arguments: default: none
##  + $basename defaults to "$opname"
##  + unary operation test
##    - compiles $fsm[12] from "${basename}-in-[12].tfst"
##    - calls $result = $fsm1->${opname}($fsm2,@{$opts->{args}});
##    - saves temporary to "${basename}-got.tfst"
##    - checks equivalence of "${basename}-got.tfst" with "${basname}-out.tfst"
sub binopok {
  my ($opname,$opts) = @_;
  $opts->{base} = $opname if (!defined($opts->{base}));
  $opts->{args}     = [] if (!defined($opts->{args}));

  my $fsm1 = Gfsm::Automaton->new();
  $fsm1->compile("$TEST_DIR/$opts->{base}-in-1.tfst")
    or die("could not compile '$TEST_DIR/$opts->{base}-in-1.tfst': $!");
  my $fsm2 = Gfsm::Automaton->new();
  $fsm2->compile("$TEST_DIR/$opts->{base}-in-2.tfst")
    or die("could not compile '$TEST_DIR/$opts->{base}-in-2.tfst': $!");

  my $sub = $fsm1->can($opname)
    or die("no method for binop '$opname'!");

  my $out = $sub->($fsm1,$fsm2,@{$opts->{args}})
    or die("no output fsm for binop '$opname'!");

  #$out->is_transducer(1);
  $out->print_att("$TEST_DIR/$opts->{base}-got.tfst");
  ufileok("$TEST_DIR/$opts->{base}-got.tfst", "$TEST_DIR/$opts->{base}-out.tfst");
  #unlink("$opts->{base}-got.tfst");
}

# 1..4 : closure-like
unopok('optional');
unopok('closure',{base=>'closure-plus',args=>[1]});
unopok('closure',{base=>'closure-star',args=>[0]});
unopok('n_closure',{args=>[3]});

#-- load alphabet
$abet = Gfsm::Alphabet->new();
$abet->load("$TEST_DIR/test.lab");

# +2: complement
unopok('complement');
unopok('complement',{base=>'complement-b',args=>[$abet]});

# +2 : complete
#unopok('complete');
#unopok('complete',{base=>'complete-b',args=>[$abet]});

# +1 compose
binopok('compose');

# +1
binopok('concat');

# +1
unopok('connect');

# +1
unopok('determinize');

# +1
binopok('difference');

# +1
binopok('intersect');

# +1
unopok('invert');

# +2
unopok('project',{base=>'project-lo',args=>[Gfsm::LSLower]});
unopok('project',{base=>'project-hi',args=>[Gfsm::LSUpper]});

# +1
unopok('rmepsilon');

# +1
binopok('union');

# +0
#isok("dummy:insert_automaton()");

# +0
#isok("dummy:replace()");

# +1:
unopok('renumber_states',{base=>'renumber',inplace=>1});

print "\n";


