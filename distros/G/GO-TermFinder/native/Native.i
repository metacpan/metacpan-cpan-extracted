/***********************************************************************
 *
 * File        : Native.i
 * Author      : Ihab A.B. Awad
 * Date Begun  : October 08 2004
 *
 * $Id: Native.i,v 1.1 2004/10/11 21:22:40 ihab Exp $
 *
 * License information (the MIT license)
 *
 * Copyright (c) 2004 Ihab A.B. Awad; Stanford University
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use, copy,
 * modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 *
 **********************************************************************/

/*
 * Declare the target language (Perl) module where this interface
 * will go.
 */

%module "GO::TermFinder::Native"

/*
 * Directive to ensure that the header file is included in the
 * emitted C++ output.
 */

%{
#include "Distributions.hxx"
%}

/*
 * Pull in the entire header file, thereby auto-generating a SWIG
 * interface for all its contents.
 */

%include "Distributions.hxx"
