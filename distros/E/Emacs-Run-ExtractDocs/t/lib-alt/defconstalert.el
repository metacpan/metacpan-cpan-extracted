;;; defconstalert.el ---

;; Copyright 2008 Joseph Brenner
;;
;; Author: doom@kzsu.stanford.edu
;; Version: $Id: defconstalert.el,v 0.0 2008/03/05 00:05:38 doom Exp $
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
;;   (require 'defconstalert)

;;; Code:

(provide 'defconstalert)
(eval-when-compile
  (require 'cl))



;;;;##########################################################################
;;;;  User Options, Variables
;;;;##########################################################################

(defconst defconstalert-1 "hey"
  "Alert doctor string!")

(defconst defconstalert-2 1
  "Alert doctor digit!")

(defconst defconstalert-3 t
  "Alert doctor tea!")

;;; defconstalert.el ends here


