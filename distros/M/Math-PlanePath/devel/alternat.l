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


; This file is named alternat.l since the file chooser in xfractint is
; limited to CP/M style 8.3 filenames.


; X is at the end of an even segment.  That segment expands to a left
; turn in the middle and the existing turn after the segment flip L<->R.
; That flip is achieved by a "|" turn 180 degrees.
;
; Y is at the end of an odd segment.  That segment expands to a right
; turn in the middle, and again existing turn after it flip L<->R.
;
Alternate {
  Angle 4            ; 90 degrees
  Axiom FX
  X = X+FY|
  Y = X-FY|
}

; X is at the end of an even segment.
; Y is at the end of an odd segment.
; Two expansions of each is
;
;                    R---R
;                    |   |
;     X segment  .---L   .       Y segment  .   R---.
;                                           |   |
;                                           L---L
;
; Existing turns are unchanged, since they are flipped left <-> right
; twice which is back to the same as they were.
;
; The "order" here is effectively doubled, so that say 8 for
; "Alternate" is equivalent to 4 for "Alternate2".
;
Alternate2 {
  Angle 4            ; 90 degrees
  Axiom FX
  X = X+FY-FX-FY
  Y = X+FY+FX-FY
}

; Same as "Alternate2" above, but each F there is doubled to F here,
; and the turns are given chamfers by two steps of 45 degrees and an F
; in between so + is +F+ and - is -F-.
;
; The doubled FF makes the side longer than the chamfer.
; A single F for both the sides and the chamfer would be a more rounded look.
;
AlternateRound2 {
  Angle 8            ; 45 degrees
  Axiom FFX
  X = X+F+FFY-F-FFX-F-FFY
  Y = X+F+FFY+F+FFX-F-FFY
}

; Local variables:
; compile-command: "xfractint type=lsystem lfile=alternat.l lname=Alternate params=8"
; End:
