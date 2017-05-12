;; Use eekboek-mode for .eb files. Treat .ebz files as (zip) archives.

(autoload 'eekboek-mode "eekboek-mode" "Major mode for editing EekBoek data." t)
(add-to-list 'auto-mode-alist '("\\.eb\\'" . eekboek-mode))
(add-to-list 'auto-mode-alist '("\\.ebz\\'" . archive-mode))
(if (boundp 'auto-coding-alist) ;; no such variable in xemacs21
    (add-to-list 'auto-coding-alist '("\\.ebz\\'" . no-conversion)))

;;; eekboek-site-start.el ends here
