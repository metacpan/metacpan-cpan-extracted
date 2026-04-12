# Graphics::Framebuffer MCE Demos

[![Graphics::Framebuffer Logo](../../pics/GFB.png?raw=true "Graphics::Framebuffer Click For Demo Video")](https://www.youtube.com/watch?v=X8RpFBq6F9I)

Mario Roy has some excellent examples using alternate multiprocessing methods, instead of threads.  Clone his repository and copy the files in the "framebuffer" directory into this directory and run them.

```
./get-mce-demos
```

You may have to install extra prerequisites to get them to work, but they allow for a single shared object usage, instead of opening a separate object for each thread/process.

(You will need the modules "MCE" and "MCE::Hobo")
