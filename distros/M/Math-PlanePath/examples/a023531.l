; Copyright 2019 Kevin Ryde
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


; a023531.l -- Triangle Spiral by A023531 Turns.
; Kevin Ryde, December 2019
;
; The turn sequence of Math::PlanePath::TriangleSpiral is OEIS A240025.
; This file is a lightly massaged copy of my upload there.

; Usage: xfractint type=lsystem lfile=a023531.l lname=TriangleSpiral params=9
;
; Or interactively, the usual key "t", choose type lsystem, "F6" files,
; "F6" again the current directory, choose a023531.l, etc.
;
; "lname" can be TriangleSpiral or TriangleSpiral2 which are the
; variations below.  Interactively, "t" and choose type lsystem
; (again) goes to the available L-systems in the current file.
;
; "params=9" is the expansion level (order).  This is the number of
; sides in the spiral here.  Interactively, key "z" changes just the
; order.


; The symbol string generated is like
;
;            S F T + F F T + F F F T + F F F F T + F F F F F T + 
;     a(n) =      1   0   1   0 0   1   0 0 0   1   0 0 0 0   1  
;        n =      0   1   2   3 4   5   6 7 8   9   10    13  14
;
; F is draw forward.
; Turn a(n) is after each F, and is either "+" for a(n)=1 turn, or
; nothing for a(n)=0 which is no turn.
; T is a non-drawing symbol.  It precedes each "+" and its expansion
; increases the length of the preceding run of Fs which are a(n)=0s
; and which are the preceding side.
;
; The morphism given in the comments in A023531 has 1->0,1 which here
; would be a rule like "+ = F+".  But Fractint doesn't allow rewrite
; of "+", hence T before each + to achieve the same result.

TriangleSpiral {
  Angle 3            ; 120 degrees
  Axiom S
  S = SFT+
  T = FT
}


; A little variation can be made by putting the T before each run of
; Fs instead of after.  The symbol string generated is then like
;
;     S T F + T F F + T F F F + T F F F F + T F F F F F + 
;
; T is still used to increase the length of the Fs, but the Fs following it.
; In this form, T is also at the start of the string which makes it a
; little less like the morphism 1->0,1.

TriangleSpiral2 {
  Angle 3            ; 120 degrees
  Axiom S
  S = STF+
  T = TF
}

; Local variables:
; compile-command: "xfractint type=lsystem lfile=a023531.l lname=TriangleSpiral params=9"
; End:
