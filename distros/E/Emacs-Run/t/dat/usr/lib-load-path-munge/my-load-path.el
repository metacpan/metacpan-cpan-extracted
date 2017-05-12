;;; my-load-path.el ---

;; Copyright 2008 Joseph Brenner
;;
;; Author: doom@kzsu.stanford.edu
;; Version: $Id: my-load-path.el,v 0.0 2008/03/18 21:31:59 doom Exp $
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

;; When this is loaded, it adds a location to the load-path

;; Put this file into your load-path and the following into your ~/.emacs:
;;   (require 'my-load-path)

;;; Code:

(provide 'my-load-path)
;; (eval-when-compile
;;   (require 'cl))



;;;;##########################################################################
;;;;  User Options, Variables
;;;;##########################################################################

(defun emacs-run-testorama-prepend-to-load-path (loc)
  "Taking the given LOC as relative to pwd, prepend to load-path."
  (let* ( ( temp (shell-command-to-string "pwd"))
          ( usr  (substring temp 0 (- (length temp) 1)) ) ; chop
          )
    (add-to-list 'load-path
                 (expand-file-name
                  (concat usr "/" loc)))
    ))

(emacs-run-testorama-prepend-to-load-path "lib-target")


;;; my-load-path.el ends here
