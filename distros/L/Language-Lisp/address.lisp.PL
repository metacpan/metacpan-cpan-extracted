{
  my $fn = shift;
  my $data = join '', <DATA>;
  open my $fhout, ">$fn" or die "can't open >$fn: $!";
  binmode $fhout;
  print $fhout $data;
  #no close $fhout;
}
__DATA__
;;; address.lisp -- CFFI extension to allow mutable pointers

;;; Copyright 2006 Stuart Sierra

;;; This program is free software; you can redistribute it and/or
;;; modify it under the terms of the Lisp Lesser GNU General Public
;;; License (LLGPL) published by Franz, Inc., available at
;;; http://opensource.franz.com/preamble.html

;;; This program is distributed in the hope that it will be useful,
;;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; Lesser GNU General Public License for more details.

(in-package :common-lisp-user)

(defpackage :cffi-address
  (:use :common-lisp :cffi)
  (:export #:address-incf #:address-decf #:address-ref))

(in-package :cffi-address)

(defvar *pointer-size*
  (foreign-type-size :pointer)
  "The size of a pointer on the current platform, in bytes.")
(ecase *pointer-size*
  (1 (defctype :address :uint8))   ; unlikely
  (2 (defctype :address :uint16))  ; possible
  (4 (defctype :address :uint32))  ; most common
  (8 (defctype :address :uint64))) ; possible
(defmacro address-incf (address &optional (n 1))
  `(incf ,address (* ,n *pointer-size*)))

(defmacro address-decf (address &optional (n 1))
  `(decf ,address (* ,n *pointer-size*)))
(defmacro address-ref (address type)
  `(mem-ref (make-pointer ,address) ,type))
