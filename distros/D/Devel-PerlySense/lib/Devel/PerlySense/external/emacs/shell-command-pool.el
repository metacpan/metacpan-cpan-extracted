

;; Note: this isn't a pool per command. It's hard coded to use one
;; command, at a time. That's because the command in itself needs to
;; take a single line with a working dir, and a single line of input
;; to work. So that's rather special, limiting the general use.
;;
;;But it could easily become more flexible and general if needed.


(defvar scp/buffer-ready nil "Buffer object ready to run")
(defvar scp/buffer-command-running nil "Buffer object running a command")



(defun shell-command-pool ()
  "Reset a any prepared shell commands"
  (interactive)

  (and scp/buffer-ready (kill-buffer scp/buffer-ready))
  (setq scp/buffer-ready nil)

  (setq scp/buffer-command-running nil)
  (and scp/buffer-command-running (kill-buffer scp/buffer-command-running))
  )



(defun scp/prepare-shell-command (command)
  "Setup a new prepared shell command"
  (if scp/buffer-ready
      (message "Shell Command Pool already set up for (%s)" command)
    ;; TODO: Leading space to make invisible
    (let ((output-buffer (generate-new-buffer " *scp/command-shell*")))
      (start-process command output-buffer shell-file-name shell-command-switch command)
      (setq scp/buffer-ready output-buffer))
    )
  )



(defun scp/shell-command-to-string (dir command stdin-args)
  "Run 'command' using a possibly already prepared shell and
print 'stdin-args' to it. Prepare for the next call.

Return the output of running 'command', or nil on error."
  (let ((abs-dir (expand-file-name dir)))
    (if (not scp/buffer-ready) (scp/prepare-shell-command command))
    (if scp/buffer-command-running (kill-buffer
                                    scp/buffer-command-running))
    (setq scp/buffer-command-running scp/buffer-ready)
    (setq scp/buffer-ready nil)

    (let ((running-process
           (get-buffer-process scp/buffer-command-running)))
      (process-send-string
       scp/buffer-command-running
       (concat abs-dir "\n"))
      (process-send-string
       scp/buffer-command-running
       (concat stdin-args "\n"))
      (while (string= (process-status running-process) "run")
        (accept-process-output running-process)
        (sleep-for 0 100)))

    (with-current-buffer scp/buffer-command-running
      (let* (
             (raw-output (buffer-string))
             (output
             ; Added by some Emacs call-process apparently
              (replace-regexp-in-string "\nProcess[ ]+perly_sense[ ]+--stdin[ ]+\\(<[^>]*?>[ ]+\\)?finished[ ]*?\n" "" raw-output))
             \nProcess perly_sense --stdin <1> finished\n
             )
;;        (message "Pool output: (%s)" output)
        (kill-buffer scp/buffer-command-running)
        (setq scp/buffer-command-running nil)

        (scp/prepare-shell-command command)

        output))))



(provide 'shell-command-pool)

