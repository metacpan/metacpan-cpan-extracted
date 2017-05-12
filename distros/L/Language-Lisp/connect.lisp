(format t "yep, I (connect.lisp) will try performing connection!
connection is done w/o sockets, at CFFI level!
currently things set up to run from current directory w/o installation
so...
")

(load (string-concat (getenv "HOME") "/" ".clisprc.lisp")  :if-does-not-exist nil)

(asdf:operate 'asdf:load-op :cffi)

(load  "address.lisp")
(load  "perlapi.lisp")
(load  "perl-in.lisp")

(in-package :perl)


;
; in win32 - boot_DynaLoader in perl58.dll (perllib)
; in linux - shared lib should be created where it will be linked
;get 'xs_init' function out from xsinit.dll
;define-foreign-library
;load-foreign-library
(pushnew #+UNIX #P"blib/arch/auto/Language/Lisp/"
	 #+WIN32 #P"blib\\arch\\auto\\Language\\Lisp\\"
	 cffi:*foreign-library-directories* :test #'equal)
(cffi:load-foreign-library 
   '(:default "Lisp"))
(cffi:defcfun ("xs_init" xs-init) :void)
(cffi:defcfun ("lisp_init" lisp-init) :void
  (cb :pointer))

(cffi:defcfun "create_lisp_sv" :sv
  (pkg_name :string)
  (lisp_name :string))
(cffi:defcfun "eval_wrapper" :av
  (code :string))
(cffi:defcfun "call_wrapper" :av
  (fun :sv)
  (args :sv))

(cffi:defcallback l-xsinit :void ((athx_ :interpreter))
	; do the call
	;   newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, file);
	; (currently do this from the C side, then may be move to LISP)
		     (xs-init))
(setq perl::*perl-xsinit* (get-callback 'l-xsinit))

;;check if dyna-loading worked
;(format t "before ttst~%")
;(cffi:defcfun ("ttst" ttst) :int)
;(print (ttst))

(cffi:defcallback lisp-eval :sv ((s :string))
    (perl-from-lisp (eval (read-from-string s))))
(lisp-init (get-callback 'lisp-eval))

(perl::need-perl)
