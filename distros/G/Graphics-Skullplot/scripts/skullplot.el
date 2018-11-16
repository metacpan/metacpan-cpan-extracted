;;; skullplot.el --- graphical plots of sql select results

;; Copyright 2016 Joseph Brenner
;;
;; Author: doom@kzsu.stanford.edu
;; Version: $Id: skullplot.el,v 0.0 2016/07/16 23:33:00 doom Exp $
;; Keywords:
;; X-URL: not distributed yet

;; License: the same as GNU Emacs, currently GPL v.3  (see LEGAL below).

;; Description:
;; A typical database shell (e.g. psql, mysql) displays the
;; results of queries in a tabular text format I call the box format
;; or "dbox" (file extension: *.dbox).

;; The skullplot.el package exists to assist in generating graphical
;; plots of SQL query results in this "dbox" form form (by the way:
;; database purists dislike pronouncing SQL as 'sequel', an obvious
;; alternative is 'skull').  It works with a perl script skullplot.pl
;; and a perl module Table::BoxFormat, and the R statistical language package
;; ggplot2.

;; TODO: really every piece should check that all the other pieces are installed. 

;;  The main user function here is:
;;   skullplot-this-dbox

;; Installation:

;; Put this file into your load-path and the following into your ~/.emacs:
;;   (require 'skullplot)

;; TODO key assignment for skullplot-this-dbox in various shells and db interfaces...

;;; Code:

(provide 'skullplot)
(eval-when-compile
  (require 'cl))

;;---------
;; early function definitions

(defun skullplot-fixdir (dir &optional root)
  "Fixes the DIR.
Conditions directory paths for portability and robustness.
Some examples:
 '~/tmp'             => '/home/doom/tmp/'
 '~/tmp/../bin/test' => '/home/bin/test/'
Note: converts relative paths to absolute, using the current
default-directory setting, unless specified otherwise with the
ROOT option, this has the side-effect of converting the empty
string into the default-directory or the ROOT setting."
  (let ((return
         (substitute-in-file-name
          (convert-standard-filename
           (file-name-as-directory
            (expand-file-name dir root))))))
    return))

;;---------
;; settings and globals

(defvar progname "skullplot"
  "Name of this program (used in warnings and so on).")

(defvar skullplot-clean-up-buffers t
  "Clean-up the temporary buffers used to pass dbox data.
Defaults to t, set to nil for debugging.")
(setq skullplot-clean-up-buffers nil)

(defvar skullplot-dbox-location ""
  "Location to place the *.dbox files")
(setq skullplot-dbox-location "~/.skullplot/dbox")
(skullplot-fixdir skullplot-dbox-location)

(defvar skullplot-hr-pattern ""
  "Matches 'horizontal rule' lines used in dbox format.
This matches lines like:
 ----+------------+-----------+--------
and also the psql unicode lines:
 ────┼────────────┼───────────┼────────
" )
(setq skullplot-hr-pattern "^[-─+┼][-─+┼][-─+┼]+$")

;; TODO
;; Something like pg format might have a *single* veritcal bar
;; if you've just done a select on two fields (and actually,
;; *none* is possible, if you select just one field... but
;; you're unlikely to want to plot that, correct?)
(defvar skullplot-vbar-pattern ""
  "Match lines that have any vertical bars on them." )
(setq skullplot-vbar-pattern "^.*?[|│]")

(defvar skullplot-vbar-or-cross-pattern ""
  "Heuristic match for any dbox lines, either data, header, or hrs." )
(setq skullplot-vbar-or-cross-pattern "^.*?[|│+┼]")

;; unused
(defvar skullplot-blank-line-pattern ""
  "Match a blank line." )
(setq skullplot-blank-line-pat "^[ \t]*$")


;;---------
;; dbox plotters
;; the main user command(s)

;; wrapper to use as entry point TODO obsolete now?
(defun skullplot-basic-group-by ( indie-count )
  "Takes a numeric argument to distinguish dependent columns from independent.
See section 'TODO'.  The argument defaults to 1."
  (interactive "p")
  ;; (message "indie-count: %d" indie-count )
  (skullplot-this-dbox indie-count)
 )

(defun skullplot-this-dbox ( indie-count )
  "Pop a window with a graphical display of data in the current
or immediately previous dbox."
  (interactive "p")
  (let* (
         ;; emacs uses exec-path list, which has the PATH added to it
         (progfile "skullplot.pl")
         (plotter    progfile)
         (tmpfile (skullplot-create-unique-tempfile))
         (orig-buff (current-buffer))
           buffy
        )

    (setq cmd
          (cond (indie-count
                 ;; skullplot.pl --indie_count=2 input_data.dbox
                 (concat plotter " --indie_count="
                         (number-to-string indie-count)
                         " " tmpfile) )
                 (t
                  (concat plotter " " tmpfile) )
                ))

    (setq table (skullplot-get-dbox))
    (find-file tmpfile)

    (insert table)
    (save-buffer)
    (setq buffy (buffer-name))
    ;; (delete-window)  ;; ?

    (switch-to-buffer orig-buff)

    (if skullplot-clean-up-buffers
         (kill-buffer buffy))

    ;; run the cmd asynchronusly in another process (no shell):
    (start-process "skullplot" "*skullplot*" plotter tmpfile)
    (message "Running: %s" cmd);; DEBUG
    ))

(defun skullplot-of-region (beg end)
  "Pop a window with a graphical display of data in dbox in region.
You might use this if the skullplot-this-dbox heuristics fail,
and you want to specify what to plot manually."
  (interactive "r") ;; r -- Region: point and mark as 2 numeric args, smallest first.  Does no I/O.

  (let* (
         ;; emacs looks through exec-path list, which has the PATH added.
         (progfile "skullplot.pl")
         (slash "/") 
         (plotter      (concat progfile) )
         ;; (tmpdir       "/home/doom/tmp")  ;; Maybe "$HOME/.skullplot"?  But: create if not there
         (tmpdir   temporary-file-directory) ;; "/tmp"
         (tmpfile  (skullplot-fixdir (concat tmpdir slash "skullplot.dbox") ))
         (cmd (concat plotter " " tmpfile) )
        )
    (setq table (buffer-substring-no-properties beg end))
    (find-file tmpfile)
    ;; clear the buffer
    (mark-whole-buffer)
    (delete-region (mark) (point))
    ;;   TODO extra credit: add safety features, e.g. preserve any existing content

    (insert table)
    (save-buffer)
    ;;(write-file nil)
    ;; TODO close the buffer?  Or just the window?

    ;; run the cmd in another process (no shell):
    (message "Running: %s" cmd)

    ;; wasn't working, not sure why:
    ;; (start-process "skullplot" "*skullplot*" cmd)

    ;; works, but it blocks:
    ;; (call-process plotter tmpfile '("*skullplot*" t) t)

    ;; asynchronus
    (start-process "skullplot" "*skullplot*" plotter tmpfile)
))

;;---------
;; move to pattern

;;--------
;; hr rule

(defun skullplot-move-up-to-hr ()
  "Move upwards to first match of 'skullplot-hr-pattern' or start of buffer."
  (interactive)
  ;; Q: why not re-search-backward?  Eaiser to negate the pattern match, right?
  (move-beginning-of-line 1)
  (catch 'FLY
    (while (not (looking-at skullplot-hr-pattern ) )
      (forward-line -1) ;; move up to previous line
      (if (= (point) (point-min))
          (throw 'FLY nil))
      )))

(defun skullplot-move-down-to-hr ()
  "Move downwards to first match of 'skullplot-hr-pattern' or end of buffer.
Returns nil if not found."
  (interactive)
  ;; Q: why not re-search-forward?  A: eaiser to negate the pattern match, right?
  (move-beginning-of-line 1)
  (catch 'FLY
    (while (not (looking-at skullplot-hr-pattern ) )
      (forward-line 1)
      (move-end-of-line 1)
      (if (= (point) (point-max))
          (throw 'FLY nil))
      (move-beginning-of-line 1)
     )))

;;--------
;; vb sep lines or hrs

(defun skullplot-move-down-to-end-of-dbox ()
  "Move downwards to last line with vertical bars."
  (interactive)
  (move-beginning-of-line 1)
  (catch 'FLY
    (while ( looking-at skullplot-vbar-or-cross-pattern )
      (forward-line 1)
      (move-end-of-line 1)
      (if (= (point) (point-max))
          (throw 'FLY nil))
      (move-beginning-of-line 1)
     ))
  (forward-line -1)
  (move-end-of-line 1) )


(defun skullplot-move-up-to-start-of-dbox ()
  "Move upwards to first line with vertical bars."
  (interactive)
  (move-beginning-of-line 1)
  (catch 'FLY
    (while ( looking-at skullplot-vbar-or-cross-pattern )
      (forward-line -1) ;; move up to previous line
      (if (= (point) (point-min))
          (throw 'FLY nil))
      ))
  (forward-line 1))

;;--------
;; scraping dboxes

(defun skullplot-find-dbox ()
  "Look upwards for the previous dbox (if any)."
  (interactive)
  (let* ( (savepoint (point))
          dbox-start dbox-end  ;; start of upper line; end of lower line
          )
    (skullplot-move-up-to-hr)
    (skullplot-move-up-to-start-of-dbox)
    (setq dbox-start (point))
    (skullplot-move-down-to-end-of-dbox)
    (move-end-of-line 1)
    (setq dbox-end (point))
    ;; (message "%d %d" dbox-start dbox-end)
    (goto-char savepoint)
    (list dbox-start dbox-end)
    ))

(defun skullplot-get-dbox ()
  "Return previous dbox as string.."
  (interactive)
  (let* (( pair (skullplot-find-dbox) )
         ( beg (nth 0 pair) )
         ( end (nth 1 pair) )
         )
    (buffer-substring-no-properties beg end)))

;;--------
;; utilites

(defun skullplot-snag-line ()
  "Returns the current line as a string."
  (let ( start end line )
    (move-beginning-of-line 1)
    (setq start (point))
    (move-end-of-line 1)
    (setq end (point))
    (setq line (buffer-substring start end))
    line))

(defun skullplot-create-unique-tempfile ( &optional seed )
  "Create a uniquely named dbox file, using the SEED.
Location defaults to skullplot-dbox-location."
  (unless seed (setq seed ""))
  (let ( slashy temploc prefix templfile )
    (setq slashy (convert-standard-filename "/"))
    (setq temploc skullplot-dbox-location)
    (unless (file-exists-p temploc)
      (make-directory temploc t))
    (setq prefix
          (concat temploc slashy seed))
    (setq tempfile
          (make-temp-file prefix nil ".dbox"))
    )
  tempfile)



;; LEGAL

;; This code is licensed in the same way as GNU Emacs, which is currently
;; under the GPL v.3 (or later).

;;; skullplot.el ends here
