#ifdef __cplusplus
extern "C" {
#endif
#include <stdio.h>
/*
 * gcc long pointer support code for HPPA.
 * Copyright 1998, DIS International, Ltd.
 * Permission is granted to use this code under the GNU LIBRARY GENERAL
 * PUBLIC LICENSE, Version 2, June 1991.
 */
typedef struct {
  int		spaceid;
  unsigned int 	offset;
  } longpointer;

#undef  LONGPOINTER
#define LONGPOINTER	longpointer

int getspaceid(void *source)
  {
  int val;
  /*
   * Given the short pointer, determine it's space ID.
   */

  /*
   * The colons separate output from input parameters. In this case,
   * the output of the instruction (output indicated by the "=" in the
   * constraint) is to a memory location (indicated by the "m"). The
   * input constraint indicates that the source to the instruction
   * is a register reference (indicated by the "r").
   * The general format is:
   *   asm("<instruction template>" : <output> : <input> : <clobbers>);
   *     where <output> and <input> are:
   *       "<constraint>" (<token>)
   *     <instruction template> is the PA-RISC instruction in template fmt.
   *     <clobbers> indicates those registers clobbered by the instruction
   *     and provides hints to the optimizer.
   *
   * Refer to the gcc documentation or http://www.dis.com/gnu/gcc_toc.html
   */
  __asm__ __volatile__ (
      "   comiclr,= 0,%1,%%r28\n"
      "\t   ldsid (%%r0,%1),%%r28\n"
      "\t stw %%r28, %0"
  			: "=m" (val)	// Output to val
			: "r" (source)	// Source must be gen reg
			: "%r28");	// Clobbers %r28
  return (val);
  };

LONGPOINTER longaddr(void *source)	
  {
  LONGPOINTER lptr;
  /*
   * Return the long pointer for the address in sr5 space.
   */

  __asm__ __volatile__ (
      "  comiclr,= 0,%2,%%r28\n"
      "\t    ldsid (%%r0,%2),%%r28\n"
      "\t  stw %%r28, %0\n"
      "\t  stw %2, %1"
  			: "=m" (lptr.spaceid),
			  "=m" (lptr.offset)	// Store to lptr
			: "r" (source) 		// Source must be gen reg
			: "%r28");	// Clobbers %r28
  return (lptr);
  };

LONGPOINTER addtopointer(LONGPOINTER source,	// %r26 == source offset
						// %r25 == source space
			int		len)	// %r24 == length in bytes
  {
  /*
   * Increment a longpointer.
   */

  __asm__ __volatile__ (
      "  copy %0,%%r28\n"			// copy space to r28
      "\t  add %1,%2,%%r29"			// Increment the pointer
       			:			// No output
			: "r" (source.spaceid), // Source address
			  "r" (source.offset),
			  "r" (len)		// Length
			: "%r28",		// Clobbers
			  "%r29");
  };

void longmove(int len,			// %r26 == byte length
	      LONGPOINTER source,	// %r23 == source space, %r24 == off
	      LONGPOINTER target)	// sp-#56 == target space, sp-#52== off
  {
  /*
   * Move data between two buffers in long pointer space.
   */

  __asm__ __volatile__ (
      "  .import $$lr_unk_unk_long,MILLICODE\n"
      "\t  mtsp %0,%%sr1\n"			// copy source space to sr1
      "\t  copy %1,%%r26\n"			// load source offset to r26
      "\t  copy %4,%%r24\n"			// load length to r24
      "\t  copy %3,%%r25\n"			// load target offset to r25
      "\t  bl $$lr_unk_unk_long,%%r31\n"	// start branch to millicode
      "\t  mtsp %2,%%sr2"			// copy target space to sr2
  			: 			// No output
			: "r" (source.spaceid),	// Source address
			  "r" (source.offset),	
			  "r" (target.spaceid),	// Target address
			  "r" (target.offset),
			  "r" (len)		// Byte length
			: "%r1",		// Clobbers
			  "%r24",
			  "%r25",
			  "%r26",
			  "%r31");
  };

int longpeek(LONGPOINTER source)	
  {
  /*
   * Fetch the int in long pointer space.
   */
  unsigned int val;

  __asm__ __volatile__ (
      "  mtsp %1, %%sr1\n"
      "\t  copy %2, %%r28\n"
      "\t  ldw 0(%%sr1, %%r28), %%r28\n"
      "\t  stw %%r28, %0"
      			: "=m" (val)		// Output val
			: "r" (source.spaceid),	// Source space ID
			  "r" (source.offset)	// Source offset
			: "%r28");		// Clobbers %r28

  return (val);
  };

void longpoke(LONGPOINTER target,	// %r25 == spaceid, %r26 == offset
  	  unsigned int val)		// %r24 == value
  {
  /*
   * Store the val into long pointer space.
   */
  __asm__ __volatile__ (
      "  mtsp %0,%%sr1\n"
      "\t  copy %1, %%r28\n"
      "\t  stw %2, 0(%%sr1, %%r28)"	
       			:			// No output
      			: "r" (target.spaceid),	// Target space ID
			  "r" (target.offset),	// Target offset
			  "r" (val)		// Value to store
			: "%r28"		// Clobbers %r28
			);			// Copy space to %sr1
  };

void move_fast(int len,			// %r26 == byte length
               void *source,		// %r25 == source addr
               void *target)		// %r24 == target addr
  {
  /*
   * Move using short pointers.
   */
  __asm__ __volatile__ (
      "  .import $$lr_unk_unk,MILLICODE\n"
      "\t  copy %1, %%r26\n"			// Move source addr into pos
      "\t  copy %2, %%r25\n"			// Move target addr into pos
      "\t  bl $$lr_unk_unk,%%r31\n"		// Start branch to millicode
      "\t  copy %0, %%r24"			// Move length into position
  			: 			// No output
			: "r" (len),	 	// Byte length
			  "r" (source),		// Source address
			  "r" (target)		// Target address
			: "%r24",		// Clobbers
			  "%r25",
			  "%r26",
			  "%r31");
  };

#ifdef __cplusplus
}

#undef LONGPOINTER


#define CONSTRUCTOR(T)				\
    LONGPOINTER::LONGPOINTER(T *the_addr) {	\
      spaceid	= 0;				\
      if (the_addr) {				\
        spaceid	= getspaceid (the_addr);	\
        offset	= (unsigned long) the_addr;	\
      }						\
      printf ("space: $%x.$%08x\n", spaceid, offset); \
    }

class LONGPOINTER {

  public:
    int			spaceid;
    unsigned int	offset;

  public:

    /*
     * Constructor.
     */
    LONGPOINTER::LONGPOINTER() {

      spaceid	= 0;
      offset	= 0;
    }

    CONSTRUCTOR(char);
    CONSTRUCTOR(short);
    CONSTRUCTOR(long);
    CONSTRUCTOR(long long);
};
#endif
