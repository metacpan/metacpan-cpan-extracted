;; epl-server.el -- run as a slave of Perl
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

;;; The loading of this file constitutes a START message as described
;;; in EPL.pm.

(require 'epl)

(setq epl-interp
      (let ((process-connection-type nil))  ; Use a pipe.
	(make-epl-interp ':out (apply 'start-process "perl" nil
				      (cdr command-line-args-left))
			 ':child-p nil))
      perl-interpreter epl-interp)

;; Check version
(let ((me (format "%d.%d" epl-major-version epl-minor-version))
      (you (car command-line-args-left)))
  (if (not (string= you me))
      (epl-send-message "&cb_raise("
			(format "Version mismatch: %s versus epl.el %s"
				you me) ")")))

(setq command-line-args-left nil)

;; Answer the START.
(epl-debug "Server start, pid " (emacs-pid) "\n")
(epl-send-and-receive "&cb_return()")
