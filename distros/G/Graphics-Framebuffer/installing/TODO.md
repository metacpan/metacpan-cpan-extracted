# TO DO

## The following are some ideas for the future:

### Requests are seriously considered for new features or system compatibility.

   Many features this module have were as a result of user requests.

-----

### Completely C accelerate all primitive drawing

   Currently only some functions are C code accelerated.  More are added as work progresses.

   The slowest will be addressed first.

   Realistically though, I doubt some specific routines will be converted, as they would be determined to be sufficiently quick.

-----

### Incorporate all methods that need Imager to use their own C code, so Imager is no longer needed.

   Imager's lack of support for RGB565 (16 bit) is the reason for this need.  The slight increase in speed won't hurt either.

   Imager uses a proprietary surface model, similar to X-Windows graphics libraries.  I would prefer drawing directly to the framebuffer without the blitting overhead, which slows things down.

-----
