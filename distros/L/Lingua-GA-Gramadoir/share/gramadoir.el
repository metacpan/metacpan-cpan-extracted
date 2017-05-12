;;; gramadoir.el --- Interface to An Gramadóir

;; Copyright (C) 2003  Free Software Foundation, Inc.

;; Author: Martin Gregory <Martin.Gregory@eur.sas.com>
;; Keywords: hypermedia, unix

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin St, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This package provides an interface to the Irish language grammar
;; checking program An Gramadóir

;;; Code:

(defvar gramadoir-program-path "/usr/bin/gram-ga.pl"
"Location of the executable for An Gramadóir"
)

(defvar gramadoir-highlight-text t
  "Whether to highlight the words in error in the checked text. A
value of t highlights, nil prevents not. The words in error in the
Gramadoir output buffer are always highlighted")

(defvar gramadoir-program-options "--html --aschod=ISO-8859-1"
"options for the executable for An Gramadóir")

(defvar gramadoir-display-buffer "*Gramadoir Output*"
"Name of buffer containing human readable output of An Gramadóir")

(defvar gramadoir-current-file ""
"File containing the current error")

(defvar gramadoir-current-line 0
"Line in the current file on which the current error occurs")

(defvar gramadoir-check-file-msgid "^Currently checking %s"
"gettext message id for determining the translation of the message which
identifies the file currently being checked."
)

(defun gramadoir-set-check-file-msg ()
  "Set gramadoir-check-file-msg according to locale."
  (setq gramadoir-check-file-msg
	(format 
	 (concat "^"
		 (shell-command-to-string
		  "gettext gramadoir \"Currently checking %s\"")) ""))
  )

(defvar gramadoir-check-file-msg (gramadoir-set-check-file-msg)
"Regular expression used to determine which file a message relates to. The 
initial value is taken from the translation of the English version of the
 message.")

(defun gramadoir-check-region (start end)
"This function runs the grammar checking program An Gramadóir on the current 
region, if there is one. The function can also be called using 
	(gramadoir-check-region (point) (mark))
from within a lisp program. The xml output from An Gramadóir is sent to a 
temporary buffer whence it can be parsed.
"
(interactive "r") ; default to region for start and end if interactive

(call-process-region (point) (mark)	; the region
		     gramadoir-program-path 
		     nil	; keep output
		     buffer	; write to buffer
		     nil	; dont show it until finished
		     ,@(split-string gramadoir-program-options " "))
;; might want to call (setq output (shell-command-to-string command))
;; calls:
;gramadoir-parse-results (buffer)
)

(defun gramadoir-check-files (gramadoir-file-spec)
  "This function runs the grammar checking program An Gramadóir on a list of 
files.
"
  (interactive "sFiles: ")
  (if (get-buffer gramadoir-display-buffer)
      (progn
	(set-buffer gramadoir-display-buffer)
	(erase-buffer)
	))
  (setq gr-cmd `(call-process gramadoir-program-path 
			      nil	; no standard input
			      gramadoir-display-buffer	; write to buffer
			      nil	; dont show it until finished
			      ,@(split-string gramadoir-program-options " ")
			      ,@(split-string gramadoir-file-spec " ")))
  (eval gr-cmd)

  ;; calls:
  ;;gramadoir-parse-results (buffer)
  ;; display the results in the lower window.
  (with-current-buffer gramadoir-display-buffer
    (goto-char (point-min))
    (gramadoir-highlight)
    ;(goto-char (point-min))
    (display-buffer gramadoir-display-buffer t)
  ))

(defun gramadoir-format-message (text)
"convert an error message code (xml tag) into a human-readable form")

(defun gramadoir-get-location (text)
"determine the exact location of the erroneous text so that it can be 
highlighted in the display")

(defun gramadoir-get-substitution (text)
"If An Gramadóir suggests an alternative, save it keyed on the error location 
so it can be presented to the user for possible substitution")

(defun gramadoir-parse-results (buffer)
"Parse the results of the call to An Gramadóir"
;; calls:
; (gramadoir-format-message)
; (gramadoir-get-location)
; (gramadoir-get-substitution)
)

(defun gramadoir-next-message ()
  "Jump to next message"
  (interactive)
  (set-buffer gramadoir-display-buffer)
  (if (get-buffer-window gramadoir-display-buffer)
      (delete-window (get-buffer-window gramadoir-display-buffer)))
  ;; determine line number of next message
  ;(message "Before re-search: in %s at %d" (current-buffer) (point))
  (if (re-search-forward "^\\([0-9]*\\):" nil t)
      (progn
	(setq gramadoir-current-line (string-to-number (match-string 1)))

	;;(message "Before excursion: in %s at %d" (current-buffer) (point))

	;; determine which file is the message in 
	(setq gramadoir-current-file 
	      (save-excursion 
		(end-of-line) ; in case we are located on a file name line
		(re-search-backward gramadoir-check-file-msg)
		(forward-word 2)
		(buffer-substring (+ 1 (point))
				  (save-excursion (end-of-line) (point)))))

	(gramadoir-goto-message gramadoir-current-file gramadoir-current-line))
    (message "No more errors."))
  )

(defun gramadoir-goto-message (gramadoir-current-file gramadoir-current-line)
  "Jump to selected message"
  (interactive)
  ;; load the file if it is not already loaded
  ;(message "ggm: %s %s %s" gramadoir-current-file gramadoir-current-line
  ;	   (get-file-buffer gramadoir-current-file))
  (if (get-file-buffer gramadoir-current-file) 
      nil
    (find-file-other-window gramadoir-current-file)
    )
  (set-buffer (get-file-buffer gramadoir-current-file))
  (goto-line gramadoir-current-line)

  ;; now find the words to highlight. Since setting text properties
  ;; marks the buffer as modified, but we want to preserve modified
  ;; state, save the current setting to use as argument to
  ;; set-buffer-modified-p after we highlight.
  (if gramadoir-highlight-text
      (let (the-word 
	    (eol (save-excursion (end-of-line) (point)))
	    (was-modified (buffer-modified-p)))
	(while (setq the-word (with-current-buffer gramadoir-display-buffer
				(gramadoir-get-word)))
	  ;; search to end of line for the word and highlight
	  (if (re-search-forward the-word eol t)
	      (put-text-property (match-beginning 0) (match-end 0)
				 'face 'font-lock-comment-face)
	    ))
	(set-buffer-modified-p was-modified)
	))
  ;(message "ggm: %s %d " gramadoir-current-file (point))

  (switch-to-buffer (get-file-buffer gramadoir-current-file))
  (display-buffer gramadoir-display-buffer)
)

(defun gramadoir-highlight ()
  "Function to highlight messages from An Gramadóir"
  (interactive)
  (save-excursion 
    (let ((start-re "<b class=gramadoir>") 
	  (end-re "</b>")
	  (start-error 0))
      (goto-char (point-min))
      (while (re-search-forward start-re (point-max) t)
	(put-text-property (match-beginning 0) (point) 'invisible t)
	(setq start-error (point))
	(if (re-search-forward end-re (point-max) t)
	    (progn
	      (put-text-property start-error (match-beginning 0)
				 'face 'font-lock-comment-face)
	      (put-text-property (match-beginning 0) (point) 'invisible t)
	      )))))
  ;; remove the <br> tags
  (save-excursion
    (while (re-search-forward "<br>" nil t)
      (replace-match "" nil t)))
  (message "end of gramadoir-highlight, point=%d" (point))
  )

(defun gramadoir-get-word ()
  "Function to retrieve word to which a message refers. This function searches
for the invisible text surrounding the word in error and returns either the 
word or an empty string. If a word is found, the pointer is placed after the 
invisible closing tag so that the next call will search ahead. The function
only searches within the current line"
  (interactive)
  (let ((open-b 0)
	(start-word 0) 
	(end-word 0) 
	(close-b 0)
	(eol (save-excursion (end-of-line) (point)))
	(word ""))
    (setq open-b (text-property-any (point) eol 'invisible t))
    (setq word
	  (if open-b
	      (progn
		(setq start-word (text-property-any open-b eol 'invisible nil))
		(if start-word 
		    (progn
		      (setq end-word (text-property-any start-word eol 'invisible t))
		      (buffer-substring-no-properties start-word end-word)
		      ))
		))
	  )
    (if (stringp word)
	(progn
	  (goto-char end-word)
	  (goto-char (or (text-property-any (point) eol 'invisible nil) eol))
	  ;;(message "word is: %s, %d" word close-b)
	  word
	  )
      nil)
    )
  )

(defun gramadoir-dired ()
  "Run gramadoir on files in a dired buffer. If no files are marked, the 
file on the current line is checked, otherwise all marked files are checked.

This command should only be used in a dired buffer."
  (interactive)
  (if (equal major-mode 'dired-mode)
    (let* ((file-list (dired-get-marked-files))
	   (list-len (length file-list))
	   (this-string "")
	   (i 0))
      (while (<= i list-len)
	(setq this-string (concat this-string (nth i file-list) " "))
	(setq i (1+ i)))
      (gramadoir-check-files this-string))
    (message "gramadoir-dired: current buffer is not a dired buffer.")
    )
  )

(provide 'gramadoir)
;;; gramadoir.el ends here
