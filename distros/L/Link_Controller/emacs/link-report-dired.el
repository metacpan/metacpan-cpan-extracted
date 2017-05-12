;;; link-report-dired.el --- run a `link-report' command and dired the output
;;; based on find-dired 

;; Copyright (C) 1992, 1994, 1995 Free Software Foundation, Inc.
;; Copyright (C) 1997 Michael De La Rue.

;; Author: Michael De La Rue 
;; FindDired authors
;;         Roland McGrath <roland@gnu.ai.mit.edu>,
;;	   Sebastian Kremer <sk@thp.uni-koeln.de>
;; Keywords: unix linkcontroller

;; This file is part of LinkController

;; LinkController is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; LinkController is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with LinkController; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Code:

(require 'dired)

(defvar link-report-args nil
  "Last arguments given to `link-report' by \\[link-report-dired].")

;; History of find-args values entered in the minibuffer.
(defvar link-report-args-history nil)

;;;###autoload
(defun link-report-dired (args)
  "Run `link-report' and go into dired-mode on a buffer of the output.
The command run is

    link-report --long-list \\( ARGS \\)"
  (interactive (list (read-string "Run link-report (with args): " link-report-args
				  '(link-report-args-history . 1))))
  (switch-to-buffer (get-buffer-create "*LinkControl*"))
  (widen)
  (kill-all-local-variables)
  (setq buffer-read-only nil)
  (erase-buffer)
  (setq link-report-args args		; save for next interactive call
	args (concat "link-report --long-list "
		     (if (string= args "")
			 ""
		       args ) ))
  ;; the listing has no directory context.. I wonder how we express this.. 
  (dired-mode "/")
  ;; This really should rerun the link-report command, but I don't
  ;; have time for that.
;  (use-local-map (append (make-sparse-keymap) (current-local-map)))
;  (define-key (current-local-map) "g" 'undefined)
  (if (fboundp 'dired-simple-subdir-alist)
      ;; will work even with nested dired format (dired-nstd.el,v 1.15
      ;; and later)
      (dired-simple-subdir-alist)
    ;; else we have an ancient tree dired (or classic dired, where
    ;; this does no harm) 
    (set (make-local-variable 'dired-subdir-alist)
	 (list (cons "/" (point-min-marker)))))   ;if only I knew what
						  ;I was doing.. oh
						  ;well, I guess it
						  ;would be an unfair
						  ;advantage.
  (setq buffer-read-only nil)
  ;; Make second line a ``link-report'' line in analogy to the ``total'' or
  ;; ``wildcard'' line. 
  (insert "  " args "\n")
  ;; Start the link-report process.
  (let ((proc (start-process-shell-command "link-report" (current-buffer) args)))
    (set-process-filter proc (function link-report-dired-filter))
    (set-process-sentinel proc (function link-report-dired-sentinel))
    ;; Initialize the process marker; it is used by the filter.
    (move-marker (process-mark proc) 1 (current-buffer)))
  (setq mode-line-process '(":%s")))


(defun link-report-dired-filter (proc string)
  ;; Filter for \\[link-report-dired] processes.
  (let ((buf (process-buffer proc)))
    (if (buffer-name buf)		; not killed?
	(save-excursion
	  (set-buffer buf)
	  (save-restriction
	    (widen)
	    (save-excursion
	      (let ((buffer-read-only nil)
		    (end (point-max)))
		(goto-char end)
		(insert string)
		(goto-char end)
		(or (looking-at "^")
		    (forward-line 1))
		(while (looking-at "^")
		  (insert "  ")
		  (forward-line 1))
		;; Convert ` ./FILE' to ` FILE'
		;; This would lose if the current chunk of output
		;; starts or ends within the ` ./', so back up a bit:
		(goto-char (- end 3))	; no error if < 0
		(while (search-forward " ./" nil t)
		  (delete-region (point) (- (point) 2)))
		;; Link-Report all the complete lines in the unprocessed
		;; output and process it to add text properties.
		(goto-char end)
		(if (search-backward "\n" (process-mark proc) t)
		    (progn
		      (dired-insert-set-properties (process-mark proc)
						   (1+ (point)))
		      (move-marker (process-mark proc) (1+ (point)))))
		))))
      ;; The buffer has been killed.
      (delete-process proc))))

(defun link-report-dired-sentinel (proc state)
  ;; Sentinel for \\[link-report-dired] processes.
  (let ((buf (process-buffer proc)))
    (if (buffer-name buf)
	(save-excursion
	  (set-buffer buf)
	  (let ((buffer-read-only nil))
	    (save-excursion
	      (goto-char (point-max))
	      (insert "\nlink-report " state)
	      (forward-char -1)		;Back up before \n at end of STATE.
	      (insert " at " (substring (current-time-string) 0 19))
	      (forward-char 1)
	      (setq mode-line-process
		    (concat ":"
			    (symbol-name (process-status proc))))
	      ;; Since the buffer and mode line will show that the
	      ;; process is dead, we can delete it now.  Otherwise it
	      ;; will stay around until M-x list-processes.
	      (delete-process proc)
	      (force-mode-line-update)))
	  (message "link-report-dired %s finished." (current-buffer))))))

(provide 'link-report-dired)

;;; link-report-dired.el ends here
