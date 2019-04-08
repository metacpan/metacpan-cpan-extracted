/* Copyright (C) 2009-2015 Francesco Nidito 
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to do
 * so, subject to the following conditions: 
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software. 
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE. 
 */

#ifndef _TRY_THROW_CATCH_H_
#define _TRY_THROW_CATCH_H_

#include <stdlib.h>
#include <stdio.h>
#include <setjmp.h>

/* For the full documentation and explanation of the code below, please refer to
 * http://www.di.unipi.it/~nids/docs/longjump_try_trow_catch.html
 */

#undef _TRY_THROW_SETJMP
/* If we abort it is really really bad luck... */
#define _TRY_THROW_SETJMP(LW, envp) jmp_buf localenv; do {              \
  if ((LW) == NULL) {                                                   \
    envp = &localenv;                                                   \
  } else {                                                              \
    if ((LW)->envp == NULL) {                                           \
      (LW)->envp = (jmp_buf *) malloc(sizeof(jmp_buf));                 \
      if ((LW)->envp == NULL) abort();                                  \
      (LW)->envpmallocl = (LW)->envpusedl = 1;                          \
    } else {                                                            \
      if ((LW)->envpusedl < (LW)->envpmallocl) {                        \
        (LW)->envpusedl++;                                              \
      } else {                                                          \
        jmp_buf *tmp = (jmp_buf *) realloc((LW)->envp, sizeof(jmp_buf) * ((LW)->envpusedl = ++(LW)->envpmallocl)); \
        if (tmp == NULL) abort();                                       \
        (LW)->envp = tmp;                                               \
      }                                                                 \
    }                                                                   \
    envp = &((LW)->envp[(LW)->envpusedl - 1]);                          \
  }                                                                     \
  } while (0)

#undef _TRY_SETJMP_IMPL
#undef _TRY_LONGJMP_IMPL
#if defined(LUA_USE_POSIX)
#  define _TRY_SETJMP_IMPL(env)     _setjmp(env)
#  define _TRY_LONGJMP_IMPL(env, x) _longjmp(env, x)
#else
#  define _TRY_SETJMP_IMPL(env)      setjmp(env)
#  define _TRY_LONGJMP_IMPL(env, x)  longjmp(env, x)
#endif

#undef _TRY_THROW_GETJMP
#define _TRY_THROW_GETJMP(LW) (LW)->envp[(LW)->envpusedl - 1]

#undef TRY
#define TRY(LW) do { jmp_buf *envp; _TRY_THROW_SETJMP(LW, envp); switch( _TRY_SETJMP_IMPL(*envp) ) { case 0: while(1) {

#undef CATCH
#define CATCH(LW, x) break; case x:

#undef FINALLY
#define FINALLY(LW) break; } default: {

#undef ETRY
#define ETRY(LW) break; } } if (((LW) != NULL) && ((LW)->envpusedl > 0)) (LW)->envpusedl--; } while(0)

#undef THROW
#define THROW(LW, x) if (((LW) != NULL) && ((LW)->envpusedl > 0)) { _TRY_LONGJMP_IMPL(_TRY_THROW_GETJMP(LW), x); }

#endif /*!_TRY_THROW_CATCH_H_*/
