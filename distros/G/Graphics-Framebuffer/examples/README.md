# Example File Descriptions

To view the documentation for these, just use "perldoc".
Also note, to exit these just use CTRL-C

-----
```
* dump.pl        - A program that dumps important diagnostic data to a file
                   called, "dump.log".  Send this file as an email attachment
                   along with your explanation of the issue.  Note, it MUST be
				   a file attachment, not pasted inline.

* fonts.pl       - A program that just shows each system TrueType font.  It is
                   not too glamorous, but it shows Graphics::Framebuffer and
                   Imager is working.

* primitives.pl  - A simple spam method of testing all of the module's screen-
                   specific operations.  It has a benchmark at the end.

* screensaver.pl - Not very fancy.  I just blanks the screen and plasters
                   the current time in random places.

* slideshow.pl   - Pass it a specific image path and it will show all of the
                   images in that path, including those in nested directories.

* template.pl    - Use a copy of this to create a script skeleton and base
                   your script on this.  You don't have to, but it helps to
                   learn.

* text_mode.pl   - Maybe your script crashed, and the cursor is not responding
                   Hit [ENTER] then blindly run this to fix the screen and
                   restore text mode.

                   Note, I highly suggest not using graphics mode while
                   developing your code.  It will still show you graphics
                   output, but if your code crashes, you can still use the
                   cursor.

* vector.pl      - A rudimentary vector drawing language that uses source
                   "gfb" files to draw on the screen.  See "vector-usa.gfb" as
                   an example.

* viewpic.pl     - Shows one image passed to it.
```
