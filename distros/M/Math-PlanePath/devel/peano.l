; Copyright 2019, 2020 Kevin Ryde
;
; This file is part of Math-PlanePath.
;
; Math-PlanePath is free software; you can redistribute it and/or modify it
; under the terms of the GNU General Public License as published by the Free
; Software Foundation; either version 3, or (at your option) any later
; version.
;
; Math-PlanePath is distributed in the hope that it will be useful, but
; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
; for more details.
;
; You should have received a copy of the GNU General Public License along
; with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.

; from http://mathworld.wolfram.com/HilbertCurve.html 
PeanoMathworld {
  Angle 4            ; 90 degrees
  Axiom X
  X = XFYFX+F+YFXFY-F-XFYFX
  Y = YFXFY-F-XFYFX+F+YFXFY
}

PeanoDiagonal3 {
  Angle 4            ; 90 degrees
  Axiom FX
  X = X-FY+FX++
  Y = Y+FX-FY++
}

PeanoDiagonal3f {
  Angle 4            ; 45 degrees
  Axiom FX
  X = Y+FX-FY      ; to be applied an even number of times
  Y = X-FY+FX
}

PeanoDiagonal3fr {
  Angle 8            ; 45 degrees
  Axiom FX
  X = Y+F+FX-F-FY      ; to be applied an even number of times
  Y = X-F-FY+F+FX
}

; cf
; /usr/share/xfractint/lsystem/fractint.l
;   Peano1
;     Segment replacement in the manner of Mandelbrot, which is
;     Peano's unit square shape, but not Peano's form as it doesn't
;     transpose alternate segments.
;   Peano2
;     Sierpinski curve.
;   Peano3
;     Peano S shape midpoints.


; Local variables:
; compile-command: "xfractint type=lsystem lfile=peano.l lname=PeanoDiagonal3 params=4"
; End:
