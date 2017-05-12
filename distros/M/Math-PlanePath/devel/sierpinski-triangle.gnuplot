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

#------------------------------------------------------------------------------

set xrange [0:16]; set yrange [0:16]
set key off
set samples 256
splot (int(x)&int(y))==0 ? 1 : NaN with points
pause 100




#------------------------------------------------------------------------------

triangle_x(n) = (n > 0                                           \
                 ? 2*triangle_x(int(n/3)) + digit_to_x(int(n)%3) \
                 : 0)
triangle_y(n) = (n > 0                                           \
                 ? 2*triangle_y(int(n/3)) + digit_to_y(int(n)%3) \
                 : 0)
digit_to_x(d) = (d==0 ? 0 : d==1 ? -1 : 1)
digit_to_y(d) = (d==0 ? 0 : 1)

# Plot the Sierpinski triangle to "level" many replications.
# trange and samples are chosen so that the parameter t runs through
# integers 0 to 3**level-1 inclusive.
#
level=6
set trange [0:3**level-1]      # 
set samples 3**level           # making t integers
set parametric
set key off
plot triangle_x(t), triangle_y(t) with points

pause 100

#------------------------------------------------------------------------------

# 0   0   0
# 1  -1   1
# 2   1  -1
# n%3 >= 

# triangle(n) = (n > 0                                            \
#                ? 2*triangle(int(n/3)) + (int(n)%3==0   ? {0,0}  \
#                                          : int(n)%3==1 ? {-1,1} \
#                                          :               {1,1}) \
#                : 0)
# level=6
# set trange [0:3**level-1]
# set samples 3**level
# set parametric
# set key off
# plot real(triangle(t)), imag(triangle(t)) with points
# 
# pause 100
# 
# #------------------------------------------------------------------------------


# root = cos(pi*2/3) + {0,1}*sin(pi*2/3)
# 
# print root**0
# print root**1
# print root**2
# 
# # triangle(n) = (n > 0                                            \
# #                ? (1+2*triangle(int(n/3)))*root**(int(n)%3)  \
# #                : 0)
# 
# # left = cos(pi*2/3) + {0,1}*sin(pi*2/3)
# # right = cos(pi*1/3) + {0,1}*sin(pi*1/3)
# left = {-1,1}
# right = {1,1}
# 
# 
# t_to_x(t,size) = int(t / size)
# t_to_y(t,size) = (int(t) % size)
# 
# t_to_pyramid_x(t,size) = t_to_x(t,size) - t_to_y(t,size)
# t_to_pyramid_y(t,size) = t_to_x(t,size) + t_to_y(t,size)
# 
# sierpinski_x(t,size) =                  \
#   (t_to_x(t,size) & t_to_y(t,size)      \
#     ? NaN                               \
#     : t_to_pyramid_x(t,size))
# sierpinski_y(t,size) =                  \
#   (t_to_x(t,size) & t_to_y(t,size)      \
#    ? NaN                                \
#    : t_to_pyramid_y(t,size))
# 
# size=50
# set trange [0:size*size-1]
# set samples size*size
# set parametric
# set key off
# plot sierpinski_x(t,size), sierpinski_y(t,size) with points
# 
# pause 100