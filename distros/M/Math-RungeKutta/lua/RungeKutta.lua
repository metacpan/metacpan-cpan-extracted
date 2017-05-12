-- RungeKutta.lua
-- ----------------------------------------------------------------- --
--      This Lua5 module is Copyright (c) 2010, Peter J Billam       --
--                        www.pjb.com.au                             --
--                                                                   --
--   This module is free software; you can redistribute it and/or    --
--          modify it under the same terms as Lua5 itself.           --
-- ----------------------------------------------------------------- --
local M = {} -- public interface
M.Version = '1.07'
M.VersionDate = '20aug2010'

-- Example usage:
-- local RK = require 'RungeKutta'
-- RK.rk4()

--------------------- infrastructure ----------------------
local function arr2txt(...) -- neat printing of arrays for debug use
	local txt = {}
	for e in ... do txt[#txt+1] = string.format('%g',e) end
	return table.concat(txt,' ') .. "\n"
end
local function warn(str)
	io.stderr:write(str,'\n')
end
local function die(str)
	io.stderr:write(str,'\n')
	os.exit(1)
end
local flag = false
local a
local b
local function gaussn(standdev)
	-- returns normal distribution around 0.0 by the Box-Muller rules
	if not flag then
		a = math.sqrt(-2.0 * math.log(math.random()))
		b = 6.28318531 * math.random()
		flag = true
		return standdev * a * math.sin(b)
	else
		flag = false
		return standdev * a * math.cos(b)
	end
end
-------------------------------------------------------

function M.rk2(yn, dydt, t, dt)
	if type(yn) ~= 'table' then
		warn("RungeKutta.rk2: 1st arg must be an table\n")
		return false
	end
	if type(dydt) ~= 'function' then
		warn("RungeKutta.rk2: 2nd arg must be a function\n")
		return false
	end

	local gamma = .75;  -- Ralston's minimisation of error bounds
	local alpha = 0.5/gamma; local beta = 1.0-gamma;
	local alphadt=alpha*dt; local betadt=beta*dt; local gammadt=gamma*dt;
	local ny = #yn;
	local ynp1 = {}
	local dydtn = {}
	local ynpalpha = {}  -- Gear calls this q
	local dydtnpalpha = {}
	dydtn = dydt(t, yn);
	-- for i=1, ny do
	for i in pairs(yn) do
		ynpalpha[i] = yn[i] + alphadt*dydtn[i];
	end
	dydtnpalpha = dydt(t+alphadt, ynpalpha);
	for i in pairs(yn) do
		ynp1[i] = yn[i]+betadt*dydtn[i]+gammadt*dydtnpalpha[i];
	end
	return t+dt, ynp1
end
function deepcopy(object)  -- http://lua-users.org/wiki/CopyTable
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end


local saved_k0; local use_saved_k0 = false
function M.rk4(yn, dydt, t, dt)
	-- The Runge-Kutta-Merson 5-function-evaluation 4th-order method
	-- in the sine-cosine example, this seems to work as a 7th-order method !
	if (type(yn) ~= 'table') then
		warn("RungeKutta.rk4: 1st arg must be a table\n")
		return false
	end
	if (type(dydt) ~= 'function') then
		warn("RungeKutta.rk4: 2nd arg must be a function\n")
		return false
	end
	local ny = #yn; local i;

	local k0
	if use_saved_k0 then
		k0 = deepcopy(saved_k0)  -- a simpler single-level copy  would do...
-- without the copy() it gets trashed on the 2nd call to this function :-(
	else  k0 = dydt(t, yn)
	end
	for i in pairs(yn) do k0[i] = k0[i] * dt end

	local eta1 = {}
	for i in pairs(yn) do eta1[i] = yn[i] + k0[i]/3.0 end
	local k1 = dydt(t + dt/3.0, eta1)
	for i in pairs(yn) do k1[i] = k1[i] * dt end

	local eta2 = {}
	local k2 = {}
	for i in pairs(yn) do
		eta2[i] = yn[i] + (k0[i]+k1[i])/6.0
	end
	k2 = dydt(t + dt/3.0, eta2)
	for i in pairs(yn) do k2[i] = k2[i] * dt end

	local eta3 = {}
	for i in pairs(yn) do
		eta3[i] = yn[i] + (k0[i]+3.0*k2[i])*0.125
	end
	local k3 = dydt(t+0.5*dt, eta3)
	for i in pairs(yn) do k3[i] = k3[i] * dt end

	local eta4 = {}
	for i in pairs(yn) do
		eta4[i] = yn[i] + (k0[i]-3.0*k2[i]+4.0*k3[i])*0.5
	end
	local k4 = dydt(t+dt, eta4)
	for i in pairs(yn) do k4[i] = k4[i] * dt end

	local ynp1 = {}
	for i in pairs(yn) do
		ynp1[i] = yn[i] + (k0[i]+4.0*k3[i]+k4[i])/6.0;
	end

	-- Merson's method for error estimation, see Gear p85, only works
	-- if F is linear, ie F = Ay + bt, so that eta4 has no 4th-order
	-- errors.  So in general step-doubling is the only way to do it.
	-- Estimate error terms ...
	-- if ($epsilon) {
	-- 	my $errmax = 0; my $diff;
	-- 	for ($i=$[; $i<=$ny; $i++) {
	-- 		$diff = 0.2 * abs ($ynp1[$i] - $eta4[$i]);
	-- 		if ($errmax < $diff) { $errmax = $diff; }
	-- 	}
	-- 	-- print "errmax = $errmax\n"; -- not much related to the actual error
	-- }

	return t+dt, ynp1
end

local t = 0; local halfdt; local y2 = {}
function M.rk4_auto(yn, dydt, t, dt, arg4)
	if (type(yn) ~= 'table') then
		warn("RungeKutta.rk4_auto: 1st arg must be a table\n")
		return false
	end
	if (type(dydt) ~= 'function') then
		warn("RungeKutta.rk4_auto: 2nd arg must be a function\n")
		return false
	end
	if dt == 0 then dt = 0.1 end
	local errors; local epsilon = nil
	if (type(arg4) == 'table') then
		errors = arg4; epsilon = nil
	else
		epsilon = math.abs(arg4); errors = nil
		if epsilon == 0 then epsilon = .0000001 end
	end
	local ny = #yn; local i

	local y1 = {}
	local y3 = {}
	saved_k0 = dydt(t, yn)
	local resizings = 0;
	local highest_low_error = 0.1e-99; local highest_low_dt = 0.0;
	local lowest_high_error = 9.9e99;  local lowest_high_dt = 9.9e99;
	while true do
		halfdt = 0.5 * dt; local dummy
		use_saved_k0 = true
		dummy, y1 = M.rk4(yn, dydt, t, dt)
		dummy, y2 = M.rk4(yn, dydt, t, halfdt)
		use_saved_k0 = false
		dummy, y3 = M.rk4(y2, dydt, t+halfdt, halfdt)

		local relative_error
		if epsilon then
	 		local errmax = 0; local diff; local ymax = 0
	 		for i in pairs(yn) do
	 			diff = math.abs(y1[i] - y3[i])
	 			if errmax < diff then errmax = diff end
	 			if ymax < math.abs(yn[i]) then ymax = math.abs(yn[i]) end
	 		end
			relative_error = errmax / (epsilon*ymax)
		elseif errors then
			relative_error = 0.0; local diff;
	 		for i in pairs(yn) do
	 			diff = math.abs(y1[i] - y3[i]) / math.abs(errors[i])
	 			if relative_error < diff then relative_error = diff end
	 		end
		else
			die "RungeKutta.rk4_auto: \$epsilon & \@errors both undefined\n";
		end
		-- Gear's "correction" assumes error is always in 5th-order terms :-(
		-- $y1[$i] = (16.0*$y3{$i] - $y1[$i]) / 15.0;
		if relative_error < 0.60 then
			if dt > highest_low_dt then
				highest_low_error = relative_error; highest_low_dt = dt
			end
		elseif relative_error > 1.67 then
			if dt < lowest_high_dt then
				lowest_high_error = relative_error; lowest_high_dt = dt
			end
		else
			break
		end
		if lowest_high_dt<9.8e99 and highest_low_dt>1.0e-99 then -- interpolate
			local denom = math.log(lowest_high_error/highest_low_error)
			if highest_low_dt==0.0 or highest_low_error==0.0 or denom == 0.0 then
				dt = 0.5 * (highest_low_dt+lowest_high_dt)
			else
				dt = highest_low_dt * ( (lowest_high_dt/highest_low_dt)
				 ^ ((math.log(1.0/highest_low_error)) / denom) )
			end
		else
			local adjust = relative_error^(-0.2) -- hope error is 5th-order ...
			if math.abs(adjust) > 2.0 then
				dt = dt * 2.0  -- prevent infinity if 4th-order is exact ...
			else
				dt = dt * adjust
			end
		end
		resizings = resizings + 1
		if resizings>4 and highest_low_dt>1.0e-99 then
			-- hope a small step forward gets us out of this mess ...
			dt = highest_low_dt;  halfdt = 0.5 * dt;
			use_saved_k0 = true
			dummy, y2 = M.rk4(yn, dydt, t, halfdt)
			use_saved_k0 = false
			dummy, y3 = M.rk4(y2, dydt, t+halfdt, halfdt)
			break
		end
	end
	return t+dt, dt, y3
end

function M.rk4_auto_midpoint()
	return t+halfdt, y2
end

------------------------ EXPORT_OK routines ----------------------

function M.rk4_ralston (yn, dydt, t, dt)
	if (type(yn) ~= 'table') then
		warn("RungeKutta.rk4_ralston: 1st arg must be arrayref\n")
		return false
	end
	if (type(dydt) ~= 'function') then
		warn("RungeKutta.rk4_ralston: 2nd arg must be a subroutine ref\n")
		return false
	end
	local ny = #yn; local i;

	-- Ralston's minimisation of error bounds, see Gear p36
	local alpha1=0.4; local alpha2 = 0.4557372542  -- = .875 - .1875*(sqrt 5);

	local k0 = dydt(t, yn)
	for i in pairs(yn) do k0[i] = dt * k0[i] end

	local k1 = {}
	for i in pairs(yn) do k1[i] = yn[i] + 0.4*k0[i] end
	k1 = dydt(t + alpha1*dt, k1)
	for i in pairs(yn) do k1[i] = dt * k1[i] end

	local k2 = {}
	for i in pairs(yn) do
		k2[i] = yn[i] + 0.2969776*k0[i] + 0.15875966*k1[i]
	end
	k2 = dydt(t + alpha2*dt, k2)
	for i in pairs(yn) do k2[i] = dt * k2[i] end

	local k3 = {}
	for i in pairs(yn) do
		k3[i] = yn[i] + 0.21810038*k0[i] - 3.0509647*k1[i] + 3.83286432*k2[i]
	end
	k3 = dydt(t+dt, k3)
	for i in pairs(yn) do k3[i] = dt * k3[i] end

	local ynp1 = {}
	for i in pairs(yn) do
		ynp1[i] = yn[i] + 0.17476028*k0[i]
		 - 0.55148053*k1[i] + 1.20553547*k2[i] + 0.17118478*k3[i]
	end
	return t+dt, ynp1
end
function M.rk4_classical(yn, dydt, t, dt)
	if (type(yn) ~= 'table') then
		warn("RungeKutta.rk4_classical: 1st arg must be arrayref\n")
		return false
	end
	if (type(dydt) ~= 'function') then
		warn("RungeKutta.rk4_classical: 2nd arg must be subroutine ref\n")
		return false
	end
	local ny = #yn; local i;

	-- The Classical 4th-order Runge-Kutta Method, see Gear p35

	local k0 = dydt(t, yn)
	for i in pairs(yn) do k0[i] = dt * k0[i] end

	local eta1 = {}
	for i in pairs(yn) do eta1[i] = yn[i] + 0.5*k0[i] end
	local k1 = dydt(t+0.5*dt, eta1)
	for i in pairs(yn) do k1[i] = dt * k1[i] end

	local eta2 = {}
	for i in pairs(yn) do eta2[i] = yn[i] + 0.5*k1[i] end
	local k2 = dydt(t+0.5*dt, eta2)
	for i in pairs(yn) do k2[i] = dt * k2[i] end

	local eta3 = {}
	for i in pairs(yn) do eta3[i] = yn[i] + k2[i] end
	local k3 = dydt(t+dt, eta3)
	for i in pairs(yn) do k3[i] = dt * k3[i] end

	local ynp1 = {}
	for i in pairs(yn) do
		ynp1[i] = yn[i] + (k0[i] + 2.0*k1[i] + 2.0*k2[i] + k3[i]) / 6.0;
	end
	return t+dt, ynp1
end


return M

--[[

=pod

=head1 NAME

RungeKutta.lua - Integrating Systems of Differential Equations

=head1 SYNOPSIS

 local RK = require 'RungeKutta'
 function dydt(t, y) -- the derivative function
   -- y is the table of the values, dydt the table of the derivatives
   -- the table can be an array (1...n), or a dictionary; whichever,
   -- the same indices must be used for the return table: dydt
   local dydt = {}; ... ; return dydt 
 end
 y = initial_y(); t=0; dt=0.4;  -- the initial conditions
 -- For automatic timestep adjustment ...
 while t < tfinal do
    t, dt, y = RK.rk4_auto(y, dydt, t, dt, 0.00001)
    display(t, y)
 end

 -- Or, for fixed timesteps ...
 while t < tfinal do
   t, y = RK.rk4(y, dydt, t, dt)  -- Merson's 4th-order method
   display(t, y)
 end
 -- alternatively, though not so accurate ...
 t, y = RK.rk2(y, dydt, t, dt)   -- Heun's 2nd-order method

 -- or, also available ...
 t, y = RK.rk4_classical(y, dydt, t, dt) -- Runge-Kutta 4th-order
 t, y = RK.rk4_ralston(y, dydt, t, dt)   -- Ralston's 4th-order

=head1 DESCRIPTION

RungeKutta.lua offers algorithms for the numerical integration
of simultaneous differential equations of the form

 dY/dt = F(t,Y)

where Y is an array of variables whose initial values Y(0) are
known, and F is a function known from the dynamics of the problem.

The Runge-Kutta methods all involve evaluating the derivative function
F(t,Y) more than once, at various points within the timestep, and
combining the results to reach an accurate answer for the Y(t+dt).
This module only uses explicit Runge-Kutta methods; the implicit methods
involve, at each timestep, solving a set of simultaneous equations
involving both Y(t) and F(t,Y), and this is generally intractable.

Three main algorithms are offered.  I<rk2> is Heun's 2nd-order
Runge-Kutta algorithm, which is relatively imprecise, but does have
a large range of stability which might be useful in some problems.  I<rk4>
is Merson's 4th-order Runge-Kutta algorithm, which should be the normal
choice in situations where the step-size must be specified.  I<rk4_auto>
uses the step-doubling method to adjust the step-size of I<rk4> automatically
to achieve a specified precision; this saves much fiddling around trying
to choose a good step-size, and can also save CPU time by automatically
increasing the step-size when the solution is changing only slowly.

This module is the translation into I<Lua> of the I<Perl> CPAN module
Math::RungeKutta, and comes in its C<./lua> subdirectory.
There also exists a translation into I<JavaScript>
which comes in its C<./js> subdirectory.
The calling-interfaces are identical in all three versions.

This module has been designed to be robust and easy to use, and should
be helpful in solving systems of differential equations which arise
within a I<Lua> context, such as economic, financial, demographic
or ecological modelling, mechanical or process dynamics, etc.

Version 1.07

=head1 FUNCTIONS

=over 3

=item I<rk2>(y, dydt, t, dt )

where the arguments are:
 I<y> an array of initial values of variables,
 I<dydt> the function calculating the derivatives,
 I<t> the initial time,
 I<dt> the timestep.

The algorithm used is that derived by Ralston, which uses Lotkin's bound
on the derivatives, and minimises the solution error (gamma=3/4).
It is also known as the Heun method, though unfortunately several other
methods are also known under this name. Two function evaluations are needed
per timestep, and the remaining error is in the 3rd and higher order terms.

I<rk2> returns t, y where these are now the new values
at the completion of the timestep.

=item I<rk4>( y, dydt, t, dt )

The arguments are the same as in I<rk2>.

The algorithm used is that developed by Merson,
which performs five function evaluations per timestep.
For the same timestep, I<rk4> is much more accurate than I<rk4_classical>,
so the extra function evaluation is well worthwhile.

I<rk4> returns t, y where these are now the new values
at the completion of the timestep.

=item I<rk4_auto>( y, dydt, t, dt, epsilon )

=item I<rk4_auto>( y, dydt, t, dt, errors )

In the first form the arguments are:
 I<y> an array of initial values of variables,
 I<dydt> the function calculating the derivatives,
 I<t> the initial time,
 I<dt> the initial timestep,
 I<epsilon> the errors per step will be about epsilon*ymax

In the second form the last argument is:
 I<errors> an array of maximum permissible errors.

The first I<epsilon> calling form is useful when all the elements of
I<y> are in the same units and have the same typical size (e.g. y[10]
is population aged 10-11 years, y[25] is population aged 25-26 years).
The default value of the 4th argument is I<epsilon = 0.00001>.

The second I<errors> form is useful otherwise
(e.g. y[1] is gross national product, y[2] is interest rate).
In this calling form, the permissible errors are specified in
absolute size for each variable; they won't get scaled at all.

I<rk4_auto> adjusts the timestep automatically to give the
required precision.  It does this by trying one full-timestep,
then two half-timesteps, and comparing the results.
(Merson's method, as used by I<rk4>, was devised to be able
to give an estimate of the remaining local error; for the
record, it is I<0.2*(ynp1[i]-eta4[i])> in each term.
I<rk4_auto> does not exploit this feature because it only
works for linear I<dydt> functions of the form I<Ay + bt>.)

I<rk4_auto> needs 14 function evaluations per double-timestep, and
it has to re-do 13 of those every time it adjusts the timestep.

I<rk4_auto> returns t, dt, y where these
are now the new values at the completion of the timestep.

=item I<rk4_auto_midpoint>()

I<rk4_auto> performs a double timestep within dt, and returns
the final values; the values as they were at the midpoint do
not normally get returned.  However, if you want to draw a
nice smooth graph, or to update a nice smoothly-moving display,
those values as they were at the midpoint would be useful to you.
Therefore, I<rk4_auto_midpoint> provides a way of retrieving them.

Note that you must call I<rk4_auto> first, which returns the values at
time t+dt, then I<rk4_auto_midpoint> subsequently, which returns the
values at t+dt/2, in other words you get the two sets of values out
of their chronological order. Sorry about this.  For example,

 while t < tfinal do
   t, dt, y = rk4_auto(y, dydt, t, dt, epsilon)
   t_midpoint, y_midpoint = rk4_auto_midpoint()
   update_display(t_midpoint, y_midpoint)
   update_display(t, y)
 end

I<rk4_auto_midpoint> returns t, y where these were the
values at the midpoint of the previous call to I<rk4_auto>.

=back

=head1 CALLER-SUPPLIED FUNCTIONS

=over 3

=item I<dydt>( t, y )

This subroutine will be passed by reference as the second argument to
I<rk2>, I<rk4> and I<rk4_auto>. The name doesn't matter of course.
It must expect the following arguments:
 I<t> the time (in case the equations are time-dependent),
 I<y> the array of values of variables.

It must return an array of the derivatives
of the variables with respect to time.

=back

=head1 EXPORT_OK FUNCTIONS

The following functions are not the usual first choice,
but are supplied in case you need them:

=over 3

=item I<rk4_classical>( y, dydt, t, dt )

The arguments and the return values are the same as in I<rk2> and I<rk4>.

The algorithm used is the classic, elegant, 4th-order Runge-Kutta
method, using four function evaluations per timestep:
 k0 = dt * F(y(n))
 k1 = dt * F(y(n) + 0.5*k0)
 k2 = dt * F(y(n) + 0.5*k1)
 k3 = dt * F(y(n) + k2)
 y(n+1) = y(n) + (k0 + 2*k1 + 2*k2 + k3) / 6

=item I<rk4_ralston>( y, dydt, t, dt )

The arguments and the return values are the same as in I<rk2> and I<rk4>.

The algorithm used is that developed by Ralston, which optimises
I<rk4_classical> to minimise the error bound on each timestep.
This module does not use it as the default 4th-order method I<rk4>,
because Merson's algorithm generates greater accuracy, which allows
the timestep to be increased, which more than compensates for
the extra function evaluation.

=back

=head1 EXAMPLES

There are a couple of example Perl scripts in the I<./examples/>
subdirectory of the build directory.
You can use their code to help you get your first application going.

=over 3

=item I<sine-cosine>

This script uses I<Term::Clui> (arrow keys and Return, or q to quit)
to offer a selection of algorithms, timesteps and error criteria for
the integration of a simple sine/cosine wave around one complete cycle.
This was the script used as a testbed during development.

=item I<three-body>

This script uses the vt100 or xterm 'moveto' and 'reverse'
sequences to display a little simulation of three-body gravity.
It uses I<rk4_auto> because a shorter timestep is needed when
two bodies are close to each other. It also uses I<rk4_auto_midpoint>
to smooth the display.  By changing the initial conditions you
can experience how sensitively the outcome depends on them.

=back

=head1 TRAPS FOR THE UNWARY

Alas, things can go wrong in numerical integration.

One of the most fundamental is B<instability>. If you choose a timestep
I<dt> much larger than time-constants implied in your derivative
function I<dydt>, then the numerical solution will oscillate wildy,
and bear no relation to the real behaviour of the equations.
If this happens, choose a shorter I<dt>.

Some of the most difficult problems involve so-called B<stiff>
derivative functions. These arise when I<dydt> introduces a wide
range of time-constants, from very short to long. In order to avoid
instability, you will have to set I<dt> to correspond to the shortest
time-constant; but this makes it impossibly slow to follow the
evolution of the system over longer times.  You should try to separate
out the long-term part of the problem, by expressing the short-term
process as the finding of some equilibrium, and then assume that that
equilibrium is present and solve the long-term problem on its own.

Similarly, numerical integration doesn't enjoy problems where
time-constants change suddenly, such as balls bouncing off hard
surfaces, etc. You can often tackle these by intervening directly
in the I<@y> array between each timestep. For example, if I<$y[17]>
is the height of the ball above the floor, and I<$y[20]> is the
vertical component of the velocity, do something like

 if y[17]<0.0 then y[17] = -0.9*y[17]; y[20] = -0.9*y[20] end

and thus, again, let the numerical integration solve just the
smooth part of the problem.

=head1 JAVASCRIPT

In the C<js/> subdirectory of the install directory there is I<RungeKutta.js>,
which is an exact translation of this Perl code into JavaScript.
The function names and arguments are unchanged.
Brief Synopsis:

 <SCRIPT type="text/javascript" src="RungeKutta.js"> </SCRIPT>
 <SCRIPT type="text/javascript">
 var dydt = function (t, y) {  // the derivative function
    var dydt_array = new Array(y.length); ... ; return dydt_array;
 }
 var y = new Array();

 // For automatic timestep adjustment ...
 y = initial_y(); var t=0; var dt=0.4;  // the initial conditions
 // Arrays of return vaules:
 var tmp_end = new Array(3);  var tmp_mid = new Array(2);
 while (t < tfinal) {
    tmp_end = rk4_auto(y, dydt, t, dt, 0.00001);
    tmp_mid = rk4_auto_midpoint();
    t=tmp_mid[0]; y=tmp_mid[1];
    display(t, y);   // e.g. could use wz_jsgraphics.js or SVG
    t=tmp_end[0]; dt=tmp_end[1]; y=tmp_end[2];
    display(t, y);
 }

 // Or, for fixed timesteps ...
 y = post_ww2_y(); var t=1945; var dt=1;  // start in 1945
 var tmp = new Array(2);  // Array of return values
 while (t <= 2100) {
    tmp = rk4(y, dydt, t, dt);  // Merson's 4th-order method
    t=tmp[0]; y=tmp[1];
    display(t, y);
 }
 </SCRIPT>

I<RungeKutta.js> uses several global variables
which all begin with the letters C<_rk_> so you should
avoid introducing variables beginning with these characters.

=head1 AUTHOR

Peter J Billam, http://www.pjb.com.au/comp/contact.html

=head1 REFERENCES

I<On the Accuracy of Runge-Kutta's Method>,
M. Lotkin, MTAC, vol 5, pp 128-132, 1951

I<An Operational Method for the study of Integration Processes>,
R. H. Merson,
Proceedings of a Symposium on Data Processing,
Weapons Research Establishment, Salisbury, South Australia, 1957

I<Numerical Solution of Ordinary and Partial Differential Equations>,
L. Fox, Pergamon, 1962

I<A First Course in Numerical Analysis>, A. Ralston, McGraw-Hill, 1965

I<Numerical Initial Value Problems in Ordinary Differential Equations>,
C. William Gear, Prentice-Hall, 1971

=head1 SEE ALSO

See also the scripts examples/sine-cosine and examples/three-body,
http://www.pjb.com.au/,
http://www.pjb.com.au/comp/,
Math::WalshTransform,
Math::Evol,
Term::Clui,
Crypt::Tea_JS,
http://www.xmds.org/

=cut
]]
