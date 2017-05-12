use Config;
if ($Config{usemultiplicity}) {
  $s0 = "(interpreter :interpreter)";
  $s1 = "perl-api::*aTHX_*";
}
{
  my $fn = shift;
  my $data = join '', <DATA>;
  open my $fhout, ">$fn" or die "can't open >$fn: $!";
  binmode $fhout;
  # transform $data according to current perl configuration
  $data =~ s/\{\{\{athx\}\}\}/$s0/gm;
  $data =~ s/\{\{\{pthx\}\}\}/$s1/gm;
  # ... and out it go!
  print $fhout $data;
  #no close $fhout;
}
__DATA__
;; TODO  populate these *aTHX_* changes into the perl-in-lisp.nw file !!!!!



;;;; perlapi.lisp - CFFI definitions for the Perl C API

;;; Copyright 2006 Stuart Sierra

;;; This program is free software; you can redistribute it and/or
;;; modify it under the terms of the Lisp Lesser GNU General Public
;;; License (LLGPL) published by Franz, Inc., available at
;;; http://opensource.franz.com/preamble.html

;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; Lesser GNU General Public License for more details.

(cl:in-package :common-lisp-user)

(defpackage :perl-api
  (:use :common-lisp :cffi :cffi-address)
  (:export #:perl-alloc #:perl-construct #:perl-parse #:perl-run
           #:perl-destruct #:perl-free
           #:*pl-perl-destruct-level*
           #:sv #:any #:refcnt #:flags
           #:perl-newsv
           #:perl-newsviv #:perl-newsvuv #:perl-newsvnv
           #:perl-newsvpv #:perl-newsvpvn
           #:perl-newsvsv
           #:perl-sv-newref #:perl-sv-free
           #:svtype
           #:perl-sv-true
           #:perl-sv-2iv #:perl-sv-2uv #:perl-sv-2nv
           #:sv-flags #:perl-sv-pvn-force-flags
           #:perl-get-sv
           #:perl-sv-setsv
           #:perl-sv-setsv-flags
           #:perl-sv-setiv-mg #:perl-sv-setuv-mg #:perl-sv-setnv-mg
           #:perl-sv-setpv-mg #:perl-sv-setpvn-mg
           #:perl-newav
           #:perl-av-fetch
           #:perl-av-store
           #:perl-av-clear
           #:perl-av-undef
           #:perl-av-push
           #:perl-av-pop
           #:perl-av-unshift
           #:perl-av-shift
           #:perl-av-len
           #:perl-av-fill
           #:perl-av-delete
           #:perl-av-exists
           #:perl-newhv
           #:perl-hv-store
           #:perl-hv-fetch
           #:perl-hv-exists
           #:perl-hv-delete
           #:perl-hv-clear
           #:perl-hv-undef
           #:perl-hv-iterinit #:perl-hv-iternext #:perl-hv-iterkey
           #:perl-hv-iterkeysv #:perl-hv-iterval
           #:perl-newrv #:perl-newrv-noinc
           #:xrv #:rv
           #:*pl-stack-sp*
           #:*pl-markstack-ptr* #:*pl-markstack-max* #:*pl-stack-base* #:perl-markstack-grow
           #:*pl-stack-max* #:perl-stack-grow
           #:perl-push-scope #:perl-free-tmps #:perl-pop-scope #:perl-sv-2mortal
           #:perl-call-sv
           #:perl-call-flags
           #:perl-call-pv
           #:perl-eval-pv

           #:perl-eval-sv))

(in-package :perl-api)

;; TODO - should be configurable
(define-foreign-library libperl
  (:unix "libperl.so")
  (:windows "perl58")
  (t (:default "tell-us-your-perl-lib-name!")))
(use-foreign-library libperl)

#+WIN32 (defvar athx 1)
#+UNIX (defvar athx 0)

(defvar *aTHX_* nil)

(if (eq athx 0)
  (defmacro defperlcfun (name ret &rest args)
      (let* ((funame (substitute #\- #\_ (string-upcase name)))
	     (cname (intern (ext:string-concat "CALL-" funame) :perl-api))
	     (pname (intern funame :perl-api)))
         (eval `(defcfun ,name ,ret ,@args))
         ;(pprint (macroexpand-1 `(defcfun (,name ,funame) ,ret ,@args)))
	 (list 'defun cname (list '&rest 'argumm)
	    ;(list 'format t "name=~S funame=~S;~%" name funame)
	    `(apply #',pname argumm)) ;; or interpreter instance will be substituted here
    )))
(if (eq athx 1)
  (defmacro defperlcfun (name ret &rest args)
      (let* ((funame (substitute #\- #\_ (string-upcase name)))
	     (cname (intern (ext:string-concat "CALL-" funame) :perl-api))
	     (pname (intern funame :perl-api)))
         (eval `(defcfun ,name ,ret (interpreter :interpreter) ,@args))
	 (list 'defun cname (list '&rest 'argumm)
	    (list 'format t "name=~S funame=~S;~%" name funame)
	    `(apply #',pname *aTHX_* argumm)) ;; substitute interpreter instance
    )))

(defctype :i32 :int32)
(defctype :u32 :uint32)
(defctype :iv  :int32)
(defctype :uv  :uint32)
(defctype :nv  :double)
(defctype :pv  :pointer) ; char*
(defctype :strlen :uint32)
(defctype :interpreter :pointer :translate-p nil)
(defctype :sv :pointer)
(defcstruct sv
  (any :pointer)
  (refcnt :uint32)
  (flags :uint32))
(defcenum svtype
  :null ; undef
  :iv   ; Scalar (integer)
  :nv   ; Scalar (double float)
  :rv   ; Scalar (reference)
  :pv   ; Scalar (string)
  :pviv ; a pointer to an IV (used in hashes)
  :pvnv ; a pointer to an NV (used in hashes)
  :pvmg ; blessed or magical scalar
  :pvbm ; ??
  :pvlv ; ??
  :pvav ; Array
  :pvhv ; Hash
  :pvcv ; Code reference
  :pvgv ; typeglob (possibly a file handle)
  :pvfm ; ??
  :pvio ; an I/O handle?
  )
(defctype :av :pointer)
(defctype :hv :pointer)
(defctype :he :pointer
  :documentation "An entry in a Perl hash table")
(defcstruct xrv
  (rv :sv))
(defcfun "perl_alloc" :interpreter)

(defcfun "perl_construct" :void
  (interpreter :interpreter))

(defcfun "perl_parse" :void
  (interpreter :interpreter)
  (xsinit :pointer)
  (argc :int)
  (argv :pointer)
  (env :pointer))

(defcfun "perl_run" :int
  (interpreter :interpreter))
(defcfun "perl_destruct" :void
  (interpreter :interpreter))

(defcfun "perl_free" :void
  (interpreter :interpreter))
(defcvar "PL_perl_destruct_level" :i32)


(defcfun "Perl_newSV" :sv
  {{{athx}}}
  (size :strlen))
(defcfun "Perl_newSViv" :sv
  {{{athx}}}
  (int :iv))

(defcfun "Perl_newSVuv" :sv
  {{{athx}}}
  (uint :uv))

(defcfun "Perl_newSVnv" :sv
  {{{athx}}}
  (double :nv))
(defcfun "Perl_newSVpv" :sv
  {{{athx}}}
  (string :string)
  (length :strlen)) ; automatically computed if zero

(defcfun "Perl_newSVpvn" :sv
  {{{athx}}}
  (string :string)
  (length :strlen)) ; NOT automatically computed
(defcfun "Perl_newSVsv" :sv
  {{{athx}}}
  (scalar :sv))
(defcfun "Perl_sv_newref" :sv
  {{{athx}}}
  (scalar :sv))

(defcfun "Perl_sv_free" :void
  {{{athx}}}
  (scalar :sv))
(defcfun "Perl_sv_true" :boolean
  {{{athx}}}
  (scalar :sv))
(defcfun "Perl_sv_2iv" :iv
  {{{athx}}}
  (scalar :sv))

(defcfun "Perl_sv_2uv" :uv
  {{{athx}}}
  (scalar :sv))

(defcfun "Perl_sv_2nv" :nv
  {{{athx}}}
  (scalar :sv))
(defbitfield sv-flags
  (:immediate-unref 1)
  (:gmagic 2)
  (:cow-drop-pv 4) ; Unused in Perl 5.8.x
  (:utf8-no-encoding 8)
  (:nosteal 16))

(defcfun "Perl_sv_pvn_force_flags" :pointer
  {{{athx}}}
  (scalar :sv)
  (length :pointer) ; STRLEN*
  (flags :i32))
(defcfun "Perl_get_sv" :sv
  {{{athx}}}
  (name :string)
  (create :boolean))
(defcfun "Perl_sv_setsv" :void
  {{{athx}}}
  (destination :sv)
  (source :sv))
(defcfun "Perl_sv_setsv_flags" :void
  {{{athx}}}
  (destination :sv)
  (source :sv)
  (flags :i32))
(defcfun "Perl_sv_setiv_mg" :void
  {{{athx}}}
  (destination :sv)
  (source :iv))
(defcfun "Perl_sv_setuv_mg" :void
  {{{athx}}}
  (destination :sv)
  (source :uv))
(defcfun "Perl_sv_setnv_mg" :void
  {{{athx}}}
  (destination :sv)
  (source :nv))
(defcfun "Perl_sv_setpv_mg" :void
  {{{athx}}}
  (destination :sv)
  (source :string)
  (length :strlen)) ; automatically calculated if 0
(defcfun "Perl_sv_setpvn_mg" :void
  {{{athx}}}
  (destination :sv)
  (source :string)
  (length :strlen)) ; NOT automatically calculated
(defcfun "Perl_newAV" :av
  {{{athx}}}
	 )
(defcfun "Perl_av_fetch" :pointer
  {{{athx}}}
  (array :av)
  (key :i32)
  (create :boolean))
(defcfun "Perl_av_store" :pointer
  {{{athx}}}
  (array :av)
  (key :i32)
  (scalar :sv))
(defcfun "Perl_av_clear" :void
  {{{athx}}}
  (array :av))
(defcfun "Perl_av_undef" :void
  {{{athx}}}
  (array :av))
(defcfun "Perl_av_push" :void
  {{{athx}}}
  (array :av)
  (scalar :sv))
(defcfun "Perl_av_pop" :sv
  {{{athx}}}
  (array :av))
(defcfun "Perl_av_unshift" :void
  {{{athx}}}
  (array :av)
  (count :i32))
(defcfun "Perl_av_shift" :sv
  {{{athx}}}
  (array :av))
(defcfun "Perl_av_len" :i32
  {{{athx}}}
  (array :av))
(defcfun "Perl_av_fill" :void
  {{{athx}}}
  (array :av)
  (fill :i32))
(defcfun "Perl_av_delete" :sv
  {{{athx}}}
  (array :av)
  (key :i32)
  (flags :i32))
(defcfun "Perl_av_exists" :boolean
  {{{athx}}}
  (array :av)
  (key :i32))
(defcfun "Perl_newHV" :hv
  {{{athx}}}
	 )
(defcfun "Perl_hv_store" :pointer ; SV**
  {{{athx}}}
  (hash :hv)
  (key :string)
  (key-length :u32)
  (value :sv)
  (precomputed-hash-value :u32))
(defcfun "Perl_hv_fetch" :pointer ; SV**
  {{{athx}}}
  (hash :hv)
  (key :string)
  (key-length :u32)
  (lvalue :i32))
(defcfun "Perl_hv_exists" :boolean
  {{{athx}}}
  (hash :hv)
  (key :string)
  (key-length :u32))
(defcfun "Perl_hv_delete" :pointer ; SV**
  {{{athx}}}
  (hash :hv)
  (key :string)
  (key-length :u32)
  (flags :i32))
(defcfun "Perl_hv_clear" :void
  {{{athx}}}
  (hash :hv))
(defcfun "Perl_hv_undef" :void
  {{{athx}}}
  (hash :hv))
;; initialize an iterator for the hash
(defcfun "Perl_hv_iterinit" :i32 ; returns # of hash entries
  {{{athx}}}
  (hash :hv))

;; advance to the next hash entry
(defcfun "Perl_hv_iternext" :he
  {{{athx}}}
  (hash :hv))

;; get the key of the hash entry
(defcfun "Perl_hv_iterkey" :pointer ; char*, may contain NULL
  {{{athx}}}
  (hash-entry :he)
  (key-length :pointer)) ; I32*, length of the char*

;; same as above but creates new mortal SV to hold the key
(defcfun "Perl_hv_iterkeysv" :sv
  {{{athx}}}
  (hash-entry :he))

;; get the value of the hash entry
(defcfun "Perl_hv_iterval" :sv
  {{{athx}}}
  (hash :hv)
  (hash-entry :he))
(defcfun "Perl_newRV" :sv
  {{{athx}}}
  (thing :sv))

(defcfun "Perl_newRV_noinc" :sv
  {{{athx}}}
  (thing :sv))
(defcvar "PL_stack_sp" :address)
(defcvar "PL_markstack_ptr" :address)  ; *pl-markstack-ptr*
(defcvar "PL_markstack_max" :address)  ; *pl-markstack-max*
(defcvar "PL_stack_base" :address)     ; *pl-stack-base*
(defcfun "Perl_markstack_grow" :void  ; (perl-markstack-grow)
  {{{athx}}}
  )
(defcvar "PL_stack_max" :address)
(defcfun "Perl_stack_grow" :address
  {{{athx}}}
  (sp :address) (p :address) (n :uint))
(defcfun "Perl_push_scope" :void ; ENTER
  {{{athx}}}
  )
(defcfun "Perl_free_tmps" :void  ; FREETMPS
  {{{athx}}}
  )
(defcfun "Perl_pop_scope" :void  ; LEAVE
  {{{athx}}}
  )
(defcfun "Perl_sv_2mortal" :sv
  {{{athx}}}
  (scalar :sv))
(defcfun "Perl_call_sv" :i32
  {{{athx}}}
  (name :sv)
  (flags :i32))
(defbitfield perl-call-flags
  (:scalar   0)  ; call in scalar context
  (:array    1)  ; call in array context
  (:void   128)  ; call in void context (no return values)
  (:discard  2)  ; Call FREETMPS.
  (:eval     4)  ; Assume 'eval {}' around subroutine call.
  (:noargs   8)  ; Don't construct a @_ array.
  (:keeperr 16)  ; Append errors to $@, don't overwrite it.
  (:nodebug 32)  ; Disable debugging at toplevel.
  (:method  64)) ; Calling method. 
(defcfun "Perl_call_pv" :i32
  {{{athx}}}
  (name :string)
  (flags :i32))
(defcfun "Perl_eval_pv" :sv
  {{{athx}}}
  (code :string)
  (die-on-error :boolean))
(defcfun "Perl_eval_sv" :i32
  {{{athx}}}
  (code :sv)
  (flags :i32))

;; functions below call actual function within shared library, either
;; with interpreter as parameter, or not
(defun call-perl-eval-pv (&rest args)
  (apply 'perl-eval-pv {{{pthx}}} args))

