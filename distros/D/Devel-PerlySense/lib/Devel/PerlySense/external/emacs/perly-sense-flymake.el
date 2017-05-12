
;;;; Flymake support for PerlySense


(require 'flymake)


(defun flymake-perlysense-init ()
  (let* ((temp-file
          (flymake-init-create-temp-buffer-copy
           'flymake-create-temp-inplace))
         (local-file
          (file-relative-name
           temp-file
           (file-name-directory buffer-file-name))))
    (list "perly_sense" (list "flymake_file" (format "--file=%s" local-file)))))


(setq
 flymake-allowed-file-name-masks
 (append
  '(("\\.pl\\'" flymake-perlysense-init))
  '(("\\.pm\\'" flymake-perlysense-init))
  '(("\\.t\\'" flymake-perlysense-init))
  flymake-allowed-file-name-masks))


(add-hook 'cperl-mode-hook 'flymake-mode t)




(defun ps/flymake-display-err-for-current-line ()
  "Display a menu/message (depending on display capabilities and
customization) with errors/warnings for current line if it has
errors and/or warnings."
  (interactive)
  (if (and (display-popup-menus-p) (not ps/flymake-prefer-errors-in-minibuffer))
      (flymake-display-err-menu-for-current-line)
    (ps/flymake-display-err-message-for-current-line)
    )
  )



(defun ps/flymake-display-err-message-for-current-line ()
  "Display a message with errors/warnings for current line if it
has errors and/or warnings."
  (interactive)
  (let ((err (get-char-property (point) 'help-echo)))
            (when err
              (message err)))
  )



(global-set-key (format "%ssn" ps/key-prefix) 'flymake-goto-next-error)
(global-set-key (format "%ssp" ps/key-prefix) 'flymake-goto-prev-error)
(global-set-key (format "%sss" ps/key-prefix) 'ps/flymake-display-err-for-current-line)




;;END
