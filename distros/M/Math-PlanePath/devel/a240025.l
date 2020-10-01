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


; a240025.l -- Square Spiral by A240025 Turns.
; Kevin Ryde, April 2020
;
; Name this file a240025.l and run from the command line
;
;   xfractint type=lsystem lfile=a240025.l lname=SquareSpiral params=9
;
; Or interactively, the usual key "t", choose type lsystem, "F6" files,
; "F6" again the current directory, choose a240025.l, etc.  Must name
; the file just foo.l not foo.l.txt for it to appear in the file chooser.
;
; "lname" can be SquareSpiral or SquareSpiral2 which are the
; variations below.  Interactively, "t" and choose type lsystem
; (again) goes to the available L-systems in the current file.
;
; "params=9" is the expansion level (order).  This is the number of
; sides in the spiral here.  Interactively, key "z" changes just the
; order.


; The symbol string generated is like
;
;            S F T + F T + F F T + F F T + F F F T +  F F F T + 
;     a(n) = 1     1     1  0    1  0   1   0 0 0  1   0 0 0  1
;        n = 0     1     2  3    4  5   6   7 8 9 10  11     144
;
; F is draw forward.
; Turn a(n), for n>=1, is after each F.
; It is "+" for a(n)=1 turn, or nothing for a(n)=0 no turn.
;
; T is a non-drawing symbol.  It precedes each "+" and its expansion
; increases the length of the preceding run of Fs which are a(n)=0s
; and which are a side of the square.
; The morphism given in the comments in A240025 has 1->0,1 which here
; would be a rule like "+ = F+".  But Fractint doesn't allow rewrite
; of "+", hence T before each + to achieve the same result.
;
; Initial a(0)=1 is reckoned as a special start-of-sequence symbol S.
; It could have a turn "+" like other a(n)=1's, but that merely has
; the effect of turning the whole spiral by 90 degrees.  Prefer to
; omit it so start directed East.
;
; The expansion of S is two sides of length 1, and they expand
; subsequently to two sides length 2, then two sides length 3, etc.

SquareSpiral {
  Angle 4            ; 90 degrees
  Axiom S
  S = SFT+FT+
  T = FT
}


; A little variation can be made by putting T before each run of Fs
; instead of after.  The symbol string generated is then like
;
;     S T F + T F + T F F + T F F + T F F F + T F F F + 
;
; T is still used to increase the length of the Fs, but the Fs following it.
; In this form, T is also at the start of the string which makes it a
; little less like the morphism 1->0,1.

SquareSpiral2 {
  Angle 4            ; 90 degrees
  Axiom S
  S = STF+TF+
  T = TF
}

; Local variables:
; compile-command: "xfractint type=lsystem lfile=a240025.l lname=SquareSpiral params=9"
; End:
