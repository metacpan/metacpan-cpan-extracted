#!/usr/bin/lua
-- ----------------------------------------------------------------- --
--      This Lua5 script is Copyright (c) 2010, Peter J Billam       --
--                        www.pjb.com.au                             --
--                                                                   --
--   This script is free software; you can redistribute it and/or    --
--          modify it under the same terms as Lua5 itself.           --
-- ----------------------------------------------------------------- --
local Version = '1.0  for Lua5'
local VersionDate  = '25aug2010';
local detailed = false
local M = require 'Evol'

--------------------------- infrastructure ------------------------
local Test = 12 ; local i_test = 0; local Failed = 0;
function ok(b,s)
	i_test = i_test + 1
	if b then
		io.write('ok '..i_test..' - '..s.."\n")
	else
		io.write('not ok '..i_test..' - '..s.."\n")
		Failed = Failed + 1
	end
end
local function warn(str)
	io.stderr:write(str,'\n')
end
local function die(str)
	io.stderr:write(str,'\n')
	os.exit(1)
end
-------------------------------------------------------------------

local function minimise(x)
	local sum = 1.0
	for k,v in pairs(x) do sum = sum + v * v end
	return sum
end
local function contain(x)
	if (x[1] > 1.0) then x[1] = 1.0;  -- it's a greyscale value
	elseif (x[1] < 0.0) then x[1] = 0.0;
	end
	if (x[2] > 1.0) then x[2] = 1.0;  -- it's a greyscale value
	elseif (x[2] < 0.0) then x[2] = 0.0;
	end
	if (x[3] > 1.0) then x[3] = 1.0;  -- it's a greyscale value
	elseif (x[3] < 0.0) then x[3] = 0.0;
	end
	-- warn('contain: x = '..x[1]..' '..x[2]..' '..x[3]..' '..x[4].."=n")
	return x
end
local function choosebetter(arglist)
	local a = arglist[1]; local b = arglist[2];
	local a_sum = 0.0; for k,v in ipairs(a) do a_sum = a_sum + v * v end
	local b_sum = 0.0; for k,v in ipairs(b) do b_sum = b_sum + v * v end
	local preference = 1; if b_sum < a_sum      then preference = 2 end
--warn("a_sum="..tostring(a_sum).." b_sum="..tostring(b_sum).."\n")
	local continue   = false; if a_sum > 0.00000001 then continue   = true end
	return preference, continue
end
local text = [[
/w 3.456  def % evol step 0.8 min 0 max 1
/x 1.234  def % evol step 0.4 min 0 max 1
/y -2.345 def % evol step 0.6 min 0 max 1
/z 4.567  def % evol step 1.2
]]

local x  = {3.456, 1.234, -2.345, 4.567}
local sm = {.8, .4, .6, 1.2}

-- ----------------- test M.evol --------------------
local returns = {M.evol(x, sm, minimise, contain, 10)}
local fail1 = 0
for k,v in ipairs(returns[1]) do
	if math.abs(v) >0.00015 then
		if detailed then
			warn("\$_ = $_\n"); fail1 = fail1 + 1
		end
	end
end
ok (fail1 == 0 and returns[4], "evol");
if detailed then
	if fail1 > 0 then warn("evol failed to find the minimum\n") end
	for k,v in ipairs(returns[2]) do
		if math.abs(v) > 0.00015 then
			warn("step size still v\n")
			fail1 = fail1 + 1
		end
	end
	if fail1 > 0 then
		warn("evol returns:\n x = ", table.concat(returns[1],", "), "\n")
		warn("sm = ", table.concat(returns[2]", "), "\n")
		warn("objective = "..tostring(returns[3]).."\n")
		warn("success   = "..tostring(returns[4]).."\n")
	end
	if not returns[4] then
		warn("evol ran out of time; maybe you have a slow cpu ?\n")
	end
end

M.ec = nil
returns = {M.evol(x, sm, minimise, contain, 10)}
fail1 = 0
for k,v in ipairs(returns[1]) do
	if math.abs(v) > 0.0001 then
		if detailed then warn("v = "..tostring(v).."\n") end
		fail1 = fail1 + 1
	end
end
ok (fail1 == 0 and returns[4], "evol without absolute convergence criterion")
if detailed then
	if fail1 > 0 then warn("evol failed to find the minimum\n") end
	for k,v in ipairs(returns[2]) do
		if math.abs(v) > 0.0001 then
			warn("step size still $_\n")
			fail1 = fail1 + 1
		end
	end
	if fail1 > 0 then
		warn("evol returns:\n x = ", table.concat(returns[1],", "), "\n")
		warn("sm = ", table.concat(returns[2], ", "), "\n")
		warn("objective = "..tostring(returns[3]).."\n")
		warn("success   = "..tostring(returns[4]).."\n")
	end
	if not returns[4] then
		warn("evol ran out of time; maybe you have a slow cpu ?\n")
	end
end

M.ec = 1e-16
M.ed = nil
returns = {M.evol(x, sm, minimise, contain, 10)}
fail1 = 0
for k,v in ipairs(returns[1]) do
	if math.abs(v) >0.0001 then
		if detailed then warn("v = $_\n") end
		fail1 = fail1 + 1
	end
end
ok (fail1 == 0 and returns[4], "evol without relative convergence criterion")
if detailed then
	if fail1 > 0 then warn("evol failed to find the minimum\n") end
	for k,v in ipairs(returns[2]) do
		if math.abs(v) > 0.0001 then
			warn("step size still $_\n")
			fail1 = fail1
		end
	end
	if fail1 > 0 then
		warn("evol returns:\n x = ", table.concat(returns[1], ", "), "\n")
		warn("sm = ", table.concat(returns[2], ", "), "\n")
		warn("objective = "..tostring(returns[3]).."\n")
		warn("success   = "..tostring(returns[4]).."\n")
	end
	if not returns[4] then
		warn("evol ran out of time; maybe you have a slow cpu ?\n")
	end
end

M.ec = nil
M.ed = nil
returns = {M.evol(x, sm, minimise, contain, 2)}
fail1 = 0
for k,v in ipairs(returns[1]) do
	if math.abs(v) > 0.0001 then
		if detailed then warn("v = $_\n") end
		fail1 = fail1 + 1
	end
end
ok (fail1 == 0 and not returns[4], "evol with \$tm timelimit paramater")
ok (not returns[4], "evol correctly reports timelimit exceeded")
if detailed then
	if fail1 > 0 then warn("evol failed to find the minimum\n") end
	for k,v in ipairs(returns[2]) do
		if math.abs(v) > 0.0001 then
			warn("step size still $_\n")
			fail1 = fail1 + 1
		end
	end
	if fail1 > 0 then
		warn("evol returns:\n x = ", table.concat(returns[1], ", "), "\n")
		warn("sm = ", table.concat(returns[2], ", "), "\n")
		warn("objective = "..tostring(returns[3]).."\n")
		warn("success   = "..tostring(returns[4]).."\n")
	end
	if not returns[4] then
		warn("evol ran out of time, as it's supposed to")
	end
end

-- ----------------- test M.select_evol --------------------
x  = {3.456, 1.234, -2.345, 4.567}
sm = {.8, .4, .6, 1.2}
returns = {M.select_evol(x, sm, choosebetter, nil, 1)}
local fail2 = 0
for k,v in ipairs(returns[2]) do
	if math.abs(v)>0.001 then
		if detailed then warn("v = "..tostring(v).."\n") end
		fail2 = fail2 + 1
	end
end
ok (fail2 == 0, "select_evol")
if detailed then
	if fail2 > 0 then
		warn("select_evol failed to find the minimum")
	end
	for k,v in ipairs(returns[2]) do
   		if math.abs(v) > 0.001 then
			warn("step size still $_\n")
			fail2 = fail2 + 1 -- XXX ???
		end
	end
	if fail2 > 0 then
   		warn("select_evol returns:\n x = ", table.concat(returns[1],", "),"\n")
   		warn("sm = ", table.concat(returns[2], ", "), "\n")
	end
end

--[[
  needs a sub choosebettertext, RSN ...
-- ----------------- third test select_evol --------------------
local $new_text = &text_evol( $text, \&choosebettertext, 1);
local $fail3 = 0;
print "new_text = ...\n$new_text";
if ($fail3) {
   warn "select_evol returns:\n x = ", table.concat(", ", @{$returns[0]}), "\n";
   warn "sm = ", table.concat(", ", @{$returns[1]}), "\n";
} else {
   print "subroutine text_evol OK\n";
}

=pod

=head1 NAME

test.pl - Perl script to test Math::Evol.pm

=head1 SYNOPSIS

 perl test.pl

=head1 DESCRIPTION

This script tests Math::Evol.pm

=head1 AUTHOR

Peter J Billam <peter@pjb.com.au>

=head1 SEE ALSO

Math::Evol.pm , http://www.pjb.com.au/ , perl(1).

=cut

]]
