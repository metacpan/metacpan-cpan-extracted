;;; defunnery.el ---

;; Copyright 2008 Joseph Brenner
;;
;; Author: doom@kzsu.stanford.edu
;; Version: $Id: defunnery.el,v 0.0 2008/03/04 23:33:52 doom Exp $
;; Keywords:
;; X-URL: not distributed yet

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

;; Miscellanious defuns, to play with docstring extraction.

;; Put this file into your load-path and the following into your ~/.emacs:
;;   (require 'defunnery)

;;; Code:

(provide 'defunnery)
(eval-when-compile
  (require 'cl))



;;;;##########################################################################
;;;;  User Options, Variables
;;;;##########################################################################


(defun defunnery-1 ()
  "The first defun found in the defunnery."
  (interactive); and why not?
  (message "Defunnery 1!"))

(defun defunnery-2 ()
  "The 2nd defun found in the defunnery.
This bears a strong resemblence to \\[defunnery-1]."
  (interactive); and why not?
  (message "Defunnery 2!"))

(defun defunnery-3 (argumentum)
  "The 3rd of the series, don't forget the ARGUMENTUM.
See also: \\[defunnery-2]."
  (interactive); and why not?
  (message "Defunnery 3!"))


;;; defunnery.el ends here
