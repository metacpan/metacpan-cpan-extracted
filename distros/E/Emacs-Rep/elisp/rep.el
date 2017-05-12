;;; rep.el --- find and replace using perl5

;; Copyright 2010,2012 Joseph Brenner
;;
;; Author: doom@kzsu.stanford.edu
;; Version: $Id: rep.el,v 0.0 2010/05/14 01:49:29 doom Exp $
;; Keywords:
;; X-URL: not distributed yet

;; Note: in the event that the licensing of the Emacs::Rep module
;; (see the file lib/Emacs/Rep.pm in this package)
;; conflicts with the following statement, the terms of Emacs::Rep
;; shall be used.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:

;; "Rep" is a system for doing global finds and replaces throughout
;; a file with a set of perl substitution commands (that is, "s///g").

;; This elisp code is the interactive front-end, which uses perl
;; code as a back-end to execute the changes, so you get to use
;; actual perl5 regexps, and you have (almost) all of the features
;; of perl substitutions.

;; The interactive features of rep.el include the ability to
;; reject individual changes, or to revert all of the changes and
;; start over.

;; INSTALLATION and SET-UP

;; If it isn't there already, put this file (rep.el) somewhere in
;; your emacs load-path.

;; If possible, you should just install the Emacs-Rep CPAN
;; package (and see the README file inside that package).

;; Otherwise, you will also need to make sure the script "rep.pl"
;; to be located somewhere in your system PATH, and the Emacs::Rep
;; perl module (i.e. the file Emacs/Rep.pm) is installed somewhere
;; that rep.pl can find it (e.g. a location in your PERL5LIB
;; environment variable).

;; Just add the following into your ~/.emacs (or equivalent):
;;   (require 'rep)
;;   (rep-standard-setup)

;; Alternately, if you don't want to use "\C-c." (control c dot) as
;; your standard prefix, you might do this to, for example, use
;; "\C-c|" (control c pipe) instead:

;;   (require 'rep)
;;   (setq rep-key-prefix [(control ?c) ?|]   ;; for rep-modified-mode
;;   (rep-standard-setup)

;; USAGE

;; When editing a file you'd like to modify you can use "C-c.S" to open a
;; small window suitable for entering a series of perl substitution
;; commands, typically of the form: "s/<find_pattern>/<replace_string>/g;".

;; When you're ready, "C-x #" will run these substitutions on the
;; other window.

;; The usual font-lock syntax coloring will be temporarily
;; shut-off, so that modified strings can be indicated easily,
;; with colors correspond to the particular s///g command that
;; made the change.

;; In the buffer for the modified file a "rep-modified-mode" minor
;; mode has been switched on with keybindings to do various useful
;; tasks as you evaluate the changes made by your substitutions.

;;    TAB       rep-modified-skip-to-next-change
;;              You can easily skip to the next change with the tab key.
;;              The message in the status bar tells you what it was
;;              before the change.

;;    "C-c.u"   rep-modified-undo-change-here
;;              Does an undo of an individual change, changing it back
;;              to the string indicated with "C-c.w".

;;    "C-c.R"   rep-modified-revert-all-changes
;;              Reverts all of the changes at once.
;;              If there have been multiple substitutions runs
;;              on the same file-buffer, repeated uses of this
;;              command will continue reverting the previous run.

;;     "C-c.A"  rep-modified-accept-changes
;;              When you're convinced that the substitutions did
;;              what you wanted, you can use this to accept the changes
;;              and get your normal syntax coloring back.

;;  Note that the *.rep files you create with C-c.S can be run again
;;  on other files.  This can simplify making similar changes to
;;  a large number of files.

;; For more information:

;; Web pages about this code:
;;    http://obsidianrook.com/rep

;; The CPAN Emacs-Rep package:
;;    http://search.cpan.org/search?query=Emacs%3A%3ARep&mode=all

;; The latest code:
;;   http://github.com/doomvox/rep


;;; Code:

(provide 'rep)
(eval-when-compile
  (require 'cl)
  (require 'dired-aux)
  (require 'json)
  )



;;---------
;;  User Options, Variables

(defvar rep-version "1.00"
 "Version number of the rep.el elisp file.
This version should match the versions of
the rep.pl script and the Rep.pm \(Emacs::Rep\)
perl library.")

(defvar rep-debug nil
  "Set to t to enable some debug messages.")
;; (setq rep-debug nil)
;; (setq rep-debug t)

(defvar rep-trace nil
  "Set to t to enable subroutine trace messages.")
;; (setq rep-trace nil)
;; (setq rep-trace t)

(defcustom rep-underline-changes-color nil
  "If this is set to a color name such as \"red\" then the
substitution changes will also be underlined in that color.  If
it is set to t, then the changes will be underlined in the same
color as their markup face.  See \\[rep-lookup-markup-face].")

(defvar rep-font-lock-buffer-status nil
  "Buffer local variable to store the previous font-lock-mode status.
This allows us to remember that font-lock-mode was on, and should be
re-enabled after changes are accepted.")
(make-variable-buffer-local 'rep-font-lock-buffer-status)

(defvar rep-default-substitutions-directory nil
  "The location to place newly created files of substitution commands.
Note: include a trailing slash.
If this is nil, then a sub-directory named \".rep\" will
be created in parallel with the file to be modified.")

;; Note, at present, the *.rep file-extension is hard-coded.
(defvar rep-default-substitutions-file-name-prefix "substitutions"
  "This is used to name newly created files of substitution commands.
By default, the name would typically be something like
\"substitutions-273-DJE.rep\".")

;; Note, at present, the *.bak file-extension is hard-coded.
(defvar rep-standard-backup-location nil
  "The location to place back-up copies of modified files.
Note: include a trailing slash.
If this is nil, then a sub-directory named \".rep\" will
be created in parallel with the file to be modified.")

(defvar rep-previous-versions-stack ()
  "Buffer local stack of previous backup versions.
Each run of a set of substitutions on a file will generate
another backup file.  Reverts can trace this stack upwards to get
back to any version.")
(make-variable-buffer-local 'rep-previous-versions-stack)
(put 'rep-previous-versions-stack 'risky-local-variable t)

(defvar rep-change-metadata ()
  "Buffer local stash of the change metadata returned from rep.pl.
This has been unserialized into an array of arrays of alists.
The fields in each alist:
  pass    the substitution number that made the change (integer)
  beg     beginning of the changed region (integer)
  end     end of the changed region (integer)
  delta   change in length of the modified text
  orig    the original string which was matched
  rep     the replaced string
  pre     some context characters from immediately before
  post    some context characters from immediately after
")
(make-variable-buffer-local 'rep-change-metadata)
(put 'rep-change-metadata 'risky-local-variable t)

(defvar rep-property 'rep-metadata-offset
  "A property that we guarantee will be present in any rep.el overlay.")
;; (setq rep-property 'rep-metadata-offset)

;; =======
;; documentation variables (used just for places to attach docstrings)

(defvar rep-tag t
  "The overlay property rep-tag is used to mark rep overlays so that
the \\[remove-overlays] function can find them easily.  This
proerties value is always set to t: according to the
documentation, remove-overlays can't identify overlays solely by
property, it needs to know the value of the property also.

This var is just a place to attach a docstring for this property.
")

(defvar rep-metadata-pass nil
  "The overlay property rep-metadata-pass contains the index for the outer
array of the array-of-arrays-of-alists `rep-change-metadata'.

This var is just a place to attach a docstring for this property.
")

(defvar rep-metadata-offset nil
  "The overlay property rep-metadata-pass contains the index for the inner
array of the array-of-arrays-of-alists `rep-change-metadata'.

This var is just a place to attach a docstring for this property.
")

;;--------
;; colorized faces used to mark-up changes
(defmacro rep-make-face (name number color1 color2)
  "Generate a colorized face suitable to markup changes.
NAME is the name of the face, COLOR1 is for light backgrounds
and COLOR2 is for dark backgrounds.
NUMBER is the corresponding rep substitution number (used only
in the doc string for the face."
  `(defface ,name
  '((((class color)
      (background light))
     (:foreground ,color1))
    (((class color)
      (background dark))
     (:foreground ,color2)))
  ,(format "Face used for changes from substitution number: %s." number)
  :group 'desktop-recover-faces
  ))

(rep-make-face rep-00-face 00 "DarkGoldenrod4" "DarkGoldenrod2")
(rep-make-face rep-01-face 01 "MediumPurple4" "MediumPurple1")
(rep-make-face rep-02-face 02 "forest green" "light green")
(rep-make-face rep-03-face 03 "PaleVioletRed4" "PaleVioletRed1")
(rep-make-face rep-04-face 04 "gold4" "gold1")
(rep-make-face rep-05-face 05 "salmon4" "salmon1")
(rep-make-face rep-06-face 06 "RoyalBlue1" "RoyalBlue1")
(rep-make-face rep-07-face 07 "DarkOrchid4" "DarkOrchid1")
(rep-make-face rep-08-face 08 "green4" "green1")
(rep-make-face rep-09-face 09 "khaki1" "khaki4")
(rep-make-face rep-10-face 10 "DarkOrange4" "DarkOrange1")
(rep-make-face rep-11-face 11 "SeaGreen4" "SeaGreen1")
(rep-make-face rep-12-face 12 "maroon4" "maroon1")
(rep-make-face rep-13-face 13 "firebrick4" "firebrick1")
(rep-make-face rep-14-face 14 "PeachPuff4" "PeachPuff1")
(rep-make-face rep-15-face 15 "CadetBlue4" "CadetBlue1")
(rep-make-face rep-16-face 16 "aquamarine4" "aquamarine1")
(rep-make-face rep-17-face 17 "OliveDrab4" "OliveDrab1")
(rep-make-face rep-18-face 18 "SpringGreen4" "SpringGreen1")
(rep-make-face rep-19-face 19 "chocolate4" "chocolate1")
(rep-make-face rep-20-face 20 "DarkSeaGreen4" "DarkSeaGreen1")
(rep-make-face rep-21-face 21 "LightSalmon4" "LightSalmon1")
(rep-make-face rep-22-face 22 "DeepSkyBlue4" "DeepSkyBlue1")
(rep-make-face rep-23-face 23 "chartreuse4" "chartreuse1")
(rep-make-face rep-24-face 24 "cyan4" "cyan1")
(rep-make-face rep-25-face 25 "magenta4" "magenta1")
(rep-make-face rep-26-face 26 "blue4" "blue1")
(rep-make-face rep-27-face 27 "DeepPink4" "DeepPink1")
(rep-make-face rep-28-face 28 "DarkOliveGreen4" "DarkOliveGreen1")
(rep-make-face rep-29-face 29 "coral4" "coral1")
(rep-make-face rep-30-face 30 "PaleGreen4" "PaleGreen1")
(rep-make-face rep-31-face 31 "tan4" "tan1")
(rep-make-face rep-32-face 32 "orange4" "orange1")
(rep-make-face rep-33-face 33 "cornsilk4" "cornsilk1")

(defvar rep-face-alist ()
 "Faces keyed by number (an integer to font association).
Used by function \\[rep-lookup-markup-face].")

;; hardcoded look-up table (stupid, but simple)
(setq rep-face-alist
      '(
        (00 . rep-00-face)
        (01 . rep-01-face)
        (02 . rep-02-face)
        (03 . rep-03-face)
        (04 . rep-04-face)
        (05 . rep-05-face)
        (06 . rep-06-face)
        (07 . rep-07-face)
        (08 . rep-08-face)
        (09 . rep-09-face)
        (10 . rep-10-face)
        (11 . rep-11-face)
        (12 . rep-12-face)
        (13 . rep-13-face)
        (14 . rep-14-face)
        (15 . rep-15-face)
        (16 . rep-16-face)
        (17 . rep-17-face)
        (18 . rep-18-face)
        (19 . rep-19-face)
        (20 . rep-20-face)
        (21 . rep-21-face)
        (22 . rep-22-face)
        (23 . rep-23-face)
        (24 . rep-24-face)
        (25 . rep-25-face)
        (26 . rep-26-face)
        (27 . rep-27-face)
        (28 . rep-28-face)
        (29 . rep-29-face)
        (30 . rep-30-face)
        (31 . rep-31-face)
        (32 . rep-32-face)
        (33 . rep-33-face)
        ))

;;--------
;; choosing faces

;; Used by rep-markup-substitution-lines
;;       & rep-modify-target-buffer
(defun rep-lookup-markup-face (pass)
  "Given an integer PASS, returns an appropriate face from \\[rep-face-alist].
These faces are named rep-NN-face where NN is a two-digit integer.
In the event that PASS exceeds the number of such defined faces, this
routine will wrap around and begin reusing the low-numbered faces.
If PASS is nil, this will return nil.
Underlining may be turned on with `rep-underline-changes-color'."
  (if rep-trace (rep-message (format "%s" "rep-lookup-markup-face")))
  (cond (pass
         (let ( markup-face limit index )
           (setq limit (length rep-face-alist) )
           (setq index (mod pass limit))
           (setq markup-face (cdr (assoc index rep-face-alist)))
           (message (pp-to-string markup-face))
           (cond (rep-underline-changes-color
                  (set-face-underline-p markup-face rep-underline-changes-color)
                  ))
           markup-face))
        (t
         nil)))


;;--------
;;  set-up routines

(defun rep-standard-setup (&optional dont-touch-tab)
  "Perform the standard set-up operations.
Calling this is intended to be a single step to get useful
keybindings and so on.
If you agree with our ideas about set-up, you can just run this,
if you'd rather do it yourself, then skip this, and the rep.el
package will use more unobtrusive defaults.
Note: the \"standard\" behavior is what is better documented.
If the optional DONT-TOUCH-TAB flag is set to t, tab and backtab
bindings should be left alone."
  (if rep-trace (rep-message (format "%s" "rep-standard-setup")))
  (cond ((rep-probe-for-rep-pl)
         (message "rep.pl must be in PATH for rep.el to work.")
         ))
  (rep-check-versions)

  (unless dont-touch-tab
    (rep-define-rep-modified-rebind-tab))

  (add-to-list
   'auto-mode-alist
   '("\\.\\(rep\\)\\'" . rep-substitutions-mode))

  (define-key rep-substitutions-mode-map "\C-x#"
    'rep-substitutions-apply-to-other-window)

  ;; bind global "entry point" command to "C-c.S"
  (let* ((prefix rep-key-prefix)
         )
    (global-set-key (format "%sS" prefix) 'rep-open-substitutions)
    (if rep-debug
        (message "Defined bindings for key: S under the prefix %s" prefix)))
  )

(defun rep-probe-for-rep-pl ()
  "Probe the system for the \"rep.pl\" external program.
Returns t if found, nil otherwise.  As a side-effect, generates a
warning message if it isn't found."
  (if rep-trace (rep-message (format "%s" "rep-probe-for-rep-pl")))
  (let* (
         (rep-pl "rep.pl")
         (cmd    (format "%s --version" (shell-quote-argument rep-pl)))
         (result (shell-command-to-string cmd))
         (expected-pat
          (format "^Running[ ]+%s[ ]+version:" rep-pl))
         )
    (cond ((not (string-match expected-pat result))
           (message "The program %s does not seem to be in your PATH." rep-pl)
           nil)
          (t
           t)
         )
    ))

(defun rep-check-versions ()
  "Make sure the versions of all three parts of the system match."
  (if rep-trace (rep-message (format "%s" "rep-check-versions")))
  (let* (
         (rep-pl "rep.pl")
         (version rep-version)
         (cmd
          (format "%s --check_versions='%s'"
                  (shell-quote-argument rep-pl) version))
         (result (shell-command-to-string cmd))
         (warning-pat
          (format "^Warning:"))
         )
    (cond ((string-match warning-pat result)
           (message "%s" result)
           nil)
          (t
           t)
          )
    ))

(defun rep-probe-for-rep-pl ()
  "Probe the system for the \"rep.pl\" external program.
Returns t if found, nil otherwise.  As a side-effect, generates a
warning message if it isn't found."
  (if rep-trace (rep-message (format "%s" "rep-probe-for-rep-pl")))
  (let* (
         (rep-pl "rep.pl")
         (cmd    (format "%s --version" (shell-quote-argument rep-pl)))
         (result (shell-command-to-string cmd))
         (expected-pat
          (format "^Running[ ]+%s[ ]+version:" rep-pl))
         )
    (cond ((not (string-match expected-pat result))
           (message "The program %s does not seem to be in your PATH." rep-pl)
           nil)
          (t
           t)
         )
    ))


;;========
;; controlling  modes

;; This system's "controllers" come in three stages:
;;  (1) a global key binding to create and edit a new substitutions file-buffer.
;;  (2) a rep-substitutions-mode, with a binding to apply to other window.
;;  (3) a rep-modified-mode: a minor-mode automatically enabled in that
;;      other window once it's been modified.  This has keybindings to
;;      examine, undo, revert or accept the changes.

(defun rep-open-substitutions ()
  "Open a new substitutions file buffer.
This is the intended entry-point command.  It should have a
\"global\" keybinding which ideally would be available in all
\\(or mostly all\\) modes \\(though emacs doesn't make that easy\\).

This will typically open up a file something like this:

   .rep/substitutions-832-JDE.rep

Where the sub-directory '.rep' is located in the same place
as the file it was assuming you were about to modify.
The numeric value in the name is the process id, and
the unique 3 letter suffix is randomly chosen.

If you have the `rep-default-substitutions-directory' variable
set to some location, then the *.rep files will all be located
there.

The standard prefix \\(default: \"substitutions\"\\) comes from
this variable: `rep-default-substitutions-file-name-prefix'."
  (if rep-trace (rep-message (format "%s" "rep-open-substitutions")))
  (interactive)
  (let* ((file-location (file-name-directory (buffer-file-name)))
         (dir (or
               rep-default-substitutions-directory
               (rep-sub-directory file-location)))
         (name rep-default-substitutions-file-name-prefix )
         (ext  "rep" )
         (pid (number-to-string (emacs-pid)))
         (suffix (rep-generate-random-suffix))
         (full-file-name (concat dir "/" name "-" pid "-" suffix "." ext))
         )
     (while (file-exists-p full-file-name)
       (setq suffix (rep-generate-random-suffix))
       (setq full-file-name (concat dir "/" name "-" pid "-" suffix "." ext)))
    (rep-open-substitutions-file-buffer-internal full-file-name )
    ))

(defun rep-open-substitutions-prompt (name)
  "Open a new substitutions file buffer, prompting for the NAME.
This is an alternate entry-point command, much like
\\[rep-open-substitutions]."
  (if rep-trace (rep-message (format "%s" "rep-open-substitutions-prompt")))
  (interactive "FName of substitutions file:")
  (rep-open-substitutions-file-buffer-internal name )
  )

(defun rep-open-substitutions-file-buffer-internal ( file )
  "Open a new substitutions file buffer, given the full FILE name.
This goes through some gyrations to get enough space to create the new
window without being too obnoxious about it.
This just handles the window management and template insertion.
Choosing the file name and location is a job for routines such as
\\[rep-open-substitutions]."
  (if rep-trace (rep-message (format "%s" "rep-open-substitutions-file-buffer-internal")))
  (interactive)
  (let* (
         (apply-desc  ;; C-x#
          (mapconcat 'key-description
                     (where-is-internal
                      'rep-substitutions-apply-to-other-window
                      rep-substitutions-mode-map
                      ) ", "))
         (next-desc ;; TAB, n
          (mapconcat 'key-description
                     (where-is-internal
                      'rep-modified-skip-to-next-change rep-modified-mode-map
                      ) ", "))
         (undo-desc ;; u
          (mapconcat 'key-description
                     (where-is-internal
                      'rep-modified-undo-change-here rep-modified-mode-map
                      ) ", "))
         (accept-desc ;; A
          (mapconcat 'key-description
                     (where-is-internal
                      'rep-modified-accept-changes rep-modified-mode-map
                      ) ", "))
         (revert-desc ;; R
          (mapconcat 'key-description
                     (where-is-internal
                      'rep-modified-revert-all-changes rep-modified-mode-map
                      ) ", "))
         (prefix-desc (key-description rep-key-prefix))

         (hint
           (concat
           "# Enter s///g; lines, "
           "/e not allowed /g assumed. "
           apply-desc
           " runs on other window"))
         (length-header (length hint))
         (substitution-template "s///g;" )
         start-here
         (hint2
           (concat
           "# In the modififed buffer, the prefix is "
           prefix-desc
           "\n"
           "# Next change: "
           next-desc
           "  Undo: "
           undo-desc
           "  Accept all: "
           accept-desc
           "  Revert all: "
           revert-desc
           ))
         (f-height (frame-height) )
         (w-height (window-body-height) )
         (number-lines 10 )
         (need-window-lines (round (* 1.5 number-lines)) )
         (expansion-limit (- f-height w-height))
         (current-deficit (- need-window-lines w-height ))
         )
    (cond ((> w-height need-window-lines)
           (split-window-vertically number-lines)
          )
          ((<= current-deficit expansion-limit)
           (enlarge-window current-deficit)
           (split-window-vertically number-lines)
           )
          (t
           ;; fall back: enlarge a few lines, cut new window size in half,
           (enlarge-window 2)
           (split-window-vertically (round (/ number-lines 2)))
           )
          )
    (find-file file)
    (rep-substitutions-mode)
    (insert hint)
    (put-text-property 1 length-header 'read-only t)
    (insert "\n") ;; check portability?

    (setq start-here (point))

    (open-line 6)
    (goto-char (point-max))
    (insert hint2)

    (goto-char start-here)
    (insert substitution-template)
    (move-beginning-of-line 1)
    (forward-char 2)
    ))


(define-derived-mode rep-substitutions-mode
  cperl-mode "rep-substitutions"
  "Major mode to enter stack of substitutions to be applied.
Derived from cperl-mode, because we're editing substitutions
that use perl's syntax \(and are interpreted using perl\).
\\{rep-substitutions-mode-map}"
  (use-local-map rep-substitutions-mode-map))

(defvar rep-key-prefix (kbd "C-c .")
  "Prefix key to use for the rep-modified-mode minor mode.")

;;(setq rep-modified-mode-map
(defvar rep-modified-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "w"
      'rep-modified-what-was-changed-here-verbose)
    (define-key map "X" 'describe-text-properties)
    (define-key map "u" 'rep-modified-undo-change-here)
    (define-key map "R" 'rep-modified-revert-all-changes)
    (define-key map "A" 'rep-modified-accept-changes)
    (define-key map "n" 'rep-modified-skip-to-next-change)
    (define-key map "p" 'rep-modified-skip-to-prev-change)
    map))
;;     (define-key map "@" 'rep-modified-accept-changes)

(defvar rep-modified-minor-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map rep-key-prefix rep-modified-mode-map)
    map)
  "Keymap used for binding rep-modified minor mode.")

(define-minor-mode rep-modified-mode
  "Toggle Rep Modified mode.
     With no argument, this command toggles the mode.
     Non-null prefix argument turns on the mode.
     Null prefix argument turns off the mode.

     When Rep Modified mode is enabled, key bindings are defined
     to examine and undo the changes made by rep substitutions.
     These are commands such as \\[rep-modified-undo-change-here], and
      \\[rep-modified-revert-all-changes].
      See: \\{rep-modified-mode-map}."
  ;; The initial value.
  :init-value nil
  ;; The indicator for the mode line.
  :lighter " Rep"
  :keymap     rep-modified-minor-mode-map
  )

(defun rep-define-rep-modified-rebind-tab ()
  "Re-binds the tab (and backtab) key in rep-modified-mode."
  (define-key rep-modified-minor-mode-map [tab]
    'rep-modified-skip-to-next-change)
  (define-key rep-modified-minor-mode-map [backtab]
    'rep-modified-skip-to-prev-change)
  )

;;--------
;; rep-substitutions-mode function(s)

;; C-x#, code-name: "apply"
(defun rep-substitutions-apply-to-other-window ()
  "Two buffers must be open, the list of substitution command
and the file they will modify, with the substitutions window
selected.  Each substitution command and the changes it produces
in the other window will be highlighted in corresponding colors.
Turns off font-lock to avoid conflict with existing syntax coloring."
  (interactive)
  (if rep-trace (rep-message (format "%s" "rep-substitutions-apply-to-other-window")))
  (let ( raw-change-metadata
         change-metadata changes-list-file   changes-list-buffer
         target-file     target-file-buffer  backup-file
         )
    (setq changes-list-file    (buffer-file-name))
    (setq changes-list-buffer  (current-buffer))
    (save-buffer)

    (other-window 1) ;; now we're in the buffer to modify, the target buffer
    (setq target-file          (buffer-file-name))
    (setq target-file-buffer   (current-buffer))
    (setq backup-file          (rep-generate-backup-file-name target-file))
    (save-buffer)

    (setq raw-change-metadata
          (rep-run-perl-substitutions
           changes-list-file target-file backup-file t))

    ;; hack: if there's an odd error message about "find",
    ;; just strip it out and keep going
    (cond ((string-match "^find:" raw-change-metadata)
           (let* ((new-value-1
                   (replace-regexp-in-string
                    "^find:[^\n]*"
                    ""
                    raw-change-metadata))
                  (new-value-2
                   (replace-regexp-in-string
                    "^Usage:[^\n]*"
                    ""
                    new-value-1))
                  )
             (setq raw-change-metadata new-value-2)
             (message "modified: %s" raw-change-metadata)
           )))

    (cond ((not (> (length raw-change-metadata) 1))
           (message "No changes made by substitutions."))
          ((string-match "^Problem" raw-change-metadata) ;; error message
           (message "%s" raw-change-metadata))
          (t ;; so let's do it
           (setq change-metadata
                 (rep-unserialize-change-metadata raw-change-metadata))

           (rep-modify-target-buffer
             change-metadata target-file-buffer backup-file)

           (rep-markup-substitution-lines changes-list-buffer)

           (set-buffer target-file-buffer)
           ;; jump to the first unshadowed change in the modified buffer
           (let* (
                  (goto t)
                  (o-ster
                   (rep-next-top-overlay (point-min) rep-property goto))
                  )
             (cond ((overlayp o-ster)
                    (rep-modified-what-was-changed-here))
                   (t
                    (message "No marked-up changes found in buffer."))
                   ))))
    (if rep-debug
        (rep-metadata-report))
    ))

;; Used by rep-substitutions-apply-to-other-window
(defun rep-run-perl-substitutions ( changes-list-file target-file backup-file
                                       &optional no-changes )
  "Applies substitutions in a CHANGES-LIST-FILE to a TARGET-FILE.
The CHANGES-LIST-FILE should contain substitutions in the traditional
unix 's///' style \(perl5 flavor\), one on each line.  The changes
are made throughout the TARGET-FILE as though the /g modifier was
used on all of them.  The original file is saved as the given BACKUP-FILE.
If NO-CHANGES is t, then the TARGET-FILE will not actually be modified."
  (if rep-trace (rep-message (format "%s" "rep-run-perl-substitutions")))
  (let* (
         (rep-pl "rep.pl")
         perl-rep-cmd
         data
         cmd-format
         )
    (setq cmd-format
          (cond (no-changes
                 "%s --backup %s --substitutions %s --target %s --trialrun"
                 )
                (t
                 "%s --backup %s --substitutions %s --target %s "
                 )
                ))
    (setq perl-rep-cmd
               (format cmd-format
                rep-pl
                (shell-quote-argument
                  backup-file)
                (shell-quote-argument
                  changes-list-file)
                (shell-quote-argument
                  target-file)))

    (if rep-debug
        (rep-message (format "%s" perl-rep-cmd)))

    (setq data (shell-command-to-string perl-rep-cmd))
    (if rep-debug
        (message "%s" data))
    data))

;; Used by rep-substitutions-apply-to-other-window
;;   code name "modify"
(defun rep-modify-target-buffer (metadata target-buffer backup-file)
  "Applies the given change METADATA to the TARGET-BUFFER.
Highlights the changes using different color faces.

For each modification, the buffer-local vars
rep-previous-versions-stack and rep-change-metadata are set by
this function, and the the overlay properties rep-metadata-pass
and rep-metadata-offset are set (indirectly, via the function
rep-create-overlay).

Presumes the target-buffer contains the original, unmodified
text at the outset.

Requires the METADATA to be in an array-of-arrays-of-alists form.
The inner alist describes each change, each change is in an array
of changes produced by a pass of a s/// command, and the outer array
is the collection of effects of the full stack of s/// commands."
  (if rep-trace (rep-message (format "%s" "rep-modify-target-buffer")))
  (set-buffer target-buffer)
  ;; if font-lock-mode was on in target, save that information
  (setq rep-font-lock-buffer-status font-lock-mode)
  (font-lock-mode -1)

  (rep-modified-mode t)

  (push backup-file rep-previous-versions-stack)  ;; buffer-local variable
  (setq rep-change-metadata metadata)             ;; buffer-local variable
  (let* ((layer_count (length rep-change-metadata))
         (pass 0)
         record
         )
    ;; step forward through layers of s/// passes...
    (while (<= pass (1- layer_count)) ;; loop closes with pass++
      ;; within each pass, step backward through the change records
      (let* ((layer (aref rep-change-metadata pass) )
             (i (1- (length layer))))
        (while (>= i 0)     ;; loop closes with i--
          (if ;; skip any empty records (if any)
              (setq record (aref layer i))
              (let* (
                     (delta  (rep-get 'record 'delta))
                     (orig   (rep-get 'record 'orig))     ;; aka find-string
                     (rep    (rep-get 'record 'rep))      ;; aka replace-string
                     (beg    (rep-get 'record 'beg))
                     (end2   (+ beg (length rep)))        ;; after change

                     (end1   (- end2 delta))              ;; before change

                     (shadowed_changes (rep-get-local-state beg end1))
                     string1 string1-np overlay
                     )
                ;; check the substring at beg & end1: make sure it matches orig
                (setq string1-np (buffer-substring-no-properties beg end1))
                (cond ((not (string= string1-np orig))
                       (rep-message
                        (format
                         "Warning: at %d, \"%s\" is not \"%s\"" beg string1 orig)))
                      )

                ;; preserve the shadowed_changes list in the metadata record
                (rep-set 'record 'shadowed_changes shadowed_changes)

                ;; delete the old substring, insert rep
                (setq string1 (buffer-substring beg end1))
                (delete-region beg end1)
                (goto-char beg)
                (insert rep)

                ;; put metadata in overlay properties:
                ;;   i => rep-metadata-record, pass => rep-metadata-pass
                (setq overlay (rep-create-overlay beg end2 pass i ))

                ;; save the record of metadata in the global stash
                (aset layer i record)
                (aset rep-change-metadata pass layer)

                ))   ;; end if/setq/let*
          (setq i (1- i)) ;; i--
          ) ;; end while i (inner)
        ) ;; end let
      (setq pass (1+ pass)) ;; pass++
      ) ;; end while
    )  ;; end let
  ) ;; end defun


(defun rep-get-local-state (beg end)
  "Get the state of overlays in and around region between BEG and END.
Finds overlays in the vicinity of the given region, and records
important aspects that need to be restored in the event that a change
is undone, notably the beginning and end points of each overlay,
expressed in relative terms, using BEG as the point of origin.
Returns a list of alists, with fields keyed by symbols beg, end and
overlay."
  (let* (
         (search-prop  rep-property)
         (outreach 1)
         (raw-overlays (overlays-in
                         (rep-safe-sum beg (- outreach))
                         (rep-safe-sum end (+ outreach)))
                       )
         (rep-overlays (rep-filter-overlays-by-property raw-overlays search-prop))
          state
          )
    (dolist (overlay rep-overlays)
      (let* ( (p1 (overlay-start overlay))
              (p2 (overlay-end   overlay))
              (relative-p1 (- p1 beg))
              (relative-p2 (- p2 beg))
              (record-alist () )
              )
        (rep-set 'record-alist 'overlay overlay)
        (rep-set 'record-alist 'beg relative-p1) ;;TODO beg/end confusing names?
        (rep-set 'record-alist 'end relative-p2)
        (push record-alist state)
        ))
    state
    ))

;; Used by:  rep-modify-target-buffer
;; Note: this is the only place that uses make-overlay
;; TODO we could skip passing "previous-string" since it can
;; be looked up from rep-change-metadata using pass and offset (orig).
(defun rep-create-overlay (beg end pass offset )
                                                  ;; previous-string )
  "Create an overlay with properties reflecting a change.
BEG and END are the start and end points of the overlay,
PREV-STRING is the previous version of the text. PASS becomes
the overlay \"priority\", and is used to choose a \"face\", and
is also set to \"rep-metadata-pass\".  OFFSET will be saved as
\"rep-metadata-offset\".  Returns the new overlay object."
  (let* (
         (markup-face (rep-lookup-markup-face pass))
         (overlay (make-overlay beg end (current-buffer) nil t))
         )
    (overlay-put overlay 'priority pass)
    (overlay-put overlay 'face markup-face)
    (overlay-put overlay 'rep-metadata-offset offset)
    (overlay-put overlay 'rep-metadata-pass pass)

    (overlay-put overlay 'rep-tag t) ;; used by rep-clear-overlays
    overlay))

;; Used by rep-modified-accept-changes
(defun rep-clear-overlays (&optional buffer)
  "Clears the rep.el properties for the entire BUFFER.
Defaults to current buffer."
  (if rep-trace (rep-message (format "%s" "rep-clear-overlays")))
  (setq buffer-read-only nil)
  (unless buffer
    (setq buffer (current-buffer)))
  (set-buffer buffer)
  (remove-overlays (point-min) (point-max) 'rep-tag 't))

;; used by: rep-substitutions-apply-to-other-window
(defun rep-unserialize-change-metadata (data)
  "Converts the raw DATA from rep.pl to a lisp data structure.
That \"raw\" DATA is an aref of hrefs, and it is passed in JSON
form, so simply using the json package to decode it gets an
elisp array of alists."
  (if rep-trace (rep-message (format "%s" "rep-unserialize-change-metadata")))
  (let* (change-metadata)
    (cond (data
           (setq change-metadata (json-read-from-string data))
           )
          (t
           (message "No change data returned from rep.pl.")
           ))
    change-metadata))


;; Used by rep-substitutions-apply-to-other-window
(defun rep-markup-substitution-lines (buffer)
  "Mark-up the substitution lines in the given BUFFER.
Uses the line number with rep-lookup-markup-face to
Assign a color to each substitution command in the buffer,
\(by counting from the top and feeding the position number
to \\[rep-lookup-markup-face]\).
Presumes all substitution commands begin with \"s\".
Acts on the given BUFFER, but leaves the current window active."
  (if rep-trace (rep-message (format "%s" "rep-markup-substitution-lines")))
  (save-excursion ;; but that trick *never* works... so don't trust it
    (let* ( (original-buffer (current-buffer))
            (comment_pat  "^\s*?#")
            (scmd_beg_pat "^\s*?s")
;;            (scmd_end_pat ";\s*?\(#\|$\)")  ;; n.g.
            (scmd_end_pat ";\s*?$")  ;; eh.
            (scmd_count 0)
            markup-face
            )
      (set-buffer buffer)
      (font-lock-mode -1) ;; turns off font-lock unconditionally
      (goto-char (point-min))

      (while (re-search-forward scmd_beg_pat nil t)
        (setq markup-face (rep-lookup-markup-face scmd_count))

        (let ( beg end )
          (setq beg (match-beginning 0))
          (cond ((re-search-forward scmd_end_pat nil t)
                 (setq end (match-end 0))
                 (put-text-property beg end 'face markup-face)
                 (setq scmd_count (1+ scmd_count))
                 (goto-char (- end 1))
                 )
                (t ;; found beginning but not ending...
                 (message "Incomplete substitution command.")
                 )
                )
          ))
      (set-buffer original-buffer)
      )
    ))

;; Used by: rep-modified-accept-changes, rep-modified-revert-all-changes
(defun rep-substitutions-mode-p ()
  "Check if the current buffer has the rep-substitutions-mode on."
  (if rep-trace (rep-message (format "%s" "rep-substitutions-mode-p")))
  (let* ((this-mode major-mode)
         (mode-name "rep-substitutions-mode")
         )
    (string= this-mode mode-name)
    ))


;;--------
;; rep-modified-mode functions (all interactive, bound to keys usually)

;; C-c.R
(defun rep-modified-revert-all-changes ()
  "Revert last substitutions, restoring the previous backup file.
Uses the `rep-previous-versions-stack' buffer local variable."
  (interactive)
  (if rep-trace (rep-message (format "%s" "rep-modified-revert-all-changes")))
  (let* ( (current-buffer-file-name (buffer-file-name))
          (previous-file (pop rep-previous-versions-stack))
          (preserve-stack rep-previous-versions-stack)
               )
    (cond ((not previous-file)
           (message "No previous version found on stack."))
          ((not (file-exists-p previous-file))
            (message "rep.el backup file not found: %s" previous-file))
          (t
           (copy-file previous-file current-buffer-file-name t)
           (revert-buffer t t)))

    (rep-clear-overlays)
    ;; covering flakiness in revert-buffer & text properties.
    (font-lock-fontify-buffer)

    ;; in case you want to revert another step up the stack
    (rep-modified-mode t)
    (setq rep-previous-versions-stack preserve-stack)
    ;; also restore cperl syntax colors in substitutions window
    (save-excursion
      (other-window -1)
      (cond ((rep-substitutions-mode-p)
             (font-lock-mode -1)
             (font-lock-fontify-buffer)
             (other-window 1)))
      )
    ))

;; C-c.A
(defun rep-modified-accept-changes ()
  "Accept changes made in buffer, return to normal state.
Restores the standard syntax coloring, etc."
  (interactive)
  (if rep-trace (rep-message (format "%s" "rep-modified-accept-changes")))
  (let ((file  (buffer-file-name))
        )
    (setq buffer-read-only nil)
    (rep-modified-mode -1)

    ;; turn font-lock back on if it was on
    (cond (rep-font-lock-buffer-status
        (font-lock-mode 1)
        (font-lock-fontify-buffer)
        ))

    (rep-clear-overlays)
    (save-buffer)
    ;; also restore cperl syntax colors in substitutions window
    (save-excursion
      (other-window -1)
      (cond ((rep-substitutions-mode-p)
             (font-lock-mode 1)
             (font-lock-fontify-buffer)
             (other-window 1))))
    (message "rep.el: Changes accepted to %s." file)
    ))

;; bound to TAB, code name "next"
(defun rep-modified-skip-to-next-change ()
  "Skips to next beginning of changed region.
As written, sends message indicating beginning and end
of overlay, and the value associated with the property.
If none are found, emits a generic 'thats all'."
;; Could there be multiple overlapping overlays in the same place?  Work ok?
  (interactive)
  (if rep-trace (rep-message (format "%s" "rep-modified-skip-to-next-change")))
  (let* (
         (goto-flag t)
         (big-o
          (rep-next-top-overlay (point) rep-property goto-flag))
         beg end val
         )
         (cond ((overlayp big-o)
                (rep-modified-what-was-changed-here)
                )
               (t
                (message "No futher changed regions.")
                ))
         ))

;; bound to BACKTAB by default
(defun rep-modified-skip-to-prev-change ()
  "Move back to the previous changed region, stopping at the beginning point.
Uses `rep-metadata-record' property."
  (interactive)
  (if rep-trace (rep-message (format "%s" "rep-modified-skip-to-prev-change")))
  (let* (
         (goto-flag t)
         (reverse t)
         (big-o
          (rep-prev-top-overlay (point) rep-property goto-flag))
         )
    (cond ((overlayp big-o)
           (rep-modified-what-was-changed-here)
           )
          (t
           (message "No futher changed regions.")
           ))
    ))

;; C-c.w
(defun rep-modified-what-was-changed-here ()
  "Tells you the original string was before it was replaced."
  ;; looks up the orig string in metadata
  (if rep-trace (rep-message (format "%s" "rep-modified-what-was-changed-here")))
  (let* (
          (ova (rep-top-overlay-here (point) rep-property))
          beg end pass offset record-number orig
         )
    (cond (ova
           (setq beg (overlay-start ova))
           (setq end (overlay-end   ova))

           (setq pass
                 (overlay-get ova 'rep-metadata-pass))
           (setq offset
                 (overlay-get ova 'rep-metadata-offset))

           (cond ((eq rep-change-metadata nil)
                  (message "Warning: in %s rep-change-metadata is nil."
                           "rep-modified-what-was-changed-here")
                  )
                 ((and pass offset)
                  (setq orig (rep-metadata-get 'orig pass offset))
                  (message "Was: %s" orig)
                  ) ;; any t condition?  warn: "something weird"
                 )))))

;; C-c.w  code name: "what"
;; Not used by any other functions: see rep-modified-what-was-changed-here
(defun rep-modified-what-was-changed-here-verbose ()
  "Tells you the original string was before it was replaced.
Looks at the changed string under the cursor, or if we're not
inside a change, tries to advance the cursor to the next change.
This also supplies additional information like the number of the
substitution pass that made the change."
;; Note it might've be more consistent to just message that there's nothing there.
;; but it's more convienient to skip ahead, and this is a top-level
;; interactive routine not used by other code.
  (interactive)
  (if rep-trace (rep-message
                 (format "%s" "rep-modified-what-was-changed-here-verbose")))
  (let* (
          (here (point))
          (ova (rep-top-overlay-here here rep-property))
          (goto-flag t)
          last-change beg end
          pass offset
          )

     (cond ( (not ova) ;; we are not yet inside a changed region
             ;; This jumps to the next change, rather than look just "here"
             (setq ova (rep-next-overlay here rep-property 0 goto-flag))
             ))
    (cond ((overlayp ova)
           ;; pass is used to lookup record *and* in messaging (so stet!)
           (setq pass
                 (overlay-get ova 'rep-metadata-pass))
           (setq offset
                 (overlay-get ova 'rep-metadata-offset))
           (cond ((and pass offset)
                  (let* (
                         (layer   (aref rep-change-metadata pass))
                         (record  (aref layer offset))
                         (orig    (rep-get 'record 'orig))
                         ;; Note: hold open door to more info from record for messaging
                         )
                    (message
                     "This was: %s (changed by substitution number: %d)."
                     orig
                     (1+ pass)
                     )
                    ))
                 ))
          (t
           (message "There are no further substitution changes in this buffer.")
           ))
    ))


;; Bound to "u" key, code name "undo"
(defun rep-modified-undo-change-here ()
  "Undos the individual rep substitution change under the cursor.
Undos the change at point, or if none is there, warns and does nothing.
Note that this has nothing to do with the usual emacs \"undo\"
system, which operates completely independently."
  (interactive)
  (if rep-trace (rep-message (format "%s" "rep-modified-undo-change-here")))
  (let* (
         (overlay (rep-top-overlay-here (point) rep-property))
         )
    (cond ((not (overlayp overlay))
           (message "No change to undo at point.")
           )
          (t
           (let* ((beg (overlay-start overlay))
                  (end (overlay-end overlay))

                  (existing (buffer-substring-no-properties beg end))

                  (record (rep-record-from-overlay-and-metadata overlay))

                  (orig             (rep-get 'record 'orig))  ;; for messaging only
                  (rep              (rep-get 'record 'rep))
                  (shadowed_changes (rep-get 'record 'shadowed_changes))
                  )

             (rep-message (format "undo %s to %s\n" rep orig))

             (cond
              ((not (string= existing rep))
                 (message
                  "Can't revert: \"%s\", looks like it was edited (expected \"%s\")."
                  existing rep)
               )
              ((setq shadow
                     (rep-overlay-shadowed-p overlay rep-property))
               (let* (
                      (s-record (rep-record-from-overlay-and-metadata shadow))
                      (s-rep (rep-get 's-record 'rep)) ;; for messaging only
                      )
                 (message
                  "Can't revert fragment: \"%s\". Must undo change of \"%s\" first."
                  existing s-rep)
                 ))
              (t
               (let* ((restore-string orig
                       ))
                 (delete-region beg end)
                 (goto-char beg)
                 (insert restore-string)
                 )
               ;; readjust overlays of shadowed changes now revealed after the undo
               (rep-restore-shadowed-changes-relative-to  beg shadowed_changes)

               ;; disconnect overlay from buffer, we're done with it
               (delete-overlay overlay)

               (goto-char beg)
               (message "Change reverted: \"%s\"" existing)

               ))))
          )))

;; Used by rep-modified-undo-change-here
(defun rep-restore-shadowed-changes-relative-to (origin shadowed_changes)
  "Resets extents relative to ORIGIN of all overlays in SHADOWED_CHANGES.
SHADOWED_CHANGES is a list of alists, where each alist is
keyed by the symbols: overlay, beg, end."
  (dolist (shadowed_change shadowed_changes)
    (let* (
           (shadowlay
            (rep-get 'shadowed_change 'overlay))
           (shadowlay-rel-beg
            (rep-get 'shadowed_change 'beg))
           (shadowlay-rel-end
            (rep-get 'shadowed_change 'end))
           (shadowlay-beg (+ shadowlay-rel-beg origin))
           (shadowlay-end (+ shadowlay-rel-end origin))
           )
      (move-overlay shadowlay shadowlay-beg shadowlay-end)
      ;; (overlay-put shadowlay 'priority (overlay-get shadowlay 'rep-metadata-pass)) ;; didn't help
      )))

;;========
;; rep utility functions

;;--------
;; filename/directory manipulations

;; Used by rep-open-substitutions & rep-generate-backup-file-name
(defun rep-sub-directory (file-location)
  "Given a directory, returns path to a '.rep' sub-directory.
If the sub-directory does not exist, this will create it. "
  (if rep-trace (rep-message (format "%s" "rep-sub-directory")))
  (let* ( (dir
           (substitute-in-file-name
            (convert-standard-filename
             (file-name-as-directory
              (expand-file-name file-location))))) ;; being defensive
          (standard-subdir-name ".rep")
          (subdir (concat dir  standard-subdir-name))
         )
    (unless (file-directory-p subdir)
      (make-directory subdir t))
    subdir))

;; Use by rep-open-substitutions  & rep-generate-backup-file-name
(defun rep-generate-random-suffix ()
  "Generate a three character suffix, pseudo-randomly."
  (if rep-trace (rep-message (format "%s" "rep-generate-random-suffix")))
  ;; As written, this is always 3 upper-case asci characters.
  (let (string)
    (random t)
    (setq string
          (concat
           (format "%c%c%c"
                   (+ (random 25) 65)
                   (+ (random 25) 65)
                   (+ (random 25) 65)
                   )
           ))
    ))

;; Used by rep-substitutions-apply-to-other-window
(defun rep-generate-backup-file-name (file)
  "Given a FILE name, generate a unique backup file name.
If `rep-standard-backup-location' is defined it will be used as
the standard location for backups, otherwise, a \".rep\"
subdirectory will be used in parallel with the FILE."
  (interactive)
  (if rep-trace (rep-message (format "%s" "rep-generate-backup-file-name")))
  (let* ((file-location (file-name-directory file))
         (name          (file-name-nondirectory file))
         (dir (or
               rep-standard-backup-location
               (rep-sub-directory file-location)))
         (ext "bak")
         (suffix (rep-generate-random-suffix))
         (pid (number-to-string (emacs-pid)))
         (full-file-name (concat dir "/" name "-" pid "-" suffix "." ext))
         )
    (while (file-exists-p full-file-name)
       (setq suffix (rep-generate-random-suffix))
       (setq full-file-name (concat dir "/" name "-" pid "-" suffix "." ext))
       )
    full-file-name))

;;--------
;; rep debug messages

;; currently unused
(defun rep-same-string-or-warn (label1 string1 label2 string2)
  "Compare STRING1 to STRING2 \(string=\) and warn if not the same.
Uses LABEL1 and LABEL2 in the warning message.
Example use:
   \(rep-same-string-or-warn \"label1\" string1 \"label2\" string2\)
"
  (cond
   ((not (string= string1 string2))
    (rep-message
     (concat
      "Warning, not same: "
      (format
       "%s: %s, %s: %s\n" label1 string1 label2 string2)
       ))
    )))

;; currently unused
(defun rep-same-number-or-warn (label1 number1 label2 number2)
  "Compare NUMBER1 to NUMBER2 \(=\) and warn if not the same.
Uses LABEL1 and LABEL2 in the warning message.
Example use:
   \(rep-same-number-or-warn \"label1\" number1 \"label2\" number2\)
"
  (cond
   ((not (= number1 number2))
    (rep-message
     (concat
      "Warning, not same: "
      (format
       "%s: %s, %s: %s\n" label1 number1 label2 number2)
       ))
    )))


;;--------
;; rep debug utilities

(defun rep-message (message)
  "Output given string MESSAGE to the *Rep* buffer.
Does nothing unless the `rep-debug' variable is set.
Unlike the built-in \\[message], this does not do an implicit format."
;; Example usage:
;;  (if rep-trace (rep-message (format "%s" "rep-generate-backup-file-name")))
;;
  (cond (rep-debug
         (let* ( (display-buffer (get-buffer-create "*Rep*"))
                 (start-buffer   (current-buffer))
                 )
           (set-buffer display-buffer)
           (goto-char (point-max))
           (insert message)
           (goto-char (point-max))
           (set-buffer start-buffer)
           ))))


;;--------
;; metadata manipulation utilities

;; Used by rep-modified-what-was-changed-here
(defun rep-metadata-get (field pass offset)
  "Gets value of FIELD for PASS and OFFSET from `rep-change-metadata'.
Example usage, get field \"orig\" for record in pass 3, with offset 4:
   (rep-metadata-get 'orig 3 4)
"
  (let* ((layer   (aref rep-change-metadata pass))
         (record  (aref layer offset))
         (value   (rep-get 'record field)))
    value))

(defun rep-record-from-overlay-and-metadata (overlay)
  "Returns a record of rep metadata, given a rep OVERLAY.
The rep OVERLAY should have `rep-metadata-pass' and
`rep-metadata-offset' properties. The returned record is an alist
as documented here: `rep-change-metadata'."
  (let* (
         (pass
          (overlay-get overlay 'rep-metadata-pass))
         (offset
          (overlay-get overlay 'rep-metadata-offset))
         ;; TODO consider a check, before trying to look up record:
         ;;           (cond ((and pass offset)
         (layer   (aref rep-change-metadata pass))
         (record  (aref layer offset))
         )
    record))






;;========
;; general utililities

;;--------
;; overlay utilities

   ;; TODO move overlay utilities to a general-purpose package:
   ;;   overlay-utils.el

;; TODO should I handle the case where the given
;; property does not exist in the overlay?
(defun rep-overlay-get (overlay property)
  "Gets the value of the PROPERTY from the OVERLAY.
Returns nil if either input is nil (will not error-out like
\\[overlay-get]."
  (cond  ((and overlay property)
          (overlay-get overlay property)
          )
         (t
          nil)
         ))

;; Used by *everything*
(defun rep-overlays-here (&optional spot)
  "Return a list of overlays at one point in the buffer.
If SPOT is not given, lists the overlays at point.  This is a
variant of \\[overlays-in] and \\[overlays-at], designed to
gather both zero-width overlays and the wider ones at a location
found by doing a \\[next-overlay-change]."
  (interactive) ;; debug
  (let (
        (spot (or spot (point)))
        (o-list
         (append
          (overlays-in spot spot)  ;; finds zero-width overlays
          (overlays-at spot)       ;; finds wider overlays
          ;; (overlays-in (1+ spot) (1+ spot)) ;; also finds wider overlays
          ))
        )
    o-list))

;; used by rep-get-local-state, rep-get-local-state, rep-next-overlay
;; and indirectly by everything: "apply", "undo", TAB, BACKTAB, "what", "modify"
(defun rep-filter-overlays-by-property (overlay-list property)
  "Given an OVERLAY-LIST selects only the ones matching PROPERTY.
Returns the filtered list. If overlay-list is nil, returns nil.
If property is nil, that means there's no filtering and it
returns the given overlay-list unchanged."
  (let ( overlay p hit-list ret)
    (setq ret
          (cond ((not property)
                 overlay-list
                 )
                (t
                (cond (overlay-list
                 (dolist (overlay overlay-list)
                   (setq p-list (overlay-properties overlay))
                   (dolist (p p-list)
                     (cond( (equal p property)
                            (push overlay hit-list)
                            ))
                     ))
                 hit-list)
                (t
                 nil)) ;; end cond overlay-list
                )) ;; end cond not propery
          );; end set ret
    ret))

;; Used by: rep-next-overlay
(defun rep-filter-overlays-priority (overlay-list priority)
  "Given an OVERLAY-LIST selects only the ones greater than PRIORITY.
Returns the filtered list. If either input is nil, returns nil."
  (let* ((cutoff priority)
         overlay p hit-list prior ret)
    (setq ret
          (cond ((and overlay-list property)
                 (dolist (overlay overlay-list)
                   (cond( (>= (overlay-get overlay 'priority) cutoff)
                          (push overlay hit-list)
                          )))
                 hit-list)
                (t
                 nil)))
    ret))



(defun rep-sort-overlays-on-priority (o-list)
  "Given a list of overlays, sort them on priority.
Returns a sorted list in descending order, with the maximum
at the top."
  ;; so if not given valid overlays, it doesn't error out (zat good?)
  (let ( new-o-list
         )
    (setq new-o-list
          (sort o-list
                '(lambda (a b)
                  (let ((pa (cond ((overlayp a)
                                   (overlay-get a 'priority))
                                  ))
                        (pb (cond ((overlayp a)
                                   (overlay-get b 'priority))
                                  ))
                        )
                    (> pa pb)  ;; descending order, max at the top
                    ))))
    new-o-list))

;; used by "next", "prev", and "rep-top-overlay-here" (used by "undo", "what")
(defun rep-max-priority-overlay (overlay-list)
  "Given an OVERLAY-LIST, returns an overlay with maximum priority.
If input is nil, returns nil."
  ;; The usual deal: sweep through the list, save the last one
  ;; replace it with the current one if it's priority is larger.
  (let* ( (candy-priority -27) ;; initialize to a lower number than is in use
          overlay priority candidate ret
          )
    (cond (overlay-list
           (dolist (overlay overlay-list)
             (setq priority (overlay-get overlay 'priority))
             (cond ((> priority candy-priority)
                    (setq candidate overlay)
                    (setq candy-priority priority)
                    ))
             )
           (setq ret candidate))
          (t
           (setq ret nil)))
    ret))

;; Directly used by:
;;          rep-next-top-overlay
;;          rep-overlay-shadowed-p
;;          rep-modified-what-was-changed-here-verbose
;; Indirectly used by: rep-modified-skip-to-next-change
;;                     rep-substitutions-apply-to-other-window
(defun rep-next-overlay (&optional position property priority-cutoff goto-flag)
  "Looks for the leading edges of overlays following POSITION.
POSITION defaults to point. Works in the current buffer.

If PROPERTY is given, it will search for the first overlay(s)
with that PROPERTY.
If PRIORITY-CUTOFF is given, it will ignore any overlays that
do not have a higher or equal priority.

If more than one qualifying overlays begin at the same place,
returns the overlay with maximum priority, or nil if none are
found.

If the GOTO-FLAG is t, it will also move to the start of
the overlay."
  (let* ( (spot (or position (point)))
          (save-point-a (point))
          (priority priority-cutoff)
          o-list overlay
          )
    ;; repeat peek ahead looking for overlays that qualify,
    ;; i.e. that have property and exceed priority cutoff
    (while (not (progn  ;; repeat-until
                  (setq o-list
                        (rep-next-raw-overlays spot t)) ;; goto flag on
                  ;; restrict by property &/or priority
                  (if property
                      (setq o-list (rep-filter-overlays-by-property o-list property)))
                  (if priority
                      (setq
                       o-list (rep-filter-overlays-priority o-list priority)))
                  ;; get set for next interation (if any)
                  (setq spot (point))
                  ;; exit if found some meeting criteria, or hit the EOB
                  (or
                   o-list
                   (= (point) (point-max)) )
                  )))
    ;; get the max (might be more than one)
    (setq overlay (rep-max-priority-overlay o-list))
    (cond ((and goto-flag
                (overlayp overlay))
           (goto-char (overlay-start overlay))
           )
          (t
           (goto-char save-point-a)))
  overlay))


;; Unused (because BACKTAB uses rep-prev-top-overlay,
;; which uses previous-overlay-change and rep-top-overlay-here)
;; Note rep-next-overlay *is* used to apply changes and such.
(defun rep-prev-overlay (&optional position property priority-cutoff goto-flag)
  "Looks for the leading edges of overlays before POSITION.
POSITION defaults to point. Works in the current buffer.

If PROPERTY is given, it will search for the first overlay(s)
with that PROPERTY.

If PRIORITY-CUTOFF is given, it will ignore any overlays that
do not have a higher or equal priority.

If more than one qualifying overlays begin at the same place,
returns the overlay with maximum priority, or nil if none are
found.

If the GOTO-FLAG is t, it will also move to the start of
the overlay."
  (let* ( (spot (or position (point)))
          (save-point-a (point))
          (priority priority-cutoff)
          o-list overlay
          )
    ;; repeat peek back looking for overlays that qualify,
    ;; i.e. that have property and exceed priority cutoff
    (while (not (progn  ;; repeat-until
                  (setq o-list
                        (rep-prev-raw-overlays spot t)) ;; need to goto
                  ;; restrict by property &/or priority
                  (if property
                      (setq o-list (rep-filter-overlays-by-property o-list property)))
                  (if priority
                      (setq
                       o-list (rep-filter-overlays-priority o-list priority)))
                  ;; get set for next interation (if any)
                  (setq spot (point))
                  ;; exit if found some meeting criteria, or hit the BOB
                  (or
                   o-list
                   (= (point) (point-min)) )
                  )))
    ;; get the max (might be more than one)
    (setq overlay (rep-max-priority-overlay o-list))
    (cond ((and goto-flag
                (overlayp overlay))
           (goto-char (overlay-start overlay))
           )
          (t
           (goto-char save-point-a)))
  overlay))


;; Used by rep-next-overlay
(defun rep-next-raw-overlays (&optional position goto-flag)
  "Searches for any overlays after POSITION, which defaults to point.
If GOTO-FLAG is set, it will move to the location.
Returns a list of overlays found \(there can be more than one
at the same position\)."
  (let* (
         (spot (or position (point)))
         (save-point-b (point))
         o-list
         raw-list
         )
    ;; next-overlay-change stops at leading and trailing edges.
    ;; So if we turn up no overlays with it, it could
    ;; be we're at the trailing edge, so we try again.
    (while  ;; repeat-until
        (not
         (progn
           (setq spot (next-overlay-change spot))
           (goto-char spot)
           (setq o-list
                 (rep-overlays-here spot))
           (or                    ;; exit if...
            o-list                ;;   found something
            (= spot (point-max))) ;;   hit EOB
           )
         )
      )
    (if o-list
        (setq raw-list o-list))
    (unless goto-flag
      (goto-char save-point-b))
    raw-list))

;; Unused, because only referenced by another unused: rep-prev-overlay
(defun rep-prev-raw-overlays (&optional position goto-flag)
  "Searches for any overlays before POSITION, which defaults to point.
If GOTO-FLAG is set, it will move to the location.
Returns a list of overlays found \(there can be more than one
at the same position\)."
  (let* (
         (spot (or position (point)))
         (save-point-b (point))
         o-list
         raw-list
         )
    ;; previous-overlay-change stops at leading and trailing edges.
    ;; So if we turn up no overlays with it, it could
    ;; be we're at the trailing edge, so we try again.
    (while  ;; repeat-until
        (not
         (progn
           (setq spot (previous-overlay-change spot))
           (goto-char spot)
           (setq o-list
                 (rep-overlays-here spot))
           (or                    ;; exit if...
            o-list                ;;   found something
            (= spot (point-min))) ;;   hit BOB
           )
         )
      )
    (if o-list
        (setq raw-list o-list))
    (unless goto-flag
      (goto-char save-point-b))
    raw-list))

;; Used by "undo", "what" (and indirectly by "tab" and "backtab")
;; specically, used by:
;;   rep-prev-top-overlay
;;   rep-next-top-overlay
;;   rep-modified-undo-change-here
;;   rep-modified-what-was-changed-here-verbose
;;   rep-modified-what-was-changed-here

(defun rep-top-overlay-here (&optional position property)
  "Returns the top overlay active at the given position, in the current buffer.
A \"top\" overlay is \"unshadowed\", i.e. there is no overlapping
overlay of higher priority.  If POSITION is not given, it looks
at point, if PROPERTY is given, it looks for the top most overlay
with that PROPERTY. Returns nil, if there's no such overlay."
  (let* ((spot (or position (point)))
         (save-point-c (point))
         (overlays-list
          (rep-filter-overlays-by-property (rep-overlays-here spot) property))
         (candidate
          (rep-max-priority-overlay overlays-list))
         beg end priority top
         )
    (cond (candidate
           (setq beg      (overlay-start candidate))
           (setq end      (overlay-end   candidate))
           (setq priority (overlay-get   candidate 'priority))
           (setq top candidate) ;; top initialized as candidate, we set to nil if this fails

           (goto-char beg) ;; sweep through extent of candidate overlay.
           (while (and top ;; once we know it's not top, might as well stop
                       (<= (point) end)  ;; check at every char up to end of overlay
                       )
             (let* (
                    (raw-overlays-here (rep-overlays-here (point)))
                    (overlays-here
                     (rep-filter-overlays-by-property raw-overlays-here property) )
                    current-priority max-overlay-here
                    )
               (setq current-priority ;; will be -1 if no overlays at all
                     (cond ( overlays-here
                             (setq max-overlay-here
                                   (rep-max-priority-overlay overlays-here))
                             (rep-overlay-get max-overlay-here 'priority)
                             )
                           (t -1)))
               (cond ((> current-priority priority)
                      (setq top nil) ;; no top overlay at this POSITION
                      ))
               )
             (forward-char 1)
             ))
          (t
           (setq top nil) ;; if candidate is undef, we want to return nil
           ))
    (goto-char save-point-c)
    top))

;; used by: rep-modified-skip-to-next-change (aka "next" or TAB ) also "apply"
(defun rep-next-top-overlay (&optional position property goto-flag)
  "Find immediately next top level overlay.
Begins looking at point unless POSITION is given.
If PROPERTY is given, only looks for overlays with that property.
If GOTO-FLAG is on, also moves to the location.
Returns the location found, or nil if none."
  (let* ((spot (or position (point)))
         (start-point (point))
         (goto-flag t)
         candidate candidate-spot shadow found beg end priority shadow-beg
         )
    (while  ;; repeat-until
        (not
         (progn
           (setq spot (next-overlay-change spot))
           ;; Note any "top overlay" is *unshadowed* by definition
           (cond ( (setq found
                         (rep-top-overlay-here spot rep-property))
                   (setq spot (overlay-start found))
                   )
                 )
           (cond ((= spot (point-max))    ;; at EOB, so exit
                  t)
                 (found                   ;; found something, so exit
                  found)
                 )
           )))
    (if goto-flag
        (goto-char spot))
    found))

;; Used by: rep-modified-skip-to-prev-change (aka BACKTAB)
(defun rep-prev-top-overlay (&optional position property goto-flag)
  "Find immediately previous top level overlay.
Begins looking at point unless POSITION is given.
If PROPERTY is given, only looks for overlays with that property.
If GOTO-FLAG is on, also moves to the location.
Returns the location found, or nil if none."
  (let* ((spot (or position (point)))
         (start-point (point))
         (goto-flag t)
         candidate candidate-spot shadow found beg end priority shadow-beg
         )
    (while  ;; repeat-until
        (not
         (progn
           (setq spot (previous-overlay-change spot))
           ;; Note any "top overlay" is *unshadowed* by definition
           (cond ((setq found
                         (rep-top-overlay-here spot rep-property))
                  (setq spot (overlay-start found))
                  ))
           (cond ((= spot (point-min))    ;; at BOB, so exit
                  t)
                 (found                      ;; found something, so exit
                  found)
                 )
           )))
    (if goto-flag
        (goto-char spot))
    found))

;; Used by: rep-prev-top-overlay, rep-modified-undo-change-here
(defun rep-overlay-shadowed-p (overlay &optional tag-property)
  "Is OVERLAY shadowed (and not a top overlay)?
With TAG-PROPERTY, only considers overlays that contain that tag.
Returns the shadowing overlay, if one is found, nil otherwise."
  (save-excursion ;; pleeeease preserve point.  thank you.
    (let* ((beg (overlay-start overlay))
           (end (overlay-end   overlay))
           (priority (overlay-get overlay 'priority))
           (over-overlay (rep-next-overlay beg tag-property
                                           (1+ priority)
                                           nil))
           ;; nil => goto-flag is off
           shadow dark-beg
           )
      (cond (over-overlay
             (setq dark-beg      (overlay-start over-overlay))
             ))
      ;; if found a higher overlay that starts before the end of
      ;; the given one, it's a shadow
      (cond ((and over-overlay (<= dark-beg end))
             (setq shadow over-overlay)))
      shadow
      )))



;;--------
;; alist manipulation utilities

;; Used a lot here!
(defun rep-get (alist-symbol key)
  "Look up value for given KEY in ALIST.
Example:
   (rep-get 'rep-general-alist 'field)
Note: must quote alist name and key."
  (if rep-trace (rep-message (format "%s" "rep-get")))
  (let* ((value (cdr (assoc key (eval alist-symbol))))
         )
    ;; hack! Sometimes need car/cdr, sometimes just cdr, who knows why.
    (setq value
          (cond ((listp value)
                 (car value)
                 )
                (t
                 value
                 )))

    ;; automatic conversion of numeric strings to numbers (yes, i like perl)
    (cond ((not (stringp value))
           value)
          ((string-match "^[-+.0-9]+$" value)
           (string-to-number (match-string 0 value))
           )
          (t
           value)
          )
    ))

(defun rep-set (alist-symbol key value)
  "Store given VALUE under KEY in ALIST.
Example:
   (rep-set 'rep-general-alist 'C \"CCC\")
Note: must quote alist name."
  (if rep-trace (rep-message (format "%s" "rep-set")))
  (set alist-symbol (cons (list key value) (eval alist-symbol)))
  )

;;--------
;; buffer location & string manipulation utilities

;; used by rep-get-local-state
(defun rep-safe-sum (here try-reach)
  "Starting from HERE, tries to add TRY-REACH, but does not exceed boundaries.
If HERE plus TRY-REACH exceeds the min or max, returns the min or max,
otherwise just returns the sum.  Note that TRY-REACH can be a negative
number.

This is intended to be used to write safe peek-ahead or peek-behind
code that will not error-out when near buffer boundaries."
  (let* (
         (min  (point-min))
         (max  (point-max))
         (sum (+ here try-reach))
         there
         )
    (cond ((< sum min)
           (setq there min)
           )
          ((> sum max)
           (setq there max)
           )
          (t
           (setq there sum)
           ))
    there))

;;--------
;; safe buffer substring
;; currently un-used
(defun rep-buffer-string-before (here &optional chunk-size)
  "Tries to get a substring before HERE of size CHUNK-SIZE \(default: 10\).
If too close to the beginning of the buffer, returns as many characters
as it can \(without signalling an error\). No properties are
included in the substring.  HERE is taken as point when run
interactively."
  (interactive "d")
  (let* ((chunk-size (or chunk-size 8))
         (min  (point-min))
         (there (- here chunk-size))
         string
         )
    (cond ((< there min)
           (setq there min)
           ))
    ;; step back ten chars, get string
    (setq string (buffer-substring-no-properties there here))

    (message "||%s||" string)
    string
    ))

;; currently un-used
(defun rep-buffer-string-after (here &optional chunk-size)
  "Tries to get a substring after HERE of size CHUNK-SIZE \(default: 10\).
If too close to the end of the buffer, returns as many characters
as it can \(without signalling an error\). No properties are
included in the substring.  HERE is taken as point when run
interactively."
  (interactive "d")
  (let* ((chunk-size (or chunk-size 8))
         (max  (point-max))
         (there (+ here chunk-size))
         string
         )
    (cond ((> there max)
           (setq there max)
           ))
    ;; step back ten chars, get string
    (setq string (buffer-substring-no-properties there here))

    (message "||%s||" string)
    string
    ))

;;========
;; debug tools


;;; rep.el ends here
