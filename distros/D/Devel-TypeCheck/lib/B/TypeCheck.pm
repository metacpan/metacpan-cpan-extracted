package B::TypeCheck;

use strict;
use B;
use B::Asmdata qw(@specialsv_name);
use Carp;
use Scalar::Util qw(blessed);
use English;
require 'opnames.ph';

# Base of type checking
use Devel::TypeCheck::Type;
use Devel::TypeCheck::Util;

# Include branch types
use Devel::TypeCheck::Type::Mu;
use Devel::TypeCheck::Type::Eta;
use Devel::TypeCheck::Type::Kappa;
use Devel::TypeCheck::Type::Nu;
use Devel::TypeCheck::Type::Rho;
use Devel::TypeCheck::Type::Omicron;
use Devel::TypeCheck::Type::Chi;
use Devel::TypeCheck::Type::Upsilon;
use Devel::TypeCheck::Type::Zeta;

# Include terminal types
use Devel::TypeCheck::Type::Io;
use Devel::TypeCheck::Type::Pv;
use Devel::TypeCheck::Type::Iv;
use Devel::TypeCheck::Type::Dv;

# Type variables
use Devel::TypeCheck::Type::Var;

# The environment, GAMMA
use Devel::TypeCheck::Environment;
use Devel::TypeCheck::Glob2type;
use Devel::TypeCheck::Pad2type;

# Names of CVs to type check
our @cvnames;
our @modules;

# Set of CVs to type check
our %roots;

# Whether or not to check the main body
our $mainRoot = FALSE;
our $all = FALSE;
our $ugly = FALSE;
our $continue = FALSE;

# Whether logical operations require an Upsilon (TRUE) or a Nu (FALSE)
our $relax = FALSE;
our $inferLogop = undef;

# Symbol to type lookup for global symbols
our $glob2type;

# Position information for error reporting
our $globalLine = "";
our $globalFile = "";

# For output
our $depth = 0;
our $depthIncrement = 4;
our $opcodes = 0;

our @list;

# Required function for O(3pm) use.  Adapted from B::Concise
sub compile {
    my $setModule = FALSE;
    my $setCvname = FALSE;

    while (@_) {
	my $o = shift(@_);
	
	if ($o eq "-verbose") {
	    setVerbose(TRUE);
	} elsif ($o eq "-continue") {
	    $continue = TRUE;
	} elsif ($o eq "-ugly") {
	    $ugly = TRUE;
	} elsif ($o eq "-main") {
	    $mainRoot = TRUE;
	} elsif ($o eq "-relax") {
	    $relax = TRUE;
	} elsif ($o eq "-all") {
	    $continue = TRUE;
	    $all = TRUE;
	} elsif ($o eq "-module") {
	    $setModule = TRUE;
	    my $m = shift(@_);
	    if (defined($m)) {
		push(@modules, $m);
	    } else {
		warn "Null argument to -module option";
	    }
	} elsif ($o !~ /^-/) {
	    $setCvname = TRUE;
	    push(@cvnames, $o);
	} else {
	    warn "Option $o unrecognized";
	}

    }
    
	if (!($mainRoot || $all || $setModule || $setCvname)) {
	    warn "Defaulting to -main\n";
	    $mainRoot = TRUE;
	}

    return \&callback;
}

# Fully qualified terminal types
our $IO = Devel::TypeCheck::Type::Mu->new(Devel::TypeCheck::Type::Io->new());
our $PV = Devel::TypeCheck::Type::Mu->new(Devel::TypeCheck::Type::Kappa->new(Devel::TypeCheck::Type::Upsilon->new(Devel::TypeCheck::Type::Pv->new())));
our $IV = Devel::TypeCheck::Type::Mu->new(Devel::TypeCheck::Type::Kappa->new(Devel::TypeCheck::Type::Upsilon->new(Devel::TypeCheck::Type::Nu->new(Devel::TypeCheck::Type::Iv->new()))));
our $DV = Devel::TypeCheck::Type::Mu->new(Devel::TypeCheck::Type::Kappa->new(Devel::TypeCheck::Type::Upsilon->new(Devel::TypeCheck::Type::Nu->new(Devel::TypeCheck::Type::Dv->new()))));

# Special value, unique in references, for use in the *Proto functions
our $ANY = \0;

# Typical tuple returns from the get*by* operators
sub GSBY {
    my ($env) = @_;
    return $env->genOmicronTuple($PV, $PV, $IV, $PV);
}

sub GPW {
    my ($env) = @_;
    return $env->genOmicronTuple($PV, $PV, $IV, $IV, $IV, $PV, $PV, $PV, $PV, $IV);
}

sub GGR {
    my ($env) = @_;
    return $env->genOmicronTuple($PV, $PV, $IV, $PV);
}

sub GHBY {
    my ($env) = @_;
    return $env->genOmicronTuple($PV, $PV, $IV, $IV, $env->genOmicron($IV));
}

sub GNBY {
    my ($env) = @_;
    return $env->genOmicronTuple($PV, $PV, $IV, $IV);
}

sub GPBY {
    my ($env) = @_;
    return $env->genOmicronTuple($PV, $PV, $IV);
}

# Sane wrapper around raw unify
sub myUnify {
    my ($env, $var, @vars) = @_;

    if (defined($var)) {
	
	my $acc = $var;
	for my $i (@vars) {
	    if (!defined($i)) {
		confess("Tried to unify an undefined value");
	    }

	    my $oldacc = $acc;

	    if ($acc->is(Devel::TypeCheck::Type::H()) && $i->is(Devel::TypeCheck::Type::P())) {
		verbose(" " x $depth, "  Enacting MH ~= MKPMH rule");
		$i = $i->deref;
	    }

	    if ($i->is(Devel::TypeCheck::Type::H()) && $acc->is(Devel::TypeCheck::Type::P())) {
		verbose(" " x $depth, "  Enacting MH ~= MKPMH rule");
		$acc = $acc->deref;
	    }

	    verbose_(" " x $depth, "  unify(", myPrint($oldacc, $env), ", ", myPrint($i, $env), ") = ");
	    $acc = $env->unify($acc, $i);
	    verbose($acc?myPrint($acc, $env):"FAIL");

	    if (!$acc) {
		my $msg = ("TYPE ERROR: Could not unify " . myPrint($env->find($oldacc), $env) . " and " . myPrint($env->find($i), $env) .
		    " at line " . $globalLine . ", file " . $globalFile . "\n");
		if (getVerbose()) {
		    confess($msg);
		} else {
		    die($msg);
		}
	    }
	}

	return $env->find($acc);
    } else {
	return undef;
    }
}

# Sane wrapper around print
sub myPrint {
    my ($t, $env) = @_;

    if (!$ugly) {
	return $t->pretty($env);
    } else {
	return $t->str($env);
    }
}

sub smash {
    my ($r, $env) = @_;
    my @results = @$r;

    my $result;

    if ($#results == 0) {
	$results[0] = $env->find($results[0]);
    }

    if ($#results == 0 && $results[0]->is(Devel::TypeCheck::Type::O())) {
	# There's a single array in the results.  Just pass it on.
	$result = $results[0];
    } elsif ($#results == 0 && $results[0]->isa("Devel::TypeCheck::Type::Var")) {
	# There's a single array in the results.  Just pass it on.
	myUnify($env, $results[0], $env->genOmicron());
	$result = $results[0];
    } else {
	# Mash everything in @results together and hope for the best.
	$result = $env->genOmicron();
	foreach my $i (@results) {
	    my $oldresult = $result;
	    $result = $result->append($i, $env);
	    die("TYPE ERROR: failure to unify " . myPrint($i, $env) . " with " . myPrint($oldresult, $env) .
		" at line " . $globalLine . ", file " . $globalFile . "\n") if (!defined($result));
	}
    }

    return $result;
}

# Type the children of a given operator
sub typeOpChildren {
    my ($op, $pad2type, $env, $cv, $context) = @_;

    if (!defined($context)) {
	$context = SCALAR();
    }

    # If the operator has kids, the type of the NULL op is the type of the last kid
    # Otherwise, this operator is untyped
    
    my $result;
    my @returns;
    my @results;
    
    if ($op->flags & B::OPf_KIDS()) {
	for (my $kid = $op->first(); $$kid; $kid = $kid->sibling()) {
	    # Type the kid
	    my ($s, $r) = typeOp($kid, $pad2type, $env, $cv, $context);
	
	    if (defined($s)) {
		push(@results, $s);
		$result = $s;
	    }
    
	    # Set up unify of return values from down in the tree
	    if (defined($r)) {
		push(@returns, $r);
	    }
	}
    }
    
    if ($context == LIST()) {
	$result = smash(\@results, $env);
    }

    return ($result, myUnify($env, @returns));
}

sub typeOpChildren_ {
    my ($op, $pad2type, $env, $cv, $context) = @_;

    if (!defined($context)) {
	$context = SCALAR();
    }

    # If the operator has kids, the type of the NULL op is the type of the last kid
    # Otherwise, this operator is untyped
    
    my @results;
    my @returns;
    
    if ($op->flags & B::OPf_KIDS()) {
	for (my $kid = $op->first(); $$kid; $kid = $kid->sibling()) {
	    # Type the kid
	    my ($s, $r) = typeOp($kid, $pad2type, $env, $cv, $context);
	    
	    # Overwrite the result
	    push(@results, $s) if (defined($s));
	    
	    # Set up unify of return values from down in the tree
	    push(@returns, $r) if (defined($r));
	}
    }
    
    my $result;
    if ($context == LIST()) {
	$result = smash(\@results, $env);
    } else {
	$result = myUnify($env, @results);
    }

    return ($result, myUnify($env, @returns));
}

# Type the children of a given operator
sub typeOpChildrenSkip {
    my ($op, $pad2type, $env, $cv, $context, $skip) = @_;

    if (!defined($context)) {
	$context = SCALAR();
    }

    # If the operator has kids, the type of the NULL op is the type of the last kid
    # Otherwise, this operator is untyped
    
    my $result;
    my @returns;
    my @results;
    
    if ($op->flags & B::OPf_KIDS()) {
	my $start = $op->first();
	while ($skip != 0) {
	    $start = $start->sibling();
	    $skip--;
	}

	for (my $kid = $start ; $$kid; $kid = $kid->sibling()) {
	    # Type the kid
	    my ($s, $r) = typeOp($kid, $pad2type, $env, $cv, $context);
	
	    if (defined($s)) {
		push(@results, $s);
		$result = $s;
	    }
    
	    # Set up unify of return values from down in the tree
	    if (defined($r)) {
		push(@returns, $r);
	    }
	}
    }
    
    if ($context == LIST()) {
	$result = smash(\@results, $env);
    }

    return ($result, myUnify($env, @returns));
}

sub typeRest {
    my ($kid, $pad2type, $env, $cv) = @_;

    my @rets;

    for ( ; $$kid; $kid = $kid->sibling()) {
	my ($t, $r) = typeOp($kid, $pad2type, $env, $cv, SCALAR());
	push(@rets, $r) if ($r);
    }

    return myUnify($env, @rets);
}

sub typeProto {
    my ($op, $pad2type, $env, $cv, @proto) = @_;
    
    my $index = 0;
    my @rets;
    if ($op->flags & B::OPf_KIDS()) {
	my $type = $op->first()->type();
	if ($type != OP_PUSHMARK() &&
	    $type != OP_NULL()) {
	    die("Operator is not a function-call type.  Cannot use typeProto()");
	}
	
	for (my $kid = $op->first()->sibling(); $$kid; $kid = $kid->sibling()) {
	    my ($t, $r);
	    if (($proto[$index]) == $ANY) {
		$r = typeRest($kid, $pad2type, $env, $cv);
		push(@rets, $r) if ($r);
		last;
	    } elsif ($proto[$index]->is(Devel::TypeCheck::Type::O())) {
		($t, $r) = typeOp($kid, $pad2type, $env, $cv, LIST());
	    } else {
		($t, $r) = typeOp($kid, $pad2type, $env, $cv, SCALAR());
	    }
	    myUnify($env, $t, $proto[$index]);
	    push(@rets, $r) if ($r);
	    $index++;
	    die ("Too many arguments") if ($index > ($#proto + 1));
	}
    }

    return (myUnify($env, @rets), ($#proto + 1) - $index);
}

sub typeProtoOp {
    my ($op, $pad2type, $env, $cv, @proto) = @_;
    
    my $index = 0;
    my @rets;
    if ($op->flags & B::OPf_KIDS()) {
	for (my $kid = $op->first(); $$kid; $kid = $kid->sibling()) {
	    #next if ($kid->type() == OP_NULL());

	    my ($t, $r);
	    if (($proto[$index]) == $ANY) {
		$r = typeRest($kid, $pad2type, $env, $cv);
		push(@rets, $r) if ($r);
		last;
	    } elsif ($proto[$index]->is(Devel::TypeCheck::Type::O())) {
		($t, $r) = typeOp($kid, $pad2type, $env, $cv, LIST());
	    } else {
		($t, $r) = typeOp($kid, $pad2type, $env, $cv, SCALAR());
	    }
	    myUnify($env, $t, $proto[$index]);
	    push(@rets, $r) if ($r);
	    $index++;
	    die ("Too many arguments") if ($index > ($#proto + 1));
	}
    }

    return (myUnify($env, @rets), ($#proto + 1) - $index);
}

# Perl conflates the use of rv2XX operators for references, globs, and
# references to globs.  This does it's best to disambiguate that.
sub rvConflate {
    my ($env, $ref, $XX) = @_;

    $ref = $env->find($ref);

    if (!defined($ref)){
	confess("Undefined parameter \$ref");
    }

    # If $ref is a VAR, unify $ref and RHO($XX), and be done with the
    # sordid business
    if ($ref->type() == Devel::TypeCheck::Type::VAR()) {
	myUnify($env, $ref, $env->genRho($XX));
	return $XX;
    }

    # If it's a glob
    if ($ref->is(Devel::TypeCheck::Type::H())) {
      RVC_ISETA:

	# If we're looking for the KAPPA part of the glob
	if ($XX->is(Devel::TypeCheck::Type::K())) {
	    # Project the K from the H
	    $ref = $ref->derefKappa;
	    return $ref;
	} elsif ($XX->is(Devel::TypeCheck::Type::O())) {
	    $ref = $ref->derefOmicron;
	    return $ref;
	} elsif ($XX->is(Devel::TypeCheck::Type::X())) {
	    $ref = $ref->derefChi;
	    return $ref;
	} elsif ($XX->is(Devel::TypeCheck::Type::Z())) {
	    $ref = $ref->derefZeta();
	} else {
	    # $XX is the type we want, after all
	    return($XX);
	}

	# Unify the newly dereferenced ref with the desired type
	return myUnify($env, $ref, $XX);

    } elsif ($ref->is(Devel::TypeCheck::Type::K()) &&
	     $ref->is(Devel::TypeCheck::Type::VAR())) {

	# Garbage garbage garbage
	myUnify($env, $ref, $env->genRho($env->fresh));
	goto RVC_ISRHO;

    # If it's a reference
    } elsif ($ref->is(Devel::TypeCheck::Type::P())) {
      RVC_ISRHO:
	$ref = $ref->deref;

	# Stupid hack alert: these operators do the same thing if $ref
	# is a glob or a ref to a glob
	goto RVC_ISETA if ($ref->is(Devel::TypeCheck::Type::H()));

	# Make sure whatever we dereferenced matches the type we want
	myUnify($env, $ref, $XX);

	return($XX);
    } else {
	confess("Could not dereference through rvConflate: " . myPrint($ref, $env));
	return undef;
    }
}

sub getPvConst {
    my ($op, $cv) = @_;

    my $sv = $op->sv;

  RETRY_PVCONST:
    my $class = B::class($sv);

    if ($class eq "PV") {
	return $sv->PV;
    } elsif ($class eq "SPECIAL") {
	$sv = (($cv->PADLIST()->ARRAY())[1]->ARRAY)[$op->targ];
	goto RETRY_PVCONST;
    } else {
	die("Can't get PV constant out of $class");
    }

}

sub getIvConst {
    my ($op, $cv) = @_;

    my $sv = $op->sv;

  RETRY_IVCONST:
    my $class = B::class($sv);

    if ($class eq "IV") {
	return $sv->int_value;
    } elsif ($class eq "SPECIAL") {
	$sv = (($cv->PADLIST()->ARRAY())[1]->ARRAY)[$op->targ];
	goto RETRY_IVCONST;
    } else {
	die("Can't get IV constant out of $class");
    }

}

sub getUpsilonConst {
    my ($op, $cv) = @_;

    my $sv = $op->sv;

  RETRY_YCONST:
    my $class = B::class($sv);

    if ($class eq "IV") {
	return $sv->int_value;
    } elsif ($class eq "PV") {
	return $sv->PV;
    } elsif ($class eq "NV") {
	return $sv->NV;
    } elsif ($class eq "SPECIAL") {
	$sv = (($cv->PADLIST()->ARRAY())[1]->ARRAY)[$op->targ];
	goto RETRY_YCONST;
    } else {
	die("Can't get Y constant out of $class");
    }
}

sub constructConst {
    my ($sv, $cv, $op, $env) = @_;

  RETRY_CONST:
    my $class = B::class($sv);

    if ($class eq "PV" || $class eq "BM") {
	# BM seems to be the "substring" constant type.  BM probably
	# stands for Boyer-Moore, but it's not actually documented
	# anywhere that I can find.
	return $PV;

    } elsif ($class eq "IV") {
	return $IV;

    } elsif ($class eq "NV") {
	# Constants of type NV are always doubles
	return $DV;

    } elsif ($class eq "RV") {
	return $env->genRho(constructConst($sv->RV, $cv, $op, $env));

    } elsif ($class eq "PVMG") {
	# We have no idea how this might be used, so punt, but make
	# sure whatever uses it, uses it consistently.
	verbose("Found magic, ignoring");
	return $env->fresh();

    } elsif ($class eq "PVNV") {

	return $env->freshNu();
	
    } elsif ($class eq "SPECIAL") {
	$sv = (($cv->PADLIST()->ARRAY())[1]->ARRAY)[$op->targ];
	goto RETRY_CONST;

    } else {
	confess("Cannot construct a type for referent type $class");
    }
}

# For comparing context
sub LIST { return 0 };
sub SCALAR { return 1 };

sub contextPick {
    my ($context, $list, $scalar) = @_;
    if ($context == LIST()) {
	return $list;
    } else {
	return $scalar;
    }
}

sub coerce {
    my ($env, $result, $context) = @_;

    # If we can prove that the return is a 1-tuple and the context is scalar, promote to scalar
    if ($context == SCALAR() &&
	defined($result) &&
	$result->is(Devel::TypeCheck::Type::O()) &&
	$result->homogeneous == FALSE() &&
	$result->arity == 1) {
	$result = $result->derefIndex(0, $env);
    }

    return $result;
}

# This assumes that all children of $op have already been typed to IV
sub extractConstList {
    my ($op, $cv) = @_;
    my @ret;

    for (my $kid = $op->first(); $$kid; $kid = $kid->sibling()) {
	next if ($kid->type() == OP_PUSHMARK());

	if ($kid->type() != OP_CONST()) {
	    return undef;
	}

	push(@ret, getIvConst($kid, $cv));
    }

    return(\@ret);
}

# Invoked when the operator might be an operation-assignment operator (like +=)
sub opAssign {
    my ($env, $op, $f, $a) = @_;

    # This is also an assignment operator
    if (($op->first()->flags & B::OPf_REF()) &&
	($op->first()->flags & B::OPf_MOD())) {
	myUnify($env, $a, $f);
    }
}

sub arithmetic {
    my ($env, $ft, $lt) = @_;
    # Bind both to an incomplete Nu value.
    $ft = myUnify($env, $ft, $env->freshNu);
    $lt = myUnify($env, $lt, $env->freshNu);

    if ($ft->is(Devel::TypeCheck::Type::DV()) ||
	$lt->is(Devel::TypeCheck::Type::DV())) {

	# Bind up incomplete types to whatever we're going to
	# return.  No more than one is incomplete
	if (! $ft->complete) {
	    # $ft is incomplete Nu
	    myUnify($env, $ft, $DV);
	} elsif (! $lt->complete) {
	    # $lt is incomplete Nu
	    myUnify($env, $lt, $DV);
	}

	return $DV;
    } elsif ($ft->is(Devel::TypeCheck::Type::IV()) ||
	     $lt->is(Devel::TypeCheck::Type::IV())) {

	# Bind up incomplete types to whatever we're going to
	# return.  No more than one is incomplete
	if (! $ft->complete) {
	    # $ft is incomplete Nu
	    myUnify($env, $ft, $IV);
	} elsif (! $lt->complete) {
	    # $lt is incomplete Nu
	    myUnify($env, $lt, $IV);
	}

	return $IV;
    } else {
	return myUnify($env, $ft, $lt);
    }
}

sub SVOP2SV {
    my ($op, $cv) = @_;

    if (! $op->isa("B::SVOP")) {
	die "operator is not a SVOP";
    }

    my $sv = $op->sv;
    my $class = B::class($sv);

    if ($class eq "SPECIAL") {
	$sv = (($cv->PADLIST()->ARRAY())[1]->ARRAY)[$op->targ];
    }

    return ${$sv->object_2svref()};
}

sub inferNu {
    my $env = $_[0];
    return $env->freshNu();
}

sub inferUpsilon {
    my $env = $_[0];
    return $env->freshUpsilon();
}

sub typeOp {
    my ($op, $pad2type, $env, $cv, $context) = @_;

    $opcodes++;

    $depth += $depthIncrement;

    verbose(" " x $depth, ($context)?"S":"L", ":", $op->name, " {");

    my ($realResult, $realReturn);

    confess("op is null") if (!defined($op));
    confess("pad2type is null") if (!defined($pad2type));
    confess("env is null") if (!defined($env));
    confess("cv is null") if (!defined($cv));
    confess("context is null") if (!defined($context));

    my $t = $op->type();

  RETRY:
    if ($t == OP_LIST()     || # This one almost always gets optimized out
        $t == OP_LEAVELOOP()||
        $t == OP_ENTERTRY() ||
        $t == OP_ENTERLOOP()||
        $t == OP_ENTER()    ||
        $t == OP_LINESEQ()  ||
        $t == OP_SCOPE()) {

	my $c = $context;
	$c = LIST() if ($t == OP_LIST() && $op->first()->type() == OP_PUSHMARK());

        ($realResult, $realReturn) = typeOpChildren($op, $pad2type, $env, $cv, $c);

	$realResult = coerce($env, $realResult, $context);

    } elsif ($t == OP_NULL()) {

	no strict qw(subs);
        if ($op->targ == OP_LIST()) {
	    # Hack for ex-list
            $t = $op->targ;
            goto RETRY;
	} elsif ($op->can("first") && $op->first()->can("sibling") && ($op->first()->sibling()->can("type")) && ($op->first()->sibling()->type() == OP_READLINE())) {
	    # Hack for readline.  Act like this is an sassign from the readline to the first argument
	    my ($t0, $r0) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	    my ($t1, $r1) = typeOp($op->first()->sibling(), $pad2type, $env, $cv, SCALAR());

	    ($realResult, $realReturn) = (myUnify($env, $t0, $t1), myUnify($env, $r0, $r1));
        } else {
            ($realResult, $realReturn) = typeOpChildren($op, $pad2type, $env, $cv, SCALAR());
        }

    } elsif ($t == OP_LEAVESUB()) {

	($realResult, $realReturn) = typeOpChildren($op, $pad2type, $env, $cv, $context);

	if (defined($realReturn)) {
	    if (defined($realResult)) {
		# If the result is a plain scalar, promote it to be a 1-tuple of that scalar
		if ($realResult->is(Devel::TypeCheck::Type::K())) {
		    $realResult = $env->genOmicronTuple($realResult);
		}

		# Unify the return value (which is guaranteed to be an Omicron of some sort) with the result value.
		$realReturn = myUnify($env, $realResult, $realReturn);

		my $tmpResult = coerce($env, $realResult, $context);
		if ($tmpResult != $realResult) {
		    $realReturn = $realResult = $tmpResult;
		}
	    }
	} else {
	    if (defined($realResult)) {
		$realReturn = $realResult;
	    }
	}	    

    } elsif ($t == OP_LEAVE()) {
	
	($realResult, $realReturn) = typeOpChildren($op, $pad2type, $env, $cv, $context);

	$realResult = coerce($env, $realResult, $context);
    } elsif ($t == OP_LEAVETRY()) {

	my ($t, $r) = typeOpChildren($op, $pad2type, $env, $cv, $context);
	if (!$r) {
	    ($realResult, $realReturn) = ($t, undef);
	} else {
	    ($realResult, $realReturn) = (myUnify($env, $t, $r), undef);
	}

    } elsif ($t == OP_ENTERSUB()) {

	my @params;
	my @rets;
	my $root = $op;
	my $first = undef;
	my $last = undef;
	if ($root->first()->type() == OP_NULL()) {
	    $root = $root->first();
	}
	if ($root->flags & B::OPf_KIDS()) {
	    for (my $kid = $root->first(); $$kid; $kid = $kid->sibling()) {
		if ($kid->type() != OP_PUSHMARK()) {
		    $first = $kid if (!defined($first));
		    my ($s, $r) = typeOp($kid, $pad2type, $env, $cv, $context);

		    push(@params, $s) if (defined($s));
		    push(@rets, $r) if (defined($r));
		}
		$last = $kid;
	    }
	}

	# The function is always the last operator to the ENTERSUB operand
	my $fnArg = pop(@params);

	# Null-reduce
	while ($last->type() == OP_NULL()) {
	    $last = $last->first();
	}

	# Figure out what kind of function call this is.
	my $name = undef;
	if ($last->type() == OP_GV()) {
	    my $class = B::class($last);

	    my $gv;
	    if ($class eq "PADOP") {
		$gv = (($cv->PADLIST->ARRAY)[1]->ARRAY)[$last->padix];
	    } elsif ($class eq "SVOP") {
		$gv = $op->gv;
	    }

	    $name = $gv->STASH->NAME . "::" . $gv->NAME;
	} elsif ($last->type() == OP_METHOD_NAMED()) {
	    if ($first->type() == OP_CONST()) {
		my $ft = constructConst($first->sv, $cv, $first, $env);
		
		if ($ft == $PV) {
		    $name = SVOP2SV($first, $cv) . "::" . SVOP2SV($last, $cv);
		} else {
		    die "OP_METHOD_NAMED used with a non-PV name";
		}
	    } else {
		verbose "OP_METHOD_NAMED used with a non-constant name";
	    }
	} elsif ($last->type() == OP_METHOD()) {
	    die "can't deal with references to methods yet";
	}
	
	if (defined($name)) {
	    verbose(" " x $depth, "function name is $name");
	}

	# Use rvConflate to extract CV from a ref to a GV or a ref to a CV

	my $returnType;

	$returnType = $env->fresh;

	my $fnType = rvConflate($env, $fnArg, $env->genZeta(smash(\@params, $env), $returnType));
	
	($realResult, $realReturn) = ($fnType->derefReturn, myUnify($env, @rets));
	
    } elsif ($t == OP_ENTEREVAL() || 
	     $t == OP_DOFILE()) {
	
	# Make sure we're passing it a PV
	my ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	myUnify($env, $t, $PV);

	# Generate a new type variable, since the return might be anything
	($realResult, $realReturn) = ($env->fresh(), $t);

    } elsif ($t == OP_ENTERITER()) {

	# The first operand is a dead pushmark, so just ignore it

	# The second operand is the list
	my ($t, $r) = typeOp($op->first()->sibling(), $pad2type, $env, $cv, LIST());

	# Promote $t to a homogeneous list
	myUnify($env, $t, $env->genOmicron($env->freshKappa));

	# If the third argument is there, then it's a glob reference
	# to the variable that we're iterating over.
	my $targ = $op->targ;
	if ($targ) {
	    # No third argument, iterator is a lexically scoped variable
	    my $pad = $pad2type->get($targ, $env);
	    myUnify($env, $pad, $t->derefHomogeneous);
	} else {
	    my ($t0, $r0) = typeOp($op->first()->sibling()->sibling(), $pad2type, $env, $cv, SCALAR());
	    
	    # project the scalar for the reference

	    $t0 = $t0->derefKappa();

	    myUnify($env, $t0, $t->derefHomogeneous);
	}

	($realResult, $realReturn) = ($t->derefHomogeneous, undef);

    } elsif ($t == OP_ITER()) {
	
	($realResult, $realReturn) = ($env->freshKappa, undef);

    } elsif ($t == OP_STUB()) {

	# YYY It puts a new SV on the stack in pp.c in a scalar
	# context.  I guess it gets a null array in a list context.
	($realResult, $realReturn) = (contextPick($context, $env->genOmicron(), $env->fresh), undef);

    } elsif ($t == OP_PRINT()) {

	# The children are the parameters of the operator
	my ($t, $r) = typeOpChildren($op, $pad2type, $env, $cv);

	($realResult, $realReturn) = ($IV, $r);
	
    } elsif ($t == OP_INT()) {

	# Can be used as a coercion from DV to IV, so accept Nu
	my ($ot, $or) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	myUnify($env, $ot, $env->freshNu);
	($realResult, $realReturn) = ($IV, $or);

    } elsif ($t == OP_PREINC() ||
	     $t == OP_PREDEC() ||
	     $t == OP_POSTINC()||
	     $t == OP_POSTDEC()) {
	# Unary number operators

	my ($ot, $or) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	myUnify($env, $ot, $env->freshNu);
	($realResult, $realReturn) = ($ot, $or);

    } elsif ($t == OP_NOT()) {

	my ($ot, $or) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	myUnify($env, $ot, &$inferLogop($env));
	($realResult, $realReturn) = ($IV, $or);
	
    } elsif ($t == OP_NEGATE()   ||
	     $t == OP_I_NEGATE() ||
	     $t == OP_I_PREINC() ||
	     $t == OP_I_PREDEC() ||
	     $t == OP_I_POSTINC()||
	     $t == OP_I_POSTDEC()||
	     $t == OP_COMPLEMENT()) {
	# Unary number operators that are strict in IV

	my ($ot, $or) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	myUnify($env, $ot, $IV);
	($realResult, $realReturn) = ($IV, $or);

    } elsif ($t == OP_RAND()) {
	# Operand is optional
       
	my $class = B::class($op);

	if ($class eq "UNOP") {
	    my ($ot, $or) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	    myUnify($env, $ot, $env->freshNu)
	}

	($realResult, $realReturn) = ($DV, undef);

    } elsif ($t == OP_EQ() ||
	     $t == OP_NE()) {

	# Have to be able to compare pointers
	my ($ft, $fr) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	my ($lt, $lr) = typeOp($op->last, $pad2type, $env, $cv, SCALAR());

	if ((defined($ft) && $ft->is(Devel::TypeCheck::Type::PV())) || (defined($lt) && $lt->is(Devel::TypeCheck::Type::PV()))) {
	    die("TYPE ERROR: Cannot use numeric comparison (== or !=) to compare strings");
	}

	($realResult, $realReturn) = (myUnify($env, $ft, $lt), myUnify($env, $fr, $lr));

    } elsif ($t == OP_ADD()        ||
	     $t == OP_SUBTRACT()   ||
	     $t == OP_MULTIPLY()   ||
	     $t == OP_MODULO()     ||
	     $t == OP_LT()         ||
	     $t == OP_GT()         ||
	     $t == OP_LE()         ||
	     $t == OP_GE()         ||
	     $t == OP_NCMP()       ||
	     $t == OP_POW()) {
	# Binary number operators

	# Both sides should be unified with Nu, and resulting
	# expression type is Nu.

	my ($ft, $fr) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	my ($lt, $lr) = typeOp($op->last, $pad2type, $env, $cv, SCALAR());
	
	($realResult, $realReturn) = (arithmetic($env, $ft, $lt),
				      myUnify($env, $fr, $lr));

	if ($t == OP_ADD()      ||
	    $t == OP_SUBTRACT() ||
	    $t == OP_MULTIPLY() ||
	    $t == OP_MODULO()   ||
	    $t == OP_POW()) {
	    opAssign($env, $op, $ft, $realResult);
	}

    } elsif ($t == OP_DIVIDE()) {

	my ($ft, $fr) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	my ($lt, $lr) = typeOp($op->last, $pad2type, $env, $cv, SCALAR());
	
	# Bind both to an incomplete Nu value.
	$ft = myUnify($env, $ft, $env->freshNu);
	$lt = myUnify($env, $lt, $env->freshNu);

	($realResult, $realReturn) = ($DV, myUnify($env, $fr, $lr));

	opAssign($env, $op, $ft, $realResult);

    } elsif ($t == OP_ATAN2() ||
	     $t == OP_SIN()   ||
	     $t == OP_COS()   ||
	     $t == OP_EXP()   ||
	     $t == OP_LOG()   ||
	     $t == OP_SQRT()  ||
	     $t == OP_HEX()   ||
	     $t == OP_OCT()   ||
	     $t == OP_ABS()) {

	my ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	
	# Bind to an incomplete Nu value.
	$t = myUnify($env, $t, $env->freshNu);

	($realResult, $realReturn) = ($DV, $r);

    } elsif ($t == OP_I_ADD()      ||
	     $t == OP_I_SUBTRACT() ||
	     $t == OP_I_MULTIPLY() ||
	     $t == OP_I_DIVIDE()   ||
	     $t == OP_I_MODULO()   ||
	     $t == OP_I_LT()       ||
	     $t == OP_I_GT()       ||
	     $t == OP_I_LE()       ||
	     $t == OP_I_GE()       ||
	     $t == OP_I_EQ()       ||
	     $t == OP_I_NE()       ||
	     $t == OP_I_NCMP()     ||
	     $t == OP_BIT_AND()    ||
	     $t == OP_BIT_OR()     ||
	     $t == OP_BIT_XOR()    ||
	     $t == OP_SETPGRP()    ||
	     $t == OP_LEFT_SHIFT() ||
	     $t == OP_RIGHT_SHIFT()) {
	# Binary number operators that are strict in IV

	my ($ft, $fr) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	my ($lt, $lr) = typeOp($op->last, $pad2type, $env, $cv, SCALAR());
	
	myUnify($env, $ft, $IV);
	myUnify($env, $lt, $IV);
	
	($realResult, $realReturn) = ($IV, myUnify($env, $fr, $lr));

	if ($t == OP_I_ADD()      ||
	    $t == OP_I_SUBTRACT() ||
	    $t == OP_I_MULTIPLY() ||
	    $t == OP_I_DIVIDE()   ||
	    $t == OP_I_MODULO()   ||
	    $t == OP_BIT_AND()    ||
	    $t == OP_BIT_OR()     ||
	    $t == OP_BIT_XOR()    ||
	    $t == OP_LEFT_SHIFT() ||
	    $t == OP_RIGHT_SHIFT()) {
	    opAssign($env, $op, $ft, $realResult);
	}
    } elsif ($t == OP_SEQ() ||
	     $t == OP_SNE() ||
	     $t == OP_SLT() ||
	     $t == OP_SGT() ||
	     $t == OP_SLE() ||
	     $t == OP_SGE() ||
	     $t == OP_SCMP()) {
	# Binary comparison operators

	# Both sides should be unified with PV, but resulting
	# expression type is NV.

	my ($ft, $fr) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	my ($lt, $lr) = typeOp($op->last, $pad2type, $env, $cv, SCALAR());
	
	myUnify($env, $ft, $PV);
	myUnify($env, $lt, $PV);
	
	($realResult, $realReturn) = ($IV, myUnify($env, $fr, $lr));

    } elsif ($t == OP_CONCAT()) {

	# Both sides should be unified with Ka, and resulting
	# expression type is PV.

	my ($ft, $fr) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	my ($lt, $lr) = typeOp($op->last, $pad2type, $env, $cv, SCALAR());
	
	myUnify($env, $ft, $env->freshUpsilon);
	myUnify($env, $lt, $env->freshUpsilon);
	
	($realResult, $realReturn) = ($PV, myUnify($env, $fr, $lr));

	opAssign($env, $op, $ft, $PV);

    } elsif ($t == OP_GELEM()) {

	my ($ft, $fr) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	my ($lt, $lr) = typeOp($op->last, $pad2type, $env, $cv, SCALAR());

	myUnify($env, $ft, $env->freshEta($env));
	myUnify($env, $lt, $PV);

	my $const = getPvConst($op->last, $cv);
	my $r = myUnify($env, $fr, $lr);

	# Dereferencing typed elements as necessary
	if ($const eq "SCALAR") {
	    ($realResult, $realReturn) = ($env->genRho($ft->derefKappa), $r);
	} elsif ($const eq "IO" ||
		 $const eq "FILEHANDLE") {
	    ($realResult, $realReturn) = ($env->genRho($IO), $r);
	} elsif ($const eq "ARRAY") {
	    ($realResult, $realReturn) = ($env->genRho($ft->derefOmicron), $r);
	} elsif ($const eq "HASH") {
	    ($realResult, $realReturn) = ($env->genRho($ft->derefChi), $r);
	} elsif ($const eq "CODE") {
	    ($realResult, $realReturn) = ($env->genRho($ft->derefZeta), $r);
	} elsif ($const eq "GLOB") {
	    # YYY I'm pretty sure a gelem(glob0) -> glob0 
	    ($realResult, $realReturn) = ($env->genRho($ft), $r);
	} else {
	    die("Unknown *foo{THING} syntax on $const");
	}

    } elsif ($t == OP_GVSV()) {

	# Get the type of the referencing GV.  I don't fully
	# understand the following line.  It was borrowed from
	# B/Concise.pm.
        my $class = B::class($op);

        my $gv;
        if ($class eq "PADOP") {
            $gv = (($cv->PADLIST->ARRAY)[1]->ARRAY)[$op->padix];
        } elsif ($class eq "SVOP") {
            $gv = $op->gv;
        } else {
            confess("unknown op type $class for GVSV");
        }

	my $tgv = $glob2type->get($gv->STASH()->NAME() . "::" . $gv->SAFENAME(), $env);

	# Project the type of the referent SV.  $tgv is guaranteed to
	# be an instance of Devel::TypeCheck::Type::Eta.
	($realResult, $realReturn) = ($tgv->derefKappa, undef);

    } elsif ($t == OP_GV()) {

        my $class = B::class($op);

        my $gv;
        if ($class eq "PADOP") {
            $gv = (($cv->PADLIST->ARRAY)[1]->ARRAY)[$op->padix];
        } elsif ($class eq "SVOP") {
            $gv = $op->gv;
        } else {
            confess("unknown op type $class for GV");
        }

        my $tgv = $glob2type->get($gv->STASH()->NAME() . "::" . $gv->SAFENAME(), $env);

	($realResult, $realReturn) = ($env->genRho($tgv), undef);

    } elsif ($t == OP_RV2GV()) {

	my ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	
	# Guarantee that we can dereference something
	myUnify($env, $t, $env->freshRho());

	my $d = $env->find($t)->deref;

	myUnify($env, $d, $env->freshEta($env));
	($realResult, $realReturn) = ($d, $r);

    } elsif ($t == OP_RV2SV()) {

        my ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());

	# cheat
	myUnify($env, $t, $env->genRho($env->fresh)) if ($op->first()->type() == OP_PADSV());

	my $d = rvConflate($env, $t, $env->freshKappa());
	($realResult, $realReturn) = ($d, $r);

    } elsif ($t == OP_RV2AV()) {
	
        my ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());

	# cheat
	myUnify($env, $t, $env->genRho($env->fresh)) if ($op->first()->type() == OP_PADSV());

	my $d = rvConflate($env, $t, $env->genOmicron);
	($realResult, $realReturn) = ($d, $r);

    } elsif ($t == OP_RV2HV()) {
	
        my ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());

	# cheat
	myUnify($env, $t, $env->genRho($env->fresh)) if ($op->first()->type() == OP_PADSV());

	my $d = rvConflate($env, $t, $env->genChi);
	($realResult, $realReturn) = ($d, $r);

    } elsif ($t == OP_RV2CV()) {
	
        my ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());

	# cheat
	myUnify($env, $t, $env->genRho($env->fresh)) if ($op->first()->type() == OP_PADSV());

	my $d = rvConflate($env, $t, $env->freshZeta);
	($realResult, $realReturn) = ($d, $r);

    } elsif ($t == OP_ANONCODE()) {
	
#         my $class = B::class($op);
# 	my $ttcv;
#         if ($class eq "PADOP") {
#             $ttcv = (($cv->PADLIST->ARRAY)[1]->ARRAY)[$op->padix];
#         } elsif ($class eq "SVOP") {
#             $ttcv = $op->gv;
#         }
# 	verbose("class is " . $ttcv);
# 	my $tcv = $glob2type->get($ttcv->STASH()->NAME() . "::" . $ttcv->SAFENAME(), $env)->derefZeta;
# 	my $op = $tcv->ROOT;
# 	my %cur;

# 	$cur{'cv'} = $tcv;
# 	$cur{'op'} = $op;
# 	$roots{'anon'} = \%cur;

# 	push(@list, 'anon');
	
	# XXX revisit this
	($realResult, $realReturn) = ($env->freshZeta, undef);

    } elsif ($t == OP_PROTOTYPE()) {

	# XXX revisit this
	my ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	myUnify($env, $t, $env->freshZeta);

	($realResult, $realReturn) = ($PV, $r);

    } elsif ($t == OP_REFGEN()) {

	my $newType = $env->genOmicron();

	my @returns;

	for (my $kid = $op->first()->first()->sibling;
	     $$kid;
	     $kid = $kid->sibling()) {
	    my ($type, $return) = typeOp($kid, $pad2type, $env, $cv, LIST());

	    push(@returns, $return);

	    $type = $env->find($type);

	    verbose("found type ", myPrint($type, $env));

	    if ($type->isa("Devel::TypeCheck::Type::Var")) {
		$type = $env->genOmicron();
	    }

	    my $optype = $kid->type();

	    # If the incoming type is an array or hash and not an
	    # actual reference...
	    if (($type->is(Devel::TypeCheck::Type::O()) ||
		 $type->is(Devel::TypeCheck::Type::H())) &&
	        !($optype == OP_RV2AV() ||
		  $optype == OP_RV2HV() ||
		  $optype == OP_PADAV() ||
		  $optype == OP_PADHV())) {
		my $tmptype = $type->referize($env);

		if (!$tmptype->homogeneous() &&
		    $tmptype->arity == 0) {
		    $tmptype = $env->genOmicron($env->genRho($env->fresh));
		}

		$newType = $newType->append($tmptype, $env);
		verbose("referizing to ", myPrint($newType, $env));
	    } else {
		$newType = $newType->append($env->genRho($type), $env);
		verbose("generating reference ", myPrint($newType, $env));
	    }
	}

	if (!$newType->homogeneous() &&
	    $newType->arity == 1) {
	    verbose("dereferencing");
	    $newType = $newType->derefIndex(0, $env);
	}

	verbose("realResult is ", myPrint($newType, $env));
	$realResult = $newType;
	$realReturn = myUnify($env, @returns);

    } elsif ($t == OP_SREFGEN()) {

	my ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	($realResult, $realReturn) = ($env->genRho($t), $r);

    } elsif ($t == OP_REF()) {

	# Can be passed anything
	my ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	
	# Returns a string
	($realResult, $realReturn) = ($PV, $r);

    } elsif ($t == OP_BLESS()) {

	my ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	
	if (${$op->first()->sibling()}) {
	    my ($st, $sr) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	    myUnify($env, $st, $PV);
	    $r = myUnify($env, $r, $sr);
	}

	($realResult, $realReturn) = ($t, $r);

    } elsif ($t == OP_ANONLIST()) {

	($realResult, $realReturn) = typeOpChildren($op->first(), $pad2type, $env, $cv, LIST());

    } elsif ($t == OP_AELEMFAST()) {

	my $elt = $op->private;

	my $ary;
	if ($op->flags & B::OPf_REF) {
	    # This is a pad aelemfast
	    $ary = $pad2type->get($op->targ, $env);
	    $ary = $env->find($ary);
	} else {
	    # This is a glob aelemfast
	    my $gv = (($cv->PADLIST->ARRAY)[1]->ARRAY)[$op->padix];
	    my $tgv = $glob2type->get($gv->STASH()->NAME() . "::" . $gv->SAFENAME(), $env);
	    $ary = $tgv->derefOmicron();
	}

	# Negative index indicates a homogeneous array.
	if ($elt < 0) {
	    myUnify($env, $ary, $env->genOmicron($env->freshKappa));
	}

	($realResult, $realReturn) = ($ary->derefIndex($elt, $env), undef);
    
    } elsif ($t == OP_AELEM()) {
	my ($ft, $fr) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	my ($lt, $lr) = typeOp($op->last, $pad2type, $env, $cv, SCALAR());

	# Last must be an IV
	myUnify($env, $lt, $IV);

	my $t;

	# If last is a constant:
	if ($op->last->type() == OP_CONST()) {
	    # First must be an undistinguished Omicron.
	    my $list = $env->genOmicron();
	    myUnify($env, $ft, $list);

	    # Assuming $ft is an Omicron, if it's a list, the type is
	    # just the homogeneous type.
	    if ($list->homogeneous) {
		$t = $list->derefHomogeneous;
	    } else {
		my $const = getIvConst($op->last, $cv);

		# Negative index indicates a homogeneous array, since
		# we don't know where the end of the tuple is until
		# the type has been completely determined.
		if ($const < 0) {
		    myUnify($env, $list, $env->genOmicron($env->freshKappa));
		}

		$t = $list->derefIndex(getIvConst($op->last, $cv), $env);
	    }

	} else {
	    # If last is not a constant:
	    # First must be a list
	    my $list = $env->genOmicron($env->freshKappa);
	    myUnify($env, $ft, $list);

	    # The type then is just the homogeneous type
	    $t = $list->derefHomogeneous;
	}

	# Resulting type is a generic KAPPA
	($realResult, $realReturn) = ($t, undef);

    } elsif ($t == OP_HELEM()) {

	my ($ft, $fr) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	my ($lt, $lr) = typeOp($op->last, $pad2type, $env, $cv, SCALAR());

	# Last must be a non-reference scalar
	myUnify($env, $lt, $env->freshUpsilon);
	
	my $t;

	if ($op->last->type() == OP_CONST()) {
	    my $hash = $env->genChi();

	    myUnify($env, $ft, $hash);

	    if ($hash->homogeneous) {
		$t = $hash->derefHomogeneous;
	    } else {
		$t = $hash->derefIndex(getUpsilonConst($op->last, $cv), $env);
	    }
	} else {
	    my $hash = $env->genChi($env->freshKappa);
	    myUnify($env, $ft, $hash);
	    $t = $hash->derefHomogeneous;
	}

	# Resulting type is a generic KAPPA
	($realResult, $realReturn) = ($t, undef);
       
    } elsif ($t == OP_SASSIGN()) {
	
	if (B::class($op) ne "UNOP") {
	    
	    # At this point the type check is flow insensitive, and we're
	    # not doing any subtyping.  Thus, all we have to do is unify
	    # both sides with each other.

	    my ($ft, $fr) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	    my ($lt, $lr) = typeOp($op->last(), $pad2type, $env, $cv, SCALAR());

	    ($realResult, $realReturn) =
	      (myUnify($env, $ft, $lt),
	       myUnify($env, $fr, $lr));
	} else {

	    # Unless SASSIGN is a UNOP because of an ORASSIGN or an
	    # ANDASSIGN higher up in the tree.  This, of course, makes
	    # no sense and the SASSIGN isn't even used.

	    ($realResult, $realReturn) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());

	}

    } elsif ($t == OP_AASSIGN()) {

	# Infer array for lhs
	my ($lt, $lr) = typeOp($op->first(), $pad2type, $env, $cv, LIST());
	#myUnify($env, $lt, $env->genOmicron());

	# Infer array for rhs
	my ($rt, $rr) = typeOp($op->last, $pad2type, $env, $cv, LIST());
	#myUnify($env, $rt, $env->genOmicron());

	# Unify lhs and rhs
	myUnify($env, $lt, $rt);

	# Unify the return values
	myUnify($env, $lr, $rr);

	($realResult, $realReturn) = ($lt, $lr);

    } elsif ($t == OP_CONST()) {

	my $sv = $op->sv;
	($realResult, $realReturn) = constructConst($sv, $cv, $op, $env);

    } elsif ($t == OP_SPLIT()) {

	# First is always the pushre pmop, second is the string, and
	# third is the count.  
	if ($context == SCALAR() &&
	    !defined($op->first()->pmreplroot())) {
	    warn("split in a scalar context is deprecated");
	}

	my $pmreplroot = $op->first()->pmreplroot();

	# To simplify things, just make the return a homogeneous list of non-reference scalars.
	my $result = $env->genOmicron($env->freshUpsilon);

	# Do something if the target of the split is stored in the PMOP
	if (ref($pmreplroot) eq "B::GV") {
	    my $tgv = $glob2type->get($pmreplroot->STASH()->NAME() . "::" . $pmreplroot->SAFENAME(), $env);
	    myUnify($env, $result, $tgv->derefOmicron);
	} elsif (!ref($pmreplroot) and $pmreplroot) {
            my $gv = (($cv->PADLIST->ARRAY)[1]->ARRAY)[$pmreplroot];
	    my $tgv = $glob2type->get($gv->STASH()->NAME() . "::" . $gv->SAFENAME(), $env);
	    myUnify($env, $result, $tgv->derefOmicron);
        }

	# Make sure the string getting split up is a PV or number, not a ref.
	my ($st, $sr) = typeOp($op->first()->sibling(), $pad2type, $env, $cv, SCALAR());
	myUnify($env, $st, $env->freshUpsilon);

	# This last thing will always be an integer.
	my ($ct, $cr) = typeOp($op->first()->sibling()->sibling(), $pad2type, $env, $cv, SCALAR());
	myUnify($env, $ct, $IV);
	
	($realResult, $realReturn) = ($result, myUnify($env, $sr, $cr));

    } elsif ($t == OP_JOIN()) {

	# First is a pushmark, second is a PV, rest are type checked
	# in a list context but not unified.  There is potential for
	# loss of precision here.
	my ($t, $r) = typeOp($op->first()->sibling(), $pad2type, $env, $cv, SCALAR());
	myUnify($env, $t, $PV);

	my @rets;
	push(@rets, $r) if ($r);

	for (my $kid = $op->first()->sibling()->sibling(); $$kid; $kid = $kid->sibling()) {
	    ($t, $r) = typeOp($kid, $pad2type, $env, $cv, LIST());
	    push(@rets, $r) if ($r);
	}

	($realResult, $realReturn) = ($PV, myUnify($env, @rets));

    } elsif ($t == OP_MATCH()) {

	my ($t, $r) = (undef, undef);

	if ($op->flags & B::OPf_KIDS()) {
	    ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	    myUnify($env, $t, $PV);
	}

	if ($context == SCALAR()) {
	    ($realResult, $realReturn) = ($IV, $r);
	} else {
	    ($realResult, $realReturn) = ($env->genOmicron($env->freshUpsilon()), $r);
	}
    } elsif ($t == OP_SUBST()) {

	my ($t, $r);
	my @rets;

	if (${$op->pmreplstart}) {
	    ($t, $r) = typeOp($op->pmreplstart, $pad2type, $env, $cv, SCALAR());
	} else {
	    my $cur = $op->first();
	    if ($op->flags & B::OPf_STACKED()) {
		($t, $r) = typeOp($cur, $pad2type, $env, $cv, SCALAR());
		myUnify($env, $t, $PV);
		push(@rets, $r) if ($r);
		$cur = $op->last;
	    }
	    
	    ($t, $r) = typeOp($cur, $pad2type, $env, $cv, SCALAR());
	}

	push(@rets, $r) if ($r);

	($realResult, $realReturn) = ($IV, myUnify($env, @rets));

    } elsif ($t == OP_SUBSTCONT()) {

	my ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	myUnify($env, $t, $PV);
	
	($realResult, $realReturn) = ($PV, $r);

    } elsif ($t == OP_NEXTSTATE() ||
	     $t == OP_DBSTATE() ||
	     $t == OP_SETSTATE()) {

	# Has no effect on typing

	verbose(" " x $depth, "  line ", $op->line, ", file ", $op->file);
	# Set some globals for error reporting purposes
	$globalLine = $op->line;
	$globalFile = $op->file;

	($realResult, $realReturn) = (undef, undef);

    } elsif ($t == OP_COND_EXPR() ||
	     $t == OP_AND() ||
	     $t == OP_OR()) {

	# All LOGOPs
	my @types;
	my @rets;

	my ($ft, $fr) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());

	if (!($ft->is(Devel::TypeCheck::Type::O()) ||
	      $ft->is(Devel::TypeCheck::Type::X()))) {
	    myUnify($env, $ft, &$inferLogop($env));
	}

	push(@rets, $fr) if (defined($fr));

	# Remaining operands should unify together if the result wants something
	my $test = $op->flags & 3;
	
	if ($t == OP_AND() || $t == OP_OR()) {
	    push(@types, &$inferLogop($env));
	}

	my $ctx = $context;

	$ctx = SCALAR() if ($test == 2);
	$ctx = LIST() if ($test == 3);

	for (my $kid = $op->first()->sibling(); $$kid; $kid = $kid->sibling()) {
	    my ($t, $r) = typeOp($kid, $pad2type, $env, $cv, $ctx);
	    push(@types, $t) if (defined($t));
	    push(@rets, $r) if (defined($r));
	}

	my $s = undef;
	if ($test != 1) {
	    $s = myUnify($env, @types);
	}
	
	my $r = myUnify($env, @rets);
	($realResult, $realReturn) = ($s, $r);

    } elsif ($t == OP_XOR()) {

	my ($r, $missing) = typeProtoOp($op, $pad2type, $env, $cv, ($env->freshKappa, $env->freshKappa));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_ORASSIGN() ||
	     $t == OP_ANDASSIGN()) {

	my ($r, $missing) = typeProtoOp($op, $pad2type, $env, $cv, ($IV, $IV));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_SCALAR()) {

	# Get ready for an ugly hack
	my $cur = $op->first();

	$cur = $cur->sibling() if (($cur->type() == 0) && (${$cur->sibling()}));

	my ($t, $r) = typeOp($cur, $pad2type, $env, $cv, SCALAR());

	# If the operand has some scalar type, return that scalar
	# type.  Otherwise, return a fresh scalar type.
	if ($t->is(Devel::TypeCheck::Type::K())) {
	    ($realResult, $realReturn) = ($t, $r);
	} else {
	    ($realResult, $realReturn) = ($env->freshKappa, $r);
	}

    } elsif ($t == OP_WANTARRAY()) {

	# Always generate an IV
	($realResult, $realReturn) = ($IV, undef);

    } elsif ($t == OP_AV2ARYLEN()) {
	
	# Infer undistinguished AV type for operand
	my ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	myUnify($env, $t, $env->genOmicron());

	# Return IV type
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_SHIFT()     ||
	     $t == OP_POP()) {
	
	my ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	myUnify($env, $t, $env->genOmicron($env->freshKappa));

	# Return the homogeneous type of $t.
	($realResult, $realReturn) = ($t->derefHomogeneous, $r);

    } elsif ($t == OP_UNSHIFT() ||
	     $t == OP_PUSH()) {

	my ($t, $r) = typeOp($op->first()->sibling(), $pad2type, $env, $cv, SCALAR());
	myUnify($env, $t, $env->genOmicron($env->freshKappa));

	my @returns = ($r);
	my @results = ();
	for (my $kid = $op->first()->sibling()->sibling(); $$kid; $kid = $kid->sibling()) {
	    my ($t, $r) = typeOp($kid, $pad2type, $env, $cv, LIST());
	    push(@results, $t) if (defined($t));
	    push(@returns, $r) if (defined($r));
	}

	my $tt = smash(\@results, $env);
	$r = myUnify($env, @returns);

	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_PADSV()) {

	# Make sure it's a scalar value of some sort
	my $pad = $pad2type->get($op->targ, $env);
	myUnify($env, $pad, $env->freshKappa);
	($realResult, $realReturn) = ($pad, undef);

    } elsif ($t == OP_PADAV()) {

	my $pad = $pad2type->get($op->targ, $env);
	my $list = $env->genOmicron();
	myUnify($env, $pad, $list);
	($realResult, $realReturn) = ($pad, undef);

    } elsif ($t == OP_PADHV()) {
	
	my $pad = $pad2type->get($op->targ, $env);
	my $hash = $env->genChi();
	myUnify($env, $pad, $hash);
	($realResult, $realReturn) = ($pad, undef);

    } elsif ($t == OP_PADANY()) {

	# It's not implemented.  It shouldn't show up.
	die("PADANY not implemented");
	($realResult, $realReturn) = (undef, undef);

    } elsif ($t == OP_SYSTEM()) {

	my ($t, $r) = typeOpChildren_($op, $pad2type, $env, $cv);
	myUnify($env, $t, $PV);
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_PUSHMARK()) {

	# Operators that are completely ignored
	($realResult, $realReturn) = (undef, undef);

    } elsif ($t == OP_REQUIRE()) {
	
	my ($r, $missed) = typeProtoOp($op, $pad2type, $env, $cv, ($env->freshKappa()));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_CHDIR()  ||
	     $t == OP_CHROOT() ||
	     $t == OP_QUOTEMETA() ||
	     $t == OP_UNLINK()) {
	
	my ($r, $missed) = typeProto($op, $pad2type, $env, $cv, ($PV));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_GSBYNAME()) {
	# IV|AV = op(PV [, PV])
	my ($r, $missed) = typeProto($op, $pad2type, $env, $cv, ($PV, $PV));
	($realResult, $realReturn) = (contextPick($context, GSBY($env), $IV), $r);

    } elsif ($t == OP_GSBYPORT()) {

	# PV|AV = op(IV [, PV])
	my ($r, $missed) = typeProto($op, $pad2type, $env, $cv, ($IV, $PV));
	($realResult, $realReturn) = (contextPick($context, GSBY($env), $PV), $r);

    } elsif ($t == OP_BACKTICK()) {

	# List of printables
	my ($r, $missed) = typeProto($op, $pad2type, $env, $cv, ($PV));
	($realResult, $realReturn) = (contextPick($context, $env->genOmicron($env->freshUpsilon), $env->freshUpsilon), $r);
    } elsif ($t == OP_GHBYNAME()) {

	# GHBY
	my ($r, $missed) = typeProto($op, $pad2type, $env, $cv, ($PV));
	($realResult, $realReturn) = (contextPick($context, GHBY($env), $IV), $r);

    } elsif ($t == OP_GPBYNAME()) {

	# GPBY
	my ($r, $missed) = typeProto($op, $pad2type, $env, $cv, ($PV));
	($realResult, $realReturn) = (contextPick($context, GPBY($env), $IV), $r);

    } elsif ($t == OP_GNBYNAME()) {

	# GNBY
	my ($r, $missed) = typeProto($op, $pad2type, $env, $cv, ($PV));
	($realResult, $realReturn) = (contextPick($context, GNBY($env), $IV), $r);

    } elsif ($t == OP_GPWNAM()) {

	# GPW
	my ($r, $missed) = typeProto($op, $pad2type, $env, $cv, ($PV));
	($realResult, $realReturn) = (contextPick($context, GPW($env), $IV), $r);

    } elsif ($t == OP_GGRNAM()) {

	# GGR
	my ($r, $missed) = typeProto($op, $pad2type, $env, $cv, ($PV));
	($realResult, $realReturn) = (contextPick($context, GGR($env), $IV), $r);

    } elsif ($t == OP_GHBYADDR()) {

	# GHBY
	my ($r, $missed) = typeProto($op, $pad2type, $env, $cv, ($IV, $IV));
	($realResult, $realReturn) = (contextPick($context, GHBY($env), $IV), $r);

    } elsif ($t == OP_GNBYADDR()) {

	# GNBY
	my ($r, $missed) = typeProto($op, $pad2type, $env, $cv, ($IV, $IV));
	($realResult, $realReturn) = (contextPick($context, GNBY($env), $IV), $r);

    } elsif ($t == OP_GPBYNUMBER()) {

	# GPBY
	my ($r, $missed) = typeProto($op, $pad2type, $env, $cv, ($IV));
	($realResult, $realReturn) = (contextPick($context, GPBY($env), $IV), $r);

    } elsif ($t == OP_GPWUID()) {

	# GPW
	my ($r, $missed) = typeProto($op, $pad2type, $env, $cv, ($IV));
	($realResult, $realReturn) = (contextPick($context, GPW($env), $IV), $r);

    } elsif ($t == OP_GGRGID()) {

	# GGR
	my ($r, $missed) = typeProto($op, $pad2type, $env, $cv, ($IV));
	($realResult, $realReturn) = (contextPick($context, GGR($env), $IV), $r);

    } elsif ($t == OP_GHOSTENT()) {

	# GHBY
	($realResult, $realReturn) = (contextPick($context, GHBY($env), $IV), undef);
	
    } elsif ($t == OP_GNETENT()) {

	# GNBY
	($realResult, $realReturn) = (contextPick($context, GNBY($env), $IV), undef);
	
    } elsif ($t == OP_GPROTOENT()) {

	# GPBY
	($realResult, $realReturn) = (contextPick($context, GPBY($env), $IV), undef);
	
    } elsif ($t == OP_GSERVENT()) {

	# GSBY
	($realResult, $realReturn) = (contextPick($context, GSBY($env), $IV), undef);
	
    } elsif ($t == OP_GPWENT()) {

	# GPW
	($realResult, $realReturn) = (contextPick($context, GPW($env), $IV), undef);
	
    } elsif ($t == OP_GGRENT()) {

	# GGR
	($realResult, $realReturn) = (contextPick($context, GGR($env), $IV), undef);
	
    } elsif ($t == OP_EHOSTENT() ||
	     $t == OP_ENETENT() ||
	     $t == OP_EPROTOENT() ||
	     $t == OP_ESERVENT() ||
	     $t == OP_SPWENT() ||
	     $t == OP_EPWENT() ||
	     $t == OP_SGRENT() ||
	     $t == OP_EGRENT()) {
	# IV = op()
	
	($realResult, $realReturn) = ($IV, undef);
	
    } elsif ($t == OP_SHOSTENT() ||
	     $t == OP_SNETENT() ||
	     $t == OP_SPROTOENT() ||
	     $t == OP_SSERVENT()) {
	# IV = op(MKa)

	my ($r, $missed) = typeProto($op, $pad2type, $env, $cv, ($env->freshKappa));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_FTRREAD() ||
	     $t == OP_FTRWRITE() ||
	     $t == OP_FTREXEC() ||
	     $t == OP_FTEREAD() ||
	     $t == OP_FTEWRITE() ||
	     $t == OP_FTEEXEC() ||
	     $t == OP_FTIS() ||
	     $t == OP_FTEOWNED() ||
	     $t == OP_FTROWNED() ||
	     $t == OP_FTZERO() ||
	     $t == OP_FTSIZE() ||
	     $t == OP_FTMTIME() ||
	     $t == OP_FTATIME() ||
	     $t == OP_FTCTIME() ||
	     $t == OP_FTSOCK() ||
	     $t == OP_FTCHR() ||
	     $t == OP_FTBLK() ||
	     $t == OP_FTFILE() ||
	     $t == OP_FTDIR() ||
	     $t == OP_FTPIPE() ||
	     $t == OP_FTLINK() ||
	     $t == OP_FTSUID() ||
	     $t == OP_FTSGID() ||
	     $t == OP_FTSVTX() ||
	     $t == OP_FTTTY() ||
	     $t == OP_FTTEXT() ||
	     $t == OP_FTBINARY()) {

	# If we're doing it to an IO handle, then this is a PADOP
	# instead of a UNOP, and there aren't really any operands to
	# check.
	my ($t, $r) = (undef, undef);
	if ($op->flags & B::OPf_KIDS) {
	    ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	    myUnify($env, $t, $PV);
	}

	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_STAT() ||
	     $t == OP_LSTAT()) {

	my ($r, $missed) = typeProtoOp($op, $pad2type, $env, $cv, ($PV));
	($realResult, $realReturn) = ($env->genOmicronTuple($IV, $IV, $IV, $IV, $IV, $IV, $IV, $IV, $IV, $IV, $IV, $IV, $IV), $r);
	
    } elsif ($t == OP_REGCMAYBE() ||
	     $t == OP_REGCRESET() ||
	     $t == OP_REGCOMP() ||
	     $t == OP_QR() ||
	     $t == OP_SCHOP() ||
	     $t == OP_SCHOMP() ||
	     $t == OP_UCFIRST() ||
	     $t == OP_LCFIRST() ||
	     $t == OP_UC() ||
	     $t == OP_LC() ||
	     $t == OP_READLINK()) {

	my ($r, $missed) = typeProtoOp($op, $pad2type, $env, $cv, ($PV));
	($realResult, $realReturn) = ($PV, $r);
	
    } elsif ($t == OP_STUDY() ||
	     $t == OP_POS() ||
	     $t == OP_RMDIR()) {

	my ($r, $missed) = typeProtoOp($op, $pad2type, $env, $cv, ($PV));
	($realResult, $realReturn) = ($IV, $r);
	
    } elsif ($t == OP_SRAND() ||
	     $t == OP_ALARM()) {

	my ($r, $missed) = typeProtoOp($op, $pad2type, $env, $cv, ($IV));
	($realResult, $realReturn) = ($IV, $r);
	
    } elsif ($t == OP_CHR()) {

	my ($r, $missed) = typeProtoOp($op, $pad2type, $env, $cv, ($IV));
	($realResult, $realReturn) = ($PV, $r);
	
    } elsif ($t == OP_LOCALTIME() ||
	     $t == OP_GMTIME()) {

	my ($r, $missed) = typeProtoOp($op, $pad2type, $env, $cv, ($IV));
	($realResult, $realReturn) = (contextPick($context, $env->genOmicronTuple($IV, $IV, $IV, $IV, $IV, $IV, $IV, $IV, $IV), $PV), $r);

    } elsif ($t == OP_DELETE()) {

	# homogenize aggregate data types, sort of like push, pop, shift, and unshift.
	my ($t, $r);
	if ($op->first()->targ == OP_AELEM()) {
	    my $list = $env->genOmicron($env->freshKappa);
	    ($t, $r) = typeOp($op->first()->first(), $pad2type, $env, $cv, SCALAR());
	    myUnify($env, $t, $list);

	    my ($t0, $r0) = typeOp($op->first()->sibling(), $pad2type, $env, $cv, SCALAR());
	    myUnify($env, $t0, $IV);
	    myUnify($env, $r0, $r);
	} elsif ($op->first()->targ == OP_HELEM()) {
	    my $list = $env->genChi($env->freshKappa);
	    ($t, $r) = typeOp($op->first()->first(), $pad2type, $env, $cv, SCALAR());
	    myUnify($env, $t, $list);

	    my ($t0, $r0) = typeOp($op->first()->first()->sibling(), $pad2type, $env, $cv, SCALAR());
	    myUnify($env, $t0, $env->freshUpsilon);
	    myUnify($env, $r0, $r);
	} else {
	    confess("unknown invocation of OP_DELETE, expected an ex-aelem or ex-helem as operand");
	}

	($realResult, $realReturn) = ($IV, $r);
	
    } elsif ($t == OP_EXISTS()) {

	my ($t, $r) = typeOpChildren($op, $pad2type, $env, $cv);
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_FORK() ||
	     $t == OP_WAIT() ||
	     $t == OP_TIME()) {

	($realResult, $realReturn) = ($IV, undef);

    } elsif ($t == OP_TMS()) {

	($realResult, $realReturn) = (contextPick($context, $env->genOmicronTuple($IV, $IV, $IV, $IV), $DV), undef);

    } elsif ($t == OP_TRANS()) {

	($realResult, $realReturn) = ($PV, undef);

    } elsif ($t == OP_GLOB() ||
	     $t == OP_RCATLINE()) {

	my ($t, $r) = typeOpChildren($op, $pad2type, $env, $cv);
	($realResult, $realReturn) = ($env->fresh, $r);
	
    } elsif ($t == OP_READLINE()) {
	
	my ($t, $r) = typeOpChildren($op, $pad2type, $env, $cv);

	if ($context == SCALAR()) {
	    ($realResult, $realReturn) = ($env->freshUpsilon(), $r);
	} else {
	    ($realResult, $realReturn) = ($env->genOmicron($env->freshUpsilon()), $r);
	}

    } elsif ($t == OP_UNDEF()) {

	# Can't infer type here, since undef may legitimately be used
	# to vacate variables of any sort.  Still, we should typecheck
	# the argument, if there is one.
	my ($t, $r) = (undef, undef);
	if ($op->flags & B::OPf_KIDS()) {
	    ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	}

	# Generate a type of ref to var
	($realResult, $realReturn) = ($env->freshKappa(), $r);

    } elsif ($t == OP_GOTO() ||
	     $t == OP_DUMP()) {

	# Make sure the argument to goto (if there is one) is at least
	# internally consistent.
	my ($t, $r) = (undef, undef);
	if ($op->flags & B::OPf_KIDS()) {
	    ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	}	

	($realResult, $realReturn) = (undef, $r);
	
    } elsif ($t == OP_UNSTACK() ||
	     $t == OP_LAST()    ||
	     $t == OP_NEXT()    ||
	     $t == OP_REDO()) {

	($realResult, $realReturn) = (undef, undef);

    } elsif ($t == OP_DIE() ||
	     $t == OP_WARN()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($ANY));
	($realResult, $realReturn) = (undef, myUnify($env, $r));

    } elsif ($t == OP_EXIT()) {

	my ($t, $r);
	if ($op->flags & B::OPf_KIDS()) {
	    ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	}

	($realResult, $realReturn) = (undef, $r);

    } elsif ($t == OP_RETURN()) {
	
	my ($t, $r) = typeOpChildren($op, $pad2type, $env, $cv, LIST());

	($realResult, $realReturn) = ($t, $t);

    } elsif ($t == OP_METHOD() ||
	     $t == OP_METHOD_NAMED()) {

	($realResult, $realReturn) = ($env->genRho($env->freshZeta), undef);

    } elsif ($t == OP_GREPWHILE() ||
	     $t == OP_MAPWHILE()) {
	
	my ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	($realResult, $realReturn) = (contextPick($context, $t, $env->freshKappa), $r);

    } elsif ($t == OP_CUSTOM()) {
	
	my ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	($realResult, $realReturn) = ($env->fresh, $r);

    } elsif ($t == OP_FLIP() ||
	     $t == OP_FLOP()) {

	my ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, $context);
	myUnify($env, ,$t, $env->genOmicron());
	($realResult, $realReturn) = ($t, $r);

    } elsif ($t == OP_DEFINED() ||
	     $t == OP_UNTIE() ||
	     $t == OP_LOCK()) {

	my ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_CHOP() ||
	     $t == OP_CHOMP()) {

	my ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, LIST());
	($realResult, $realReturn) = ($env->genOmicron($env->freshUpsilon), $r);

    } elsif ($t == OP_SORT()) {

	my ($t, $r);

	# If the first argument is a scope or a bareword
	if ($op->first()->sibling()->type() == OP_NULL() &&
	    ($op->first()->sibling()->first()->type() == OP_SCOPE() ||
	     ($op->first()->sibling()->first()->type() == OP_CONST() &&
	      $op->first()->sibling()->first()->private & 64) ||
	     ($op->first()->sibling()->first()->type() == OP_NULL() &&
	      $op->first()->sibling()->first()->first()->type() == OP_ENTER()))) {
	    # Type it but don't do anything
	    typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	    typeOp($op->first()->sibling(), $pad2type, $env, $cv, SCALAR());

	    # Type the rest
	    ($t, $r) = typeOpChildrenSkip($op, $pad2type, $env, $cv, LIST(), 2);

	} else {
	    # Otherwise type everything
	    ($t, $r) = typeOpChildren($op, $pad2type, $env, $cv, LIST());
	}

	my $list = $env->genOmicron($env->freshKappa);

	myUnify($env, $list, $t);

	($realResult, $realReturn) = ($list, $r);

    } elsif ($t == OP_REVERSE()) {

	my ($t, $r) = typeOpChildren($op, $pad2type, $env, $cv, LIST());
	my $list;  

	if ($context == SCALAR()) {
	    $list = $env->genOmicron($PV);
	    myUnify($env, $list, $t);
	    ($realResult, $realReturn) = ($PV, $r);
	} else {
	    $list = $env->genOmicron($env->freshKappa);
	    myUnify($env, $list, $t);
	    ($realResult, $realReturn) = ($list, $r);
	}
	
    } elsif ($t == OP_EXEC() ||
	     $t == OP_KILL() ||
	     $t == OP_SYSCALL()) {
	
	my ($t, $r) = typeOpChildren($op, $pad2type, $env, $cv);
	($realResult, $realReturn) = ($IV, $r);
	
    } elsif ($t == OP_SETPRIORITY() ||
	     $t == OP_SHMGET() ||
	     $t == OP_SHMCTL() ||
	     $t == OP_MSGCTL() ||
	     $t == OP_SEMGET()){

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($IV, $IV, $IV));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_VALUES()) {

	# All values must be able to unify if values() is used.
	my $list = $env->genChi($env->freshKappa);
	my ($r, $missing) = typeProtoOp($op, $pad2type, $env, $cv, ($list));
	($realResult, $realReturn) = ($list, $r);

    } elsif ($t == OP_KEYS()) {

	# All keys are of type Upsilon
	my ($r, $missing) = typeProtoOp($op, $pad2type, $env, $cv, ($env->genChi()));
	($realResult, $realReturn) = ($env->genOmicron($env->freshUpsilon), $r);

    } elsif ($t == OP_EACH()) {

	my $hash = $env->genChi($env->freshKappa);
	my ($r, $missing) = typeProtoOp($op, $pad2type, $env, $cv, ($hash));
	($realResult, $realReturn) = ($hash->subtype, $r);

    } elsif ($t == OP_LSLICE()) {

	# lslice is what you get when you do ("a", "b")[2, 3]

	my $list = $env->genOmicron();
	my $selection = $env->genOmicron($IV);

	# This should
	#   Typecheck as (list, undistinguished)
	#   return the list type
	my ($realReturn, $missing) = typeProtoOp($op, $pad2type, $env, $cv, ($selection, $list));
	
	my $consts = extractConstList($op->first(), $cv);

	# If the slice is an array of constants
	if (defined($consts)) {
	    # Project a tuple
	    $realResult = $env->genOmicron();
	    foreach my $i (@$consts) {
		$realResult = $realResult->append($list->derefIndex($i, $env), $env);
	    }
	} else {
	    # Project a list
	    $realResult = $env->genOmicron($env->freshKappa);
	    myUnify($env, $realResult, $list);
	}

	# If we're in a scalar context and there is only one operand
	# describing the projection, dereference the type for the
	# zeroth index.  This works if it's a tuple, since the
	# assertion about $op->first()->first()->sibling()->sibling() ensures
	# that there is only one element in the $realResult.  The type
	# at the zeroth index may also be the homogeneous type.
	if ($context == SCALAR() &&
	    $op->first()->first()->sibling()->sibling()->isa("B::NULL")) {
	   $realResult = $realResult->derefIndex(0, $env);
	}
	
    } elsif ($t == OP_TIED()) {

	my ($r, $missing) = typeProtoOp($op, $pad2type, $env, $cv, ($env->fresh));
	($realResult, $realReturn) = ($env->fresh, $r);

    } elsif ($t == OP_REPEAT()) {
	my ($t, $r, $t0, $r0);

	my @rets;

	# List repeat
	if ($op->private & 64) {
	    ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, LIST());

	    @rets = ($r);
	    if (${$op->last}) {
		($t0, $r0) = typeOp($op->last, $pad2type, $env, $cv, SCALAR());
		myUnify($env, $t0, $IV);
		push(@rets, $r0) if ($r0);
	    }

	    # Turn the type in to a list, if possible.
	    myUnify($env, $t, $env->genOmicron($env->freshKappa));

	    ($realResult, $realReturn) = ($t, myUnify($env, @rets));
	} else {
	    # PV repeat
	    ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	    myUnify($env, $t, $PV);
	    push(@rets, $r0) if ($r);

	    ($t0, $r0) = typeOp($op->last, $pad2type, $env, $cv, SCALAR());
	    myUnify($env, $t0, $IV);
	    push(@rets, $r0) if ($r0);

	    ($realResult, $realReturn) = ($PV, myUnify($env, @rets));
	}

    } elsif ($t == OP_CALLER()) {

	my ($r, $missing) = typeProtoOp($op, $pad2type, $env, $cv, ($IV));
	($realResult, $realReturn) = (contextPick($context, $env->genOmicronTuple($PV, $PV, $IV, $PV, $IV, $IV, $PV, $IV, $IV, $IV), $PV), $r);

    } elsif ($t == OP_RANGE()) {

	my $scalar = $env->freshUpsilon();
	my ($r, $missing) = typeProtoOp($op, $pad2type, $env, $cv, ($scalar, $scalar));
	($realResult, $realReturn) = ($env->genOmicron($scalar), $r);

    } elsif ($t == OP_RESET()) {

	my ($r, $missing) = typeProtoOp($op, $pad2type, $env, $cv, ($PV));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_CLOSE() ||
	     $t == OP_FILENO() ||
	     $t == OP_EOF() ||
	     $t == OP_TELL() ||
	     $t == OP_TELLDIR() ||
	     $t == OP_REWINDDIR() ||
	     $t == OP_CLOSEDIR()) {
	
	my ($r, $missing) = typeProtoOp($op, $pad2type, $env, $cv, ($env->freshEta));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_UMASK()) {

	my ($r, $missing) = typeProtoOp($op, $pad2type, $env, $cv, ($PV));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_DBMCLOSE()) {

	my ($r, $missing) = typeProtoOp($op, $pad2type, $env, $cv, ($env->genChi()));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_MKDIR()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($PV, $IV));
	($realResult, $realReturn) = ($IV, $r);	

    } elsif ($t == OP_READDIR()) {
	
	my ($r, $missing) = typeProtoOp($op, $pad2type, $env, $cv, ($env->freshEta));
	($realResult, $realReturn) = (contextPick($context, $env->genOmicron($PV), $PV), $r);

    } elsif ($t == OP_INDEX() ||
	     $t == OP_RINDEX()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($PV, $PV, $IV));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_RENAME() ||
	     $t == OP_LINK() ||
	     $t == OP_SYMLINK()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($PV, $PV));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_CRYPT()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($PV, $PV));
	($realResult, $realReturn) = ($PV, $r);

    } elsif ($t == OP_FLOCK() ||
	     $t == OP_BIND() ||
	     $t == OP_CONNECT() ||
	     $t == OP_SHUTDOWN() ||
	     $t == OP_SEEKDIR()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($env->freshEta, $IV));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_SYSSEEK() ||
	     $t == OP_SEEK() ||
	     $t == OP_FCNTL() ||
	     $t == OP_IOCTL() ||
	     $t == OP_GSOCKOPT()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($env->freshEta, $IV, $IV));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_SYSREAD() ||
	     $t == OP_SYSWRITE() ||
	     $t == OP_READ() ||
	     $t == OP_SEND() ||
	     $t == OP_RECV()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($env->freshEta, $env->freshKappa, $IV, $IV));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_PIPE_OP() ||
	     $t == OP_ACCEPT()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($env->freshEta, $env->freshEta));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_BINMODE() ||
	     $t == OP_OPEN_DIR()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($env->freshEta, $PV));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_SOCKET()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($env->freshEta, $IV, $IV, $IV));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_OPEN() ||
	     $t == OP_UTIME()) {

	# This operator is way too overloaded:
	# OP_OPEN         IV = fop(MKPMH(a, ...) [, PV [, PV|MKPMH(b, ...) [, ...]]]) | op()

	my ($t, $r) = typeOpChildren($op, $pad2type, $env, $cv);
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_SYSOPEN()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($env->freshEta, $PV, $IV, $IV));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_SOCKPAIR()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($env->freshEta, $env->freshEta, $IV ,$IV, $IV));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_SSOCKOPT()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($env->freshEta, $IV, $IV, $env->freshKappa));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_SPRINTF() ||
	     $t == OP_FORMLINE()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($PV, $ANY));
	($realResult, $realReturn) = ($PV, $r);

    } elsif ($t == OP_PACK()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($PV, $ANY));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_UNPACK()) {
	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($PV, $IV));
	($realResult, $realReturn) = ($env->genOmicron($env->freshUpsilon), $r);

    } elsif ($t == OP_MSGGET() ||
	     $t == OP_SEMOP()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($IV, $IV));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_SHMREAD() ||
	     $t == OP_SHMWRITE()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($IV, $PV, $IV, $IV));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_MSGSND()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($IV, $PV, $IV, $IV, $IV));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_SEMCTL()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($IV, $IV, $IV, $IV));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_MSGRCV()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($IV, $PV, $IV));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_TRUNCATE()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($PV, $IV));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_CHOWN()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($IV, $IV, $ANY));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_CHMOD()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($IV, $ANY));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_PRTF()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($ANY));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_SSELECT()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($IV, $IV, $IV, $env->freshKappa));
	($realResult, $realReturn) = (contextPick($context, $env->genOmicronTuple($IV, $DV), $IV), $r);

    } elsif ($t == OP_SELECT()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($env->fresh));
	($realResult, $realReturn) = ($PV, $r);

    } elsif ($t == OP_TIE()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($env->fresh, $PV, $ANY));
	($realResult, $realReturn) = (undef, $r);

    } elsif ($t == OP_STRINGIFY()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($env->freshKappa));
	($realResult, $realReturn) = ($PV, $r);

    } elsif ($t == OP_SUBSTR()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($PV, $IV, $IV, $IV));
	($realResult, $realReturn) = ($PV, $r);

    } elsif ($t == OP_VEC()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($env->freshKappa, $IV, $IV));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_ASLICE()) {

	my $list = $env->genOmicron($env->freshKappa);
	my $select = $env->genOmicron($IV);
	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($select, $list));
	($realResult, $realReturn) = ($list, $r);

    } elsif ($t == OP_HSLICE()) {

	my $hash = $env->genChi($env->freshKappa);
	my $select = $env->genOmicron($PV);
	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($select, $hash));
	($realResult, $realReturn) = ($env->genOmicron($hash->derefHomogeneous()), $r);

    } elsif ($t == OP_ANONHASH()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($ANY));
	($realResult, $realReturn) = ($env->genChi(), $r);

    } elsif ($t == OP_SPLICE()) {

	my $ary = $env->genOmicron($env->freshKappa);
	my $list = $env->genOmicron($env->freshKappa);
	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($ary, $IV, $IV, $list));

	# Unify the two, to make sure we're not inserting incompatible junk in to the array
	myUnify($env, $ary, $list);

	($realResult, $realReturn) = ($ary, $r);

    } elsif ($t == OP_GREPSTART()) {

	my $type = $env->genOmicron($env->freshKappa);
	my @results;
	my @returns;

	my $subop = $op->first()->sibling();

	# Type the first as an integer
	my ($t, $r) = typeOp($subop, $pad2type, $env, $cv, SCALAR());
	myUnify($env, $t, $IV);

        # Smash the rest in to a list
	for (my $kid = $subop->sibling(); $$kid; $kid = $kid->sibling()) {
	    # Type the kid
	    my ($s, $r) = typeOp($kid, $pad2type, $env, $cv, LIST());
	
	    if (defined($s)) {
		push(@results, $s);
	    }
    
	    # Set up unify of return values from down in the tree
	    if (defined($r)) {
		push(@returns, $r);
	    }
	}
	my $result = smash(\@results, $env);
	myUnify($env, $result, $type);
	myUnify($env, @returns, $r);

	($realResult, $realReturn) = ($type, $r);

    } elsif ($t == OP_MAPSTART()) {

	my $type = $env->freshKappa;
	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($type, $env->genOmicron($type)));
	($realResult, $realReturn) = ($env->genOmicron($type), $r);

    } elsif ($t == OP_DBMOPEN()) {

	my ($r, $missing) = typeProto($op, $pad2type, $env, $cv, ($env->genChi(), $PV, $IV));
	($realResult, $realReturn) = ($IV, $r);

    } elsif ($t == OP_LENGTH()) {

	my ($t, $r) = typeOp($op->first(), $pad2type, $env, $cv, SCALAR());
	myUnify($env, $t, $PV);
	($realResult, $realReturn) = ($IV, $r);

    } else {

	# OP_LEAVEEVAL() is here implicitly
	# OP_THREADSV() is here implicitly
	
	verbose("Typing for OP ", $t, " is unimplemented\n");

	# Try to do something sane depending on context
	if ($context == SCALAR()) {
	    ($realResult, $realReturn) = ($env->fresh, undef);
	} else {
	    ($realResult, $realReturn) = ($env->genOmicron(), undef);
	}

    }

    if (defined($realReturn)) {
        verbose(" " x $depth, "  ", "non-null return value ", myPrint($env->find($realReturn), $env));
    }

    verbose(" " x $depth, "} = ", $realResult?myPrint($env->find($realResult), $env):"void");
    $depth -= $depthIncrement;

    return ($realResult, $realReturn);
}

sub typecheck {
    my ($op, $cv, $env) = @_;

    my $pad2type = Devel::TypeCheck::Pad2type->new();

    my ($resType, $retType) = typeOp($op, $pad2type, $env, $cv, SCALAR());

    $resType = $resType?($env->find($resType)):undef;
    $retType = $retType?($env->find($retType)):undef;

    $pad2type->print(\*STDOUT, $cv, $env);

    return ($resType, $retType);
}

sub B::GV::subscribe {
    my ($this) = @_;

    no strict 'refs';
    my $refname = $this->STASH->NAME . "::" . $this->NAME;
    if (*{$refname}{CODE}) {
	my %cur;
	my $ref = \&{$refname};
	my $cv = B::svref_2object($ref);
	my $op = $cv->ROOT;
	if (!$op->isa("B::NULL")) {
	    $cur{'op'} = $op;
	    $cur{'cv'} = $cv;
	    my $name = $this->STASH->NAME . "::" . $this->SAFENAME;
	    $roots{$name} = \%cur;
	}
    }
}

sub checkCV {
    my ($env, $op, $cv, $name) = @_;

    my $storedDepth = $depth;
    $depth = 0;

    # Ad-hoc change to localize *_
    $glob2type->del("main::_");

    eval {
	$depth = 0;
	my ($t, $r) = typecheck($op, $cv, $env);
	# glob->get always returns an Eta
	my $p = $glob2type->get("main::_", $env)->derefOmicron();

	if (defined($p)) {
	    print("  Parameter type of $name is ", myPrint($p, $env), "\n");
	} else {
	    print("  Parameter type of $name is undefined\n");
	}

	if (defined($t)) {
	    print("  Result type of $name is ", myPrint($t, $env), "\n");
	} else {
	    print("  Result type of $name is undefined\n");
	}
	if (defined($r)) {
	    print("  Return type of $name is ", myPrint($r, $env), "\n");

	    # Assign type to the current CV
	    my $iType = $glob2type->get($name, $env)->derefZeta();
	    my $infType = $env->genZeta($p, $r);
	    myUnify($env, $iType, $infType);
	} else {
	    print("  Return type of $name is undefined\n");
	}
	print("\n");
    };
	
    if ($@) {
	if ($@ =~ /^TYPE ERROR:/ && $continue) {
	    print($@, "\n");
	} else {
	    die($@);
	}
    }

    # Ad-hoc change to localize *_
    $glob2type->del("main::_");

    $depth = $storedDepth;
}

sub callback {
    if ($relax) {
	$inferLogop = \&inferUpsilon;
    } else {
	$inferLogop = \&inferNu;
    }

    for my $name (@modules) {
	no strict 'refs';
	B::walksymtable(\%{$name}, 'subscribe', sub { return FALSE() }, $name);
    }

    for my $name (@cvnames) {
	# From B::Concise::compile
	$name = "main::" . $name unless $name =~ /::/;

	no strict 'refs';
	die "err: unknown function ($name)\n"
	    unless *{$name}{CODE};
	my $ref = \&$name;

	# &From B::Concise::concise_subref
	my $cv = B::svref_2object($ref);
	die "err: not a coderef: $ref\n" unless ref $cv eq 'B::CV';#CODE';

	my $op = $cv->ROOT;

	my %cur;
	$cur{'op'} = $op;
	$cur{'cv'} = $cv;
	$roots{$name} = \%cur;
    }

    if ($all) {
	no strict 'refs';
	B::walksymtable(\%{"main::"}, 'subscribe', sub { return TRUE() }, undef);
    }

    if ($mainRoot) {
	my %cur;
	$cur{'op'} = B::main_root();
	$cur{'cv'} = B::main_cv();
	$roots{'main::MAIN'} = \%cur;
    }

    $glob2type = Devel::TypeCheck::Glob2type->new();

    my $env = Devel::TypeCheck::Environment->new();

    print("Type checking CVs:\n");
    @list = keys(%roots);
    while ($#list >= 0) {
#	next unless (blessed($i));
	my $i = shift(@list);
	print("  $i\n");
	checkCV($env, $roots{$i}->{'op'}, $roots{$i}->{'cv'}, $i)
    }

    my ($i, $t);

    print STDOUT ("Global Symbol Table Types:\n");
    print STDOUT ("Name                Type\n");
    print STDOUT ("------------------------------------------------------------------------------\n");

    format STDOUT =
@<<<<<<<<<<<<<<<<<< @*
$i,                 $t
.
    
    for $i (sort($glob2type->symbols)) {
        $t = myPrint($glob2type->get($i, $env), $env);
        write STDOUT;
    }

    print("Total opcodes processed: $opcodes\n");
}

1;
