/*! \file pstring.h
 * \brief string type.
 *
 * \author Igor Vlasenko <vlasenko@imath.kiev.ua>
 * \warning This header file should never be included directly.
 * Include <tmplpro.h> instead.
 */

#ifndef _PSTRING_H
#define _PSTRING_H	1

/** \struct PSTRING

    \brief string type used in htmltmplpro.

    \code
    typedef struct PSTRING {
      const char* begin;
      const char* endnext;
    } PSTRING;
    \endcode


    The string is delimited by two pointers, begin and endnext.
    The length of the string is calculated as endnext - begin.
    The empty string has begin == endnext. 

    \warning It is possible for empty string to have begin == endnext == NULL.
    \warning Contents of the memory area, passed as PSTRING, should always be treated as const.
    \warning Contents of the memory area, passed as PSTRING, can be destroyed after the callback function
    completed. To be used afterwards the string content should be copied.
 */

typedef struct PSTRING {
  const char* begin;   /*!< pointer to begin of the string. */
  const char* endnext; /*!< pointer to the byte next to the last char of the string. */
} PSTRING;

/** \struct MPSTRING

    \brief Modifiable PSTRING.

    \code
    typedef struct MPSTRING {
      char* begin;
      char* endnext;
    } PSTRING;
    \endcode

    The same as PSTING, but in non-constant memory.

 */


typedef struct MPSTRING {
  char* begin;   /*!< pointer to begin of the string. */
  char* endnext; /*!< pointer to the byte next to the last char of the string. */
} MPSTRING;

#endif /* pstring.h */
