# Special Source Files

This is where the actual module code is located.  When the *Makefile.PL* script is run, these files are processed and the resulting ```lib/Graphics/Framebuffer.pm``` file is generated.  This means ```lib/Graphics/Framebuffer.pm``` is overwritten and any changes made to it disappear

This process was necessary due to not only readability, but to also modify the code to accommodate the C routines, account for possible lack of thread support and change versioning.
