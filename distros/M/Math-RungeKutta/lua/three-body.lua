#!/usr/bin/lua
-- ----------------------------------------------------------------- --
--      This Lua5 script is Copyright (c) 2010, Peter J Billam       --
--                        www.pjb.com.au                             --
--                                                                   --
--   This script is free software; you can redistribute it and/or    --
--          modify it under the same terms as Lua5 itself.           --
-- ----------------------------------------------------------------- --
local Version = '1.0  for Lua5'
local VersionDate  = '1aug2010';
local Synopsis = [[
program_name [options] [filenames]
]]

local RK = require 'RungeKutta'

-- my ($maxcols, $maxrows);
-- eval 'require "Term/Size.pm"';
-- if ($@) {
--	$maxcols = `tput cols`;
--	if ($^O eq 'linux') { $maxrows = (`tput lines` + 0);
--	} else { $maxrows = (`tput rows` + 0);
--	}
-- } else {
--	($maxcols, $maxrows) = &Term::Size::chars(*STDERR);
-- }
-- $maxcols = $maxcols || 80; $maxcols--;
-- $maxrows = $maxrows || 24;
local maxcols = 80
local maxrows = 36
local xmin=-1.4; local xrange=3.0;
local ymin=-1.6; local yrange=3.0;

-- t        x0 y0 vx0 vy0  x1 y1 vx1 vy1  x2 y2 vx2 vy2
local m = {1100,10000,95}
local t=0
local y = {0,1, 3.0,0,   0,0, -0.27,0,   0,-1, -3.0,0}
y[7] = -1.0 * (m[1]*y[3] + m[3]*y[11]) / m[2]  -- zero overall momentum
local G=.001;
local tmax = 20.0;
local dt = 0.01;
local epsilon = 0.000001;

local lastx = {1,1,1}
local lasty = {1,1,1}
function display(t, y)
	-- printf "%g 1=%g,%g 2=%g,%g 3=%g,%g\n",
	--  $t,$y[0],$y[1],$y[4],$y[5],$y[8],$y[9];
	local x_cur; local y_cur;
	local symb = {'o','O','.'}
	move(0,0)
	io.write(string.format("t = %g  ", t))
	for i=1, 3 do
		move(lastx[i],lasty[i])
		io.write(symb[i])
		local tmp = 1 + 4 * (i-1)
		x_cur = math.floor((y[tmp] - xmin) * maxcols / xrange)
		tmp = 2 + 4 * (i-1)
		y_cur = math.floor((y[tmp] - ymin) * maxrows / yrange)
		if x_cur>=0 and x_cur<maxcols and y_cur>=0 and y_cur<maxrows then
			move (x_cur,y_cur); reverse(); io.write(symb[i]); normal()
			lastx[i] = x_cur; lasty[i] = y_cur
		end
	end
end
function move(x,y)
	io.write(string.format("\027[%d;%dH", y+1, x+1))
end
function bold    () io.write("\027[1m") end
function normal  () io.write("\027[0m") end
function clear   () io.write("\027[H\027[J") end
function reverse () io.write("\027[7m") end


function dydt(t, y)
	-- t  x0 y0 vx0 vy0  x1 y1 vx1 vy1  x2 y2 vx2 vy2
	local dydt = {} -- $[=0;

	dydt[1] = y[3];  dydt[2]  = y[4];
	dydt[5] = y[7];  dydt[6]  = y[8];
	dydt[9] = y[11]; dydt[10] = y[12];

	local dist01squared = (y[1]-y[5])^2 + (y[2]-y[6])^2
	local dist02squared = (y[1]-y[9])^2 + (y[2]-y[10])^2
	local dist12squared = (y[5]-y[9])^2 + (y[6]-y[10])^2

	if dist01squared < .0001 then  -- should perhaps collide & coalesce ...
		force01  = 0.0
		force01x = 0.0
		force01y = 0.0
	else
		force01  = G * m[1]*m[2] / dist01squared
		force01x = force01 * (y[1]-y[5]) / math.sqrt(dist01squared)
		force01y = force01 * (y[2]-y[6]) / math.sqrt(dist01squared)
	end
	if dist02squared < .0001 then
		force02  = 0.0
		force02x = 0.0
		force02y = 0.0
	else
		force02  = G * m[1]*m[3] / dist02squared
		force02x = force02 * (y[9]-y[1])  / math.sqrt(dist02squared)
		force02y = force02 * (y[10]-y[2]) / math.sqrt(dist02squared)
	end
	if dist12squared < .0001 then
		force12  = 0.0
		force12x = 0.0
		force12y = 0.0
	else
		force12  = G * m[2]*m[3] / dist12squared
		force12x = force12 * (y[5]-y[9])  / math.sqrt(dist12squared)
		force12y = force12 * (y[6]-y[10]) / math.sqrt(dist12squared)
	end

	dydt[3]  = (0 - force01x - force02x) / m[1]
	dydt[4]  = (0 - force01y - force02y) / m[1]
	dydt[7]  = (force01x - force12x) / m[2]
	dydt[8]  = (force01y - force12y) / m[2]
	dydt[11] = (force02x + force12x) / m[3]
	dydt[12] = (force02y + force12y) / m[3]
	return dydt
end

clear()
--if maxcols < 100 or maxrows <60 then
--	move(0,1)
--	print("It looks best if you run a small font and a big window, say 120x80")
--end

while t<tmax do
	t, dt, y = RK.rk4_auto(y, dydt, t, dt, epsilon)
	t_midpoint, y_midpoint = RK.rk4_auto_midpoint()
	display(t_midpoint, y_midpoint)
	display(t, y)
end
move (0, maxrows-1)
os.exit(0)


--[[
__END__

=pod

=head1 NAME

three-body - Perl script to illustrate Math::RungeKutta

=head1 SYNOPSIS

 perl examples/three-body

=head1 DESCRIPTION

This script uses I<Math::RungeKutta> integrate Newton's inverse-square
law of gravity for three objects moving in a two-dimensional plane.

It uses I<rk4_auto> to adjust the step-size automatically,
and I<rk4_auto_midstep> for a smoother display.

The display assumes you are running something sufficiently
I<vt100>-compatible to understand moveto and reverse.
It looks best if you run a large square window with a tiny font,
perhaps somewhere round 118x80.

You can experiment with changing the masses I<@m> of the objects or
their initial positions and velocities I<@y>, and you will probably
discover how sensitive three-body motion is, and explore some of the
many things that can go wrong during numerical integration :-)

=head1 AUTHOR

Peter J Billam  www.pjb.com.au/comp/contact.html

=head1 CREDITS

Based on Math::RungeKutta

=head1 SEE ALSO

examples/exponentials,
examples/sine-cosine,
Math::RungeKutta,
Term::Size
]]
