
;;
;; INSTALLATION
;;
;; See the instructions at:
;; http://search.cpan.org/dist/Devel-PerlySense/lib/Devel/PerlySense.pm#Emacs_installation
;;




(load "cl-seq")  ;; find-if

(require 'gud)        ;; perldb
(require 'grep)       ;; grep-find (or rather grep-host-defaults-alist)
(require 'thingatpt)  ;; thing-at-point, etc.



(defun ps/next-line-nomark (&optional arg)
  "Deactivate mark; move cursor vertically down ARG lines.
If there is no character in the target line exactly under the current column,
the cursor is positioned after the character in that line which spans this
column, or at the end of the line if it is not long enough.
If there is no line in the buffer after this one, behavior depends on the
value of `next-line-add-newlines'.  If non-nil, it inserts a newline character
to create a line, and moves the cursor to that line.  Otherwise it moves the
cursor to the end of the buffer (if already at the end of the buffer, an error
is signaled).

The command \\[set-goal-column] can be used to create
a semipermanent goal column to which this command always moves.
Then it does not try to move vertically.  This goal column is stored
in `goal-column', which is nil when there is none."
  (interactive "p")
  (setq mark-active nil)
  (next-line arg)
  (setq this-command 'next-line))




;;;; Utilities
;(message "%s" (prin1-to-string thing))
(load "async-shell-command-to-string" nil t)

(load "shell-command-pool" nil t)
(shell-command-pool)


(defun alist-value (alist key)
  "Return the value of KEY in ALIST" ;; Surely there must be an existing defun to do this that I haven't found...
  (cdr (assoc key alist)))



(defun alist-num-value (alist key)
  "Return the numeric value of KEY in ALIST"
  (string-to-number (alist-value alist key)))



(require 'elp) ;; Benchmarking
(defmacro with-timing (&rest body)
  "Execute the forms in BODY while measuring the time.
Print the elapsed time in the echo area.

The value returned is the value of the last form in BODY."
  `(progn
     (let* ((begin-time (current-time))
            (response ,@body)
            (elapsed-time (elp-elapsed-time begin-time (current-time))))
       (message "Elapsed time (%s)" elapsed-time)
       response
       )
     ))





;; Nicked from http://blog.jrock.us/posts/Learning%20Emacs%20Lisp%20has%20paid%20off.pod
;; Thanks to Jonathan Rockway!
(defun ps/bounds-of-module-at-point ()
  "Determine where a module name starts for (thing-at-point 'perl-module)"
  (save-excursion
    (skip-chars-backward "[:alnum:]:\\->")  ; skip to F in Foo::Bar->
    (if (looking-at "[[:alnum:]:]+")        ; then get Foo::Bar
          (cons (point) (match-end 0))
      nil)))

;; allow (thing-at-point 'perl-module)
(put 'perl-module 'bounds-of-thing-at-point 'ps/bounds-of-module-at-point)

(defun ps/transient-region-as-string ()
  "Return the text of the currently selected text (if
transient-mark-mode is on) or nil if there is none"
  (if (and mark-active transient-mark-mode)
      (buffer-substring-no-properties (region-beginning) (region-end))
    nil))

(defun ps/perl-module-at-point ()
  "Return the text of the currently selected text (if
transient-mark-mode is on), or the Perl module at point, or nil
if there is none"
  (or
   (ps/transient-region-as-string)
   (thing-at-point 'perl-module)))





(defun find-buffer-name-match (match-name)
  "Return the first buffer found matching 'string-match',
or nil if none exists"
  (find-if (lambda (x) (string-match match-name (buffer-name x))) (buffer-list)))



(defun ps/switch-to-buffer (buffer)
  "Switch to BUFFER (buffer object, or buffer name). If the
buffer is already visible anywhere, re-use that visible buffer."
  (let* ((buffer-window (get-buffer-window buffer)))
    (when buffer-window
      (select-window buffer-window)
      )
    (switch-to-buffer buffer)
    )
  )



;; Probably reinventing the wheel here
(defmacro ps/with-default-directory (dir &rest body)
  "Execute the forms in BODY with the current
directory (default-directory) temporarily set to 'dir'.

The value returned is the value of the last form in BODY."
  (let ((original-dir default-directory)
        (original-buffer (current-buffer)))
    `(prog2
         (cd ,dir)
         ,@body
       (with-current-buffer ,original-buffer
         (cd ,original-dir)))))



(defun ps/active-region-string ()
  "Return the string making up the active region, or nil if no
region is active"
  (if mark-active
      (buffer-substring-no-properties (region-beginning) (region-end))
    nil))



;;;; Other modules

;; Regex Tool
(load "regex-tool" nil t)
;; Disabled: doesn't work in Emacs 29: (load "dropdown-list" nil t)


;; lang-refactor-perl
(setq
 load-path
 (cons
  (expand-file-name
   (format "%s/%s" ps/external-dir "emacs/lib")
   ) load-path))
(load "lang-refactor-perl" nil t)



;; Test::Class specific stuff
(load "perly-sense-test-class" nil t)



(defun regex-render-perl (regex sample)
  (with-temp-buffer
    (let*
        ((g-statement      ;; If /g modifier, loop over all matches
          (if (string-match "[|#!?\"'/)>}][cimosx]*?g[cimosxg]*$" regex) "while" "if"))
         (regex-line (format "%s ($line =~
m%s
) {" g-statement regex)))  ;; Insert regex spec on a separate line so it can contain Perl comments
      (insert (format "@lines = <DATA>;
$line = join(\" \", @lines);
print \"(\";
%s
  print \"(\", length($`), \" \", length($&), \" \";
  for $i (1 .. 20) {
    if ($$i) {
      print \"(\", $i, \" . \\\"\", $$i, \"\\\") \";
    }
  }
  print \")\";
}
print \")\";
__DATA__
%s" regex-line sample))
      (call-process-region (point-min) (point-max) "perl" t t)
      (goto-char (point-min))
      (read (current-buffer)))))





;; For their faces
(require 'compile)
(require 'cperl-mode)
(require 'cus-edit)



;;;; Configuration


(defgroup perly-sense nil
  "PerlySense Perl IDE."
  :prefix "ps/"
  :group 'languages
  :version "1.0")



(defcustom ps/dropdown-max-items-to-display '30
  "The maximum number of items to display in a dropdown menu. Any
more items than that, use completing read instead."
  :type 'integer
  :group 'perly-sense)



(defcustom ps/use-prepare-shell-command nil
  "Whether to use prepare-shell-command (experimental, but please
  try it) to speed things up."
  :type 'boolean
  :group 'perly-sense)



(defcustom ps/flymake-prefer-errors-in-minibuffer nil
  "Whether to display compilation error messages in the
minibuffer instead of as a popup (if your display can't display
popups, they'll always be displayed in the minibuffer).

See the POD docs for how to enable flymake."
  :type 'boolean
  :group 'perly-sense)



(defgroup perly-sense-faces nil
  "Colors."
  :link '(custom-group-link :tag "Font Lock Faces group" font-lock-faces)
  :prefix "ps/"
  :group 'perly-sense)


(defcustom ps/here-face 'font-lock-string-face
  "*Face for here-docs highlighting."
  :type 'face
  :group 'perly-sense-faces)



(defface ps/heading
  `((t (:inherit 'custom-face-tag)))
;  `((t (:inherit 'bold)))  ;
  "Face for headings."
  :group 'perly-sense-faces)
(defvar ps/heading-face 'ps/heading
  "Face for headings.")




(defface ps/module-name
  `((((class grayscale) (background light))
     (:background "Gray90"))
    (((class grayscale) (background dark))
     (:foreground "Gray80" :weight bold))
    (((class color) (background light))
     (:foreground "Blue" :background "lightyellow2"))
    (((class color) (background dark))
     (:foreground "yellow" :background ,cperl-dark-background))
    (t (:weight bold)))
  "Face for module names."
  :group 'perly-sense-faces)
(defvar ps/module-name-face 'ps/module-name
  "Face for module names.")

(defface ps/highlighted-module-name
  `((((class grayscale) (background light))
     (:background "Gray90" :weight bold))
    (((class grayscale) (background dark))
     (:foreground "Gray80" :weight bold))
    (((class color) (background light))
     (:foreground "Blue" :background "lightyellow2" :weight bold))
    (((class color) (background dark))
     (:foreground "Blue" :background, cperl-dark-background :weight bold))
    (t (:weight bold)))
  "Face for highlighted module names."
  :group 'perly-sense-faces)
(defvar ps/highlighted-module-name-face 'ps/highlighted-module-name
  "Face for highlighted module names.")

(defvar ps/bookmark-file-face compilation-info-face
  "Face for Bookmark file names.")

(defvar ps/bookmark-line-number-face 'compilation-line-number
  "Face for Bookmark line numbers.")

(defface ps/current-class-method
  `((t (:inherit 'font-lock-function-name-face)))
  "Face for methods in the current class."
  :group 'perly-sense-faces)
(defvar ps/current-class-method-face 'ps/current-class-method
  "Face for methods in the current class.")

(defface ps/current-new-method
  `((t (:inherit 'font-lock-function-name-face :weight bold)))
  "Face for new in the current class."
  :group 'perly-sense-faces)
(defvar ps/current-new-method-face 'ps/current-new-method
  "Face for new in the current class.")

(defface ps/base-class-method
  `((t (:inherit 'font-lock-keyword-face)))
  "Face for methods in the base class."
  :group 'perly-sense-faces)
(defvar ps/base-class-method-face 'ps/base-class-method
  "Face for methods in the base class.")

(defface ps/base-new-method
  `((t (:inherit 'font-lock-keyword-face :weight bold)))
  "Face for new in the base class."
  :group 'perly-sense-faces)
(defvar ps/base-new-method-face 'ps/base-new-method
  "Face for new in the base class.")

(defface ps/cpan-base-class-method
  `((t (:inherit 'font-lock-keyword-face)))
  "Face for methods in base classes outside the Project."
  :group 'perly-sense-faces)
(defvar ps/cpan-base-class-method-face 'ps/cpan-base-class-method
  "Face for methods in base classes outside the Project.")

(defface ps/cpan-base-new-method
  `((t (:inherit 'font-lock-keyword-face :weight bold)))
  "Face for new in base classes outside the Project."
  :group 'perly-sense-faces)
(defvar ps/cpan-base-new-method-face 'ps/cpan-base-new-method
  "Face for new in base classes outside the Project.")





;;;; Defuns



(defun ps/log (msg)
  "log msg in a message and return msg"
;;  (message "LOG(%s)" msg)
  )


(defun ps/current-line ()
  "Return the vertical position of point"
  (+ (count-lines 1 (point))
     (if (= (current-column) 0) 1 0)
     )
  )





;;;;

(defun ps/find-source-for-module (module)
  (let ((file (shell-command-to-string (format "perly_sense find_module_source_file --module=%s" module))))
    (if (not (string-equal file ""))
        (find-file file)
      (message "Module (%s) source file not found" module)
      nil
      )
    )
  )


(defun ps/find-source-for-module-at-point ()
  "Find the source file for the module at point."
  (interactive)
  (let ((module (or
                 (ps/perl-module-at-point)
                 (read-from-minibuffer "Find source file for module: "))))
    (if module
        (progn
          (message "Going to module %s..." module)
          (ps/find-source-for-module module)
          )
      )
    )
  )



(defun ps/fontify-pod-buffer (buffer-name)
  "Mark up a buffer with text from pod2text."
  (interactive)
  (save-excursion
    (set-buffer buffer-name)
    (goto-char (point-min))
    (while (search-forward-regexp "
 \\{4,\\}" nil t)
      (let* ((point-start (point)))
        (search-forward-regexp "
")
        (backward-char)
        (put-text-property point-start (point) 'face '(:foreground "Gray50"))   ;;TODO: Move to config variable
        )
      )
    )
  )



(defun ps/display-text-in-buffer (type name text)
  (let ((buffer-name (format "*%s %s*" type name)))
    (with-current-buffer (get-buffer-create buffer-name)
      (erase-buffer)
      (insert text)
      (goto-char 1)
      (ps/fontify-pod-buffer buffer-name)
      (display-buffer (current-buffer))
      )
    )
  )



(defun ps/parse-sexp (result)
;;  (message "RESPONSE AS TEXT |%s|" result)
  ;; TODO: check for "Error: " and display the error message
  (if (string= result "")
      '()
    (let ((response-alist (eval (car (read-from-string result)))))
      response-alist
      )
    )
  )



;;;(ps/parse-result-into-alist "'((\"class-overview\" . \"Hej baberiba [ Class::Accessor ]\") (\"class_name\" . \"Class::Accessor\") (\"message\" . \"Whatever\"))")
;;(ps/parse-result-into-alist "'((\"class_name\" . \"alpha\"))")



(defun ps/shell-command-to-string (command args-string)
  "Run command with args-string and return the response"

  (let* ((response
          (if (and ps/use-prepare-shell-command (string= command "perly_sense"))
              (scp/shell-command-to-string
               default-directory
               (concat command " --stdin ") args-string)
            (shell-command-to-string (concat command " " args-string))
            )))
;;    (message "Called (%s), got (%s)" command response)
    response
    )
)



(defun ps/command (command &optional options)
  "Call 'perly_sense COMMAND OPTIONS' and some additional default
options, and return the parsed result as a sexp"
  (unless options (setq options ""))
  (ps/parse-sexp
   (ps/shell-command-to-string
    "perly_sense"
    (format "%s --width_display=%s %s"
            command
            (- (window-width) 2)
            options
            ))))



; should use something that fontifies
(defun ps/display-pod-for-module (module)
  (let* ((result-alist
          (ps/command
           "display_module_pod"
           (format "--module=%s" module)))
         (message-string (alist-value result-alist "message"))
         (pod            (alist-value result-alist "pod"))
         )
    (if (not (string= pod ""))
        (ps/display-text-in-buffer "POD" module pod))
    (message "Nothing found")
    (when message-string
      (message "%s" message-string))
    )
  )



(defun ps/display-pod-for-module-at-point ()
  "Display POD for the module at point."
  (interactive)
  (let ((module (cperl-word-at-point)))
    (if module
        (ps/display-pod-for-module module)
      )
    )
  )



(defun ps/display-doc-message-or-buffer (doc-type name text)
  (cond ((string= doc-type "hint")
         (message "%s" text))
        ((string= doc-type "document")
         (ps/display-text-in-buffer "POD" name text)
         (message nil)
         )
        )
  t
  )





(defun ps/compile-and-then (command &optional post-compilation)
  "Run COMMAND using the compiler function.

If the POST-COMPILATION lambda is non-nil, invoke it after the
compilation has finished."
  (lexical-let
      ((post-compile-lambda0 (or post-compile-lambda (lambda () )))
       (finish-callback))
    (setq finish-callback
          (lambda (buf msg)
            (setq compilation-finish-functions (delq finish-callback compilation-finish-functions))
            (funcall post-compile-lambda0)
            ))
    (push finish-callback compilation-finish-functions)
    (compile command))
  )



(defun ps/run-file-run-command (command dir-run-from &optional post-compile-lambda)
  "Run COMMAND from DIR-RUN-FROM using the compiler function.

If POST-COMPILE-LAMBDA is non-nil, invoke it after the
compilation has finished."
  (with-temp-buffer
    (cd dir-run-from)
    (ps/compile-and-then command post-compile-lambda)
    )
  )



(defun ps/command-on-current-file-location (command &optional options)
  "Call perly_sense COMMAND with the current file and row/col,
and return the parsed result as a sexp"
  (unless options (setq options ""))
  (ps/command
   command
   (format "\"--file=%s\" --row=%s --col=%s %s"
           (buffer-file-name)
           (ps/current-line)
           (+ 1 (current-column))
           options)))



(defun ps/async-shell-command-to-string (command callback)
  "Run command asynchronously and call callback with the
response"
  (lexical-let
      ((command-string command)
       (callback-fun callback))
;;     (message "Calling (%s)" command-string)
    (async-shell-command-to-string
     command
     (lambda (response)
;;        (message "Called (%s), got (%s)" command-string response)
       (funcall callback-fun response)
       ))))



(defun ps/async-command-on-current-file-location (command callback &optional options)
  "Call perly_sense COMMAND with the current file and row/col,
call CALLBACK with the parsed result as a sexp"
  (unless options (setq options ""))
  (lexical-let ((callback-fun callback))
    (ps/async-shell-command-to-string
     (format "perly_sense %s \"--file=%s\" --row=%s --col=%s %s --width_display=%s"
             command
             (buffer-file-name)
             (ps/current-line)
             (+ 1 (current-column))
             options
             (- (window-width) 2))
     (lambda (output)
       (funcall callback-fun (ps/parse-sexp output))
       )
     )))



(defun ps/coverage-command (command)
  "Return a shell command to run COMMAND under
Devel::CoverX::Covered

Note: will currently only work in Unix-like shells because of the
way PERL5OPT is set."
  (format
   "cover -delete;
PERL5OPT=-MDevel::Cover %s;
covered runs"
   command)
  )



(defun ps/run-file-with-options (options &optional run-with-coverage)
  "Run the current file with OPTIONS passed to perly_sense"
  (let* (
         (result-alist     (ps/command-on-current-file-location "run_file" options))
         (dir-run-from     (alist-value result-alist "dir_run_from"))
         (command-run      (alist-value result-alist "command_run"))
         (type-source-file (alist-value result-alist "type_source_file"))
         (message-string   (alist-value result-alist "message")))
    (if command-run
        (progn

          ;; Test::Class integration
          (setenv "TEST_METHOD"
                  (if ps/tc/current-method
                      (format "^%s$" ps/tc/current-method)
                    nil))

          (let ((command-effective
                 (if run-with-coverage
                     (ps/coverage-command command-run)
                   command-run)
                 )
                (post-compile-lambda
                 (if run-with-coverage
                     (lambda ()
                       (ps/enable-and-reload-coverage (current-buffer)))
                   nil))
                )

            (ps/run-file-run-command
             command-effective
             dir-run-from
             post-compile-lambda)
            )
          )
      )
    (if message-string
        (message message-string)
      )
    )
  )



(defun ps/run-file (&optional use-alternate-command run-with-coverage)
  "Run the current file"
  (interactive "P")

  ;;If it's the compilation buffer, recompile, else run file
  (if (string= (buffer-name) "*compilation*")
      (progn
        (message "Recompile file...")
        (recompile)
        )

    (message "Run File...")
    (let ((alternate-command-option
           (if use-alternate-command "--use_alternate_command" "")))
      (ps/run-file-with-options alternate-command-option run-with-coverage)
      )
    )
  )



(defun ps/is-cpan-module-installed? (module-name)
  "Return t if MODULE-NAME is installed, else nil."
  (with-temp-buffer
    (shell-command (format "perl -M%s -e 1" module-name) t nil)
    ;; Empty buffer ==> no output ==> module is installed
    (eq (point-max) (point-min))))



(defun ps/ensure-cpan-module-is-installed (module-name)
  "Display error and throw exception unless
  MODULE-NAME is installed"
  (unless (ps/is-cpan-module-installed? module-name)
    (error "CPAN module (%s) is not installed." module-name)))



(defun ps/run-file-with-coverage (&optional use-alternate-command)
  "Run the current file with Devel::Cover enabled and collect
Devel::CoverX::Covered data"
  (interactive "P")
  (ps/ensure-cpan-module-is-installed "Devel::CoverX::Covered")
  (ps/run-file use-alternate-command t)
  )




(defun ps/gud-query-cmdline (command)
  (let* ((minor-mode 'perldb)
         (hist-sym (gud-symbol 'history nil minor-mode))
         (cmd-name (gud-val 'command-name minor-mode)))
    (unless (boundp hist-sym) (set hist-sym nil))
    (read-from-minibuffer
     (format "Run %s (like this): " minor-mode)
     command
     gud-minibuffer-local-map nil
     hist-sym)))



;; Copy-paste job from gud.el:perldb (shoulders of giants, etc)
(defun ps/debug-file-debug-command (command dir-debug-from)
  "Run perldb on program FILE in buffer *gud-FILE*."
  (let ((command-line (ps/gud-query-cmdline command))
        (gud-chdir-before-run nil)
        (gud-perldb-command-name command))
    (ps/with-default-directory
     dir-debug-from
     (gud-common-init command-line 'gud-perldb-massage-args 'gud-perldb-marker-filter)
     (set (make-local-variable 'gud-minor-mode) 'perldb)

     (gud-def gud-break  "b %l"         "\C-b" "Set breakpoint at current line.")
     (gud-def gud-remove "B %l"         "\C-d" "Remove breakpoint at current line")
     (gud-def gud-step   "s"            "\C-s" "Step one source line with display.")
     (gud-def gud-next   "n"            "\C-n" "Step one line (skip functions).")
     (gud-def gud-cont   "c"            "\C-r" "Continue with display.")
                                        ;  (gud-def gud-finish "finish"       "\C-f" "Finish executing current function.")
                                        ;  (gud-def gud-up     "up %p"        "<" "Up N stack frames (numeric arg).")
                                        ;  (gud-def gud-down   "down %p"      ">" "Down N stack frames (numeric arg).")
     (gud-def gud-print  "p %e"          "\C-p" "Evaluate perl expression at point.")
     (gud-def gud-until  "c %l"          "\C-u" "Continue to current line.")

     (setq comint-prompt-regexp "^  DB<+[0-9]+>+ ")
     (setq paragraph-start comint-prompt-regexp)
     (run-hooks 'perldb-mode-hook))))



(defun ps/debug-file (&optional use-alternate-command)
  "Debug the current file"
  (interactive "P")

  (if (not (buffer-file-name))
      (message "No file to debug")
    (message "Debug File...")
    (let* ((alternate-command-option
            (if use-alternate-command "--use_alternate_command" ""))
           (result-alist (ps/command-on-current-file-location
                          "debug_file"
                          alternate-command-option))
           (dir-debug-from (alist-value result-alist "dir_debug_from"))
           (command-debug (alist-value result-alist "command_debug"))
           (message-string (alist-value result-alist "message")))
      (if command-debug
          (progn
            (let ((command-debug-without-quotes
                   (replace-regexp-in-string "[\"']" "" command-debug)))
              (ps/debug-file-debug-command
               command-debug-without-quotes
               dir-debug-from))))
      (if message-string
          (message message-string)))))



(defun ps/goto-buffer-name (buffer-name)
  "Go to the currently named 'buffer-name' buffer, if any."
  (let* ((target-buffer (get-buffer buffer-name)))
    (if target-buffer
        (let* ((compilation-window (get-buffer-window target-buffer "visible")))
          (progn
            (if compilation-window (select-window compilation-window))
            (switch-to-buffer buffer-name)
            )
          )
      (message (format "There is no %s buffer to go to." buffer-name))
      nil
      )
    )
  )



(defun ps/rerun-file ()
  "Rerun the current compilation buffer"
  (interactive)
  (if (ps/goto-buffer-name "*compilation*")
      (recompile)
    (message "Can't re-run: No Run File in progress.")
    )
  )



(defun ps/display-docs-from-command (message command)
  "Message `message`, and call `command`.
Display documentation returned by the result-alist returned by
calling command."
  (message message)
  (let* ((result-alist (funcall command))
         (message-string (alist-value result-alist "message"))
         (found          (alist-value result-alist "found"))
         (name           (alist-value result-alist "name"))
         (doc-type       (alist-value result-alist "doc_type"))
         (text           (alist-value result-alist "text"))
         )
    (if (not (or (not text) (string= text "")))
        (ps/display-doc-message-or-buffer doc-type name text)
      (message "Nothing found")
      )
    (when message-string
      (message "%s" message-string))
    )
  )



(defun ps/smart-docs-at-point ()
  "Display documentation for the code at point."
  (interactive)
  (ps/display-docs-from-command
   "Smart docs..."
   '(lambda ()
      (ps/command-on-current-file-location "smart_doc"))))



(defun ps/class-method-docs (class-name method)
  "Display documentation for the 'method' of 'class-name'."
  (interactive)
  (ps/display-docs-from-command
   (format "Finding docs for method (%s)..." method)
   '(lambda ()
      (ps/command
       "method_doc"
       (format "--class_name=%s --method_name=%s --dir_origin=." class-name method)))))



(defun ps/inheritance-docs-at-point ()
  "Display the Inheritance structure for the current Class"
  (interactive)
  (message "Document Inheritance...")
  (let* ((result-alist (ps/command-on-current-file-location "inheritance_doc"))
         (message-string (alist-value result-alist "message"))
         (class-inheritance (alist-value result-alist "class_inheritance"))
         )
    (if (not class-inheritance)
        (message "No Base Class found")
      (message "%s" class-inheritance)
      )
    (if message-string
        (message message-string)
      )
    )
  )



(defun ps/use-docs-at-point ()
  "Display the used modules for the current Class"
  (interactive)
  (message "Document Uses...")
  (let* ((result-alist (ps/command-on-current-file-location "use_doc"))
         (message-string (alist-value result-alist "message"))
         (class-use (alist-value result-alist "class_use"))
         )
    (if (not class-use)
        (message "No use statements found")
      (message "%s" class-use)
      )
    (if message-string
        (message message-string)
      )
    )
  )




(defun ps/project-dir ()
  "Return the project dir of the current buffer, or nil of no
project was found"
  (let* ((result-alist (ps/command "project_dir"))
         (project-dir (alist-value result-alist "project_dir")))
    (if (string= project-dir "")
        nil
      project-dir)))


(defmacro ps/with-project-dir (&rest body)
  "Execute the forms in BODY with the current directory
temporarily set to the project dir of the current buffer.

The value returned is the value of the last form in BODY."
  (let ((dir
         (or
          (ps/project-dir)
          (progn
            (message "Could not identify a Project Directory, using current directory instead.")
            default-directory
            ))))
    `(progn
       (ps/with-default-directory
        ,dir
        ,@body))))

(defun ps/minibuffer-ack-option-filetype (new-type)
  (save-excursion
    (beginning-of-line)
    (if (re-search-forward "\\(--nocolor \\)--\\([a-z-]+\\) " nil t) ; Replace option
        (let ((existing-type (match-string 2)))
          (if (string= new-type existing-type)
              ;; Same, so toggle by removing filetype
              (replace-match "\\1" nil nil)
            ;; Not same, so replace
            (replace-match (format "\\1--%s " new-type) nil nil)
            )
          )
      (if (re-search-forward "\\(--nocolor \\)" nil t) ; Add option
          (replace-match (format "\\1--%s " new-type) nil nil)
        (message "nope"))
      )
    )
  )
(defun ps/minibuffer-ack-option-all         () (interactive) (ps/minibuffer-ack-option-filetype "all"))
(defun ps/minibuffer-ack-option-known-types () (interactive) (ps/minibuffer-ack-option-filetype "known-types"))
(defun ps/minibuffer-ack-option-perl        () (interactive) (ps/minibuffer-ack-option-filetype "perl"))
(defun ps/minibuffer-ack-option-sql         () (interactive) (ps/minibuffer-ack-option-filetype "sql"))

(defun ps/minibuffer-ack-option-toggle (option)
  (save-excursion
    (beginning-of-line)
    (if (re-search-forward (format " %s " option) nil t) ;; Found one, remove it
        (replace-match " " nil nil)
      ;; Didn't find one, add it
      (beginning-of-line)
      (if (re-search-forward (format " -- " option) nil t)
          (replace-match (format " %s -- " option) nil nil)
        )
      )
    )
  )
(defun ps/minibuffer-ack-option-toggle-caseinsensitive () (interactive) (ps/minibuffer-ack-option-toggle "-i"))
(defun ps/minibuffer-ack-option-toggle-word            () (interactive) (ps/minibuffer-ack-option-toggle "-w"))
(defun ps/minibuffer-ack-option-toggle-quote           () (interactive) (ps/minibuffer-ack-option-toggle "-Q"))

;; This key map is used inside grep-find
(define-key minibuffer-local-shell-command-map (format "%sa" ps/key-prefix) 'ps/minibuffer-ack-option-all)
(define-key minibuffer-local-shell-command-map (format "%sk" ps/key-prefix) 'ps/minibuffer-ack-option-known-types)
(define-key minibuffer-local-shell-command-map (format "%sp" ps/key-prefix) 'ps/minibuffer-ack-option-perl)
(define-key minibuffer-local-shell-command-map (format "%ss" ps/key-prefix) 'ps/minibuffer-ack-option-sql)

(define-key minibuffer-local-shell-command-map (format "%si" ps/key-prefix) 'ps/minibuffer-ack-option-toggle-caseinsensitive)
(define-key minibuffer-local-shell-command-map (format "%sw" ps/key-prefix) 'ps/minibuffer-ack-option-toggle-word)
(define-key minibuffer-local-shell-command-map (format "%sq" ps/key-prefix) 'ps/minibuffer-ack-option-toggle-quote)

(defun ps/find-project-ack-thing-at-point ()
  "Run ack from the project dir. Default to a sensible ack command line.

If there is an active region, search for that.

if there is a word at point, search for that (with -w word boundary).

If not, search for an empty string.
"
  (interactive)
  (ps/with-project-dir
   (let* ((word-only-flag "")
          (search-term (or
                        (ps/active-region-string)
                        (let ((word-at-point (find-tag-default)))
                          (if (not word-at-point)
                              nil
                            (setq word-only-flag "-w ")
                            word-at-point))
                        ""))
          (escaped-search-term (shell-quote-argument search-term))

          ;; If the string is quoted, put the cursor just inside the
          ;; quote, else at the start of the string
          (quote-offset (if (string-match "^[\"']" escaped-search-term) 1 0))

          (ack-base-command (format "ack --nopager --nogroup --nocolor --perl %s-Q -- " word-only-flag))
          (ack-command (format "%s%s" ack-base-command escaped-search-term))
          (grep-find-command   ;; For Emacs <= 22
           (cons               ;; Second item sets the initial position
            ack-command (+ 1 quote-offset (length ack-base-command))))
          (grep-host-defaults-alist  ;; For Emacs > 22, also set this
           `((localhost (grep-find-command ,grep-find-command))))
          )
   (call-interactively 'grep-find))))



(defun ps/class-method-at-point ()
  "Return the method name at (or very near) point, or nil if none was found."
  (save-excursion
    (if (looking-at "[ \n(]") (backward-char)) ;; if at end of method name, move into it
    (if (looking-at "[a-zA-Z0-9_]")                ;; we may be on a method name
        (while (looking-at "[a-zA-Z0-9_]") (backward-char))   ;; position at beginning of word
      )
    (if (looking-at ">") (backward-char))
    (if (looking-at "[\\\\-]>\\([a-zA-Z0-9_]+\\)")            ;; If on -> or \>, capture method name
        (match-string 1)
      nil
      )
    )
  )



(defun ps/method-of-method-or-object-at-point ()
  "Find name of method of method call at point. This can be:

   ->like_t|his
   $lik|e->this

Return the method name, or nil.
"
  (or
   (and  ;; $ob|ject->method
    (or
     (and (looking-back "$[a-zA-Z0-9_]*") (looking-at "[a-zA-Z0-0_]*->\\([a-zA-Z0-9_]+\\)"))
     (looking-at "$[a-zA-Z0-9_]*->\\([a-zA-Z0-9_]+\\)"))
    (buffer-substring-no-properties (match-beginning 1) (match-end 1)))
   (ps/class-method-at-point)  ;; ->me|thod
   nil
   ))



(defun ps/find-project-method-regex-at-point (regex_template)
  "Run ack from the project dir, looking for methods matching
'regex_template' of the method/word/sub at point. Default to a
sensible ack command line.

If there is a method name ->like_t|his at point, search for that method.

 (If there is a method call $lik|e->this at point, search for
that method.)

If not, search for the word at point.
"
  (ps/with-project-dir
   (let* ((method-name (or
                        (ps/method-of-method-or-object-at-point)
                        (find-tag-default)
                        ""))
          (ack-base-command (format "ack --nopager --nogroup --nocolor --perl -- "))
          (search-term (shell-quote-argument (format regex_template method-name)))
          (ack-command (format "%s%s" ack-base-command search-term))
          )
     (if (not (string= search-term ""))
         (grep-find ack-command)
       (message "No method found at point")))))



(defun ps/find-project-sub-declaration-at-point ()
  "Run ack from the project dir, looking for the method/word/sub
at point. Default to a sensible ack command line.

Look for 'method', 'sub', 'has' (somehwat simplistic atm).
"
  (interactive)
  (ps/find-project-method-regex-at-point "^\\s*(sub|method|has)\\s+[\"']?\\+?%s\\b")
)



(defun ps/find-project-method-callers-at-point ()
  "Run ack from the project dir, looking for method calls of the
method/word/sub at point. Default to a sensible ack command line."
  (interactive)
  (ps/find-project-method-regex-at-point "->\\s*%s\\b")
)



(defun ps/find-file-location (file row col)
  "Find the file and go to the row/col location. If row and/or
col is 0, the point isn't moved in that dimension."
  (push-mark nil t)
  (when file (find-file file))
  (when (> row 0) (goto-line row))
  (when (> col 0)
    (beginning-of-line)
    (forward-char (- col 1))
    )
  )



(defun ps/smart-go-to-at-point ()
  "Go to the original symbol in the code at point."
  (interactive)
  (message "Smart goto...")
  (let* ((result-alist (ps/command-on-current-file-location "smart_go_to"))
         (message-string (alist-value result-alist "message"))
         (file (alist-value result-alist "file"))
         (row (alist-value result-alist "row"))
         (col (alist-value result-alist "col"))
         )
    (if file
        (progn
          (ps/find-file-location file (string-to-number row) (string-to-number col))
          (message "Went to: %s:%s" file row))
      (message "Nothing found")
      )
    (when message-string
      (message "%s" message-string))
    )
  )




(defun ps/get-alist-from-list (list-of-alist key value)
  "Return the first alist in list which aliast's key is value, or
nil if none was found"
  (catch 'found
    (dolist (alist list-of-alist)
      (let ((alist-item-value (alist-value alist key)))
        (if (string= alist-item-value value)
            (throw 'found alist)
          nil)))))



(defun ps/choose-class-alist-from-class-list-with-dropdown (what-text class-list)
  "Let the user choose a class-alist from the lass-list of Class
definitions using a dropdown list.

Return class-alist with (keys: class_name, file, row), or nil if
none was chosen."
  (let* ((class-description-list (mapcar (lambda (class-alist)
                                    (alist-value class-alist "class_description")
                                    ) class-list))
         (n (dropdown-list class-description-list))
         )
    (if n
        (let ((chosen-class-description (nth n class-description-list)))
          (ps/get-alist-from-list
           class-list "class_description" chosen-class-description)
          )
      nil
      )
    )
  )



(defun ps/choose-class-alist-from-class-list (what-text class-list)
  "Let the user choose a class-alist from the lass-list of Class
definitions.

Return class-alist with (keys: class_name, file, row), or nil if
none was chosen."
  (ps/choose-class-alist-from-class-list-with-dropdown what-text class-list)
  )



;; Not used
(defun ps/choose-class-alist-from-class-list-with-completing-read (what-text class-list)
  "Let the user choose a class-alist from the lass-list of Class
definitions using completing read.

Return class-alist with (keys: class_name, file, row)"
  (let* ((class-description-list (mapcar (lambda (class-alist)
                                    (alist-value class-alist "class_description")
                                    ) class-list))
         (chosen-class-description (completing-read
                             (format "%s: " what-text)
                             class-description-list
                             nil
                             "force"
                             nil
                             nil
                             (car class-description-list)
                             ))
         )
    (ps/get-alist-from-list class-list "class-description" chosen-class-description)
    )
  )



(defun ps/go-to-class-alist (class-alist)
  "Go to the Class class-alist (keys: class_name, file, row)"
  (let ((class-name (alist-value class-alist "class_name"))
        (class-inheritance (alist-value class-alist "class_inheritance"))
        (file (alist-value class-alist "file"))
        (row (alist-num-value class-alist "row")))
    (ps/find-file-location file row 1)
    (message "%s" class-inheritance)
    )
  )



(defun ps/go-to-base-class-at-point ()
  "Go to the Base Class of the Class at point. If ambigous, let
the the user choose a Class."
  (interactive)
  (message "Goto Base Class...")
  (let* ((result-alist (ps/command-on-current-file-location "base_class_go_to"))
         (message-string (alist-value result-alist "message"))
         (class-list (alist-value result-alist "class_list"))
         (first-class-alist (car class-list))
         (second-class-alist (cdr class-list))
         )
    (if (not first-class-alist)
        (message "No Base Class found")
      (if (not second-class-alist)
          (ps/go-to-class-alist first-class-alist)
        (let ((chosen-class-alist
               (ps/choose-class-alist-from-class-list "Base Class" class-list)))
          (if chosen-class-alist
              (ps/go-to-class-alist chosen-class-alist)
            )
          )
        )
      )
    (if message-string
        (message message-string)
      )
    )
  )



(defun ps/find-use-module-section-position ()
  "Return the position of the end of the last use Module
statement in the file, or nil if none was found."
  (save-excursion
    (goto-char (point-max))
    (if (search-backward-regexp "^ *use +[a-zA-Z0-9][^;]+;" nil t)
        (progn
          (search-forward-regexp ";")
          (point))
      nil
      )
    )
  )



(defun ps/go-to-use-section ()
  "Set mark and go to the end of the 'use Module' section."
  (interactive)
  (message "Goto the 'use Module' section...")
  (let* ((use-position (ps/find-use-module-section-position)))
    (if (not use-position)
        (message "No 'use Module' section found")
      (push-mark)
      (goto-char use-position)
      (ps/next-line-nomark)
      (beginning-of-line)
      )
    )
  )



;; Almost identical to recompile, remove duplication
(defun ps/goto-run-buffer ()
  "Go to the current *compilation* buffer, if any."
  (interactive)
  (ps/goto-buffer-name "*compilation*")
  )



(defun ps/goto-find-buffer ()
  "Go to the current *grep* buffer, if any."
  (interactive)
  (ps/goto-buffer-name "*grep*")
  )


(defun ps/choose-from-strings-alist (prompt items-alist)
  "Let user choose amongst the strings in items-alist.

If appropriate (given the number of items in items-alist), use a
dropdown-list, otherwise a completing read with 'prompt'.

Return the chosen string, or nil if the user canceled.
"
  (if (< (length items-alist) ps/dropdown-max-items-to-display)
      (let* ((n (dropdown-list items-alist)))
        (if n
            (nth n items-alist)
          nil
          ))
    (completing-read
     (format "%s: " prompt)
     items-alist
     nil
     "force"
     nil
     nil
     (car items-alist)
     )
    )
  )



(defun ps/goto-test-other-files ()
  "Go to other test files. When in a Perl module, let user choose
amongst test files to go to. When in a test file, let user choose
amongst source files to go to.

You must have Devel::CoverX::Covered installed and have a
'covered' db for your project in the project dir."
  (interactive)
  (let* ((sub-name
          (save-excursion
            (beginning-of-line)
            (and (search-forward-regexp " *sub +\\([_a-z0-9]+\\)" (point-at-eol) t)
                 (buffer-substring-no-properties (match-beginning 1) (match-end 1)))))
         (sub-name-option
          (if sub-name (format "--sub=%s" sub-name) ""))
         (result-alist
          (ps/command-on-current-file-location "test_other_files" sub-name-option))
         (message (alist-value result-alist "message")))
    (if message
        (message "%s" message)
      (let* ((other-files-list (alist-value result-alist "other_files"))
             (project-dir (alist-value result-alist "project_dir"))
             (chosen-file (ps/choose-from-strings-alist "File: " other-files-list)))
        (if chosen-file
            (find-file (expand-file-name chosen-file project-dir)))
        )))
  )



(defun ps/goto-project-other-files ()
  "Go to other Project files. Let user choose amongst files
corresponding to the current one to go to.

You must have a File::Corresponding config file (called
.corresponding_file) in the .PerlySenseProject dir (by default).
"
  (interactive)
  (let* ((result-alist
          (ps/command-on-current-file-location "project_other_files"))
         (message (alist-value result-alist "message")))
    (if message
        (message "%s" message)
      (let* ((other-files-list (alist-value result-alist "other_files"))
             (project-dir (alist-value result-alist "project_dir"))
             (chosen-file (ps/choose-from-strings-alist "File: " other-files-list)))
        (if chosen-file
            (find-file (expand-file-name chosen-file project-dir)))
        ))
    )
  )




(defun ps/vc-project (vcs project-dir)
  "Display the Project view for the VCS (e.g. 'svn', 'none') for
the PROJECT-DIR, e.g. run svn-status for PROJECT-DIR."
  (cond
   ((string= vcs "svn")
    (message "SVN status...")
    (svn-status project-dir))
   ((string= vcs "git")
    ;; For other git modes, introduce a customization var and branch here
    (message "Magit status...")
    (condition-case nil
        (magit-status project-dir)
      (error
       (message "A Git repository was found, but the Magit mode isn't loaded"))))
   (t
    (message "No VCS...")
    (dired project-dir))
   )
  )



(defun ps/get-first-magit-status-buffer-refreshed ()
  "Return the first buffer found that is a Magit status buffer,
or nil if none exists.

If a Magit buffer is found, magit-refresh it before returning it.
"
  (let ((magit-buffer (find-buffer-name-match "^\\*magit: ")))
    (if magit-buffer
        (with-current-buffer magit-buffer (magit-refresh))
      )
    magit-buffer
    ))



(defun ps/go-to-vc-project ()
  "Go to the project view of the current Version Control, or the
project dir if there is no vc."
  (interactive)
  (message "Goto Version Control...")
  (let ((vc-buffer (or
                    (get-buffer "*svn-status*")
                    (ps/get-first-magit-status-buffer-refreshed)
                    )))  ;; (or *cvs-status*, etc)
    (if vc-buffer
        (ps/switch-to-buffer vc-buffer)
      (let* ((result-alist (ps/command "vcs_dir"))
             (project-dir (alist-value result-alist "project_dir"))
             (vcs-name (alist-value result-alist "vcs_name"))
             )
        (if (not (string= project-dir ""))
            (ps/vc-project vcs-name project-dir)
          (message "No Project dir found"))))))



(defun ps/current-package-name ()
  "Return the name of the current package statement, or nil if
  there isn't one."
  (save-excursion
    (end-of-line)
    (if (search-backward-regexp "^ *\\bpackage +\\([a-zA-Z0-9:_]+\\)" nil t)
        (let (( package-name (match-string 1) ))
          package-name)
      nil)))



(defun ps/package-name-from-file ()
  "Return the name of the current file as if it was a package
name, or return nil if not found."
  (interactive)
  (let* ((file-name (buffer-file-name)))
    (if (string-match "\\blib/\\(.+?\\)\\.pm$" file-name)
        (let* ((name-part (match-string 1 file-name)))
          (replace-regexp-in-string "/" "::" name-part)
          )
      )))



(defun ps/edit-copy-package-name ()
  "Copy (put in the kill-ring) the name of the current package
  statement, and display it in the echo area. Or, if not found,
  use the file package name."
  (interactive)
  (let ((package-name
         (or
          (ps/current-package-name)
          (ps/package-name-from-file))))
    (if package-name
        (progn
          (kill-new package-name)
          (message "Copied package name '%s'" package-name))
      (error "No package found either in the source or the file name"))))

(defun ps/current-sub-name ()
  "Return the name of the current sub, or nil if none was found."
  (save-excursion
    (end-of-line)
    (beginning-of-defun)
    (if (search-forward-regexp "\\bsub +\\([a-zA-Z0-9_]+\\)" nil t)
        (let (( sub-name (match-string 1) ))
          sub-name)
      nil)))

(defun ps/edit-copy-sub-name ()
  "Copy (put in the kill-ring) the name of the current sub, and
display it in the echo area"
  (interactive)
  (let ((sub-name (ps/current-sub-name)))
    (if sub-name
        (progn
          (kill-new sub-name)
          (message "Copied sub name '%s'" sub-name)
          )
      (error "No sub found")
      )
    )
  )

(defun ps/current-method-name ()
  "Return the 'name' of the current method, i.e. the
__PACKAGE__->SUB name, or nil if none was found."
  (save-excursion
    (let* ((package-name (ps/current-package-name))
           (sub-name (ps/current-sub-name)))
      (if (and package-name sub-name)
          (format "%s->%s" package-name sub-name)
        nil
        )
      )
    )
  )

(defun ps/edit-copy-method-name ()
  "Copy (put in the kill-ring) the name of the current method,
and display it in the echo area"
  (interactive)
  (let ((method-name (ps/current-method-name)))
    (if method-name
        (progn
          (kill-new method-name)
          (message "Copied method name '%s'" method-name)
          )
      (error "No method found")
      )
    )
  )

(defun ps/edit-copy-file-name ()
  "Copy (put in the kill-ring) the name of the current file, and
display it in the echo area"
  (interactive)
  (kill-new (buffer-file-name))
  (message "Copied file name '%s'" (buffer-file-name))
  )



(defun ps/edit-copy-package-name-from-file ()
  "Copy (put in the kill-ring) the name of the current file as if
it was a package name, and display it in the echo area"
  (interactive)
  (let* ((package-name (ps/package-name-from-file)))
    (if package-name
        (progn
          (kill-new package-name)
          (message "Copied package name '%s'" package-name)
          )
      (error "No package found, is (%s) a Perl module file in a lib directory?" (buffer-file-name)))))



(defun ps/edit-move-use-statement ()
  "If point is on a line with a single 'use Module' statement,
set mark and move that statement to the end of the 'use
Module' section at the top of the file."
  (interactive)
  (let ((message
         (catch 'message
           (save-excursion
             (end-of-line)
             (if (not (search-backward-regexp "^ *use +[a-zA-Z0-9][^\n]*?; *?$" (point-at-bol) t))
                 (throw 'message "No 'use Module' statement on this line.")
               (kill-region (match-beginning 0) (match-end 0))
               (delete-char 1)
               (push-mark)
               )
             )
           (let* ((use-position (ps/find-use-module-section-position)))
             (if (not use-position)
                 (throw 'message "No 'use Module' section found, nowhere to put the killed use statement.")
               (goto-char use-position)
               (newline-and-indent)
               (yank) (pop-mark)
               (beginning-of-line)
               (lisp-indent-line)
               )
             )
           "Set mark and moved use statement. Hit C-u C-m to return."
           )
         ))
    (if message (message "%s" message))
    )
  )



(defun ps/edit-add-use-statement ()
  "Add a 'use My::Module;' statement to the end of the 'use
 Module' section at the top of the file.

The default module name is any module name at point.
"
  (interactive)
  (let ((message
         (catch 'message
           (let* ((module-name (or
                                (ps/perl-module-at-point)
                                (read-from-minibuffer "use Module: ")))
                  (use-position (or
                                 (ps/find-use-module-section-position)
                                 (throw 'message "No 'use Module' section found, nowhere to put the killed use statement."))))
             (push-mark)
             (goto-char use-position)
             (newline-and-indent)
             (insert (format "use %s;" module-name))
             (beginning-of-line)
             (lisp-indent-line)
             (format "Added 'use %s;'. Hit C-u C-m to return." module-name)
             )
           )
         ))
    (if message (message "%s" message))
    )
  )



;; Thanks to Phil Jackson at
;; http://www.shellarchive.co.uk/Shell.html#sec21
(defun ps/increment-number-at-point (&optional amount)
  "Increment the number under point by AMOUNT.

Return a list with the items (original number, amount, new
number), or nil if there was no number at point."
  (interactive "p")
  (let ((num (number-at-point)))
    (if (numberp num)
      (let ((newnum (+ num amount))
            (p (point)))
        (save-excursion
          (skip-chars-backward "-.0123456789")
          (delete-region (point) (+ (point) (length (number-to-string num))))
          (insert (number-to-string newnum)))
        (goto-char p)
        (list num amount newnum)
        )
      nil)))



;; Thanks to Jonathan Rockway at
;; http://blog.jrock.us/articles/Increment%20test%20counter.pod
(defun ps/edit-test-count (&optional amount)
  "Increase the Test::More test count by AMOUNT"
  (interactive "p")
  (save-excursion
    (goto-char (point-min))
    (if (re-search-forward "tests\\s-+=>\\s-*[0-9]+" nil t)
        (progn
          (backward-char)
          (let ((inc-response (ps/increment-number-at-point amount)))
            (message "Test count: %s + %s = %s" (nth 0 inc-response) (nth 1 inc-response) (nth 2 inc-response))
            )
          )
      (message "Could not find a test count"))))



(defun ps/set-test-count (current-count new-count)
  "Set the Test::More test count from CURRENT-COUNT to NEW-COUNT."
  (save-excursion
    (goto-char (point-min))
    (if (re-search-forward "tests\\s-+=>\\s-*[0-9]+" nil t)
        (let ((amount (- new-count current-count)))
          (backward-char)
          (let ((inc-response (ps/increment-number-at-point amount)))
            (message "Test count: %s + %s = %s" (nth 0 inc-response) (nth 1 inc-response) (nth 2 inc-response))
            )
          )
      (message "Could not find a test count"))))



(defun ps/expected-test-count ()
  "Return the expected number of tests, or nil if that couldn't be deduced."
  (if (not (get-buffer "*compilation*"))
      nil
    (catch 'count-string
      (save-excursion
        (set-buffer "*compilation*")
        (goto-char (point-min))
        (if (re-search-forward "Files=[0-9]+, Tests=\\([0-9]+\\)" nil t)
            (throw 'count-string (string-to-number (match-string 1))))
        (if (re-search-forward "Looks like you planned \\([0-9]+\\) tests? but ran \\([0-9]+\\) extra" nil t)
            (let* ((planned-count (string-to-number (match-string 1)))
                   (extra-count (string-to-number (match-string 2)))
                   (actual-count (+ planned-count extra-count))
                   )
              (throw 'count-string actual-count)
              )
          )
        (if (re-search-forward "planned [0-9]+ tests? but \\(only \\)?ran \\([0-9]+\\)" nil t)
            (throw 'count-string (string-to-number (match-string 2))))
        (if (re-search-forward "Failed [0-9]+/\\([0-9]+\\) tests?" nil t)
            (throw 'count-string (string-to-number (match-string 1))))
        (throw 'count-string nil)))))



(defun ps/current-test-count ()
  "Return the test count of the current buffer, or nil if that couldn't be deduced."
  (save-excursion
    (goto-char (point-min))
    (and (re-search-forward "tests\\s-+=>\\s-*\\([0-9]+\\)" nil t)
         (string-to-number (match-string 1)))))



;; TODO: Duplicate defun name??
;; (defun ps/increment-number-at-point (&optional amount)
;;   "Synchronize Test::More test count with the one reported by the
;; current test run, if any"
;;   (interactive)
;;   (let
;;       ((message
;;         (catch 'message
;;           (save-excursion
;;             (let ((expected-count (ps/expected-test-count))
;;                   (current-count (ps/current-test-count)))
;;               (if (eq expected-count nil)
;;                   (throw 'message "No *compilation* buffer with a test run found."))
;;               (if (eq current-count nil)
;;                   (throw 'message "No test count found in the current buffer"))
;;               (if (= expected-count current-count)
;;                   (throw 'message
;;                          (format
;;                           "Current test count is the same as the expected count (%s)"
;;                           expected-count))
;;                 (ps/set-test-count current-count expected-count)
;;                 nil))))))
;;     (if message (message "%s" message))))



(defun ps/looking-backwards-at-comment-line ()
  (save-excursion
    (beginning-of-line)
    (if (bobp)
        nil ;; Beginning of buffer, not looking at comment
      (forward-line -1)
      (looking-at-p "\\s*?#")))
  )



(defun ps/looking-at-comment-line ()
  (save-excursion
      (beginning-of-line)
      (looking-at-p "\\s*?#")))



(defun ps/backward-to-first-comment-line ()
  "Move point back to the first line that isn't preceeded by a
non-comment line. This could mean staying in place if there is no
comment lines.

Return point, or nil if there was no comment line."
  (interactive)
  (if (ps/looking-at-comment-line)
      (progn
        (while (ps/looking-backwards-at-comment-line)
          (forward-line -1)
          )
        (beginning-of-line)
        (point))
    nil
    )
  )

(defun ps/looking-at-next-comment-line ()
  (save-excursion
    (forward-line 1)
    (if (eobp)
        nil ;; End of buffer, not looking at comment
      (beginning-of-line)
      (looking-at-p "\\s*?#")))
  )

(defun ps/forward-to-last-comment-line ()
  "Assume point is on a comment line. Move point forward to the
last line that is a comment line. This could mean staying in
place if this is the last comment line.

Return point, or nil if there was no comment line."
  (interactive)
  (progn
    (while (ps/looking-at-next-comment-line)
      (forward-line 1)
      )
    (end-of-line)
    (point))
  )

(defun ps/current-comment-region ()
  (interactive)
  "Return a two item list with the position of the beginning and
  end of the current comment block."
  (save-excursion
    (let* ((beg (ps/backward-to-first-comment-line)))
      (if beg
          (let* ((end (ps/forward-to-last-comment-line)))
            (if end
                (list beg end)
              nil))
        nil))))

(defun ps/extant-marker-for-caller (caller beg end)
  "Return '* ' if CALLER is present in the buffer between bet-end
  or '' if not."
  (save-excursion
    (goto-char beg)
    (if (search-forward-regexp (format " %s\\_>" caller) end t)
        "* "
      "")))

(defun ps/edit-find-callers-at-point-in-comment ()
  (if (save-excursion
        (beginning-of-line)
        (search-forward-regexp "\\(.*?\\)[a-zA-Z:_0-9]+->\\([a-zA-Z_0-9]+\\)" (point-at-eol) t)
        )
      ;; Insert "Finding callers of x" while working, then remove
      (let* ((prefix-string (or (match-string 1) ""))
             (indent-length (+ (length prefix-string) 4 -2)) ;; -2 is for "# "
             (indent-string (make-string indent-length ? ))
             (method-name (match-string 2))
             (comment-region (ps/current-comment-region))
             (comment-beg (car comment-region))
             (comment-end (car (cdr comment-region)))
             )
        (let* ((result-alist (ps/command-on-current-file-location
                              "find_callers"
                              (format "--sub=%s --file_origin=%s" method-name (buffer-file-name))))
               (callers (alist-value result-alist "callers"))
               (caller-string
                (mapconcat
                 ;; Check if any of these already are listed below in the comment.
                 ;; If so, prepend "* "
                 (lambda (caller)
                   (let*
                       (
                        (package (alist-value caller "package"))
                        (method (alist-value caller "method"))
                        (caller (format "%s->%s" package method))
                        (extant-marker (ps/extant-marker-for-caller
                                        caller
                                        comment-beg
                                        comment-end))
                        )
                     (format "# %s%s%s" indent-string extant-marker caller)
                     ))
                 callers
                 "\n"))
               )
          (if (string= caller-string "")
              (message "No callers found")
            (beginning-of-line)
            (open-line 1)
            (insert caller-string)

            ;; Move point to last caller
            (beginning-of-line)(forward-word)(forward-word -1)
            )
          )
        )
    (message "No method found")
    )
  )

(defun ps/edit-find-callers-at-point-in-sub ()
  (let ((sub-name (ps/current-sub-name))
        (package-name (ps/current-package-name)))
    (if (and sub-name package-name)
        (progn
          ;; Insert this method
          (end-of-line) (beginning-of-defun)
          (open-line 1)
          (insert (format "# %s->%s" package-name sub-name))

          ;; Now find callers of this method
          (ps/edit-find-callers-at-point-in-comment)
        )
      (error "No sub found.")
      )
    )
  )

(defun ps/edit-find-callers-at-point ()
  "Find callers of a method and insert them as a comment"
  (interactive)
  (if (save-excursion
        (beginning-of-line)
        (looking-at-p "^\\s*?#")
        )
      ;; If in a comment, else if in a sub
      (ps/edit-find-callers-at-point-in-comment)
    (ps/edit-find-callers-at-point-in-sub)
    )
  )
;; Special case C-o C-g: if in comment, look for a class method call

(defun ps/edit-visualize-callers-at-point ()
  "Create new buffer with a graph the call stack at point.

Create the call stack first using ps/edit-find-callers-at-point.
"
  (interactive)
  (if (save-excursion
        (beginning-of-line)
        (looking-at-p "^\\s*?#")
        )
      (let* ((comment-region (ps/current-comment-region))
             (comment-beg (car comment-region))
             (comment-end (car (cdr comment-region)))
             (comment-source
              (buffer-substring-no-properties comment-beg comment-end))
             (result-alist (ps/command-on-current-file-location
                            "visualize_callers"
                            (format "\n%s\n\n" comment-source)))
             (dummy (prin1 result-alist))
             (image-file-name (alist-value result-alist "image"))
             )
        (message "image (%s)" image-file-name)
        (if image-file-name
            (find-file-other-window image-file-name)
          (error "Error: %s" (alist-value result-alist "message"))
          )
        )
    (message "Place point in a comment wiht a call stack.\n(Create a call stack using ps/edit-find-callers-at-point)")
    )
  )
  ;;; TODO: call fn to also display any error and re-throw



(defun ps/find-method-in-buffer (method-name)
  "Find a method named METHOD-NAME in the buffer and return an
alist with (keys: row, col), or nil if no method was found."
  (save-excursion
    (beginning-of-buffer)
    (if (and
         (search-forward-regexp (format "\\(^\\| \\)sub +%s\\($\\| \\)" method-name) nil t)
         (search-backward-regexp "sub")
         )
        `(
          ("row" . ,(number-to-string (ps/current-line)))
          ("col" . ,(number-to-string (+ 1 (current-column))))
          )
      nil
      )
    )
  )



(defun ps/find-method-in-file (method-name)
  "Find a method named METHOD-NAME given the current class in the
buffer and return an alist with (keys: file, row, col), or nil if
no method was found."
  (let* ((result-alist (ps/command-on-current-file-location "method_go_to" "--method_name=new"))
         (message-string (alist-value result-alist "message"))
         (file (alist-value result-alist "file"))
         (row (alist-value result-alist "row"))
         (col (alist-value result-alist "col"))
         )
    (if row
        `(
          ("file" . ,file)
          ("row" . ,row)
          ("col" . ,col)
          )
      (when message-string
        (message "no row, message")
        (message "%s" message-string)
        )
      nil
      )
    )
  )




(defun ps/go-to-location-alist (location-alist)
  "Go to the LOCATION-ALIST which may contain the (keys: file,
row, col, class_name).

If file is specified, visit that file first.

If class_name is specified, display that class name in the echo
area."
  (let ((file (alist-value location-alist "file"))
        (row (alist-num-value location-alist "row"))
        (col (alist-num-value location-alist "col"))
        (class-name (alist-value location-alist "class_name"))
        )
    (ps/find-file-location file row col)
    (if class-name
        (message "Went to %s" class-name)
      )
    )
  )


(defun ps/go-to-method-new ()
  "Go to the 'new' method."
  (interactive)
  (message "Goto the 'new' method...")
  (let ((new-location-alist
         (or
          (ps/find-method-in-buffer "new")
          (ps/find-method-in-file "new"))))
    (if new-location-alist
        (ps/go-to-location-alist new-location-alist)
      (message "Could not find any 'new' method")
      )
    )
  )



;; todo: remove duplication between this defun and the one above
(defun ps/class-method-go-to (class-name method)
  "Go to the original symbol of 'method' in 'class-name'. Return
t on success, else nil"
  (interactive)
  (message "Go to method (%s)..." method)
  (let ((result (ps/shell-command-to-string
                 "perly_sense"
                 (format
                  "method_go_to --class_name=%s --method_name=%s --dir_origin=."
                  class-name
                  method
                  )
                 )
                ))
    (if (string-match "[\t]" result)
        (let ((value (split-string result "[\t]")))
          (let ((file (pop value)))
            (ps/find-file-location file (string-to-number (pop value)) (string-to-number (pop value)))
            (message "Went to: %s" file)
            )
          )
      (progn
        (message "Could not find method (%s) (it may be created dynamically, or in XS, or in a subclass)" method)
        nil
        )
      )
    )
  )



;; PerlySense Class major mode

;;;




(defvar ps/class-name nil "The name of the name in the current Class Overview buffer.")
(make-variable-buffer-local 'ps/class-name)



;; Set point where class-name is mentioned in current [< xxx >]
(defun ps/class-find-current-class-name (class-name)
  "Search from the buffer beginning for 'class-name'.

Return t if found, or nil if not"
  (let ((class-name-box (format "[<%s" class-name)))
    (goto-char (point-min))
    (if (search-forward class-name-box nil t)
        (progn
          (search-backward "[<" nil t)
          (forward-char)
          t)
      nil)))



(defun ps/class-find-neighbourhood ()
  "Navigate to the * NeighbourHood * in the Class Overview"
  (interactive)
  (push-mark)
  (goto-char (point-min))
  (if (search-forward "* NeighbourHood *" nil t)
      (progn
        (search-forward "[<" nil t)
        (backward-char)
        t)
    nil))



(defun ps/class-find-used ()
  "Navigate to the * Uses * in the Class Overview"
  (interactive)
  (push-mark)
  (goto-char (point-min))
  (if (search-forward "* Uses *" nil t)
      (progn
        (beginning-of-line 2)
        (forward-char)
        t)
    nil))



(defun ps/class-find-bookmarks ()
  "Navigate to the * Bookmarks * in the Class Overview"
  (interactive)
  (push-mark)
  (goto-char (point-min))
  (if (search-forward "* Bookmarks *" nil t)
      (progn
        (beginning-of-line 2)
        (if (looking-at "-")
            (beginning-of-line 2))
        t)
    nil))



(defun ps/class-find-api ()
  "Navigate to the * API * in the Class Overview.
Return t if found, else nil."
  (interactive)
  (push-mark)
  (goto-char (point-min))
  (if (search-forward "* API *" nil t)
      (progn
        (beginning-of-line 2)
        t)
    nil))



(defun ps/class-find-api-new ()
  "Navigate to the new method in the Class Overview"
  (interactive)
  (push-mark)
  (goto-char (point-min))
  (search-forward-regexp ".>new\\b" nil t)
  (backward-char 3)
  )



(defun ps/class-find-default-heading (class-name)
  "Position point at the first available heading in importance
order, e.g. first Inheritance, then Api, etc."
  (or
   (ps/class-find-current-class-name class-name)
   (ps/class-find-api)
   (ps/class-find-bookmarks)
   (ps/class-find-used)
   (ps/class-find-neighbourhood)
   nil
  ))



(defun ps/fontify-class-overview-buffer (buffer-name)
  "Mark up a buffer with Class Overview text."
  (interactive)
  (save-excursion
    (set-buffer buffer-name)

    (goto-char (point-min))
    (while (search-forward-regexp "\\[ \\w+ +\\]" nil t)
      (put-text-property (match-beginning 0) (match-end 0) 'face ps/module-name-face))

    (goto-char (point-min))
    (while (search-forward-regexp "\\[<\\w+ *>\\]" nil t)
      (put-text-property (match-beginning 0) (match-end 0) 'face ps/highlighted-module-name-face))

    (goto-char (point-min))
    (while (search-forward-regexp "^[^:\n]+:[0-9]+:" nil t)
      (let
          ((file-beginning (match-beginning 0))
           (row-end (- (match-end 0) 1)))
        (search-backward-regexp ":[0-9]+:" nil t)
        (let
            ((file-end (match-beginning 0))
             (row-beginning (+ (match-beginning 0) 1)))
          (put-text-property file-beginning file-end 'face ps/bookmark-file-face)
          (put-text-property row-beginning row-end 'face ps/bookmark-line-number-face)
          )))

    (goto-char (point-min))
    (while (search-forward-regexp "->\\w+" nil t)  ;; ->method
      (put-text-property (match-beginning 0) (match-end 0) 'face ps/current-class-method-face))

    (goto-char (point-min))
    (while (search-forward-regexp "\\\\>\\w+" nil t)  ;; \>method
      (put-text-property (match-beginning 0) (match-end 0) 'face 'font-lock-keyword-face))

    (goto-char (point-min))
    (while (search-forward-regexp "->new\\b" nil t)  ;; ->new
      (put-text-property (match-beginning 0) (match-end 0) 'face ps/current-new-method-face))

    (goto-char (point-min))
    (while (search-forward-regexp "\\\\>new\\b" nil t)  ;; \>new
      (put-text-property (match-beginning 0) (match-end 0) 'face ps/base-new-method-face))



    (goto-char (point-min))
    (while (search-forward-regexp "\\* \\w+ +\\*" nil t)
      (let
          ((heading-beginning (match-beginning 0) )
           (heading-end (match-end 0) ))
        (put-text-property heading-beginning heading-end 'face ps/heading-face)
        (add-text-properties heading-beginning (+ heading-beginning 2) '(invisible t))
        (add-text-properties (- heading-end 2) heading-end '(invisible t))
      ))
    )
  )




(defun ps/display-class-overview (class-name overview-text dir)
  (let ((buffer-name "*Class Overview*"))
    (with-current-buffer (get-buffer-create buffer-name)
;; (message "dir (%s)" dir)

      (setq default-directory dir)
      (toggle-read-only t)(toggle-read-only)  ; No better way?
      (erase-buffer)
      (insert overview-text)

      (ps/class-mode)
      (ps/fontify-class-overview-buffer buffer-name)
      (ps/class-find-default-heading class-name)
      (switch-to-buffer (current-buffer))  ;; before: display-buffer
      (toggle-read-only t)
      (setq ps/class-name class-name)  ;; Buffer local
      )
    )
  )



(defun ps/class-overview-with-argstring (argstring)
  "Call perly_sense class_overview with argstring and display Class Overview with the response"
  (interactive)
  (message "Class Overview...")
  (let* ((result-alist (ps/command "class_overview" argstring))
         (class-name (alist-value result-alist "class_name"))
         (class-overview (alist-value result-alist "class_overview"))
         (message-string (alist-value result-alist "message"))
         (dir (alist-value result-alist "dir")))
    (if class-name
        (ps/display-class-overview class-name class-overview dir))
    (if message-string
        (message message-string))))



(defun ps/class-overview-for-class-at-point ()
  "Display the Class Overview for the current class"
  (interactive)
  (ps/class-overview-with-argstring
   (format
    "--file=%s --row=%s --col=%s"
    (buffer-file-name)
    (ps/current-line)
    (+ 1 (current-column)))))



(defun ps/class-overview-x-for-class-at-point (show-what)
  "Display the Class Overview with --show=x for the current class"
  (ps/class-overview-with-argstring
   (format
    "--show=%s --file=%s --row=%s --col=%s"
    show-what
    (buffer-file-name)
    (ps/current-line)
    (+ 1 (current-column)))))



(defun ps/class-overview-inheritance-for-class-at-point ()
  "Display the Class Inheritance Overview for the current class"
  (interactive)
  (ps/class-overview-x-for-class-at-point "inheritance"))



(defun ps/class-overview-api-for-class-at-point ()
  "Display the Class API Overview for the current class"
  (interactive)
  (ps/class-overview-x-for-class-at-point "api"))



(defun ps/class-overview-bookmarks-for-class-at-point ()
  "Display the Class Bookmarks Overview for the current class"
  (interactive)
  (ps/class-overview-x-for-class-at-point "bookmarks"))



(defun ps/class-overview-uses-for-class-at-point ()
  "Display the Class Uses Overview for the current class"
  (interactive)
  (ps/class-overview-x-for-class-at-point "uses"))



(defun ps/class-overview-neighbourhood-for-class-at-point ()
  "Display the Class NeighbourHood Overview for the current class"
  (interactive)
  (ps/class-overview-x-for-class-at-point "neighbourhood"))



(defun ps/class-find-structure ()
  "Navigate to the * Structure * in the Class Overview"
  (interactive)
  (push-mark)
  (goto-char (point-min))
  (search-forward "* Structure *" nil t)
  (search-forward "-" nil t)
  (beginning-of-line 2)
  )



;; ;; Set point where class-name is mentioned in brackets
;; (defun ps/search-class-name (class-name)
;;   (let ((class-name-box (format "[ %s " class-name)))
;;     (goto-char (point-min))
;;     (search-forward class-name-box)
;;     (search-backward "[ ")
;;     (forward-char)
;;     )
;;   )








(defun ps/regex-tool ()
  "Bring up the Regex Tool"
  (interactive)
  (setq regex-tool-backend "Perl")
  (regex-tool)
  (set-buffer "*Regex*")
  (if (= (point-min) (point-max))
      (progn
        (insert "//msi")
        (goto-char 2)
        )

    )
  )



(defun ps/compile-get-file-line-from-buffer ()
  "Return a two item list with (file . row) specified on the row at
point, or an empty list () if none was found."
  ;; e.g.
  ;;  at t/unit-tests/classes/Test/App/Foo/Bar.pm line 169
  (save-excursion
    (end-of-line)
    (push-mark)
    (beginning-of-line)
    (if (search-forward-regexp
         "\\(file +`\\|at +\\)\\([/a-zA-Z0-9._ -]+\\)'? +line +\\([0-9]+\\)"
         (region-end) t)
        (let* ((file (match-string 2))
               (row (match-string 3)))
          (list file row)
          )
      (list)
      )
    )
  )



(defun ps/compile-get-file-line-from-user-input ()
  "Ask for a text to parse for a file + line, parse it using
'ps/compile-get-file-line-from-buffer'. Return what it
returns."
  (with-temp-buffer
    (insert (read-string "FILE, line N text: " (current-kill 0 t)))
    (ps/compile-get-file-line-from-buffer)
    )
  )


(defun ps/compile-goto-error-file-line ()
  "Go to the file + line specified on the row at point, or ask for a
text to parse for a file + line."
  (interactive)
  (let* ((file_row (ps/compile-get-file-line-from-buffer) )
         (file (nth 0 file_row))
         (row (nth 1 file_row)))
    (if file
        (ps/find-file-location file (string-to-number row) 1)
      (let* ((file_row (ps/compile-get-file-line-from-user-input) )
             (file (nth 0 file_row))
             (row (nth 1 file_row)))
        (if file
            (ps/find-file-location file (string-to-number row) 1)
          (message "No 'FILE line N' found")
          )
        )
      )
    )
  )



;;;;;



(defun ps/class-current-class ()
  "Return the class currenlty being displayed in the Class Overview buffer.
Use the buffer ps/class-name, or find the buffer name in the
buffer."
  (or
   ps/class-name
   (save-excursion
     (message "PS internal: Warning: looking for the class name in the buffer text (obsolete?)")
     (goto-char (point-min))
     (search-forward-regexp "\\[<\\(\\w+\\) *>\\]" nil t)
     (match-string 1))))



(defun ps/class-goto-method-at-point ()
  "Go to the method declaration for the method at point and
return t, or return nil if no method could be found at point."
  (interactive)
  (let* ((method (ps/class-method-at-point))
         (current-class (ps/class-current-class)))
    (if (and current-class method)
        (progn
          (ps/class-method-go-to current-class method)
          t
          )
      nil
      )
    )
  )



(defun ps/class-goto-bookmark-at-point ()
  "Go to the bookmark at point, if there is any.
Return t if there was any, else nil"
  (interactive)
  (message "Goto bookmark at point")
  (save-excursion
    (beginning-of-line)
    (if (search-forward-regexp "^\\([^:\n]+\\):\\([0-9]+\\):" (point-at-eol) t)
        (let ((file (match-string 1)) (row (string-to-number (match-string 2))))
          (message "file (%s) row (%s)" file row)
          (ps/find-file-location file row 1)
          t
          )
      nil
      )
    )
  )




(defun ps/find-class-name-at-point ()
  "Return the class name at point, or nil if none was found"
  (save-excursion
    (if (looking-at "[\\[]")
        (forward-char) ;; So we can search backwards without fear of missing the current char
      )
    (if (search-backward-regexp "[][]" nil t)
        (if (looking-at "[\\[]")
            (progn  ;; TODO: only match on the class name, this matches e.g. [ $blah ]
              (search-forward-regexp "\\w+" nil t)
              (match-string 0)
              )
          )
      )
    )
  )



(defun ps/class-goto-at-point ()
  "Go to the class/method/bookmark at point"
  (interactive)
  (message "Goto at point")
  (let* ((class-name (ps/find-class-name-at-point)))
         (if class-name
             (progn
               (message (format "Going to class (%s)" class-name))
               (ps/find-source-for-module class-name)
               )
           (if (not (ps/class-goto-method-at-point))
               (if (not (ps/class-goto-bookmark-at-point))
                   (message "No Class/Method/Bookmark at point")
                 )
             )
           )
         )
  )



(defun ps/class-docs-at-point ()
  "Display docs for the class/method at point"
  (interactive)
  (message "Docs at point")
  (let* ((class-name (ps/find-class-name-at-point)))
         (if class-name
             (progn
               (message (format "Finding docs for class (%s)" class-name))
               (ps/display-pod-for-module class-name)
               )
           (let* ((method (ps/class-method-at-point))  ;;;'
                  (current-class (ps/class-current-class)))
             (if (and current-class method)
                 (ps/class-method-docs current-class method)
               (message "No Class or Method at point")
               )
             )
           )
         )

  )



(defun ps/class-class-overview-at-point ()
  "Display Class Overview for the class/method at point"
  (interactive)
  (message "Class Overview at point")
  (let* ((class-name (ps/find-class-name-at-point)))
    (if class-name
        (progn
          (message (format "Class Overview for class (%s)" class-name))
          (ps/class-overview-with-argstring
           (format "--class_name=%s --dir_origin=." class-name)))
      (message "No Class at point")
      )
    )
  )



(defun ps/class-class-overview-or-goto-at-point ()
  "Display Class Overview for the class/method at point,
or go to the Bookmark at point"
  (interactive)
  (message "Class Overview at point")
  (let* ((class-name (ps/find-class-name-at-point)))
    (if class-name
        (progn
          (message (format "Class Overview for class (%s)" class-name))
          (ps/class-overview-with-argstring
           (format "--class_name=%s --dir_origin=." class-name)))
      (if (not (ps/class-goto-method-at-point))
          (if (not (ps/class-goto-bookmark-at-point))
              (message "No Class/Method/Bookmark at point"))))))



(defun ps/class-quit ()
  "Quit the Class Overview buffer"
  (interactive)
  (message "Quit")
  (kill-buffer nil)
  )



(defun ps/class-find-inheritance ()
  "Navigate to the * Inheritance * in the Class Overview"
  (interactive)
  (push-mark)
  (goto-char (point-min))
  (search-forward "* Inheritance *" nil t)
  (search-forward "[<" nil t)
  (backward-char)
  )



(defvar ps/class-mode-map nil
  "Keymap for `PerlySense Class overview major mode'.")
(if ps/class-mode-map
    ()
  (setq ps/class-mode-map (make-sparse-keymap)))
(define-key ps/class-mode-map "q" 'ps/class-quit)
(define-key ps/class-mode-map "I" 'ps/class-find-inheritance)
(define-key ps/class-mode-map "H" 'ps/class-find-neighbourhood)
(define-key ps/class-mode-map "U" 'ps/class-find-used)
(define-key ps/class-mode-map "B" 'ps/class-find-bookmarks)
(define-key ps/class-mode-map "S" 'ps/class-find-structure)
(define-key ps/class-mode-map "A" 'ps/class-find-api)
(define-key ps/class-mode-map "N" 'ps/class-find-api-new)

(define-key ps/class-mode-map "N" 'ps/class-find-api-new)
(define-key ps/class-mode-map (format "%sgn" ps/key-prefix) 'ps/class-find-api-new)

(define-key ps/class-mode-map [return] 'ps/class-class-overview-or-goto-at-point)

(define-key ps/class-mode-map "d" 'ps/class-docs-at-point)
(define-key ps/class-mode-map (format "%s\C-d" ps/key-prefix) 'ps/class-docs-at-point)

(define-key ps/class-mode-map "g" 'ps/class-goto-at-point)
(define-key ps/class-mode-map (format "%s\C-g" ps/key-prefix) 'ps/class-goto-at-point)

(define-key ps/class-mode-map "o" 'ps/class-class-overview-at-point)
(define-key ps/class-mode-map (format "%s\C-o" ps/key-prefix) 'ps/class-class-overview-at-point)





(defvar ps/class-mode-syntax-table
  (let ((st (make-syntax-table)))
    ;; Treat _ and :: as part of a word
    (modify-syntax-entry ?_ "w" st)
    (modify-syntax-entry ?: "w" st)
    st)
  "Syntax table for `ps/class-mode'.")


;; (Defvar ps/class-imenu-generic-expression
;;   ...)

;; (defvar ps/class-outline-regexp
;;   ...)

 ;;;###autoload
(define-derived-mode ps/class-mode fundamental-mode "PerlySense Class Overview"
  "A major mode for viewing PerlySense Class overview buffers."
  :syntax-table ps/class-mode-syntax-table
;;   (set (make-local-variable 'comment-start) "# ")
;;   (set (make-local-variable 'comment-start-skip) "#+\\s-*")

;;   (set (make-local-variable 'font-lock-defaults)
;;        '(ps/class-font-lock-keywords))

;;   (set (make-local-variable 'indent-line-function) 'ps/class-indent-line)
;;   (set (make-local-variable 'imenu-generic-expression)
;;        ps/class-imenu-generic-expression)
;;   (set (make-local-variable 'outline-regexp) ps/class-outline-regexp)
  )

;;; Indentation

;; (defun ps/class-indent-line ()
;;   "Indent current line of Ps/Class code."
;;   (interactive)
;;   (let ((savep (> (current-column) (current-indentation)))
;;         (indent (condition-case nil (max (ps/class-calculate-indentation) 0)
;;                   (error 0))))
;;     (if savep
;;         (save-excursion (indent-line-to indent))
;;       (indent-line-to indent))))

;; (defun ps/class-calculate-indentation ()
;;   "Return the column to which the current line should be indented."
;;   ...)



;; Key bindings
;;;; TODO: move some of these to cperl-mode local bindings

(global-set-key (format "%smf" ps/key-prefix) 'ps/find-source-for-module-at-point)  ;; Obsolete, change/remove
(global-set-key (format "%smp" ps/key-prefix) 'ps/display-pod-for-module-at-point)  ;; Obsolete, change

(global-set-key (format "%s\C-d" ps/key-prefix) 'ps/smart-docs-at-point)
(global-set-key (format "%sdi" ps/key-prefix) 'ps/inheritance-docs-at-point)
(global-set-key (format "%sdu" ps/key-prefix) 'ps/use-docs-at-point)
(global-set-key (format "%sdo" ps/key-prefix) 'ps/class-overview-for-class-at-point)

(global-set-key (format "%s\C-g" ps/key-prefix) 'ps/smart-go-to-at-point)
(global-set-key (format "%sgb" ps/key-prefix) 'ps/go-to-base-class-at-point)
(global-set-key (format "%sgu" ps/key-prefix) 'ps/go-to-use-section)
(global-set-key (format "%sgn" ps/key-prefix) 'ps/go-to-method-new)
(global-set-key (format "%sgm" ps/key-prefix) 'ps/find-source-for-module-at-point)
(global-set-key (format "%sgv" ps/key-prefix) 'ps/go-to-vc-project)

(global-set-key (format "%sfa" ps/key-prefix) 'ps/find-project-ack-thing-at-point)
(global-set-key (format "%sfs" ps/key-prefix) 'ps/find-project-sub-declaration-at-point)
(global-set-key (format "%sfc" ps/key-prefix) 'ps/find-project-method-callers-at-point)


(global-set-key (format "%secp" ps/key-prefix) 'ps/edit-copy-package-name)
(global-set-key (format "%secP" ps/key-prefix) 'ps/edit-copy-package-name-from-file)
(global-set-key (format "%secs" ps/key-prefix) 'ps/edit-copy-sub-name)
(global-set-key (format "%secm" ps/key-prefix) 'ps/edit-copy-method-name)
(global-set-key (format "%secf" ps/key-prefix) 'ps/edit-copy-file-name)
(global-set-key (format "%semu" ps/key-prefix) 'ps/edit-move-use-statement)
(global-set-key (format "%seau" ps/key-prefix) 'ps/edit-add-use-statement)
(global-set-key (format "%setc" ps/key-prefix) 'ps/edit-test-count)
(global-set-key (format "%seev" ps/key-prefix) 'lr-extract-variable)
(global-set-key (format "%seh"  ps/key-prefix) 'lr-remove-highlights)
(global-set-key (format "%sefc" ps/key-prefix) 'ps/edit-find-callers-at-point)
(global-set-key (format "%sevc" ps/key-prefix) 'ps/edit-visualize-callers-at-point)

(global-set-key (format "%sat" ps/key-prefix) 'ps/assist-sync-test-count)

(global-set-key (format "%s\C-o" ps/key-prefix) 'ps/class-overview-for-class-at-point)
(global-set-key (format "%soc" ps/key-prefix) 'ps/class-overview-for-class-at-point)
(global-set-key (format "%soi" ps/key-prefix) 'ps/class-overview-inheritance-for-class-at-point)
(global-set-key (format "%soa" ps/key-prefix) 'ps/class-overview-api-for-class-at-point)
(global-set-key (format "%sob" ps/key-prefix) 'ps/class-overview-bookmarks-for-class-at-point)
(global-set-key (format "%sou" ps/key-prefix) 'ps/class-overview-uses-for-class-at-point)
(global-set-key (format "%soh" ps/key-prefix) 'ps/class-overview-neighbourhood-for-class-at-point)

(global-set-key (format "%s\C-r" ps/key-prefix) 'ps/run-file)
(global-set-key (format "%srr" ps/key-prefix) 'ps/rerun-file)
(global-set-key (format "%src" ps/key-prefix) 'ps/run-file-with-coverage)
(global-set-key (format "%srd" ps/key-prefix) 'ps/debug-file)

(global-set-key (format "%sgf" ps/key-prefix) 'ps/goto-find-buffer)
(global-set-key (format "%sgr" ps/key-prefix) 'ps/goto-run-buffer)
(global-set-key (format "%sge" ps/key-prefix) 'ps/compile-goto-error-file-line)
(global-set-key (format "%sgto" ps/key-prefix) 'ps/goto-test-other-files)
(global-set-key (format "%sgpo" ps/key-prefix) 'ps/goto-project-other-files)

(global-set-key (format "%sar" ps/key-prefix) 'ps/regex-tool)




(load "perly-sense-visualize-coverage" nil t)
(if ps/load-flymake (load "perly-sense-flymake" nil t))



(provide 'perly-sense)



;; EOF
