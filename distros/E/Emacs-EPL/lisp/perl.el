;; perl.el -- interactive functions for Perl embedded in Emacs
;; Copyright (C) 1998-2001 by John Tobey.  All rights reserved.

;; This library is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This software is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.


(require 'perl-core)

(defvar perl-interpreter-args '("-MEmacs" "-MEmacs::Lisp"))

;; This gets called from C the first time a Perl function is called.
;;;###autoload
(defun make-perl-interpreter ()
  "Create and return a new Perl interpreter object.
The command line will be the program invocation name, followed by the
list of strings in `perl-interpreter-args', followed by some arguments
for establishing communication with Emacs."
  (if (fboundp 'perl-interpreter-new)  ; EPL
      (perl-interpreter-new)
    (let ((interp                      ; Perlmacs
	   (apply 'primitive-make-perl
		  (car command-line-args)  ; propagate argv[0]
		  (append perl-interpreter-args
			  '("-e0")))))
      ;; Alas, this hook isn't called in batch mode.
      (add-hook 'kill-emacs-hook
		`(lambda () (perl-destruct ,interp)))
      interp)))

;;;###autoload
(defun perl-eval-expression (expression &optional prefix)
  "Evaluate EXPRESSION as Perl code and print its value in the minibuffer.
With prefix arg, evaluate in list context."
  (interactive (list (read-from-minibuffer "Eval Perl: ")
		     current-prefix-arg))
  (message (prin1-to-string
	    (perl-eval expression
		       (if prefix 'list-context 'scalar-context)))))

;;;###autoload
(defun perl-eval-region (start end)
  "Execute the region as Perl code."
  (interactive "r")
  (perl-eval (buffer-substring start end)))

;;;###autoload
(defun perl-eval-buffer ()
  "Execute the current buffer as Perl code."
  (interactive)
  (perl-eval (buffer-string)))

;;;###autoload
(defun perl-load-file (filename)
  "Apply Perl's `require' operator to FILENAME."
  (interactive "FLoad Perl file: ")
  (perl-eval-and-call "sub {require $_[0]}" (expand-file-name filename)))

(defvar perl-map nil "Keymap for Perl-specific operations.")
(when (not perl-map)
  (setq perl-map (make-sparse-keymap))
  (define-key perl-map "e"    'perl-eval-expression)
  (define-key perl-map "r"    'perl-eval-region)
  (if (not (lookup-key global-map "\C-xp"))
      (define-key global-map "\C-xp" perl-map)))


(provide 'perl)
