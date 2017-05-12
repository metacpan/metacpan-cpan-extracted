;;; defvarsity.el ---

;; Copyright 2008 Joseph Brenner
;;
;; Author: doom@kzsu.stanford.edu
;; Version: $Id: defvarsity.el,v 0.0 2008/03/04 23:37:50 doom Exp $
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

;;

;; Put this file into your load-path and the following into your ~/.emacs:
;;   (require 'defvarsity)

;;; Code:

(provide 'defvarsity)
(eval-when-compile
  (require 'cl))



;;;;##########################################################################
;;;;  User Options, Variables
;;;;##########################################################################

(defvar defvarsity-1 nil
  "Here is a variable known as defvarsity-1.
Gort."
)

(defvar defvarsity-2 t
  "Here is a variable known as defvarsity-2.
Verada."
)

(defvar defvarsity-3 "I1"
  "Here is a variable known as defvarsity-3.
Nictu."
)

;;; defvarsity.el ends here
