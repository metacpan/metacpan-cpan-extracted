
;;;; Test::Class support for PerlySense


(defvar ps/tc/current-method nil
  "The current TEST_METHOD in this buffer")
(make-variable-buffer-local 'ps/tc/current-method)



(defun ps/tc/toggle-current-sub ()
  "Make the sub near point the 'current method', or clear the
'current method' if it's already current."
  (interactive)
  (let ((method-name (ps/get-nearby-sub)))
    (if method-name
        (ps/tc/toggle-current-method method-name)
      (message "No Test::Class method found")
      )))

(defun ps/tc/toggle-current-method (method-name)
  (if (string-equal ps/tc/current-method method-name)
      (progn
        (setq method-name nil)
        (message "Test::Class method: -none-")
        )
    (message "Test::Class method: %s"
             (propertize method-name 'face 'font-lock-function-name-face))
    )
  (setq ps/tc/current-method method-name)
  (ps/tc/redisplay-method method-name)
  )

(defun ps/get-nearby-sub ()
  (let ((sub-name
          (save-excursion
            (end-of-line)
            (and (search-backward-regexp " *sub +\\([_a-z0-9]+\\)" (point-min) t)
                 (buffer-substring-no-properties (match-beginning 1) (match-end 1)))))
         )
    sub-name
    ))

(defun ps/sub-pos (sub-name)
  "Return the buffer position of 'sub sub-name', or nil if none
was found."
  (let ((sub-pos
          (save-excursion
            (goto-char (point-min))
            (and (search-forward-regexp (format " *sub +%s[^_a-z0-9]" sub-name) (point-max) t)
                 (match-beginning 0)))))
    sub-pos))

(defvar ps/tc/current-method-overlay nil
  "The overlay for the current method ")
(make-variable-buffer-local 'ps/tc/current-method-overlay)

(defun ps/tc/redisplay-method (method-name)
  (remove-overlays (point-min) (point-max) 'test-class-method t)

  (let ((sub-pos (ps/sub-pos method-name)))
    (if sub-pos
        (progn
          (setq ps/tc/current-method-overlay (make-overlay sub-pos sub-pos))
          (overlay-put ps/tc/current-method-overlay 'test-class-method t)
          (overlay-put ps/tc/current-method-overlay 'before-string
                       (propertize "Test::Class --> " 'face 'font-lock-comment-face))
          ))))


(global-set-key (format "%stm" ps/key-prefix) 'ps/tc/toggle-current-sub)


; (message "(%s)" ps/tc/current-method)


;;END
