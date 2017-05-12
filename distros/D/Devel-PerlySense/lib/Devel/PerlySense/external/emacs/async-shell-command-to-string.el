

(require 'cl)

(defun async-shell-command-to-string (command callback)
  "Execute shell command COMMAND asynchronously in the
  background.

Return the temporary output buffer which command is writing to
during execution.

When the command is finished, call CALLBACK with the resulting
output as a string.

Synopsis:
  (async-shell-command-to-string \"echo hello\" (lambda (s) (message \"RETURNED (%s)\" s)))
"
  (lexical-let
      ((output-buffer (generate-new-buffer " *temp*"))
       (callback-fun callback))
    (set-process-sentinel
     (start-process "Shell" output-buffer shell-file-name shell-command-switch command)
     (lambda (process signal)
       (when (memq (process-status process) '(exit signal))
         (with-current-buffer output-buffer
           (let ((output-string
                  (buffer-substring-no-properties
                   (point-min)
                   (point-max))))
             (funcall callback-fun output-string)))
         (kill-buffer output-buffer))))
    output-buffer))

(provide 'async-shell-command-to-string)

