;;; eekboek-mode.el --- major mode for EekBoek data files

;; Copyright (C) 2007 by Johan Vromans

;; Author: Johan Vromans <jv@phoenix.squirrel.nl>
;; Keywords: languages

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

;;; Commentary:

;; Major mode for editing EekBoek data files. Mainly text-mode, but
;; without filling and wrapping, and no tabs in the written data.
;;
;; To add to your Emacs, copy this file to your lisp library and add
;; the following lines to your .emacs:
;;
;; (setq auto-mode-alist 
;;       (append
;;        '(("\\.eb$" . eekboek-mode)
;;          ("\\.ebz$" . archive-mode))
;;        auto-mode-alist))

;;; Code:

(define-derived-mode eekboek-mode
  text-mode "EekBoek"
  "Major mode for EekBoek data files.
\\{eekboek-mode-map}"
  (auto-fill-mode 0)
  (add-hook 'write-contents-hooks 'eekboek-detab)
)

(define-key eekboek-mode-map
  "\t" 'tab-to-tab-stop)

(defun eekboek-detab ()
  "Untabify the whole buffer."
  (untabify (point-min) (point-max))
  ;; Write hooks must return nil for the writing to continue.
  nil)

;;; eekboek-mode.el ends here
