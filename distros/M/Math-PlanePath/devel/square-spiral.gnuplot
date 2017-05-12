#!/usr/bin/gnuplot

# Copyright 2012 Kevin Ryde

# This file is part of Math-PlanePath.
#
# Math-PlanePath is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-PlanePath is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.


# http://rosettacode.org/wiki/Spiral_matrix
# http://rosettacode.org/wiki/Zig-zag_matrix

# set terminal png
# set terminal xterm

n_to_xy(n) = \
  (n <= 1 ? n : nd_to_xy(n, n_to_d(n)))

nd_to_xy(n,d) = \
  drem_to_xy(d, n - d_to_base(d))

n_to_d(n) = int ((2 + sqrt(int(4*n))) / 4)
d_to_base(d) = 4 * d**2

# right vertical    
# top horizontal   
# left vertical    
# bottom horizontal
#
drem_to_xy(d,r) =                   \
  (r < -2*d  ? d + (r+3*d)*{0,1}    \
   : r < 0   ? -r + d*{-1,1}        \
   : r < 2*d ? -d + (d-r)*{0,1}     \
   :           r-2*d + d*{-1,-1})


print n_to_d(0)
print n_to_d(1)
print n_to_d(2)
print n_to_d(3)
print n_to_d(4)
print n_to_d(5)
print ''

print n_to_xy(0)
print n_to_xy(1)
print n_to_xy(2)
print n_to_xy(3)
print n_to_xy(4)
print n_to_xy(5)
print n_to_xy(6)
print n_to_xy(7)
print n_to_xy(8)
print n_to_xy(9)


# set xrange [0:36]
# plot real(n_to_xy(x))
# pause 100

# set xrange [0:36]
# plot x-d_to_base(n_to_d(x))
# pause 100

length=49
set trange [0:length]
set samples 5*length+1
set parametric
set key off
plot real(n_to_xy(t)),imag(n_to_xy(t)) with labels
pause 100




# # Return the position of the highest 1-bit in n.
# # The least significant bit is position 0.
# # For example n=13 is binary "1101" and the high bit is pos=3.
# # If n==0 then the return is 0.
# # Arranging the test as n>=2 avoids infinite recursion if n==NaN (any
# # comparison involving NaN is always false).
# #
# high_bit_pos(n) = (n>=2 ? 1+high_bit_pos(int(n/2)) : 0)
# 
# # Return 0 or 1 for the bit at position "pos" in n.
# # pos==0 is the least significant bit.
# #
# bit(n,pos) = int(n / 2**pos) & 1
# 
# # dragon(n) returns a complex number which is the position of the
# # dragon curve at integer point "n".  n=0 is the first point and is at
# # the origin {0,0}.  Then n=1 is at {1,0} which is x=1,y=0, etc.  If n
# # is not an integer then the point returned is for int(n).
# #
# # The calculation goes by bits of n from high to low.  Gnuplot doesn't
# # have iteration in functions, but can go recursively from
# # pos=high_bit_pos(n) down to pos=0, inclusive.
# #
# # mul() rotates by +90 degrees (complex "i") at bit transitions 0->1
# # or 1->0.  add() is a vector (i+1)**pos for each 1-bit, but turned by
# # factor "i" when in a "reversed" section of curve, which is when the
# # bit above is also a 1-bit.
# #
# dragon(n) = dragon_by_bits(n, high_bit_pos(n))
# dragon_by_bits(n,pos) \
#   = (pos>=0 ? add(n,pos) + mul(n,pos)*dragon_by_bits(n,pos-1)  : 0)
# 
# add(n,pos) = (bit(n,pos) ? (bit(n,pos+1) ? {0,1} * {1,1}**pos   \
#                                          :         {1,1}**pos)  \
#               : 0)
# mul(n,pos) = (bit(n,pos) == bit(n,pos+1) ? 1 : {0,1})
# 
# # Plot the dragon curve from 0 to "length" with line segments.
# # "trange" and "samples" are set so the parameter t runs through
# # integers t=0 to t=length inclusive.
# #
# # Any trange works, it doesn't have to start at 0.  But must have
# # enough "samples" that all integers t in the range are visited,
# # otherwise vertices in the curve would be missed.
# #
