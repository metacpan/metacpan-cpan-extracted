/*
 * This file contains some assembly code that can be patched into camera.C.
 * This code does bi-directional transfers in camera_t::read_bytes().
 * It is tested.  It works.
 * But it's no faster than optimized C, because the bottleneck is the
 * parallel port hardware.
 * And it's a maintenance nightmare, which is why it's not in use.
 * It's in this file because I couldn't bear to throw away working code.
 * Make it faster than the C version (please?) and I'll use it.
 */

    __asm__ (
/*D*/ "1: inb %%dx,%%al\n"  /* while (!get_rdy2()) ; */
      "testl $1,%%eax\n"
      "jz 1b\n"
/*D*/ "inb %%dx,%%al\n"     /* lo = port->read_data() >> 1; */
      "shrb %%al\n"
      "mov %%eax,%%ebx\n"        /* bl now contains lo */
/*S*/ "incl %%edx\n"         /* hi = ((port->read_status() >> 3) & 0x1f) ^ 0x10; */
/*S*/ "inb %%dx,%%al\n"
      "mov %%al,%%bh\n"
      "movb $0x2c,%%al\n"
/*C*/ "incl %%edx\n"
/*C*/ "outb %%al,%%dx\n"
      "shrb $3,%%bh\n"
      "andb $0x1f,%%bh\n"
      "xorb $0x10,%%bh\n"       /* al,bh now contain hi */
           /* set_ack(1); */
      "pushb %%bx\n"             /* save hi for later use */
      "shlb $7,%%bh\n"       /* buf[nbytes+0] = lo | ((hi & 0x01) << 7); */
      "orb %%bh,%%bl\n"
      "movb %%bl,%%al\n"
      "stosb\n"                  /* saved buf[nbytes++] */
/*D*/ "subl $2,%%edx\n"
/*D*/ "2: inb %%dx,%%al\n"  /* while (get_rdy2()) ; */
      "testl $1,%%eax\n"
      "jnz 2b\n"
/*D*/ "inb %%dx,%%al\n"     /* lo2 = port->read_data() >> 1; */
      "shrl %%eax\n"
      "mov %%eax,%%ebx\n"        /* bl now contains lo2 */
/*S*/ "incl %%edx\n"         /* hi2 = ((port->read_status() >> 3) & 0x1f) ^ 0x10; */
/*S*/ "inb %%dx,%%al\n"
      "movb %%al,%%bh\n"
      "movb $0x24,%%al\n"
/*C*/ "incl %%edx\n"
/*C*/ "outb %%al,%%dx\n"
      "shrb $3,%%bh\n"
      "andb $0x1f,%%bh\n"
      "xorb $0x10,%%bh\n"       /* al,bh now contain hi2 */
           /* set_ack(0); */
      "popb %%ax\n"          /* buf[nbytes+1] = ((hi & 0x1e) << 3) | ((hi2 & 0x1e) >> 1); */
      "andb $0x1e,%%ah\n"        /* al just got (old) hi */
      "shlb $3,%%ah\n"
      "movb %%bh,%%al\n"
      "andb $0x1e,%%al\n"
      "shrb %%al\n"
      "orb %%ah,%%al\n"
      "stosb\n"                  /* saved buf[nbytes++] */
      "andb $0x01,%%bh\n"    /* buf[nbytes+2] = lo2 | ((hi2 & 0x01) << 7); */
      "shlb $7,%%bh\n"
      "orb %%bh,%%bl\n"
      "movb %%bl,%%al\n"
      "stosb\n"                  /* saved buf[nbytes++] */
/*D*/ "subl $2,%%edx\n"
      "loop 1b\n"
      :
      :"c"(ntrans), "d"(port->port), "D"(buf)
      :"ax", "bx", "cx", "dx", "di");
    nbytes += 3*ntrans;
