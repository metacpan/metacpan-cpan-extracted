;; dir-project.el --- utilities for finding DIRPROJECT under Emacs

;; Author          : Wilson Snyder <wsnyder@wsnyder.org>

;; INSTALLATION:
;;
;; Add dir-project.el in a directory listed under your
;; "M-x describe-variable load-path" (often /usr/snate/emacs/site-lisp)
;;     cp contrib/dir-project.el /usr/snate/emacs/site-lisp/
;;
;; In a directory that looks like site-start.d under your
;; "M-x describe-variable load-path" install verilog-mode-inst.el
;;     cp contrib/dir-project.el /usr/snate/emacs/site-lisp/site-start.d/
;; Alternatively, or if there is no site-start.d listed, just copy the
;; lines in that file to your .emacs or site-start.el file.

;; COPYING:
;;
;; Dir-Project is part of the http://www.veripool.org/ free EDA software
;; tool suite.  The latest version is available from CPAN and from
;; http://www.veripool.org/.
;;
;; Copyright 2001-2017 by Wilson Snyder.  This package is free software;
;; you can redistribute it and/or modify it under the terms of either the
;; GNU Lesser General Public License Version 3 or the Perl Artistic License
;; Version 2.0.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.


;;; Code:

(provide 'dir-project)

(defvar dir-project-directory-cache nil "Cached project/ resolved directory")

(defun dir-project-directory ()
  "Find the value of DIRPROJECT, using direct searching rather then calling an external program."
  (when (not dir-project-directory-cache)
    (save-match-data
      (make-local-variable 'dir-project-directory-cache)
      ;; Start at current directory
      (let ((search-dir (buffer-file-name))
	    proj-dir)
	(while (and search-dir
		    (not proj-dir)
		    (string-match "/" search-dir))
	  (setq search-dir (file-name-directory search-dir))
	  (string-match "/$" search-dir)
	  (setq search-dir (replace-match "" nil t search-dir))
	  (if (file-exists-p (expand-file-name "Project_Root" search-dir))
	      (setq proj-dir search-dir)))
	;; Default if nothing else found
	(if (not proj-dir) (setq proj-dir "project/"))
	(setq dir-project-directory-cache proj-dir))))
  ;; Return it
  dir-project-directory-cache)
;(progn (setq dir-project-directory-cache nil) (dir-project-directory))

(defun dir-project-absolutify (dir)
  "Given a DIRECTORY or file, replace project/ references to absolute files"
  (when (string-match "^project/" dir)
    (setq dir (replace-match (concat (dir-project-directory) "/") nil t dir)))
  dir)

;;; Utilities for other packages

(defun dir-project-verilog-getopt ()
  "Resolve project/ references for verilog-mode.el's verilog-library-directories.
To use this, you'd add to your site-start.el:
   (require 'dir-project)
   (add-hook 'verilog-getopt-flags-hook 'dir-project-verilog-getopt)"
  (setq verilog-library-directories
	(mapcar `dir-project-absolutify verilog-library-directories)))
;(progn (setq verilog-library-directories '("project/a" "b" "c")) (verilog-project-getopt) verilog-library-directories)
;(setq dir-getopt-flags-hook 'dir-project-getopt)

;;; dir-project.el ends here
