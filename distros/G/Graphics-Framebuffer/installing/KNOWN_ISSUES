******************************************************************************
*                              KNOWN ISSUES                                  *
*                          Graphics::Framebuffer                             *
******************************************************************************

##############################################################################

Avoid 16 bit mode if at all possible.  16 bit processing is a hack, a kludge.
It is a slower than 24/32 bit color operations.  It also may have problems.
The best way to avoid any speed or bug issues, is to avoid 16 bit mode all
together and use 24 or 32 bit mode.

Note:  The Raspberry Pi typically defaults to 16 bit color mode.  Please
       change its settings to use 24/32 bit mode.

##############################################################################

Loading very large images can crash if your system does not have enough RAM.
This is something you need to keep in mind before loading giant pictures.
Just resize them appropriately before using your script.

##############################################################################

UNMASK drawing for 16 bit displays may have issues.  Use MASK mode in
reverse as an alternate workaround.

##############################################################################

I re-enabled the console status methods, but for some reason, they are not
very reliable.  They simply read "/sys/class/tty/tty0/active" to determine
which console they are running inside, and if it's different than the console
at initialization, it is supposed to wait.  Something in that process is
flakey.

##############################################################################

Some framebuffer drivers are tearfully slow (not many).  I have noticed that
the Nouveau framebuffer driver for NVidia is Molasses slow (this is not the
fault of NVidia, but the Nouvaeu developers).  It's amazing how slow it is.
Other framebuffer drivers are amazingly fast.  It's clear the Nouveau
framebuffer driver is in dire need of optimization, or at the very least
hardware accelerated buffer copy, like CPU DMA.  I'll be looking into finding
ways to overcome this issue (don't get your hopes up).

After more testing, it seems non-bulk read or write access is simply very
slow.  Odd really.  Operations in normal mode, like blit_write are very
fast, but any other mode like OR or Alpha, are molasses slow.  Normal mode
only writes as a large block of data, and takes no care about what it
replaces.  However, other modes require bytes, words, or long words to be read
in, processed, then written back out.  That is what is not optimized in the
Nouveau driver.  Other drivers do this quickly, even the Intel driver.  I am
assuming the other drivers use a DMA routine to transfer the memory address
framebuffer to the real framebuffer, or map the actual framebuffer to real
memory, although I suspect most do it via DMA transfers.

##############################################################################

Mouse methods are rudimentary and your user must be a member of the "input"
group for them to work.  Frankly, I recommend using your own routines with
threads, or better yet, if you really need a mouse, then maybe X-Windows and
and SDL may be better for you.

I don't really plan on developing mouse capability any further.  It was a test
to see if it was possible.  Well, it was possible, but not very practical.

