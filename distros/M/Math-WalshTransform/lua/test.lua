#!/usr/bin/lua
-- ----------------------------------------------------------------- --
--      This Lua5 script is Copyright (c) 2010, Peter J Billam       --
--                        www.pjb.com.au                             --
--                                                                   --
--   This script is free software; you can redistribute it and/or    --
--          modify it under the same terms as Lua5 itself.           --
-- ----------------------------------------------------------------- --
local Version = '1.0  for Lua5'
local VersionDate  = '17aug2010';
local Synopsis = [[
cp WalshTransform.lua /usr/local/lib/lua5.1/
lua test_wt
]]
--------------------------- infrastructure ----------------
local eps = .000000001
function equal(x, y)
	-- print('#x='..#x..' #y='..#y)
	if #x ~= #y then return false end
	local i; for i=1,#x do
		if math.abs(x[i]-y[i]) > eps then return false end
	end
	return true
end
-- use Test::Simple tests => 12;
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
--------------------------- infrastructure ----------------
local M = require 'WalshTransform'

local x = {0,2,2,0};
local X = M.fht(x);
ok (equal(X, {1,0,0,-1}), "Hadamard transform");
X = M.fwt(x);
--io.write('X = '..table.concat(X,', ').."\n")
ok (equal(X, {1,0,-1,0}), "Walsh transform");

ok (equal(M.fhtinv{1,0,0,-1}, {0,2,2,0}), "Inverse Hadamard transform");
local IWT = M.fwtinv{1,0,-1,0}
ok (equal(M.fwtinv{1,0,-1,0}, {0,2,2,0}), "Inverse Walsh transform");

local f = {}
for n=1,1024 do f[n] = 9.9 * math.random() end

local H = M.fht(f); h = M.fhtinv(H);
ok(equal(f,h), "Hadamard transform and inverse");

local W = M.fwt(f); w = M.fwtinv(W);
ok(equal(f,w), "Walsh transform and inverse");

local HW = M.hadamard2walsh(H);
ok(equal(W, HW), "Hadamard to Walsh");

local WH = M.walsh2hadamard(W);
ok(equal(H,WH), "Walsh to Hadamard");

local f1= {9.87072934669408, 1.00335666118512, 3.56465114416856, 2.63433827973928, 8.70090293467903, 5.5749869059126, 1.41925315684927, 4.65320360115106}
local f2= {9.66245411968908, 6.68104040467208, 0.701308019776252, 1.67973815486713, 8.29366547532535, 4.96873463871041, 7.45273195434394, 9.43798945518134}
local lc1= {32.9201326859361, 27.6275402643456, 26.6255883154714, 29.4831966805661, 33.551184002812, 28.5361422803341, 23.2443953247871, 26.6457736818649}
local lc2 = M.logical_convolution(f1, f2);
-- io.write('lc2 = '..table.concat(lc2,', ').."\n")
ok (equal(lc1,lc2), "Logical Convolution");

ok (math.abs(2.5 - M.size{1.0,-0.5,2.0,-1.0}) < eps, "size");

x = {1.0, -1.5, 2.0, -2.5}
local y = {3.0, -3.5, -4.0, 4.5}
ok (equal(M.product(x,y), {3.0, 5.25, -8.0, -11.25}), "product");

ok (math.abs(2.5-M.distance({0.5,-0.5,3.0,1.0},{-0.5,0.0,1.0,2.0}))<eps,"distance");

y = M.normalise({1.0,-0.5,2.0,-1.0});
ok (equal(y, {0.4,-0.2,0.8,-0.4}),"normalise");

y = M.average({0.5,-0.5,3.0,1.0},{-0.5,0.0,1.0,2.0},{0.6,1.4,0.-2.2,0.3});
-- io.write('y = '..table.concat(y,', ').."\n")
ok (equal(y,{0.2,0.3,0.6,1.1}), "average");

y = M.biggest(3, {0.5,-0.5,3.0,1.0,-0.5,0.0,1.0,2.0,0.6,1.4,0,-2.2,0.3})
ok (equal(y,{0, 0, 3, 0, 0, 0, 0, 2, 0, 0, 0, -2.2, 0}), "biggest");

y = M.sublist({0.5,-0.5,3.0,1.0,-0.9,0.0,1.2,2.0,0.6,1.4,0,-2.2,0.3},3,4)
ok (equal(y,{1.0,-0.9,0.0,1.2}), "sublist");
y = M.sublist({0.5,-0.5,3.0,1.0,-0.9,0.0,1.2,2.0,0.6,1.4,0,-2.2,0.3},-5,4)
ok (equal(y,{0.6,1.4,0,-2.2}), "sublist with negative offset");
y = M.sublist({0.5,-0.5,3.0,1.0,-0.9,0.0,1.2,2.0,0.6,1.4,0,-2.2,0.3},-5)
ok (equal(y,{0.6,1.4,0,-2.2,0.3}), "sublist with length omitted");
y = M.sublist({0.5,-0.5,3.0,1.0,-0.9,0.0,1.2,2.0,0.6,1.4,0,-2.2,0.3},8,-3)
ok (equal(y,{0.6,1.4}), "sublist with negative length");

y = M.power_spectrum({.5,-.5,3,1,-.5,0,1,2,.6,1.4,0,-2.2,-.7,4.2,-1,5})
local y2 = {0.74390625, 0.0025, 0.330625, 0.15015625, 0.06890625,
 0.105625, 0.49, 0.05640625, 0.0225, 0.00765625, 0.02640625,
 0.1225, 1.1025, 0.23765625, 0.47265625, 0.25}
ok (equal(y,y2), "power_spectrum");

--[[
__END__

=pod

=head1 NAME

test.lua - Lua script to test WalshTransform.lua

=head1 SYNOPSIS

 lua test.lua

=head1 DESCRIPTION

This script tests WalshTransform.lua,
which comes in the ./lua/ subdirectory in the CPAN module
Math::WalshTransform

=head1 AUTHOR

Peter J Billam  http://www.pjb.com.au/comp/contact.html

=head1 SEE ALSO

Math::WalshTransform.pm , http://www.pjb.com.au/ , perl(1).

=cut
]]
