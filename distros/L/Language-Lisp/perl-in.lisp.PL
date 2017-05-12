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
;; TODO  populate these aTHX_ changes into the perl-in-lisp.nw file !!!!!

;;;; Perl-in.lisp - Lisp interface to the Perl API

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

(defpackage :perl-in-lisp
  (:use :common-lisp :cffi :cffi-address :perl-api)
  (:nicknames :perl)
  (:export #:start-perl #:stop-perl
           #:call-perl
           #:ev))

(in-package :perl-in-lisp)
(defvar *perl-interpreter* nil)

(defvar *sv-type-mask* #Xff)
(defmacro perl-scope (&body body)
  (let ((return-symbol (gensym)))
    `(progn 
       (perl-push-scope {{{pthx}}})  ; ENTER
       ;; SAVETMPS omitted
       (let ((,return-symbol (progn ,@body))) ; execute body
         (perl-free-tmps) ; FREETMPS
         (perl-pop-scope) ; LEAVE
         ,return-symbol))))
(defvar *perl-xsinit* (null-pointer))
(defun make-interpreter ()
  (let ((interpreter (perl-alloc))
        (arguments (foreign-alloc :pointer :count 3)))
    (perl-construct interpreter)
    (setf (mem-aref arguments :pointer 0) (foreign-string-alloc ""))
    (setf (mem-aref arguments :pointer 1) (foreign-string-alloc "-e"))
    (setf (mem-aref arguments :pointer 2) (foreign-string-alloc "0"))
    (perl-parse interpreter *perl-xsinit*
                3 arguments (null-pointer))
    (let ((run (perl-run interpreter)))
      (unless (zerop run)
        (error "perl_run failed (return value: ~A)" run)))
    interpreter))
(defun destroy-interpreter (interpreter)
  (setf *pl-perl-destruct-level* 1)
  (perl-destruct interpreter)
  (perl-free interpreter))
(declaim (inline need-perl))

(defun need-perl ()
  (unless *perl-interpreter* (start-perl)))
(defun refcnt (scalar)
  (foreign-slot-value scalar 'sv 'refcnt))
(defun svtype (scalar)
  (foreign-enum-keyword
   'svtype
   (logand (foreign-slot-value scalar 'sv 'flags)
           *sv-type-mask*)))
(defun string-from-sv (sv)
  (with-foreign-object (length :strlen)
    (foreign-string-to-lisp
        (perl-api::perl-sv-pvn-force-flags {{{pthx}}} sv length
                                 (foreign-bitfield-value
                                  'sv-flags '(:gmagic)))
        (mem-ref length :strlen)
        nil))) ; null-teminated-p
(defun set-sv (destination source &rest flags)
  (perl-api::perl-sv-setsv-flags {{{pthx}}} destination source
                       (foreign-bitfield-value
                        'sv-flags flags)))
(defun get-scalar-by-name (name)
  (perl-api::perl-get-sv {{{pthx}}} name t))
(defun av-fetch-sv (array key create)
  (let ((ptr (perl-api::perl-av-fetch {{{pthx}}} array key create)))
    (if (null-pointer-p ptr) nil
      (mem-ref ptr :pointer))))
(defun perl-aref (array index)
  (lisp-from-perl (av-fetch-sv array index t)))
(defun list-from-av (av)
  (loop for i from 0 upto (perl-api::perl-av-len {{{pthx}}} av)
        collecting (perl-aref av i)))
(defun hash-from-hv (perl-hash)
  (perl-scope ;; because SVs may be mortal copies
   (let ((lisp-hash (make-hash-table :test #'equal))
         (size (perl-api::perl-hv-iterinit {{{pthx}}} perl-hash)))
     (loop repeat size
           do (let ((entry (perl-api::perl-hv-iternext {{{pthx}}} perl-hash)))
                (setf (gethash (string-from-sv ; does not work w/ lisp-from-perl, why?
                                (perl-api::perl-hv-iterkeysv {{{pthx}}} entry))
                               lisp-hash)
                      (lisp-from-perl
                       (perl-api::perl-hv-iterval {{{pthx}}} perl-hash entry)))))
     lisp-hash)))
(defun hv-from-hash (lisp-hash)
  (let ((perl-hash (perl-api::perl-newhv {{{pthx}}})))
    (maphash #'(lambda (key value)
                 (let ((string-key (string key)))
                   (with-foreign-string
                    (cstring string-key)
                    (perl-api::perl-hv-store {{{pthx}}} perl-hash
                                   cstring
                                   (length string-key)
                                   (perl-from-lisp value)
                                   0))))
             lisp-hash)
    perl-hash))
(defun deref-rv (ref)
  (foreign-slot-value (foreign-slot-value ref 'sv 'any)
                      'xrv 'rv))

;; following functions operating with Perl stack do not work, because
;; perl has external symbols with different names in different
;; configurations...
;; this could placed in some var and configured at build time,
;; but we're not getting much useful out from this dangerous
;; dance with stack.
;(defun pushmark ()
;  (when (= (address-incf *pl-markstack-ptr*) *pl-markstack-max*)
;    (perl-markstack-grow))
;  (setf (address-ref *pl-markstack-ptr* :address)
;        (- *pl-stack-sp* *pl-stack-base*)))
;(defun ensure-room-on-stack (n)
;  (when (< (- *pl-stack-max* *pl-stack-sp*) n)
;    (setf *pl-stack-sp*
;          (perl-stack-grow *pl-stack-sp* *pl-stack-sp* n))))
;(defun pushs (scalar)
;  "Push a scalar value (a pointer) onto the Perl stack."
;  (ensure-room-on-stack 1) ; EXTEND
;  (setf (address-ref (address-incf *pl-stack-sp*) :address)
;        (pointer-address scalar)))
;(defun pops ()
;  "Pop a scalar pointer off the Perl stack."
;  (prog1
;      (address-ref *pl-stack-sp* :pointer)
;    (address-decf *pl-stack-sp*)))
;(defun push-mortals-on-stack (args)
;  (loop for arg in args
;        do (pushs (perl-sv-2mortal {{{pthx}}} (perl-from-lisp arg)))))
;(defun get-from-stack (n)
;  (nreverse (loop repeat n
;                  collecting (lisp-from-perl (pops)))))
;(defun get-stack-values (n)
;  (values-list (get-from-stack n)))
;(defun perl-call-scalar (scalar flags)
;  (perl-api::perl-call-sv {{{pthx}}} scalar (foreign-bitfield-value
;                         'perl-call-flags flags)))

(defun perl-call-function (name flags)
  (perl-api::perl-call-pv {{{pthx}}} name (foreign-bitfield-value
                         'perl-call-flags flags)))
(defun context-from-type (type)
  (cond
   ((null type) :void)
   ((find type '(:integer :float :string t)) :scalar)
   ((find type '(:list :array :alist :hash)) :array)
   (t (error "No Perl calling context for type ~a" type))))
(defun calling-flags (type methodp)
  (let ((flags (list :eval (context-from-type type))))
    (when methodp (push :method flags))
    flags))
(defun get-stack-by-type (type count)
  (declare (ignore type)) ;; fix me
  (get-stack-values count))
(defun perl-eval-scalar (scalar flags)
  (perl-api::perl-eval-sv {{{pthx}}} scalar (foreign-bitfield-value
                        'perl-call-flags flags)))
;(defun ev (code)
;  (lisp-from-perl (perl-api::call-perl-eval-pv code t))) ;; TODO free given SV
(defun ev (code)
    (lisp-from-perl (eval-wrapper (perl-sv-2mortal {{{pthx}}} (perl-api::perl-newsvpv {{{pthx}}} code 0)))))

;obsolete:
(defun eval-perl (code)
  (need-perl)
  (perl-scope
   (get-stack-values
    (perl-eval-scalar (perl-sv-2mortal {{{pthx}}} (perl-api::perl-newsvpv {{{pthx}}} code 0))
                      '(:scalar :eval)))))

(defgeneric perl-from-lisp (value))

(defmethod perl-from-lisp ((value integer))
  (need-perl)
  (cond
   ((and (<= 0 value 4294967295)) ;; 32-bit unsigned integers
    (perl-api::perl-newsvuv {{{pthx}}} value))
   ((and (> 0 value -2147483648)) ;; 32-bit signed integers
    (perl-api::perl-newsviv {{{pthx}}} value))
   (t (if nil
	 (error "Integer value out of range for Perl;
BigInts not supported (TODO - use BigInt)")
	 (perl-api::perl-newsvpv {{{pthx}}} (prin1-to-string value) 0)) ;; pass it as string TODO bless to Lisp::BigInt
	 )))

(defmethod perl-from-lisp ((value symbol))
  (need-perl)
  (create-lisp-sv "Symbol" (prin1-to-string value))) ;; bless to the proper package (Lisp::Language::Symbol)

(defmethod perl-from-lisp ((value float))
  (need-perl)
  (perl-api::perl-newsvnv {{{pthx}}}
   ;; ensure VALUE is a double-float
   (float value 1.0d0)))

(defmethod perl-from-lisp ((value string))
  (need-perl)
  (perl-api::perl-newsvpv {{{pthx}}} value 0))

(defmethod perl-from-lisp ((value list))
  (let ((a (perl-newav {{{pthx}}})))
    (loop for i in value
          ;; Perl's "push" pushes to the *end* of the array
          do (perl-api::perl-av-push {{{pthx}}} a (perl-from-lisp i)))
    a))

(defmethod perl-from-lisp ((value hash-table))
  (hv-from-hash value))
(defmethod perl-from-lisp ((value null)) ; NIL isn't a class; NULL is
  (perl-api::perl-newsv {{{pthx}}} 0))
(defun lisp-from-perl (p)
  (prin1 (svtype p)) ;;; debug VVVVV * * * * * * * * * * * * * * *
  (ecase (svtype p)
    (:null nil)
    (:iv (perl-api::perl-sv-2iv {{{pthx}}} p))
    (:nv (perl-api::perl-sv-2nv {{{pthx}}} p))
    (:rv (lisp-from-perl (deref-rv p)))
    (:pv (string-from-sv p))
    (:pviv (cffi:mem-ref p :iv))
    (:pvnv (cffi:mem-ref p :nv))
    (:pvmg (error "Blessed or magical scalars not supported yet")) ;; but we'll support 'Language::Lisp::' package ;;
    (:pvav (list-from-av p))
    (:pvhv (hash-from-hv p))))
(defun start-perl ()
  (unless *perl-interpreter*
    (setq *perl-interpreter* (make-interpreter))
    (setq perl-api::*aTHX_* *perl-interpreter*))
  (values))

(defun stop-perl ()
  (when *perl-interpreter*
    (destroy-interpreter *perl-interpreter*)
    (setq *perl-interpreter* nil)
    (setq {{{pthx}}} nil))
  (values))

(defun call (function &rest args)
  (lisp-from-perl
   (funcall 'call-wrapper
     (if (stringp function)
         (perl-from-lisp function)
           ;; SV - anonymous sub, or sub name
          function)
     ;(loop for arg in args collecting (perl-from-lisp arg))
     (perl-from-lisp args)
     )))

;; (defun call-perl (function return-type methodp &rest args)
;;   (need-perl)
;;   (perl-scope 
;;    (pushmark)
;;    (push-mortals-on-stack args)
;;    (get-stack-by-type
;;     return-type
;;     (funcall (if (stringp function) #'perl-call-function
;;                ;; either a scalar string or a code reference
;;                #'perl-call-scalar)
;;              function
;;              (calling-flags return-type methodp)))))
