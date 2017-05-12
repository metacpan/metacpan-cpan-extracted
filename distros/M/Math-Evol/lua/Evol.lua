--------------------------------------------------------------------
--     This Lua5 module is Copyright (c) 2010, Peter J Billam     --
--                       www.pjb.com.au                           --
--                                                                --
--  This module is free software; you can redistribute it and/or  --
--         modify it under the same terms as Lua5 itself.         --
--------------------------------------------------------------------
local M = {} -- public interface
M.Version = '1.12'
M.VersionDate = '24aug2010'

-- Example usage:
--local MM = require 'Evol'
--MM.bar()

----------------- infrastructure for evol ----------------
local function arr2txt(a) -- neat printing of arrays for debug use
	local txt = {}
	for k,v in ipairs(a) do txt[#txt+1] = string.format('%g',v); end
	return table.concat(txt,' ')
end
local function warn(str)
	io.stderr:write(str,'\n')
end
local function die(str)
	io.stderr:write(str,'\n')
	os.exit(1)
end
math.randomseed(os.time())
local gaussn_a = math.random()  -- reject 1st call to rand in case it's zero
local gaussn_b
local gaussn_flag = false
local function gaussn(standdev)
	-- returns normal distribution around 0.0 by the Box-Muller rules
	if not gaussn_flag then
		gaussn_a = math.sqrt(-2.0 * math.log(0.999*math.random()+0.001))
		gaussn_b = 6.28318531 * math.random()
		gaussn_flag = true
		return (standdev * gaussn_a * math.sin(gaussn_b))
	else
		gaussn_flag = false
		return (standdev * gaussn_a * math.cos(gaussn_b))
	end
end
--------------------------------------------------------------

-- various epsilons used in convergence testing ...
M.ea = 0.00000000000001;   -- absolute stepsize
M.eb = 0.000000001;        -- relative stepsize
M.ec = 0.0000000000000001; -- absolute error
M.ed = 0.00000000001;      -- relative error

function M.evol (xb ,sm, func,constrain, tm)
	if (type(xb) ~= 'table') then
		die "Evol.evol 1st arg must be a table\n";
	elseif (type(sm) ~= 'table') then
		die "Evol.evol 2nd arg must be a table\n";
	elseif (type(func) ~= 'function') then
		die "Evol.evol 3rd arg must be a function\n";
	elseif constrain and (type(constrain) ~= 'function') then
		die "Evol.evol 4th arg must be a function\n";
	end
	if not tm then tm = 10.0 end
	tm = math.abs(tm)

	local debug = false
	local n = #xb;   -- number of variables
	local clock_o = os.clock()
	local fc; local rel_limit    -- used to test convergence

	-- step-size adjustment stuff, courtesy Rechenberg ...
	local l = {}; local ten = 10
	local i; for i=1,ten do l[i] = n*i/5.0 end -- 6
	local i_l = 1
	local le = n+n; local lm = 0; local lc = 0

	if constrain then xb = constrain(xb) end
	fb = func(xb); fc = fb;
	while true do
		local x = {}; for i=1,n do x[i] = xb[i]+gaussn(sm[i]) end
		if debug then warn('      new x is '..arr2txt(x)) end
		if constrain then
			x = constrain(x)
			if debug then warn('constrained is '..arr2txt(x)) end
		end
		ff = func(x)   -- find new objective function
		if ff <= fb then    -- an improvement :-)
			le = le+1;  fb = ff;  xb,x = x,xb -- swap is faster than deepcopy
		end
		lm = lm + 1;  if lm >= n then   -- adjust the step sizes ...
			-- local k = 0.85 ^ (n+n <=> le-l[1]);
			local k = 1
			if n+n > le - l[i_l] then k = 0.85
			elseif n+n < le - l[i_l] then k = 1.0/0.85
			end
			for i=1,n do
				sm[i] = k * sm[i]
				rel_limit = math.abs(M.eb * xb[i]);
				if (sm[i] < rel_limit) then sm[i] = rel_limit end
				if (sm[i] < M.ea) then sm[i] = M.ea; end
			end
			-- i_l = i_l + 1; l[#l+1] = le; lm = 0;
			l[i_l] = le;  i_l = 1 + (i_l % 10); lm = 0
			if debug then
				warn('i_l='..i_l..' le='..le..' n='..n..' k='..k)
				warn('new step sizes sm = '..arr2txt(sm))
				warn("new l = "..arr2txt(l))
			end

			if M.ea then M.ea = math.abs(M.ea) end
			if M.eb then M.eb = math.abs(M.eb) end
			if M.ec then M.ec = math.abs(M.ec) end
			if M.ed then M.ed = math.abs(M.ed) end
			if debug then
				warn(string.format("fb=%g fc=%g M.ec=%g M.ed=%g\n",fb,fc,M.ec,M.ed))
			end
			lc = lc + 1
			local do_next = false
			if lc < 25 then
				local clock_n  = os.clock()
				if (clock_n - clock_o) > tm then   -- out of time ?
					if debug then warn("exceeded "..tm.." seconds") end
					return xb, sm, fb, false   -- return best current value
				else
					do_next = true
				end
			end
			if not do_next then
				if M.ec and ((fc-fb) <= M.ec) then
					if debug then warn("converged absolutely") end
					return xb, sm, fb, true   -- 29
				end
				if M.ed and ((fc-fb)/M.ed <= math.abs(fc)) then
					if debug then warn("converged relativelty") end
					return xb, sm, fb, true
				end
				lc = 0; fc = fb
			end
		end
	end
end

local function values(t)
	local i = 0
	return function () i = i + 1 ; return t[i] end
end
function M.select_evol(xb,sm,func,constrain,nchoices)
local xxx = 0
	if (type(xb) ~= 'table') then
		die "Evol.select_evol 1st arg must be a table\n";
	elseif (type(sm) ~= 'table') then
		die "Evol.select_evol 2nd arg must be a table\n";
	elseif (type(func) ~= 'function') then
		die "Evol.select_evol 3rd arg must be a function\n";
	elseif constrain and (type(constrain) ~= 'function') then
		die "Evol.select_evol 4th arg must be a function\n";
	end
	if not nchoices then nchoices = 1 end

	local debug = false
	local n = #xb      -- number of variables
	local choice; local continue

	-- step-size adjustment stuff, courtesy Rechenberg
	-- modified from Schwefel's sliding flat window average to an EMA
	local desired_success_rate = 1.0 - 0.8^nchoices;
	local success_rate = desired_success_rate; 
	-- test every 5*$n binary choices equivalent - 10*$n is just too slow.
	local lm = 0
	local test_every = 5 * n * math.log(2) / math.log(nchoices+1);
	local ema = math.exp (-1.0 / test_every);
	local one_m_ema = 1.0 - ema;
	if debug then warn(string.format(
		"n=%g nchoices=%g success_rate=%g test_every=%g ema=%g",
		n, nchoices, success_rate, test_every, ema))
	end

	if constrain then xb = constrain(xb) end
	while true do
		local func_args = {};  -- array of xb-arrays to be chosen from
		func_args[1] = xb  -- need to deepcopy?
		local x = {}
		local ichoice = 1, nchoices do
			for i=1,n do
				x[i] = xb[i] + gaussn(sm[i])
			end
			if constrain then x = constrain(x) end
			func_args[#func_args+1] =  x
		end
		choice, continue = func(func_args)
		if choice > 1.5 then
			xb = func_args[choice]
			success_rate = one_m_ema + ema*success_rate
		else
			success_rate = ema*success_rate
		end
		if debug then
			warn("continue="..tostring(continue))
			warn(string.format("choice=%g success_rate=%g",choice,success_rate))
		end
		if not continue then return xb, sm end
		lm = lm + 1
		if lm >= test_every then
			local k = 1
			if desired_success_rate > success_rate then k = 0.85
			elseif desired_success_rate < success_rate then k = 1.0/0.85
			end
			if debug then
				warn(string.format("success_rate=%g k=%g\n", success_rate, k))
			end
			for i=1,n do
				sm[i] =  k * sm[i]
				rel_limit = math.abs(M.eb * xb[i]);
				if sm[i] < rel_limit then sm[i] = rel_limit end
				if sm[i] < M.ea then sm[i] = M.ea end
			end
			if debug then warn("new step sizes sm = "..arr2txt(sm)) end
			lm = 0
		end
	end
end

function M.text_evol (text_s, func, nchoices)
	if not text_s then return end
	if (type(func) ~= 'function') then
		die "Evol.text_evol 2nd arg must be a function\n";
	end
	if not nchoices then nchoices = 1 end
--[[

	local debug = false
	local text = split ("\n", text_s); --- XXX
	local linenum = 1; local m = 0;
	local xb = {}; local sm = {}; local min = {}; local max = {}
	local linenums = {}; local firstbits = {}; local middlebits = {}
	local lastbit;
	local n = 0 for k,v in ipairs(text) do
		if (/^(.*?)(-?[\d.]+)(\D+)evol\s+step\s+([\d.]+)(.*)$/) then
			n = n + 1; linenums[n] = linenum; firstbits[n]=$1;
			$xb[$n]=$2; $middlebits[$n]=$3; $sm[$n]=$4; $lastbit = $5;
			if ($lastbit =~ /min\s+([-\d.]+)/) then $min[$n] = $1; end
			if ($lastbit =~ /max\s+([-\d.]+)/) then $max[$n] = $1; end
		end
		linenum = linenum + 1;
	end
	if debug then warn "xb = "..arr2txt(xb) end
	if debug then warn "sm = "..arr2txt(sm) end

	-- construct the constraint routine
	local $some_constraints = 0;
	local @sub_constr = ("sub constrain {\n");
	local $i = $[; while ($i <= $n) do
		if (defined $min[$i] and defined $max[$i]) then
			push @sub_constr,"\tif (\$_[$i]>$max[$i]) { \$_[$i]=$max[$i];\n";
			push @sub_constr,"\t} elseif (\$_[$i]<$min[$i]) { \$_[$i]=$min[$i];\n";
			push @sub_constr,"\t}\n";
		elseif (defined $min[$i]) then
			push @sub_constr,"\tif (\$_[$i]<$min[$i]) { \$_[$i]=$min[$i]; }\n";
		elseif (defined $max[$i]) then
			push @sub_constr,"\tif (\$_[$i]>$max[$i]) { \$_[$i]=$max[$i]; }\n";
		end
		if (defined $min[$i] || defined $max[$i]) then
			some_constraints = some_constraints + 1
		end
		i = i + 1
	end
	push @sub_constr, "\treturn \@_;\n}\n";
	if debug then warn join ('', @sub_constr)."\n" end

	sub choose_best {
		local $xbref; local $linenum; @texts = {};
		while ($xbref = shift @_) do
			local @newtext = @text; local $i = $[;
			foreach $linenum (@linenums) do
				$newtext[$linenum] = $firstbits[$i] . string.format ('%g', $$xbref[$i])
				. $middlebits[$i];
				i = i + 1
			end
			push @texts, join ("\n", @newtext);
		end
		return &$func(@texts);
	end

	local ($xbref, $smref);
	if ($some_constraints) then
		eval join '', @sub_constr; if ($@) then die "text_evol: $@\n"; end
		($xbref, $smref) =
		 &select_evol(\@xb, \@sm, \&choose_best, \&constrain, $nchoices);
	else
		($xbref, $smref) = &select_evol(\@xb,\@sm,\&choose_best,0,$nchoices);
	end

	local @new_text = @text; $i = $[;
	foreach $linenum (@linenums) do
		$new_text[$linenum] = $firstbits[$i] . string.format ('%g', $$xbref[$i])
		. $middlebits[$i] . ' evol step '. string.format ('%g', $$smref[$i]);
		if (defined $min[$i]) then $new_text[$linenum] .= " min $min[$i]"; end
		if (defined $max[$i]) then $new_text[$linenum] .= " max $max[$i]"; end
		i = i + 1
	end
	if debug then warn   join ("\n", @new_text)."\n" end
	return join ("\n", @new_text)."\n";
]]
end

-- warn('Evol: M = '..tostring(M))
return M

--[[

=pod

=head1 NAME

Evol - Evolution search optimisation

=head1 SYNOPSIS

 use Evol;
 ($xbref,$smref,$fb,$lf) = evol(\@xb,\@sm,\&function,\&constrain,$tm);
 -- or
 ($xbref, $smref) = select_evol(\@xb,\@sm,\&choose_best,\&constrain);
 -- or
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

 sub minimise {   -- objective function, to be minimised
    local $sum; foreach (@_) { $sum += $_*$_; }  -- sigma x^2
    return $sum;
 }
 ($xbref, $smref, $fb, $lf) = evol (\@xb, \@sm, \&minimise);

=item I<constrain>( @x );

You may also supply a subroutine I<constrain(@x)> which forces
the variables to have acceptable values.  If you do not wish
to constrain the values, just pass 0 instead.  I<constrain(@x)>
should return the list of the acceptable values. For example,

 sub constrain {   -- force values into acceptable range
    if ($_[0]>1.0) { $_[0]=1.0;  -- it's a probability
    elseif ($_[0]<0.0) { $_[0]=0.0;
    }
    local $cost = 3.45*$_[1] + 4.56*$_[2] + 5.67*$_[3];
    if ($cost > 1000.0) {  -- enforce 1000 dollars maximum cost
       $_[1]*=1000/$cost; $_[2]*=1000/$cost; $_[3]*=1000/$cost;
    }
    if ($_[4]<0.0) { $_[4]=0.0; }  -- it's a population density
    $_[5] = int ($_[5] + 0.5);     -- it's an integer
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

 use Term.Clui;
 sub choose_best { local ($aref, $bref) = @_;
    inform("Array 0 is @$aref");
    inform("Array 1 is @$bref");
    local $preference = 0 + choose('Do you prefer 0 or 1 ?','0','1');
    local $continue   = confirm('Continue ?');
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

These interact with two other small numbers M.ea and M.eb, which are
the minimum allowable step-sizes, absolute and relative respectively.

These number are set within Evol as follows:

 M.ea = 0.00000000000001;   -- absolute stepsize
 M.eb = 0.000000001;        -- relative stepsize
 M.ec = 0.0000000000000001; -- absolute error
 M.ed = 0.00000000001;      -- relative error

You can change those settings before invoking the evol subroutine, e.g.:

 $Evol.ea = 0.00000000000099;   # absolute stepsize
 $Evol.eb = 0.000000042;        # relative stepsize
 undef $Evol.ec;  # disable absolute-error-criterion
 $Evol.ec = 0.0000000000000031; # absolute error
 $Evol.ed = 0.00000000067;      # relative error

The most robust criterion is the maximum-cpu-time parameter $tm

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
see John A.R. Williams CPAN module Amoeba
which implements the Simplex strategy of Nelder and Mead;
another good algorithm is that of Davidon, Fletcher, Powell and Stewart,
currently unimplemented in Perl,
see Algorithm 46 and notes, in Comp J. 13, 1 (Feb 1970), pp 111-113;
Comp J. 14, 1 (Feb 1971), p 106 and
Comp J. 14, 2 (May 1971), pp 214-215.
See also http://www.pjb.com.au/, perl(1).

=cut

]]
