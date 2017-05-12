;;; extract-doctrings.el ---

;; Copyright 2008 Joseph Brenner
;;
;; Author: doom@kzsu.stanford.edu
;; Version: $Id: extract-doctrings.el,v 1.3 2008/03/26 00:06:31 doom Exp doom $
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

;;  This package provides some functions to extract the docstrings
;;  from an elisp package, and convert them into html.

;;  For more information, see the docstring for the variable
;;  extract-doctrings-documentation defined below.

;;; Code:

(provide 'extract-doctrings)
(eval-when-compile
  (require 'cl))


;;;;##########################################################################
;;;;  User Options, Variables
;;;;##########################################################################


;; =====
;; documentation
;;

(defvar extract-doctrings-documentation t
  "This is a placeholder for documentation for the extract-doctrings.el package.

  This package provides some functions to extract the docstrings
  from an elisp package, and convert them into html.
  (Note: the \"docstrings\" are the quoted strings that can be
  attached to a defun, defvar or defcustom.)

  The goal here is to be able to easily generate a web page
  from an elisp package that's documented largely by docstrings,
  which are sometimes used in preference to the more proper texinfo
  format, simply because docstrings are a little easier to write.
  A good example of a package documented this way is cperl-mode.el

  Usage:

  Put this file (extract-doctrings.el) into your load-path.

  Make the following into your ~/.emacs:

   \(require 'extract-doctrings\)

  Then you can create an html page from the doctrings for an
  elisp package, by executing the function
  extract-doctrings-generate-html-for-elisp-file like so:

    (extract-doctrings-generate-html-for-elisp-file
       \"my-elisp-library\"
       \"/tmp/my_elisp_library_doctrings.html\"
       \"Documentation for my-elisp-library.el (extracted docstrings)\")

  Note that this code presumes that the elisp library you're
  extracting docstrings from has been loaded and can be found in
  the load-path.  If that's not true, doing something like this
  first would be necessary:

    (setq load-path (cons \"/path/to/elisp/file\" load-path))
    (load-library \"extract-doctrings\")

  This package can also be run from perl, using the Emacs::Run::ExtractDocs
  module available on CPAN.
")

;; ========
;; docstring extraction code

;; The following functions make it easier to extract documentation
;; from extract-doctrings symbols and convert them into another form
;; (currently, mostly just html).

(defun extract-doctrings-generate-html-for-elisp-file ( source-library output-file html-title)
  "Generate an html file containing the doctrings from the given elisp file.
The first argument is the elisp SOURCE-LIBRARY, second is the html
OUTPUT-FILE, both should include the path to the file). The third
argument HTML-TITLE, is the title for the html document."
  (interactive "%sElisp file:\n%sOutput html file:%sHtml title:")
   (if (file-exists-p output-file) (delete-file output-file)) ;; delete first to avoid prompt
   (find-file output-file)
   ;; TODO should probably blank the buffer now also (an unsaved
   ;; one can be left by previous failed runs).
   (insert (extract-doctrings-html-header html-title))
   (extract-doctrings-dump-docstrings-as-html
    (extract-doctrings-symbol-list-from-elisp-file source-library))
    (insert (extract-doctrings-html-footer))
    (save-buffer)
    )

(defun extract-doctrings-html-header (html-title)
  "Generates a basic html header, using the given HTML-TITLE.
Uses the user-full-name function."
  (let ( ( html-header-format
"<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">
<html>
  <head>
    <title>%s</title>
    <meta name=\"author\" content=\"%s\">
  </head>

  <body>
    <h1>%s</h1>
" ) )
    (format html-header-format html-title (user-full-name) html-title)
    ))


(defun extract-doctrings-html-footer ()
  "Generates a basic html footer.
Uses the user-mail-address variable and the user-full-name function
to define contact information."
  (let ( ( html-footer-format
"    <hr>
    <address>
      <a href=\"mailto:%s\">%s</a>,
      %s
    </address>
  </body>
</html>
") )
    (format html-footer-format
            user-mail-address ;; presumes this was set in your .emacs
            (user-full-name)
            (format-time-string "%d %b %Y"))
    ))

(defun extract-doctrings-symbol-list-from-elisp-file (library)
  "Read the elisp for the given LIBRARY & extract all def* docstrings."
  (save-excursion
    (let* (
           (codefile (locate-library library))
           (work-buffer (generate-new-buffer "*extract-doctrings-work*"))
           (def-star-pat
             (concat
                      "^"        ;start of line
;;;                      "[ \t]*"   ;optional leading white space
                      "[ ]?[ ]?"  ; allow teeny bit of leading whitespace
                      "(def"     ;start of some function named def*
                      "\\(?:un\\|var\\|custom\\|const\\)" ;end of allowed def*s
                      "[ \t]+"   ;at least a little white space
                      "\\("      ;begin capture to \1
                      "[^ \t]*?" ;  symbol name: stuff that's not ws
                      "\\)"      ;end capture to \1
                      "\\(?:[ \t]+\\|$\\)"   ;a little white space or EOL
                      ))
                 ;;; I *could* keep going and read in the docstring in ""
                 ;;; but then... why would I do all this in elisp?
           symbol-list
           symbol-name)
      (set-buffer work-buffer)
      (insert-file-contents codefile nil nil nil t)
      (goto-char (point-min))
      (unwind-protect
          (while (re-search-forward def-star-pat nil t)
            (cond ((setq symbol-name (match-string 1))
                   (setq symbol-list (cons symbol-name symbol-list))
                   )))
        (kill-buffer work-buffer))
      (setq symbol-list (reverse symbol-list)))
    ))

(defun extract-doctrings-html-ampersand-subs (text)
  "Do common html ampersand code substitutions to use this TEXT safely in html.
Converts nil input to the empty string."
  (cond ((stringp text)
         (setq text (replace-regexp-in-string "&"   "&amp;"  text))
         (setq text (replace-regexp-in-string "\""  "&quot;" text))
         (setq text (replace-regexp-in-string ">"   "&gt;"   text))
         (setq text (replace-regexp-in-string "<"   "&lt;"   text))
         )
        (t ;; silently converts nils to empty string
         (setq text "")))
  text)

(defun extract-doctrings-dump-docstrings-as-html (list)
  "Given a LIST of symbol names, insert the doc strings with some HTML markup.
Preserves links in the documentation as html links: any
reference to a function or variable defined inside of this
package becomes an internal link to the appropriate named
anchor inside the html output.  External links are run through
\\[substitute-command-keys] to get the keystroke equivalent.
Formatting is preserved through the simple expedient of PRE wrappers
around all docstrings.  This spits out the main body of an html file into
the current buffer, does not generate html header or footer."

  (dolist (symbol-name list)
    (let* ( doc-string  doc-string-raw
             (symbol-value-as-variable nil)
             (symbol (intern-soft symbol-name)))
      (cond ((eq symbol nil)
             (message "warning: bad symbol-name %s" symbol-name))
            ((functionp symbol)
             (setq doc-string-raw
                   (documentation symbol t)))
            (t
             (setq doc-string-raw
                   (documentation-property symbol 'variable-documentation t))
             (setq symbol-value-as-variable
                   (extract-doctrings-html-ampersand-subs (pp-to-string (eval symbol))))
             ))

          ; Do this early (before adding any html double quotes)
          (setq doc-string (extract-doctrings-html-ampersand-subs doc-string-raw))
          ; Put named anchors on every entry for refs to link to
          (insert (format "<A NAME=\"%s\"></A>\n" symbol-name))
          (insert (concat "<P><H3>" symbol-name ":" ))
          (if (not (functionp symbol))
              (insert (concat
                       "&nbsp;&nbsp;&nbsp;&nbsp;"
                       symbol-value-as-variable )))
          (insert (concat "</h3>" "\n"))

           (setq doc-string
                 (extract-doctrings-htmlicize-variable-references doc-string list))

           (setq doc-string
                 (extract-doctrings-htmlicize-function-references doc-string list))

          (insert (concat "<PRE>\n" doc-string "</PRE></P>\n\n"))
          )))


(defun extract-doctrings-htmlicize-function-references (doc-string internal-symbols)
  "Transform function references in a DOC-STRING into html form.
Requires a list of INTERNAL-SYMBOLS, to identify whether a function
reference can jump to another docstring from the same .el file, or
if it's a pointer to something from another package.
External pointers are turned into keystroke mappings in the same
style as is used in the *Help* buffer.
Internally used by extract-doctrings-dump-docstrings-as-html-exp."
  (let (
        ; define constants
        (func-ref-pat "\\\\\\[\\(.*?\\)\\]") ; that's \[(.*?)]   (one hopes)
        (open-link "<A HREF=\"#")
        (mid-link  (concat "\"" ">"))
        (close-link "</A>")
        ; initialize
        (start-search 0)
        ; declare
        symb-name ; symbol name, searched for with the find-var-ref-pat
        beg end ; end points of the symbol name in the doc-string
        tranny ; the transformed form of the reference to be used in output
        adjust ; length change in the doc-string after a link is swapped in
        )

    (while (setq beg (string-match func-ref-pat doc-string start-search))
      (setq symb-name (match-string 1 doc-string))
      (setq end (match-end 0))
      (cond ((member symb-name internal-symbols) ; Is the reference internal or external?
             (setq tranny      ; html link to internal label
                   (concat open-link symb-name mid-link symb-name close-link)))
            (t
             (setq tranny        ; usual *help* display form
                   (concat " "
                           "<I>"
                           (substitute-command-keys (concat "\\[" symb-name "]"))
                           "</I>"
                           " "))))
      (setq doc-string
            (concat
             (substring doc-string 0 beg)
             tranny
             (substring doc-string end)
             ))
      (setq symb-length (length symb-name))
      (setq adjust (- (length tranny) symb-length 3)) ; here 3 is for the 3 chars: \[]
      (setq start-search (+ end adjust))
      ))
  doc-string)


(defun extract-doctrings-htmlicize-variable-references (doc-string internal-symbols)
  "Transform variable references in a DOC-STRING into html form.
Requires a list of INTERNAL-SYMBOLS, to identify whether a function
reference can jump to another docstring from the same .el file, or
if it's a pointer to something from another package.
External references are simply indicated with italics.
Internally used by extract-doctrings-dump-docstrings-as-html-exp."
  (let (
        ; define constants
        (var-ref-pat "[`]\\(.*?\\)'") ; that's `(.*?)'
        (open-link "<A HREF=\"#")
        (mid-link  (concat "\"" ">"))
        (close-link "</A>")
        ; initialize
        (start-search 0)
        ; declare
        symb-name ; symbol name, searched for with the find-var-ref-pat
        beg end ; end points of the symbol name in the doc-string
        tranny ; the transformed form of the reference to be used in output
        adjust ; length change in the doc-string after a link is swapped in
        )

    (while (setq beg (string-match var-ref-pat doc-string start-search))
      (setq symb-name (match-string 1 doc-string))
      (setq end (match-end 0))
      (cond ((member symb-name internal-symbols) ; Is the reference internal or external?
             (setq tranny      ; html link to internal label
                   (concat open-link symb-name mid-link symb-name close-link)))
            (t
             (setq tranny        ; usual *help* display form
                   (concat "<STRONG>"
                           symb-name
                           "</STRONG>"
                           ))))
      (setq doc-string
            (concat
             (substring doc-string 0 beg)
             tranny
             (substring doc-string end)
             ))
      (setq symb-length (length symb-name))
      (setq adjust (- (length tranny) symb-length 2)) ; here 2 is for the 2 chars: `'
      (setq start-search (+ end adjust))
      ))
  doc-string)


(defun extract-doctrings-fixdir (dir)
  "Fixes the DIR, making the directory path more portable & robust."
  ; Note: this is a well tested function: /home/doom/End/Cave/EmacsDocs/lib/perl/t/extract-doctrings.t
  (let ((return
  (convert-standard-filename
   (file-name-as-directory
    (file-truename
    (substitute-in-file-name dir))))))
    return))


;; (defun extract-doctrings-trial-run ()
;;   "Trial run.  Just for experimental purposes, you understand."
;;   (interactive)
;;   (let* (
;;          (source-library "image-dired")
;;          (source-file "/home/doom/End/Cave/DiredExternalApps/lib/emacs/image-dired.el")
;;          (source-file-loc (file-name-directory source-file))
;;          (output-file "/home/doom/tmp/image-dired.html")
;;          (html-title "Documentation for image-dired.el (extracted docstrings)")
;;          )
;;     (setq load-path (cons source-file-loc load-path))
;;     (load-library source-file)
;;     (extract-doctrings-generate-html-for-elisp-file source-library output-file html-title)
;;     ))

;; ;;(extract-doctrings-trial-run)


;;;==========================================================

;;; extract-doctrings.el ends here

;;  TODO

;;  o  Switch from hardcoded html header/footer to a standard
;;     template system (tempo/skeleton)?

;;  o  Support multiple output formats (texinfo?).
;;     Pick a better intermediate data representation than html?
;;     (xml/yaml/etc).

;;; o   Currently, external refs become dead text (keystroke mappings in italics).
;;;     Perhaps it would be better to automatically generate
;;;     a footnote section with docstrings for external refs.
;;;     Alternately: generate an entire file for any package referenced externally.

;; o   Ultimately, wwould like to be able to work on a *list* of packages,
;;     where pointers outside the set would be handled differently
;;     from pointers inside the set.

;; o   Work on automated tests of the header generators, perhaps...
;;     (would need to feed in a dummy user name, see technique in use in
;;     the Emacs::Run tests)
;;     Add to here (or create a new one):
;;       ~/End/Cave/EmacsPerl/Wall/Emacs-Run-ExtractDocs/t/00-extract-doctrings-elisp.t

