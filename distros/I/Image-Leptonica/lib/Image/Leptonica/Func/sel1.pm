package Image::Leptonica::Func::sel1;
$Image::Leptonica::Func::sel1::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::sel1

=head1 VERSION

version 0.04

=head1 C<sel1.c>

  sel1.c

      Basic ops on Sels and Selas

         Create/destroy/copy:
            SELA      *selaCreate()
            void       selaDestroy()
            SEL       *selCreate()
            void       selDestroy()
            SEL       *selCopy()
            SEL       *selCreateBrick()
            SEL       *selCreateComb()

         Helper proc:
            l_int32  **create2dIntArray()

         Extension of sela:
            SELA      *selaAddSel()
            static l_int32  selaExtendArray()

         Accessors:
            l_int32    selaGetCount()
            SEL       *selaGetSel()
            char      *selGetName()
            l_int32    selSetName()
            l_int32    selaFindSelByName()
            l_int32    selGetElement()
            l_int32    selSetElement()
            l_int32    selGetParameters()
            l_int32    selSetOrigin()
            l_int32    selGetTypeAtOrigin()
            char      *selaGetBrickName()
            char      *selaGetCombName()
     static char      *selaComputeCompositeParameters()
            l_int32    getCompositeParameters()
            SARRAY    *selaGetSelnames()

         Max translations for erosion and hmt
            l_int32    selFindMaxTranslations()

         Rotation by multiples of 90 degrees
            SEL       *selRotateOrth()

         Sela and Sel serialized I/O
            SELA      *selaRead()
            SELA      *selaReadStream()
            SEL       *selRead()
            SEL       *selReadStream()
            l_int32    selaWrite()
            l_int32    selaWriteStream()
            l_int32    selWrite()
            l_int32    selWriteStream()

         Building custom hit-miss sels from compiled strings
            SEL       *selCreateFromString()
            char      *selPrintToString()     [for debugging]

         Building custom hit-miss sels from a simple file format
            SELA      *selaCreateFromFile()
            static SEL *selCreateFromSArray()

         Making hit-only sels from Pta and Pix
            SEL       *selCreateFromPta()
            SEL       *selCreateFromPix()

         Making hit-miss sels from Pix and image files
            SEL       *selReadFromColorImage()
            SEL       *selCreateFromColorPix()

         Printable display of sel
            PIX       *selDisplayInPix()
            PIX       *selaDisplayInPix()

     Usage notes:
        In this file we have seven functions that make sels:
          (1)  selCreate(), with input (h, w, [name])
               The generic function.  Roll your own, using selSetElement().
          (2)  selCreateBrick(), with input (h, w, cy, cx, val)
               The most popular function.  Makes a rectangular sel of
               all hits, misses or don't-cares.  We have many morphology
               operations that create a sel of all hits, use it, and
               destroy it.
          (3)  selCreateFromString() with input (text, h, w, [name])
               Adam Langley's clever function, allows you to make a hit-miss
               sel from a string in code that is geometrically laid out
               just like the actual sel.
          (4)  selaCreateFromFile() with input (filename)
               This parses a simple file format to create an array of
               hit-miss sels.  The sel data uses the same encoding
               as in (3), with geometrical layout enforced.
          (5)  selCreateFromPta() with input (pta, cy, cx, [name])
               Another way to make a sel with only hits.
          (6)  selCreateFromPix() with input (pix, cy, cx, [name])
               Yet another way to make a sel from hits.
          (7)  selCreateFromColorPix() with input (pix, name).
               Another way to make a general hit-miss sel, starting with
               an image editor.
        In addition, there are three functions in selgen.c that
        automatically generate a hit-miss sel from a pix and
        a number of parameters.  This is useful for problems like
        "find all patterns that look like this one."

        Consistency, being the hobgoblin of small minds,
        is adhered to here in the dimensioning and accessing of sels.
        Everything is done in standard matrix (row, column) order.
        When we set specific elements in a sel, we likewise use
        (row, col) ordering:
             selSetElement(), with input (row, col, type)

=head1 FUNCTIONS

=head2 create2dIntArray

l_int32 ** create2dIntArray ( l_int32 sy, l_int32 sx )

  create2dIntArray()

      Input:  sy (rows == height)
              sx (columns == width)
      Return: doubly indexed array (i.e., an array of sy row pointers,
              each of which points to an array of sx ints)

  Notes:
      (1) The array[sy][sx] is indexed in standard "matrix notation",
          with the row index first.

=head2 selCopy

SEL * selCopy ( SEL *sel )

  selCopy()

      Input:  sel
      Return: a copy of the sel, or null on error

=head2 selCreate

SEL * selCreate ( l_int32 height, l_int32 width, const char *name )

  selCreate()

      Input:  height, width
              name (<optional> sel name; can be null)
      Return: sel, or null on error

  Notes:
      (1) selCreate() initializes all values to 0.
      (2) After this call, (cy,cx) and nonzero data values must be
          assigned.  If a text name is not assigned here, it will
          be needed later when the sel is put into a sela.

=head2 selCreateBrick

SEL * selCreateBrick ( l_int32 h, l_int32 w, l_int32 cy, l_int32 cx, l_int32 type )

  selCreateBrick()

      Input:  height, width
              cy, cx  (origin, relative to UL corner at 0,0)
              type  (SEL_HIT, SEL_MISS, or SEL_DONT_CARE)
      Return: sel, or null on error

  Notes:
      (1) This is a rectangular sel of all hits, misses or don't cares.

=head2 selCreateComb

SEL * selCreateComb ( l_int32 factor1, l_int32 factor2, l_int32 direction )

  selCreateComb()

      Input:  factor1 (contiguous space between comb tines)
              factor2 (number of comb tines)
              direction (L_HORIZ, L_VERT)
      Return: sel, or null on error

  Notes:
      (1) This generates a comb Sel of hits with the origin as
          near the center as possible.

=head2 selCreateFromColorPix

SEL * selCreateFromColorPix ( PIX *pixs, char *selname )

  selCreateFromColorPix()

      Input:  pixs (cmapped or rgb)
              selname (<optional> sel name; can be null)
      Return: sel if OK, null on error

  Notes:
      (1) The sel size is given by the size of pixs.
      (2) In pixs, hits are represented by green pixels, misses by red
          pixels, and don't-cares by white pixels.
      (3) In pixs, there may be no misses, but there must be at least 1 hit.
      (4) At most there can be only one origin pixel, which is optionally
          specified by using a lower-intensity pixel:
            if a hit:  dark green
            if a miss: dark red
            if a don't care: gray
          If there is no such pixel, the origin defaults to the approximate
          center of the sel.

=head2 selCreateFromPix

SEL * selCreateFromPix ( PIX *pix, l_int32 cy, l_int32 cx, const char *name )

  selCreateFromPix()

      Input:  pix
              cy, cx (origin of sel)
              name (<optional> sel name; can be null)
      Return: sel, or null on error

  Notes:
      (1) The origin must be positive.

=head2 selCreateFromPta

SEL * selCreateFromPta ( PTA *pta, l_int32 cy, l_int32 cx, const char *name )

  selCreateFromPta()

      Input:  pta
              cy, cx (origin of sel)
              name (<optional> sel name; can be null)
      Return: sel (of minimum required size), or null on error

  Notes:
      (1) The origin and all points in the pta must be positive.

=head2 selCreateFromString

SEL * selCreateFromString ( const char *text, l_int32 h, l_int32 w, const char *name )

  selCreateFromString()

      Input:  text
              height, width
              name (<optional> sel name; can be null)
      Return: sel of the given size, or null on error

  Notes:
      (1) The text is an array of chars (in row-major order) where
          each char can be one of the following:
             'x': hit
             'o': miss
             ' ': don't-care
      (2) Use an upper case char to indicate the origin of the Sel.
          When the origin falls on a don't-care, use 'C' as the uppecase
          for ' '.
      (3) The text can be input in a format that shows the 2D layout; e.g.,
              static const char *seltext = "x    "
                                           "x Oo "
                                           "x    "
                                           "xxxxx";

=head2 selDestroy

void selDestroy ( SEL **psel )

  selDestroy()

      Input:  &sel (<to be nulled>)
      Return: void

=head2 selDisplayInPix

PIX * selDisplayInPix ( SEL *sel, l_int32 size, l_int32 gthick )

  selDisplayInPix()

      Input:  sel
              size (of grid interiors; odd; minimum size of 13 is enforced)
              gthick (grid thickness; minimum size of 2 is enforced)
      Return: pix (display of sel), or null on error

  Notes:
      (1) This gives a visual representation of a general (hit-miss) sel.
      (2) The empty sel is represented by a grid of intersecting lines.
      (3) Three different patterns are generated for the sel elements:
          - hit (solid black circle)
          - miss (black ring; inner radius is radius2)
          - origin (cross, XORed with whatever is there)

=head2 selFindMaxTranslations

l_int32 selFindMaxTranslations ( SEL *sel, l_int32 *pxp, l_int32 *pyp, l_int32 *pxn, l_int32 *pyn )

  selFindMaxTranslations()

      Input:  sel
              &xp, &yp, &xn, &yn  (<return> max shifts)
      Return: 0 if OK; 1 on error

  Note: these are the maximum shifts for the erosion operation.
        For example, when j < cx, the shift of the image
        is +x to the cx.  This is a positive xp shift.

=head2 selGetElement

l_int32 selGetElement ( SEL *sel, l_int32 row, l_int32 col, l_int32 *ptype )

  selGetElement()

      Input:  sel
              row
              col
              &type  (<return> SEL_HIT, SEL_MISS, SEL_DONT_CARE)
      Return: 0 if OK; 1 on error

=head2 selGetName

char * selGetName ( SEL *sel )

  selGetName()

      Input:  sel
      Return: sel name (not copied), or null if no name or on error

=head2 selGetParameters

l_int32 selGetParameters ( SEL *sel, l_int32 *psy, l_int32 *psx, l_int32 *pcy, l_int32 *pcx )

  selGetParameters()

      Input:  sel
              &sy, &sx, &cy, &cx (<optional return>; each can be null)
      Return: 0 if OK, 1 on error

=head2 selGetTypeAtOrigin

l_int32 selGetTypeAtOrigin ( SEL *sel, l_int32 *ptype )

  selGetTypeAtOrigin()

      Input:  sel
              &type  (<return> SEL_HIT, SEL_MISS, SEL_DONT_CARE)
      Return: 0 if OK; 1 on error or if origin is not found

=head2 selPrintToString

char * selPrintToString ( SEL *sel )

  selPrintToString()

      Input:  sel
      Return: str (string; caller must free)

  Notes:
      (1) This is an inverse function of selCreateFromString.
          It prints a textual representation of the SEL to a malloc'd
          string.  The format is the same as selCreateFromString
          except that newlines are inserted into the output
          between rows.
      (2) This is useful for debugging.  However, if you want to
          save some Sels in a file, put them in a Sela and write
          them out with selaWrite().  They can then be read in
          with selaRead().

=head2 selRead

SEL * selRead ( const char *fname )

  selRead()

      Input:  filename
      Return: sel, or null on error

=head2 selReadFromColorImage

SEL * selReadFromColorImage ( const char *pathname )

  selReadFromColorImage()

      Input:  pathname
      Return: sel if OK; null on error

  Notes:
      (1) Loads an image from a file and creates a (hit-miss) sel.
      (2) The sel name is taken from the pathname without the directory
          and extension.

=head2 selReadStream

SEL * selReadStream ( FILE *fp )

  selReadStream()

      Input:  stream
      Return: sel, or null on error

=head2 selRotateOrth

SEL * selRotateOrth ( SEL *sel, l_int32 quads )

  selRotateOrth()

      Input:  sel
              quads (0 - 4; number of 90 degree cw rotations)
      Return: seld, or null on error

=head2 selSetElement

l_int32 selSetElement ( SEL *sel, l_int32 row, l_int32 col, l_int32 type )

  selSetElement()

      Input:  sel
              row
              col
              type  (SEL_HIT, SEL_MISS, SEL_DONT_CARE)
      Return: 0 if OK; 1 on error

  Notes:
      (1) Because we use row and column to index into an array,
          they are always non-negative.  The location of the origin
          (and the type of operation) determine the actual
          direction of the rasterop.

=head2 selSetName

l_int32 selSetName ( SEL *sel, const char *name )

  selSetName()

      Input:  sel
              name (<optional>; can be null)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Always frees the existing sel name, if defined.
      (2) If name is not defined, just clears any existing sel name.

=head2 selSetOrigin

l_int32 selSetOrigin ( SEL *sel, l_int32 cy, l_int32 cx )

  selSetOrigin()

      Input:  sel
              cy, cx
      Return: 0 if OK; 1 on error

=head2 selWrite

l_int32 selWrite ( const char *fname, SEL *sel )

  selWrite()

      Input:  filename
              sel
      Return: 0 if OK, 1 on error

=head2 selWriteStream

l_int32 selWriteStream ( FILE *fp, SEL *sel )

  selWriteStream()

      Input:  stream
              sel
      Return: 0 if OK, 1 on error

=head2 selaAddSel

l_int32 selaAddSel ( SELA *sela, SEL *sel, const char *selname, l_int32 copyflag )

  selaAddSel()

      Input:  sela
              sel to be added
              selname (ignored if already defined in sel;
                       req'd in sel when added to a sela)
              copyflag (for sel: 0 inserts, 1 copies)
      Return: 0 if OK; 1 on error

  Notes:
      (1) This adds a sel, either inserting or making a copy.
      (2) Because every sel in a sela must have a name, it copies
          the input name if necessary.  You can input NULL for
          selname if the sel already has a name.

=head2 selaCreate

SELA * selaCreate ( l_int32 n )

  selaCreate()

      Input:  n (initial number of sel ptrs; use 0 for default)
      Return: sela, or null on error

=head2 selaCreateFromFile

SELA * selaCreateFromFile ( const char *filename )

  selaCreateFromFile()

      Input:  filename
      Return: sela, or null on error

  Notes:
      (1) The file contains a sequence of Sel descriptions.
      (2) Each Sel is formatted as follows:
           - Any number of comment lines starting with '#' are ignored
           - The next line contains the selname
           - The next lines contain the Sel data.  They must be
             formatted similarly to the string format in
             selCreateFromString(), with each line beginning and
             ending with a double-quote, and showing the 2D layout.
           - Each Sel ends when a blank line, a comment line, or
             the end of file is reached.
      (3) See selCreateFromString() for a description of the string
          format for the Sel data.  As an example, here are the lines
          of is a valid file for a single Sel.  In the file, all lines
          are left-justified:
                    # diagonal sel
                    sel_5diag
                    "x    "
                    " x   "
                    "  X  "
                    "   x "
                    "    x"

=head2 selaDestroy

void selaDestroy ( SELA **psela )

  selaDestroy()

      Input:  &sela (<to be nulled>)
      Return: void

=head2 selaDisplayInPix

PIX * selaDisplayInPix ( SELA *sela, l_int32 size, l_int32 gthick, l_int32 spacing, l_int32 ncols )

  selaDisplayInPix()

      Input:  sela
              size (of grid interiors; odd; minimum size of 13 is enforced)
              gthick (grid thickness; minimum size of 2 is enforced)
              spacing (between sels, both horizontally and vertically)
              ncols (number of sels per "line")
      Return: pix (display of all sels in sela), or null on error

  Notes:
      (1) This gives a visual representation of all the sels in a sela.
      (2) See notes in selDisplayInPix() for display params of each sel.
      (3) This gives the nicest results when all sels in the sela
          are the same size.

=head2 selaFindSelByName

l_int32 selaFindSelByName ( SELA *sela, const char *name, l_int32 *pindex, SEL **psel )

  selaFindSelByName()

      Input:  sela
              sel name
              &index (<optional, return>)
              &sel  (<optional, return> sel (not a copy))
      Return: 0 if OK; 1 on error

=head2 selaGetBrickName

char * selaGetBrickName ( SELA *sela, l_int32 hsize, l_int32 vsize )

  selaGetBrickName()

      Input:  sela
              hsize, vsize (of brick sel)
      Return: sel name (new string), or null if no name or on error

=head2 selaGetCombName

char * selaGetCombName ( SELA *sela, l_int32 size, l_int32 direction )

  selaGetCombName()

      Input:  sela
              size (the product of sizes of the brick and comb parts)
              direction (L_HORIZ, L_VERT)
      Return: sel name (new string), or null if name not found or on error

  Notes:
      (1) Combs are by definition 1-dimensional, either horiz or vert.
      (2) Use this with comb Sels; e.g., from selaAddDwaCombs().

=head2 selaGetCount

l_int32 selaGetCount ( SELA *sela )

  selaGetCount()

      Input:  sela
      Return: count, or 0 on error

=head2 selaGetSel

SEL * selaGetSel ( SELA *sela, l_int32 i )

  selaGetSel()

      Input:  sela
              index of sel to be retrieved (not copied)
      Return: sel, or null on error

  Notes:
      (1) This returns a ptr to the sel, not a copy, so the caller
          must not destroy it!

=head2 selaGetSelnames

SARRAY * selaGetSelnames ( SELA *sela )

  selaGetSelnames()

      Input:  sela
      Return: sa (of all sel names), or null on error

=head2 selaRead

SELA * selaRead ( const char *fname )

  selaRead()

      Input:  filename
      Return: sela, or null on error

=head2 selaReadStream

SELA * selaReadStream ( FILE *fp )

  selaReadStream()

      Input:  stream
      Return: sela, or null on error

=head2 selaWrite

l_int32 selaWrite ( const char *fname, SELA *sela )

  selaWrite()

      Input:  filename
              sela
      Return: 0 if OK, 1 on error

=head2 selaWriteStream

l_int32 selaWriteStream ( FILE *fp, SELA *sela )

  selaWriteStream()

      Input:  stream
              sela
      Return: 0 if OK, 1 on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
