;; epl-compat.el -- Compatibility among Emacsen versions for EPL.
;; Copyright (C) 2001 by John Tobey.  All rights reserved.

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



;; XXX Should we even be using string-bytes??  Maybe the stuff sent to
;; Perl should be delimited instead of byte-counted.
(defalias 'epl-string-bytes
  (if (fboundp 'string-bytes)
      'string-bytes
    'length))

(or (fboundp 'make-hash-table)
    (fboundp 'make-hashtable)
    (require 'cl))

(defalias 'epl-puthash
  (if (fboundp 'puthash)
      'puthash
    'cl-puthash))

(defun epl-mvwht () (make-value-weak-hashtable 10 'eq))

(defun epl-mhtwv () (make-hash-table ':test 'eq ':weakness 'value))

(defalias 'epl-make-refs-table
  (if (fboundp 'make-value-weak-hashtable)
      'epl-mvwht
    'epl-mhtwv))

(defvar epl-weakrefs-reduce-count 'undecided
  "True if garbage-collection of weak hash table entries reduces the count.")

(defvar epl-have-weakrefs 'undecided
  "True if Emacs Lisp supports weak hash tables.")

;; Detect whether garbage-collection of weak hash table entries reduces
;; the hash table's count.
;; XXX This is imprecise with conservative GC.  I suppose we could resort
;; to testing Emacs version numbers and (featurep 'xemacs).
(let ((h (epl-make-refs-table)))
  (epl-puthash 0 (vector) h)
  (sleep-for 0)  ; seems to help GNU Emacs 21's conservative GC
  (garbage-collect)
  (cond ((= (hash-table-count h) 0)
	 (if (eq epl-weakrefs-reduce-count 'undecided)
	     (setq epl-weakrefs-reduce-count t))
	 (if (eq epl-have-weakrefs 'undecided)
	     (setq epl-have-weakrefs t)))
	((null (gethash 0 h))
	 (if (eq epl-weakrefs-reduce-count 'undecided)
	     (setq epl-weakrefs-reduce-count nil))
	 (if (eq epl-have-weakrefs 'undecided)
	     (setq epl-have-weakrefs t)))
	(t
	 (if (eq epl-weakrefs-reduce-count 'undecided)
	     (setq epl-weakrefs-reduce-count nil))
	 (if (eq epl-have-weakrefs 'undecided)
	     (setq epl-have-weakrefs nil)))))

(defvar epl-gc-detection-method
  (cond ((boundp 'post-gc-hook) 'hook)
	(epl-weakrefs-reduce-count 'count)
	(epl-have-weakrefs 'value)
	(t nil))
  "Method used to detect when weak hash table entries should be checked.
Must be either `hook', `count', `value', or `nil'.  `hook' means that
`post-gc-hook' will be used.  `count' means use `hash-table-count'. `value'
means use `maphash' and check for nil values.  `nil' means none of these
methods works.

See also `epl-gc-method'.")

(defvar epl-gc-method
  (cond ((eq epl-gc-detection-method 'count) 'count)
	((and (eq epl-gc-detection-method 'hook)
	      epl-weakrefs-reduce-count) 'count)
	(epl-gc-detection-method 'value)
	(t nil))
  "Method used to check for garbage-collected weak hash table entries.
Must be either `count', `value', or `nil'.  `count' means that
`hash-table-count' will be used.  `value' means use `maphash' and check for
nil values.  `nil' means do not check.

See also `epl-gc-detection-method'.")

(if (eq 'epl-gc-detection-method 'hook)
    (add-hook 'post-gc-hook 'epl-post-gc-hook))

(defun epl-make-refs-hash-table ()
  (if (fboundp 'make-value-weak-hashtable)
      (make-value-weak-hashtable 20 'eq)
    (make-hash-table ':test 'eq ':size 20 ':weakness 'value)))

(defun epl-make-cookies-hash-table ()
  (if (fboundp 'make-key-weak-hashtable)
      (make-key-weak-hashtable 20 'eq)
    (make-hash-table ':test 'eq ':size 20 ':weakness 'key)))

;; For GNU Emacs 19.34.
(or (fboundp 'with-current-buffer)
    (defmacro with-current-buffer (buffer &rest body)
      `(let ((epl-current-buffer (current-buffer)))
	 (unwind-protect
	     (progn
	       (set-buffer ,buffer)
	       . ,body)
	   (set-buffer epl-current-buffer)))))

;; For GNU Emacs 19.34.
;; XXX untested.
(or (fboundp 'with-temp-buffer)
    (defmacro with-temp-buffer (buffer &rest body)
      `(let ((epl-current-buffer (generate-new-buffer "*epl-temp*")))
	 (unwind-protect
	     (progn
	       (set-buffer ,buffer)
	       . ,body)
	   (kill-buffer epl-current-buffer)))))

;; For GNU Emacs 19.34.
(or (fboundp 'char-before)
    (defsubst char-before (&optional pos)
      (char-after (1- (or pos (point))))))


(provide 'epl-compat)

;; end of epl-compat.el
