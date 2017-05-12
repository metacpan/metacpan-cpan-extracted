# Math::Evol.pm
#########################################################################
#        This Perl module is Copyright (c) 2002, Peter J Billam         #
#               c/o P J B Computing, www.pjb.com.au                     #
#                                                                       #
#     This module is free software; you can redistribute it and/or      #
#            modify it under the same terms as Perl itself.             #
#########################################################################

package Math::Evol;
no strict;
$VERSION = '1.12';
# gives a -w warning, but I'm afraid $VERSION .= ''; would confuse CPAN
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(evol select_evol text_evol);
@EXPORT_OK = qw(arr2txt gaussn);

# various epsilons used in convergence testing ...
$ea = 0.00000000000001;   # absolute stepsize
$eb = 0.000000001;        # relative stepsize
$ec = 0.0000000000000001; # absolute error
$ed = 0.00000000001;      # relative error

sub new {
	my $arg1 = shift;
	my $class = ref($arg1) || $arg1; # can be used as class or instance method
	my $self  = {};   # ref to an empty hash
	bless $self, $class;
	$self->_initialise();
	return $self;
}


sub evol { my ( $xbref,$smref, $func_ref,$constrain_ref, $tm) = @_;
	if (ref $xbref ne 'ARRAY') {
		die "Math::Evol::evol 1st arg must be an array ref\n";
	} elsif (ref $smref ne 'ARRAY') {
		die "Math::Evol::evol 2nd arg must be an array ref\n";
	} elsif (ref $func_ref ne 'CODE') {
		die "Math::Evol::evol 3rd arg must be a function ref\n";
	} elsif ($constrain_ref && (ref $constrain_ref) ne 'CODE') {
		die "Math::Evol::evol 4th arg must be a function ref\n";
	}
	my @xb = @$xbref;
	my @sm = @$smref;
	if (! $tm) { $tm = 10.0; }
	$tm = abs $tm;

	my $debug = 0;
	my $n = scalar @xb;      # number of variables
	my $nm1 = $n + $[ - 1;   # last index
	my ($usr_o, $sys_o) = times;
	my ($fc, $rel_limit);    # used to test convergence

	# step-size adjustment stuff, courtesy Rechenberg ...
	my @l; foreach (1 .. 10) { push @l, $n*$_/5.0; } # 6
	my $le = $n+$n; my $lm = 0; my $lc = 0;

	if ($constrain_ref) { @xb = &$constrain_ref(@xb); }
	$fb = &$func_ref(@xb); $fc = $fb;
	while (1) {
		foreach $i ($[ .. $nm1) { $x[$i] = $xb[$i]+&gaussn($sm[$i]); }
		if ($constrain_ref) {
			@x = &$constrain_ref(@x);
			warn 'new @x is '.&arr2txt(@x) if $debug;
		}
		$ff = &$func_ref (@x);   # find new objective function
		if ($ff <= $fb) { $le++; $fb=$ff; @xb=@x; }
		$lm++;  if ($lm < $n) { next; }

   		# adjust the step sizes ...
		my $k = 0.85 ** ($n+$n <=> $le-$l[$[]);
		foreach $i ($[ .. $nm1) {
			$sm[$i] *=  $k;
			$rel_limit = abs ($eb * $xb[$i]);
			if ($sm[$i] < $rel_limit) { $sm[$i] = $rel_limit; }
			if ($sm[$i] < $ea) { $sm[$i] = $ea; }
		}
		# could i_l%10 the index as in lua, rather than shift and push as here
		shift @l; push (@l, $le); $lm = 0;
		if ($debug) {
			warn "le=$le l[0]=$l[$[] n=$n k=$k\n";
			warn "new step sizes sm = ".&arr2txt(@sm);
			warn "new l = ".&arr2txt(@l);
		}

		if (defined $ea) { $ea = abs $ea; }
		if (defined $eb) { $eb = abs $eb; }
		if (defined $ec) { $ec = abs $ec; }
		if (defined $ed) { $ed = abs $ed; }
		warn sprintf("fb=%g fc=%g ec=%g ed=%g\n",$fb,$fc,$ec,$ed) if $debug;
		$lc++;
		if ($lc < 25) {
			my ($usr_n, $sys_n) = times;
			if (($usr_n+$sys_n - $usr_o-$sys_o) > $tm) {   # out of time ?
				warn "exceeded $tm seconds\n" if $debug;
				return (\@xb, \@sm, $fb, 0);   # return best current value
			} else { next;
			}
		}
		if ((defined $ec) && (($fc-$fb) <= $ec)) {
			warn "converged absolutely\n" if $debug;
			return (\@xb, \@sm, $fb, 1);   # 29
		}
		if ((defined $ed) && (($fc-$fb)/$ed <= abs($fc))) {
			warn "converged relativelty\n" if $debug;
			return (\@xb, \@sm, $fb, 1);
		}
		$lc = 0; $fc = $fb; next;
	}
}

sub select_evol { my ($xbref,$smref,$func_ref,$constrain_ref,$nchoices) = @_;
	if (ref $xbref ne 'ARRAY') {
		die "Math::Evol::select_evol 1st arg must be an array ref\n";
	} elsif (ref $smref ne 'ARRAY') {
		die "Math::Evol::select_evol 2nd arg must be an array ref\n";
	} elsif (ref $func_ref ne 'CODE') {
		die "Math::Evol::select_evol 3rd arg must be a function ref\n";
	} elsif ($constrain_ref && (ref $constrain_ref) ne 'CODE') {
		die "Math::Evol::select_evol 4th arg must be a function ref\n";
	}
	my @xb = @$xbref;
	my @sm = @$smref;
	if (! $nchoices) { $nchoices = 1; }

	my $debug = 0;
	my $n = scalar @xb;      # number of variables
	my $nm1 = $n + $[ - 1;   # last index
	my ($choice, $continue);

	# step-size adjustment stuff, courtesy Rechenberg
	# modified from Schwefel's sliding flat window average to an EMA
	my $desired_success_rate = 1.0 - 0.8**$nchoices;
	my $success_rate = $desired_success_rate; 
	# test every 5*$n binary choices equivalent - 10*$n is just too slow.
	my $lm = 0;
	my $test_every = 5 * $n * (log 2) / (log ($nchoices+1));
	my $ema = exp (-1.0 / $test_every);
	my $one_m_ema = 1.0 - $ema;
	warn sprintf
	("n=$n nchoices=$nchoices success_rate=%g test_every=%g ema=%g\n",
	 $success_rate, $test_every, $ema) if $debug;

	if ($constrain_ref) { @xb = &$constrain_ref(@xb); }
	my @func_args;  # array of refs to arrays
	while () {
		my @x;  #XXX?
		@func_args = ( \@xb );
		foreach (1 .. $nchoices) {
			foreach $i ($[ .. $nm1) {
				$x[$i] = $xb[$i]+&gaussn($sm[$i]);
			}
			if ($constrain_ref) { @x = &$constrain_ref(@x); }
			push @func_args, [ @x ];
		}
		($choice, $continue) = &$func_ref(@func_args);
		if ($choice > $[) {
			@xb = @{$func_args[$choice]};
			$success_rate = $one_m_ema + $ema*$success_rate;
		} else {
			$success_rate = $ema*$success_rate;
		}
		warn "success_rate=$success_rate\n" if $debug;
		if (!$continue) { return (\@xb, \@sm); }
		$lm++; if ($lm < $test_every) { next; }

   	# adjust the step sizes ...
		my $k = 0.85 ** ($desired_success_rate <=> $success_rate);
		warn "success_rate=$success_rate k=$k\n" if $debug;
		foreach $i ($[ .. $nm1) {
			$sm[$i] *=  $k;
			$rel_limit = abs ($eb * $xb[$i]);
			if ($sm[$i] < $rel_limit) { $sm[$i] = $rel_limit; }
			if ($sm[$i] < $ea) { $sm[$i] = $ea; }
		}
		warn "new step sizes sm = ".&arr2txt(@sm) if $debug;
		$lm = 0;
	}
}

sub text_evol { my ($text, $nchoices); local ($func_ref);
	($text, $func_ref, $nchoices) = @_;
	return unless $text;
	if (ref $func_ref ne 'CODE') {
		die "Math::Evol::text_evol 2nd arg must be a function ref\n";
	}
	if (! $nchoices) { $nchoices = 1; }

	my $debug = 0;
	local @text = split ("\n", $text);
	my ($linenum,$m,@xb,@sm,@min,@max) = ($[,0);
	local (@linenums, @firstbits, @middlebits, $lastbit);
	my $n = $[ - 1; foreach (@text) {
		if (/^(.*?)(-?[\d.]+)(\D+)evol\s+step\s+([\d.]+)(.*)$/) {
			$n++; $linenums[$n] = $linenum; $firstbits[$n]=$1;
			$xb[$n]=$2; $middlebits[$n]=$3; $sm[$n]=$4; $lastbit = $5;
			if ($lastbit =~ /min\s+([-\d.]+)/) { $min[$n] = $1; }
			if ($lastbit =~ /max\s+([-\d.]+)/) { $max[$n] = $1; }
		}
		$linenum++;
	}
	warn "xb = ".&arr2txt(@xb) if $debug;
	warn "sm = ".&arr2txt(@sm) if $debug;

	# construct the constraint routine
	my $some_constraints = 0;
	my @sub_constr = ("sub constrain {\n");
	my $i = $[; while ($i <= $n) {
		if (defined $min[$i] && defined $max[$i]) {
			push @sub_constr,"\tif (\$_[$i]>$max[$i]) { \$_[$i]=$max[$i];\n";
			push @sub_constr,"\t} elsif (\$_[$i]<$min[$i]) { \$_[$i]=$min[$i];\n";
			push @sub_constr,"\t}\n";
		} elsif (defined $min[$i]) {
			push @sub_constr,"\tif (\$_[$i]<$min[$i]) { \$_[$i]=$min[$i]; }\n";
		} elsif (defined $max[$i]) {
			push @sub_constr,"\tif (\$_[$i]>$max[$i]) { \$_[$i]=$max[$i]; }\n";
		}
		if (defined $min[$i] || defined $max[$i]) { $some_constraints++; }
		$i++;
	}
	push @sub_constr, "\treturn \@_;\n}\n";
	warn join ('', @sub_constr)."\n" if $debug;

	sub choose_best {
		my $xbref; my $linenum; @texts = ();
		while ($xbref = shift @_) {
			my @newtext = @text; my $i = $[;
			foreach $linenum (@linenums) {
				$newtext[$linenum] = $firstbits[$i] . sprintf ('%g', $$xbref[$i])
				. $middlebits[$i];
				$i++;
			}
			push @texts, join ("\n", @newtext);
		}
		return &$func_ref(@texts);
	}

	my ($xbref, $smref);
	if ($some_constraints) {
		eval join '', @sub_constr; if ($@) { die "text_evol: $@\n"; }
		($xbref, $smref) =
		 &select_evol(\@xb, \@sm, \&choose_best, \&constrain, $nchoices);
	} else {
		($xbref, $smref) = &select_evol(\@xb,\@sm,\&choose_best,0,$nchoices);
	}

	my @new_text = @text; $i = $[;
	foreach $linenum (@linenums) {
		$new_text[$linenum] = $firstbits[$i] . sprintf ('%g', $$xbref[$i])
		. $middlebits[$i] . ' evol step '. sprintf ('%g', $$smref[$i]);
		if (defined $min[$i]) { $new_text[$linenum] .= " min $min[$i]"; }
		if (defined $max[$i]) { $new_text[$linenum] .= " max $max[$i]"; }
		$i++;
	}
	warn   join ("\n", @new_text)."\n" if $debug;
	return join ("\n", @new_text)."\n";
}

# --------------- infrastructure for evol ----------------

sub arr2txt { # neat printing of arrays for debug use
	my @txt; foreach (@_) { push @txt, sprintf('%g',$_); }
	return join (' ',@txt)."\n";
}
my $gaussn_a = rand;  # reject 1st call to rand in case it's zero
my $gaussn_b;
my $gaussn_flag;
sub gaussn {   my $standdev = $_[$[];
	# returns normal distribution around 0.0 by the Box-Muller rules
	if (! $gaussn_flag) {
		# $gaussn_a = sqrt(-2.0 * log(rand)); BUG #44777: Log of zero error
		$gaussn_a = sqrt(-2.0 * log(rand(0.999)+0.001));  # 1.12
		$gaussn_b = 6.28318531 * rand;
		$gaussn_flag = 1;
		return ($standdev * $gaussn_a * sin($gaussn_b));
	} else {
		$gaussn_flag = 0;
		return ($standdev * $gaussn_a * cos($gaussn_b));
	}
}
1;

__END__

=pod

=head1 NAME

Math::Evol - Evolution search optimisation

=head1 SYNOPSIS

 use Math::Evol;
 ($xbref,$smref,$fb,$lf) = evol(\@xb,\@sm,\&function,\&constrain,$tm);
 # or
 ($xbref, $smref) = select_evol(\@xb,\@sm,\&choose_best,\&constrain);
 # or
 $new_text = text_evol($text, \&choose_best_text, $nchoices );

=head1 DESCRIPTION

This module implements the evolution search strategy.  Derivatives of
the objective function are not required.  Constraints can be incorporated.
The caller must supply initial values for the variables and for the
initial step sizes.

This evolution strategy is a random strategy, and as such is
particularly robust and will cope well with large numbers of variables,
or rugged objective funtions.

Evol.pm works either automatically (evol) with an objective function to
be minimised, or interactively (select_evol) with a (suitably patient)
human who at each step will choose the better of two possibilities.
Another subroutine (text_evol) allows the evolution of numeric parameters
in a text file, the parameters to be varied being identified in the text
by means of special comments.  A script I<ps_evol> which uses that is
included for human-judgement-based fine-tuning of drawings in PostScript.

Version 1.12

=head1 SUBROUTINES

=over 3

=item I<evol>(\@xb, \@sm, \&minimise, \&constrain, $tm);

Where the arguments are:
 I<@xb> the initial values of variables,
 I<@sm> the initial values of step sizes,
 I<&minimise> the function to be minimised,
 I<&constrain> a function constraining the values,
 I<$tm> the max allowable cpu time in seconds

The step sizes and the caller-supplied functions
I<&function> and I<&constrain> are discussed below.
The default value of I<$tm> is 10 seconds.

I<evol> returns a list of four things:
 I<\@xb> the best values of the variables,
 I<\@sm> the final values of step sizes,
 I<$fb> the best value of objective function,
 I<$lf> a success parameter

I<$lf> is set false if the search ran out of cpu time before converging.
For more control over the convergence criteria, see the
CONVERGENCE CRITERIA section below.

=item I<select_evol>(\@xb, \@sm, \&choose_best, \&constrain, $nchoices);

Where the arguments are:
 I<@xb> the initial values of variables,
 I<@sm> the initial values of step sizes,
 I<&choose_best> the function allowing the user to select the best,
 I<&constrain> a function constraining the values,
 I<$nchoices> the number of choices I<select_evol> generates

The step sizes and the caller-supplied functions
I<&choose_best> and I<&constrain> are discussed below.
I<$nchoices> is the number of alternative choices which will be offered
to the user, in addition to the current best array of values.
The default value of I<$nchoices> is 1,
giving the user the choice between the current best and 1 alternative.

I<select_evol> returns a list of two things:
 I<\@xb> the best values of the variables, and
 I<\@sm> the final values of step sizes

=item I<text_evol>( $text, \&choose_best_text, $nchoices );

The $text is assumed to contain some numeric parameters to be varied,
marked out by magic comments which also supply initial step sizes for them,
and optionally also maxima and minima.
For example:

 $x = -2.3456; # evol step .1
 /x 3.4567 def % evol step .2
 /gray_sky .87 def % evol step 0.05 min 0.0 max 1.0

The magic bit of the comment is I<evol step> and the previous
number on the same line is taken as the value to be varied.
The function reference I<\&choose_best_text> is discussed below.
I<$nchoices> gets passed by I<text_evol> directly to I<select_evol>.

I<&text_evol> returns the optimised $text.

I<&text_evol> is intended for fine-tuning of PostScript, or files
specifying GUI's, or HTML layout, or StyleSheets, or MIDI,
where the value judgement must be made by a human being.
As an example, a script called I<ps_evol> for fine-tuning A4 PostScript
drawings is included with this package; it uses $nchoices = 8 and puts
the nine alternatives onto one A4 page which the user can then view with
Ghostview in order to select the best one.

=back

=head1 STEP SIZES

The caller must supply initial values for the step sizes.
Following the work of Rechenberg and of Schwefel,
I<evol> will adjust these step-sizes as it proceeds
to give a success rate of about 0.2,
but since the ratios between the step-sizes remain constant,
it helps convergence to supply sensible values.

A good rule of thumb is the expected distance of the value from its
optimum divided by the square root of the number of variables.
Larger step sizes increase the chance of discovering
a global optimum rather than an inferior local optimum,
at the cost of course of slower convergence.

=head1 CALLER-SUPPLIED SUBROUTINES

=over 3

=item I<minimise>( @x );

I<evol> minimises an objective funtion; that function accepts a
list of values and returns a numerical scalar result. For example,

 sub minimise {   # objective function, to be minimised
    my $sum; foreach (@_) { $sum += $_*$_; }  # sigma x**2
    return $sum;
 }
 ($xbref, $smref, $fb, $lf) = evol (\@xb, \@sm, \&minimise);

=item I<constrain>( @x );

You may also supply a subroutine I<constrain(@x)> which forces
the variables to have acceptable values.  If you do not wish
to constrain the values, just pass 0 instead.  I<constrain(@x)>
should return the list of the acceptable values. For example,

 sub constrain {   # force values into acceptable range
    if ($_[0]>1.0) { $_[0]=1.0;  # it's a probability
    } elsif ($_[0]<0.0) { $_[0]=0.0;
    }
    my $cost = 3.45*$_[1] + 4.56*$_[2] + 5.67*$_[3];
    if ($cost > 1000.0) {  # enforce 1000 dollars maximum cost
       $_[1]*=1000/$cost; $_[2]*=1000/$cost; $_[3]*=1000/$cost;
    }
    if ($_[4]<0.0) { $_[4]=0.0; }  # it's a population density
    $_[5] = int ($_[5] + 0.5);     # it's an integer
    return @_;
 }
 ($xbref,$smref,$fb,$lf) = evol (\@xb,\@sm,\&minimise,\&constrain);

=item I<choose_best>( \@a, \@b, \@c ... );

This function whose reference is passed to I<select_evol> 
must accept a list of array_refs;
the first ref refers to the current array of values,
and the others refer to alternative arrays of values.
The user should then judge which of the arrays is best,
and I<choose_best> must then return I<($preference, $continue)> where
I<$preference> is the index of the preferred array_ref (0, 1, etc).
The other argument I<($continue)> is set false if the user
thinks the optimal result has been arrived at;
this is I<select_evol>'s only convergence criterion.
For example,

 use Term::Clui;
 sub choose_best { my ($aref, $bref) = @_;
    inform("Array 0 is @$aref");
    inform("Array 1 is @$bref");
    my $preference = 0 + choose('Do you prefer 0 or 1 ?','0','1');
    my $continue   = confirm('Continue ?');
    return ($preference, $continue);
 }
 ($xbref, $smref, $fb, $lf) = evol(\@xb, \@sm, \&choose_best);

=item I<choose_best_text>( $text1, $text2, $text3 ... );

This function whose reference is passed to I<text_evol>
must accept a list of text strings;
the first will contain the current values
while the others contain alternative values.
The user should then judge which of the strings produces the best result.
I<choose_best_text> must return I<($preference, $continue)> where
I<$preference> is the index of the preferred string (0, 1, etc).
The other argument I<($continue)> is set false if the user
thinks the optimal result has been arrived at;
this is I<text_evol>'s only convergence criterion.

As an example, see the script called I<ps_evol> for fine-tuning
A4 PostScript drawings which is included with this package.

=back

=head1 CONVERGENCE CRITERIA

$ec (>0.0) is the convergence test, absolute.  The search is
terminated if the distance between the best and worst values
of the objective function within the last 25 trials is less
than or equal to $ec.
The absolute convergence test is suppressed if $ec is undefined.

$ed (>0.0) is the convergence test, relative. The search is
terminated if the difference between the best and worst values
of the objective function within the last 25 trials is less
than or equal to $ed multiplied by the absolute value of the
objective function.
The relative convergence test is suppressed if $ed is undefined.

These interact with two other small numbers $ea and $eb, which are
the minimum allowable step-sizes, absolute and relative respectively.

These number are set within Math::Evol as follows:

 $ea = 0.00000000000001;   # absolute stepsize
 $eb = 0.000000001;        # relative stepsize
 $ec = 0.0000000000000001; # absolute error
 $ed = 0.00000000001;      # relative error

You can change those settings before invoking the evol subroutine, e.g.:

 $Math::Evol::ea = 0.00000000000099;   # absolute stepsize
 $Math::Evol::eb = 0.000000042;        # relative stepsize
 undef $Math::Evol::ec;  # disable absolute-error-criterion
 $Math::Evol::ec = 0.0000000000000031; # absolute error
 $Math::Evol::ed = 0.00000000067;      # relative error

The most robust criterion is the maximum-cpu-time parameter $tm

=head1 LUA

In the C<lua/> subdirectory of the install directory there is
I<Evol.lua>, which is an exact translation of this Perl code into Lua.
The function names and arguments are unchanged,
except that I<text_evol> is not yet implemented.
Brief Synopsis:

 local M = require 'Evol'
 local function minimise(x) -- returns a number to be minimised
    local sum = 1.0
    for k,v in pairs(x) do sum = sum + v * v end
    return sum
 end
 local function constrain(x)
    if x[1] > 1.0 then x[1] = 1.0  -- it's a greyscale value
    elseif x[1] < 0.0 then x[1] = 0.0
    end
    return x
 end
 local function choose_best(arglist)
    local preference = 1; local i_arg
    for i_arg=1,#arglist do
       local x = arglist[i_arg]
       if that_suits_me() then preference = i_arg; break end
    end
    local continue   = true or false
    return preference, continue
 end
 M.ed = 0.00000000067                       -- relative error
 local x  = {3.456, 1.234, -2.345, 4.567}  -- starting values
 local sm = {.8, .4, .6, 1.2}          -- starting step-sizes
 local tm = 5.0                        -- max time in seconds

 -- and now...
 xb,sm,fb,lf = M.evol(xb, sm, minimise, constrain, tm)
 -- or
 xb,sm = M.select_evol(xb, sm, choose_best, constrain)

 -- not yet implemented :
 -- new_text = M.text_evol(text, choose_best_text, nchoices)

=head1 AUTHOR

Peter J Billam, www.pjb.com.au/comp/contact.html

=head1 CREDITS

The strategy of adjusting the step-size to give a success rate of 0.2
comes from the work of I. Rechenberg in his
I<Optimisation of Technical Systems in Accordance with the
Principles of Biological Evolution>
(Problemata Series, Vol. 15, Verlag Fromman-Holzboog, Stuttgart 1973).

The code of I<evol> is based on the Fortran version in
I<Numerical Optimisation of Computer Models>
by Hans-Paul Schwefel, Wiley 1981, pp 104-117, 330-337,
translated into english by M.W. Finnis from
I<Numerische Optimierung von Computer-Modellen mittels der Evolutionsstrategie>
(Interdiscipliniary Systems Research, Vol. 26), Birkhaeuser Verlag, Basel 1977.
The calling interface has been greatly Perlised,
and the constraining of values has been much simplified.

=head1 SEE ALSO

The deterministic optimistation strategies can offer faster
convergence on smaller problems (say 50 or 60 variables or less)
with fairly smooth functions;
see John A.R. Williams CPAN module Math::Amoeba
which implements the Simplex strategy of Nelder and Mead;
another good algorithm is that of Davidon, Fletcher, Powell and Stewart,
currently unimplemented in Perl,
see Algorithm 46 and notes, in Comp J. 13, 1 (Feb 1970), pp 111-113;
Comp J. 14, 1 (Feb 1971), p 106 and
Comp J. 14, 2 (May 1971), pp 214-215.
See also http://www.pjb.com.au/, perl(1).

=cut
