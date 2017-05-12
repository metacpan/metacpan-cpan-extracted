;; Copyright 2012, 2013 Kevin Ryde
;;
;; This file is part of Math-PlanePath.
;;
;; Math-PlanePath is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 3, or (at your option) any later
;; version.
;;
;; Math-PlanePath is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
;; for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with Math-PlanePath.  If not, see <http://www.gnu.org/licenses/>.


;; Usage: M-x load-file dragon-curve.el
;;
;; And thereafter M-x dragon-picture.
;;

(unless (fboundp 'ignore-errors)
  (require 'cl)) ;; Emacs 22 and earlier `ignore-errors'

(defun dragon-ensure-line-above ()
  "If point is in the first line of the buffer then insert a new line above."
  (when (= (line-beginning-position) (point-min))
    (save-excursion
      (goto-char (point-min))
      (insert "\n"))))

(defun dragon-ensure-column-left ()
  "If point is in the first column then insert a new column to the left.
This is designed for use in `picture-mode'."
  (when (zerop (current-column))
    (save-excursion
      (goto-char (point-min))
      (insert " ")
      (while (= 0 (forward-line 1))
        (insert " ")))
    (picture-forward-column 1)))

(defun dragon-insert-char (char len)
  "Insert CHAR repeated LEN many times.
After each CHAR move point in the current `picture-mode'
direction (per `picture-set-motion' etc).

This is the same as `picture-insert' except in column 0 or row 0
a new row or column is inserted to make room, with existing
buffer contents shifted down or right."

  (dotimes (i len)
    (dragon-ensure-line-above)
    (dragon-ensure-column-left)
    (picture-insert char 1)))

(defun dragon-bit-above-lowest-0bit (n)
  "Return the bit above the lowest 0-bit in N.
For example N=43 binary \"101011\" has lowest 0-bit at \"...0..\"
and the bit above that is \"..1...\" so return 8 which is that
bit."
  (logand n (1+ (logxor n (1+ n)))))

(defun dragon-next-turn-right-p (n)
  "Return non-nil if the dragon curve should turn right after segment N.
Segments are numbered from N=0 for the first, so calling with N=0
is whether to turn right at the end of that N=0 segment."
  (zerop (dragon-bit-above-lowest-0bit n)))

(defun dragon-picture (len step)
  "Draw the dragon curve in a *dragon* buffer.
LEN is the number of segments of the curve to draw.
STEP is the length of each segment, in characters.

Any LEN can be given but a power-of-2 such as 256 shows the
self-similar nature of the curve.

If STEP >= 2 then the segments are lines using \"-\" or \"|\"
characters (`picture-rectangle-h' and `picture-rectangle-v').
If STEP=1 then only \"+\" corners.

There's a `sit-for' delay in the drawing loop to draw the curve
progressively on screen."

  (interactive (list (read-number "Length of curve " 256)
                     (read-number "Each step size " 3)))
  (unless (>= step 1)
    (error "Step length must be >= 1"))

  (switch-to-buffer "*dragon*")
  (erase-buffer)
  (setq truncate-lines t)
  (ignore-errors ;; ignore error if already in picture-mode
    (picture-mode))

  (dotimes (n len)  ;; n=0 to len-1, inclusive
    (dragon-insert-char ?+ 1)  ;; corner char
    (dragon-insert-char (if (zerop picture-vertical-step)
                                    picture-rectangle-h picture-rectangle-v)
                                (1- step))  ;; line chars

    (if (dragon-next-turn-right-p n)
        ;; turn right
        (picture-set-motion (- picture-horizontal-step) picture-vertical-step)
      ;; turn left
      (picture-set-motion picture-horizontal-step (- picture-vertical-step)))

    ;; delay to display the drawing progressively
    (sit-for .01))

  (picture-insert ?+ 1) ;; endpoint
  (picture-mode-exit)
  (goto-char (point-min)))

(dragon-picture 128 2)
