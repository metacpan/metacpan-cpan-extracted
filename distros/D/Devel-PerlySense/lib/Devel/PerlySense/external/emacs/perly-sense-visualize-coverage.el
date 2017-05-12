
;;;; Inline Visualization support for PerlySense, e.g. display code coverage



(defface ps/covered-good
  `((t (:inherit 'font-lock-keyword-face :underline "DarkGreen")))
  "Face for underlining the 'sub' with a color indicating good coverage."
  :group 'perly-sense-faces)
(defvar ps/covered-good-face 'ps/covered-good
  "Face for underlining the 'sub' with a color indicating good coverage.")

(defface ps/covered-bad
  `((t (:inherit 'font-lock-keyword-face :underline "Red")))
  "Face for underlining the 'sub' with a color indicating bad coverage."
  :group 'perly-sense-faces)
(defvar ps/covered-bad-face 'ps/covered-bad
  "Face for underlining the 'sub' with a color indicating bad coverage.")


(defcustom ps/enable-test-coverage-visualization nil
  "Whether a Devel::CoverX::Covered database should be used to
visualize coverage information in the source code.

This requires Devel::CoverX::Covered to be installed, and that a
'covered' database is located in the project root dir. See the
docs for that module for further information."
  :type 'boolean
  :group 'perly-sense)

(defcustom ps/only-highlight-bad-sub-coverage nil
  "When true, only highlight subs that are badly
covered. I.e. don't clutter up the display when there's nothing
to do, only indicate subs that need improvements."
  :type 'boolean
  :group 'perly-sense)



(add-hook
 'cperl-mode-hook
 (lambda ()
   (run-with-idle-timer 1 nil
    (lambda ()
      (when (buffer-live-p (current-buffer))
        (ps/load-sub-coverage-quality))))))



(defadvice cperl-font-lock-fontify-region-function
  (after display-cover activate)
  "Add coverage fontification after cperl fontification"
  (when (buffer-live-p (current-buffer))
    (ps/display-all beg end)))



(defvar ps/alist-covered-subs-quality '()
  "Cache result of calling 'covered subs' for this buffer")
(make-variable-buffer-local 'ps/alist-covered-subs-quality)

(defvar ps/alist-covered-subs-quality-loaded-p nil
  "Whether the covered subs quality data is loaded or not")
(make-variable-buffer-local 'ps/alist-covered-subs-quality-loaded-p)



(defun ps/display-coverage (beg end)
  "If coverage is active, use any existing coverage information
to fontify the current region with code coverage"
  (when ps/enable-test-coverage-visualization
    (save-excursion
      (goto-char beg)
      (while (search-forward-regexp "\n *\\(sub\\) +\\([_a-z0-9]+\\)" end t)
        (let* ((sub-name (buffer-substring-no-properties (match-beginning 2) (match-end 2)))
               (sub-coverage-quality (ps/sub-coverage-quality sub-name))
               ;; (dummy (message "Quality for (%s) (%s)" sub-name sub-coverage-quality))
               (sub-face (cond
                          ((not sub-coverage-quality) nil)
                          ((= sub-coverage-quality 0) ps/covered-bad-face)
                          ((and
                            (> sub-coverage-quality 0)
                            (not ps/only-highlight-bad-sub-coverage))
                           ps/covered-good-face)
                          (t nil)
                          )
                         )
               )
          (when sub-face
            (put-text-property (match-beginning 1) (match-end 1) 'face sub-face))
          )
        )
      )
    )
  )



(defun ps/sub-coverage-quality (sub-name)
  "Return the coverage quality for sub-name, or nil if the
quality is unknown."
  (let* ((alist-sub-count (ps/alist-sub-coverage-for-buffer))
         (sub-quality (alist-value alist-sub-count sub-name))
         )
    (if sub-quality (string-to-number sub-quality) nil)
    ))



(defun ps/alist-sub-coverage-for-buffer ()
  "Return alist with (sub names . coverage quality) for the
current buffer, if loaded. Otherwise, return an empty '() alist."
  (if ps/alist-covered-subs-quality-loaded-p
      ps/alist-covered-subs-quality
    '()
    )
  )



(defun ps/load-coverage-if-active ()
  "Call 'perly_sense covered_subs' asynchronously on the buffer
file name and store the data in ps/alist-covered-subs-quality, or
store '() if there was no data returned. Fontify buffer if
appropriate.

Only get coverage data if ps/enable-test-coverage-visualization
is true and this is a cperl-mode buffer.

In any case, consider data loaded from now on.

Return t if coverage was loaded, else nil."
  (when (and ps/enable-test-coverage-visualization (string-equal major-mode "cperl-mode"))
    (lexical-let ((source-buffer (current-buffer)))
      (ps/async-command-on-current-file-location
       "covered_subs"
       (lambda (result-alist)
         (let ((message-string    (alist-value result-alist "message"))
               (alist-sub-quality (alist-value result-alist "sub_quality"))
               )
           (when message-string (message "%s" message-string))
           (when (buffer-live-p source-buffer)
             (with-current-buffer source-buffer
               (setq ps/alist-covered-subs-quality
                     (if alist-sub-quality alist-sub-quality '()))
               (setq ps/alist-covered-subs-quality-loaded-p t)
               (font-lock-fontify-buffer)
               ;; (message "Coverage information loaded")
               )))))))
  )


(defun ps/ensure-loaded-sub-coverage-quality ()
  "If needed, load coverage information."
  (unless ps/alist-covered-subs-quality-loaded-p
    (message "Loading coverage information...")
    (ps/load-coverage-if-active))
  )



(defun ps/load-sub-coverage-quality ()
  "Load coverage information and refresh buffer display"
  (interactive)
  (ps/load-coverage-if-active)
  )



(defun ps/reload-sub-coverage-quality ()
  "Reload coverage information"
  (interactive)
  (message "Reloading coverage information...")
  (ps/load-sub-coverage-quality)
  )



(defun ps/reload-sub-coverage-quality-in-all-buffers ()
  "Reload coverage information in all buffers which have it
  already loaded"
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when ps/alist-covered-subs-quality-loaded-p
        (ps/load-sub-coverage-quality))))
  )



(defun ps/display-all (beg end)
  "Fontify the current buffer with all display information"
  (interactive)
  (ps/display-coverage beg end)
  )



(defun ps/toggle-coverage-visualization ()
  "Toggle whether code coverage should be visualized inline in
the source code."
  (interactive)
  (setq ps/enable-test-coverage-visualization (not ps/enable-test-coverage-visualization))

  (if (not ps/enable-test-coverage-visualization)
      (message "Code coverage visualization: off")
    (ps/ensure-loaded-sub-coverage-quality)
    (message "Code coverage visualization: on")
    )
  (font-lock-fontify-buffer)
  )



(defun ps/enable-and-reload-coverage (buffer)
  "Enable coverage visualization and reload any existing buffer coverage information.

If BUFFER didn't have any coverage information yet, load the
coverage in that buffer. "
  (setq ps/enable-test-coverage-visualization t)
  (ps/reload-sub-coverage-quality-in-all-buffers)

  (with-current-buffer buffer
    (setq ps/enable-test-coverage-visualization nil)
    (ps/toggle-coverage-visualization)
    )
  )


;; Change this to "toggle all visualizations" when there are more
;; types
(global-set-key (format "%s\C-v" ps/key-prefix) 'ps/toggle-coverage-visualization)

(global-set-key (format "%svc" ps/key-prefix) 'ps/toggle-coverage-visualization)

(global-set-key (format "%svr" ps/key-prefix) 'ps/reload-sub-coverage-quality)





;;END
