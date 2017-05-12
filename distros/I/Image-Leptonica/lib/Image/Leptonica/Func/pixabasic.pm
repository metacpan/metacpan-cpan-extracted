package Image::Leptonica::Func::pixabasic;
$Image::Leptonica::Func::pixabasic::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::pixabasic

=head1 VERSION

version 0.04

=head1 C<pixabasic.c>

   pixabasic.c

      Pixa creation, destruction, copying
           PIXA     *pixaCreate()
           PIXA     *pixaCreateFromPix()
           PIXA     *pixaCreateFromBoxa()
           PIXA     *pixaSplitPix()
           void      pixaDestroy()
           PIXA     *pixaCopy()

      Pixa addition
           l_int32   pixaAddPix()
           l_int32   pixaAddBox()
           static l_int32   pixaExtendArray()
           l_int32   pixaExtendArrayToSize()

      Pixa accessors
           l_int32   pixaGetCount()
           l_int32   pixaChangeRefcount()
           PIX      *pixaGetPix()
           l_int32   pixaGetPixDimensions()
           PIX      *pixaGetBoxa()
           l_int32   pixaGetBoxaCount()
           BOX      *pixaGetBox()
           l_int32   pixaGetBoxGeometry()
           l_int32   pixaSetBoxa()
           PIX     **pixaGetPixArray()
           l_int32   pixaVerifyDepth()
           l_int32   pixaIsFull()
           l_int32   pixaCountText()
           void   ***pixaGetLinePtrs()

      Pixa array modifiers
           l_int32   pixaReplacePix()
           l_int32   pixaInsertPix()
           l_int32   pixaRemovePix()
           l_int32   pixaRemovePixAndSave()
           l_int32   pixaInitFull()
           l_int32   pixaClear()

      Pixa and Pixaa combination
           l_int32   pixaJoin()
           l_int32   pixaaJoin()

      Pixaa creation, destruction
           PIXAA    *pixaaCreate()
           PIXAA    *pixaaCreateFromPixa()
           void      pixaaDestroy()

      Pixaa addition
           l_int32   pixaaAddPixa()
           l_int32   pixaaExtendArray()
           l_int32   pixaaAddPix()
           l_int32   pixaaAddBox()

      Pixaa accessors
           l_int32   pixaaGetCount()
           PIXA     *pixaaGetPixa()
           BOXA     *pixaaGetBoxa()
           PIX      *pixaaGetPix()
           l_int32   pixaaVerifyDepth()
           l_int32   pixaaIsFull()

      Pixaa array modifiers
           l_int32   pixaaInitFull()
           l_int32   pixaaReplacePixa()
           l_int32   pixaaClear()
           l_int32   pixaaTruncate()

      Pixa serialized I/O  (requires png support)
           PIXA     *pixaRead()
           PIXA     *pixaReadStream()
           l_int32   pixaWrite()
           l_int32   pixaWriteStream()

      Pixaa serialized I/O  (requires png support)
           PIXAA    *pixaaReadFromFiles()
           PIXAA    *pixaaRead()
           PIXAA    *pixaaReadStream()
           l_int32   pixaaWrite()
           l_int32   pixaaWriteStream()


   Important note on reference counting:
     Reference counting for the Pixa is analogous to that for the Boxa.
     See pix.h for details.   pixaCopy() provides three possible modes
     of copy.  The basic rule is that however a Pixa is obtained
     (e.g., from pixaCreate*(), pixaCopy(), or a Pixaa accessor),
     it is necessary to call pixaDestroy() on it.

=head1 FUNCTIONS

=head2 pixaAddBox

l_int32 pixaAddBox ( PIXA *pixa, BOX *box, l_int32 copyflag )

  pixaAddBox()

      Input:  pixa
              box
              copyflag (L_INSERT, L_COPY, L_CLONE)
      Return: 0 if OK, 1 on error

=head2 pixaAddPix

l_int32 pixaAddPix ( PIXA *pixa, PIX *pix, l_int32 copyflag )

  pixaAddPix()

      Input:  pixa
              pix  (to be added)
              copyflag (L_INSERT, L_COPY, L_CLONE)
      Return: 0 if OK; 1 on error

=head2 pixaChangeRefcount

l_int32 pixaChangeRefcount ( PIXA *pixa, l_int32 delta )

  pixaChangeRefcount()

      Input:  pixa
      Return: 0 if OK, 1 on error

=head2 pixaClear

l_int32 pixaClear ( PIXA *pixa )

  pixaClear()

      Input:  pixa
      Return: 0 if OK, 1 on error

  Notes:
      (1) This destroys all pix in the pixa, as well as
          all boxes in the boxa.  The ptrs in the pix ptr array
          are all null'd.  The number of allocated pix, n, is set to 0.

=head2 pixaCopy

PIXA * pixaCopy ( PIXA *pixa, l_int32 copyflag )

  pixaCopy()

      Input:  pixas
              copyflag (see pix.h for details):
                L_COPY makes a new pixa and copies each pix and each box
                L_CLONE gives a new ref-counted handle to the input pixa
                L_COPY_CLONE makes a new pixa and inserts clones of
                    all pix and boxes
      Return: new pixa, or null on error

=head2 pixaCountText

l_int32 pixaCountText ( PIXA *pixa, l_int32 *pntext )

  pixaCountText()

      Input:  pixa
              &ntext (<return> number of pix with non-empty text strings)
      Return: 0 if OK, 1 on error.

  Notes:
      (1) All pix have non-empty text strings if the returned value @ntext
          equals the pixa count.

=head2 pixaCreate

PIXA * pixaCreate ( l_int32 n )

  pixaCreate()

      Input:  n  (initial number of ptrs)
      Return: pixa, or null on error

=head2 pixaCreateFromBoxa

PIXA * pixaCreateFromBoxa ( PIX *pixs, BOXA *boxa, l_int32 *pcropwarn )

  pixaCreateFromBoxa()

      Input:  pixs
              boxa
              &cropwarn (<optional return> TRUE if the boxa extent
                         is larger than pixs.
      Return: pixad, or null on error

  Notes:
      (1) This simply extracts from pixs the region corresponding to each
          box in the boxa.
      (2) The 3rd arg is optional.  If the extent of the boxa exceeds the
          size of the pixa, so that some boxes are either clipped
          or entirely outside the pix, a warning is returned as TRUE.
      (3) pixad will have only the properly clipped elements, and
          the internal boxa will be correct.

=head2 pixaCreateFromPix

PIXA * pixaCreateFromPix ( PIX *pixs, l_int32 n, l_int32 cellw, l_int32 cellh )

  pixaCreateFromPix()

      Input:  pixs  (with individual components on a lattice)
              n   (number of components)
              cellw   (width of each cell)
              cellh   (height of each cell)
      Return: pixa, or null on error

  Notes:
      (1) For bpp = 1, we truncate each retrieved pix to the ON
          pixels, which we assume for now start at (0,0)

=head2 pixaDestroy

void pixaDestroy ( PIXA **ppixa )

  pixaDestroy()

      Input:  &pixa (<can be nulled>)
      Return: void

  Notes:
      (1) Decrements the ref count and, if 0, destroys the pixa.
      (2) Always nulls the input ptr.

=head2 pixaExtendArrayToSize

l_int32 pixaExtendArrayToSize ( PIXA *pixa, l_int32 size )

  pixaExtendArrayToSize()

      Input:  pixa
      Return: 0 if OK; 1 on error

  Notes:
      (1) If necessary, reallocs new pixa and boxa ptrs arrays to @size.
          The pixa and boxa ptr arrays must always be equal in size.

=head2 pixaGetBox

BOX * pixaGetBox ( PIXA *pixa, l_int32 index, l_int32 accesstype )

  pixaGetBox()

      Input:  pixa
              index  (to the index-th pix)
              accesstype  (L_COPY or L_CLONE)
      Return: box (if null, not automatically an error), or null on error

  Notes:
      (1) There is always a boxa with a pixa, and it is initialized so
          that each box ptr is NULL.
      (2) In general, we expect that there is either a box associated
          with each pix, or no boxes at all in the boxa.
      (3) Having no boxes is thus not an automatic error.  Whether it
          is an actual error is determined by the calling program.
          If the caller expects to get a box, it is an error; see, e.g.,
          pixaGetBoxGeometry().

=head2 pixaGetBoxGeometry

l_int32 pixaGetBoxGeometry ( PIXA *pixa, l_int32 index, l_int32 *px, l_int32 *py, l_int32 *pw, l_int32 *ph )

  pixaGetBoxGeometry()

      Input:  pixa
              index  (to the index-th box)
              &x, &y, &w, &h (<optional return>; each can be null)
      Return: 0 if OK, 1 on error

=head2 pixaGetBoxa

BOXA * pixaGetBoxa ( PIXA *pixa, l_int32 accesstype )

  pixaGetBoxa()

      Input:  pixa
              accesstype  (L_COPY, L_CLONE, L_COPY_CLONE)
      Return: boxa, or null on error

=head2 pixaGetBoxaCount

l_int32 pixaGetBoxaCount ( PIXA *pixa )

  pixaGetBoxaCount()

      Input:  pixa
      Return: count, or 0 on error

=head2 pixaGetCount

l_int32 pixaGetCount ( PIXA *pixa )

  pixaGetCount()

      Input:  pixa
      Return: count, or 0 if no pixa

=head2 pixaGetLinePtrs

void *** pixaGetLinePtrs ( PIXA *pixa, l_int32 *psize )

  pixaGetLinePtrs()

      Input:  pixa (of pix that all have the same depth)
              &size (<optional return> number of pix in the pixa)
      Return: array of array of line ptrs, or null on error

  Notes:
      (1) See pixGetLinePtrs() for details.
      (2) It is best if all pix in the pixa are the same size.
          The size of each line ptr array is equal to the height
          of the pix that it refers to.
      (3) This is an array of arrays.  To destroy it:
            for (i = 0; i < size; i++)
                FREE(lineset[i]);
            FREE(lineset);

=head2 pixaGetPix

PIX * pixaGetPix ( PIXA *pixa, l_int32 index, l_int32 accesstype )

  pixaGetPix()

      Input:  pixa
              index  (to the index-th pix)
              accesstype  (L_COPY or L_CLONE)
      Return: pix, or null on error

=head2 pixaGetPixArray

PIX ** pixaGetPixArray ( PIXA *pixa )

  pixaGetPixArray()

      Input:  pixa
      Return: pix array, or null on error

  Notes:
      (1) This returns a ptr to the actual array.  The array is
          owned by the pixa, so it must not be destroyed.
      (2) The caller should always check if the return value is NULL
          before accessing any of the pix ptrs in this array!

=head2 pixaGetPixDimensions

l_int32 pixaGetPixDimensions ( PIXA *pixa, l_int32 index, l_int32 *pw, l_int32 *ph, l_int32 *pd )

  pixaGetPixDimensions()

      Input:  pixa
              index  (to the index-th box)
              &w, &h, &d (<optional return>; each can be null)
      Return: 0 if OK, 1 on error

=head2 pixaInitFull

l_int32 pixaInitFull ( PIXA *pixa, PIX *pix, BOX *box )

  pixaInitFull()

      Input:  pixa (typically empty)
              pix (<optional> to be replicated into the entire pixa ptr array)
              box (<optional> to be replicated into the entire boxa ptr array)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This initializes a pixa by filling up the entire pix ptr array
          with copies of @pix.  If @pix == NULL, we use a tiny placeholder
          pix (w = h = d = 1).  Any existing pix are destroyed.
          It also optionally fills the boxa with copies of @box.
          After this operation, the numbers of pix and (optionally)
          boxes are equal to the number of allocated ptrs.
      (2) Note that we use pixaReplacePix() instead of pixaInsertPix().
          They both have the same effect when inserting into a NULL ptr
          in the pixa ptr array:
      (3) If the boxa is not initialized (i.e., filled with boxes),
          later insertion of boxes will cause an error, because the
          'n' field is 0.
      (4) Example usage.  This function is useful to prepare for a
          random insertion (or replacement) of pix into a pixa.
          To randomly insert pix into a pixa, without boxes, up to
          some index "max":
             Pixa *pixa = pixaCreate(max);
             pixaInitFull(pixa, NULL, NULL);
          An existing pixa with a smaller ptr array can also be reused:
             pixaExtendArrayToSize(pixa, max);
             pixaInitFull(pixa, NULL, NULL);
          The initialization allows the pixa to always be properly
          filled, even if all pix (and boxes) are not later replaced.

=head2 pixaInsertPix

l_int32 pixaInsertPix ( PIXA *pixa, l_int32 index, PIX *pixs, BOX *box )

  pixaInsertPix()

      Input:  pixa
              index (at which pix is to be inserted)
              pixs (new pix to be inserted)
              box (<optional> new box to be inserted)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This shifts pixa[i] --> pixa[i + 1] for all i >= index,
          and then inserts at pixa[index].
      (2) To insert at the beginning of the array, set index = 0.
      (3) It should not be used repeatedly on large arrays,
          because the function is O(n).
      (4) To append a pix to a pixa, it's easier to use pixaAddPix().

=head2 pixaIsFull

l_int32 pixaIsFull ( PIXA *pixa, l_int32 *pfullpa, l_int32 *pfullba )

  pixaIsFull()

      Input:  pixa
              &fullpa (<optional return> 1 if pixa is full)
              &fullba (<optional return> 1 if boxa is full)
      Return: 0 if OK, 1 on error

  Notes:
      (1) A pixa is "full" if the array of pix is fully
          occupied from index 0 to index (pixa->n - 1).

=head2 pixaJoin

l_int32 pixaJoin ( PIXA *pixad, PIXA *pixas, l_int32 istart, l_int32 iend )

  pixaJoin()

      Input:  pixad  (dest pixa; add to this one)
              pixas  (<optional> source pixa; add from this one)
              istart  (starting index in pixas)
              iend  (ending index in pixas; use -1 to cat all)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This appends a clone of each indicated pix in pixas to pixad
      (2) istart < 0 is taken to mean 'read from the start' (istart = 0)
      (3) iend < 0 means 'read to the end'
      (4) If pixas is NULL or contains no pix, this is a no-op.

=head2 pixaRead

PIXA * pixaRead ( const char *filename )

  pixaRead()

      Input:  filename
      Return: pixa, or null on error

  Notes:
      (1) The pix are stored in the file as png.
          If the png library is not linked, this will fail.

=head2 pixaReadStream

PIXA * pixaReadStream ( FILE *fp )

  pixaReadStream()

      Input:  stream
      Return: pixa, or null on error

  Notes:
      (1) The pix are stored in the file as png.
          If the png library is not linked, this will fail.

=head2 pixaRemovePix

l_int32 pixaRemovePix ( PIXA *pixa, l_int32 index )

  pixaRemovePix()

      Input:  pixa
              index (of pix to be removed)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This shifts pixa[i] --> pixa[i - 1] for all i > index.
      (2) It should not be used repeatedly on large arrays,
          because the function is O(n).
      (3) The corresponding box is removed as well, if it exists.

=head2 pixaRemovePixAndSave

l_int32 pixaRemovePixAndSave ( PIXA *pixa, l_int32 index, PIX **ppix, BOX **pbox )

  pixaRemovePixAndSave()

      Input:  pixa
              index (of pix to be removed)
              &pix (<optional return> removed pix)
              &box (<optional return> removed box)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This shifts pixa[i] --> pixa[i - 1] for all i > index.
      (2) It should not be used repeatedly on large arrays,
          because the function is O(n).
      (3) The corresponding box is removed as well, if it exists.
      (4) The removed pix and box can either be retained or destroyed.

=head2 pixaReplacePix

l_int32 pixaReplacePix ( PIXA *pixa, l_int32 index, PIX *pix, BOX *box )

  pixaReplacePix()

      Input:  pixa
              index  (to the index-th pix)
              pix (insert to replace existing one)
              box (<optional> insert to replace existing)
      Return: 0 if OK, 1 on error

  Notes:
      (1) In-place replacement of one pix.
      (2) The previous pix at that location is destroyed.

=head2 pixaSetBoxa

l_int32 pixaSetBoxa ( PIXA *pixa, BOXA *boxa, l_int32 accesstype )

  pixaSetBoxa()

      Input:  pixa
              boxa
              accesstype  (L_INSERT, L_COPY, L_CLONE)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This destroys the existing boxa in the pixa.

=head2 pixaSplitPix

PIXA * pixaSplitPix ( PIX *pixs, l_int32 nx, l_int32 ny, l_int32 borderwidth, l_uint32 bordercolor )

  pixaSplitPix()

      Input:  pixs  (with individual components on a lattice)
              nx   (number of mosaic cells horizontally)
              ny   (number of mosaic cells vertically)
              borderwidth  (of added border on all sides)
              bordercolor  (in our RGBA format: 0xrrggbbaa)
      Return: pixa, or null on error

  Notes:
      (1) This is a variant on pixaCreateFromPix(), where we
          simply divide the image up into (approximately) equal
          subunits.  If you want the subimages to have essentially
          the same aspect ratio as the input pix, use nx = ny.
      (2) If borderwidth is 0, we ignore the input bordercolor and
          redefine it to white.
      (3) The bordercolor is always used to initialize each tiled pix,
          so that if the src is clipped, the unblitted part will
          be this color.  This avoids 1 pixel wide black stripes at the
          left and lower edges.

=head2 pixaVerifyDepth

l_int32 pixaVerifyDepth ( PIXA *pixa, l_int32 *pmaxdepth )

  pixaVerifyDepth()

      Input:  pixa
              &maxdepth (<optional return> max depth of all pix)
      Return: depth (return 0 if they're not all the same, or on error)

  Notes:
      (1) It is considered to be an error if there are no pix.

=head2 pixaWrite

l_int32 pixaWrite ( const char *filename, PIXA *pixa )

  pixaWrite()

      Input:  filename
              pixa
      Return: 0 if OK, 1 on error

  Notes:
      (1) The pix are stored in the file as png.
          If the png library is not linked, this will fail.

=head2 pixaWriteStream

l_int32 pixaWriteStream ( FILE *fp, PIXA *pixa )

  pixaWriteStream()

      Input:  stream (opened for "wb")
              pixa
      Return: 0 if OK, 1 on error

  Notes:
      (1) The pix are stored in the file as png.
          If the png library is not linked, this will fail.

=head2 pixaaAddBox

l_int32 pixaaAddBox ( PIXAA *paa, BOX *box, l_int32 copyflag )

  pixaaAddBox()

      Input:  paa
              box
              copyflag (L_INSERT, L_COPY, L_CLONE)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The box can be used, for example, to hold the support region
          of a pixa that is being added to the pixaa.

=head2 pixaaAddPix

l_int32 pixaaAddPix ( PIXAA *paa, l_int32 index, PIX *pix, BOX *box, l_int32 copyflag )

  pixaaAddPix()

      Input:  paa  (input paa)
              index (index of pixa in paa)
              pix (to be added)
              box (<optional> to be added)
              copyflag (L_INSERT, L_COPY, L_CLONE)
      Return: 0 if OK; 1 on error

=head2 pixaaAddPixa

l_int32 pixaaAddPixa ( PIXAA *paa, PIXA *pixa, l_int32 copyflag )

  pixaaAddPixa()

      Input:  paa
              pixa  (to be added)
              copyflag:
                L_INSERT inserts the pixa directly
                L_COPY makes a new pixa and copies each pix and each box
                L_CLONE gives a new handle to the input pixa
                L_COPY_CLONE makes a new pixa and inserts clones of
                    all pix and boxes
      Return: 0 if OK; 1 on error

=head2 pixaaClear

l_int32 pixaaClear ( PIXAA *paa )

  pixaaClear()

      Input:  paa
      Return: 0 if OK, 1 on error

  Notes:
      (1) This destroys all pixa in the pixaa, and nulls the ptrs
          in the pixa ptr array.

=head2 pixaaCreate

PIXAA * pixaaCreate ( l_int32 n )

  pixaaCreate()

      Input:  n  (initial number of pixa ptrs)
      Return: paa, or null on error

  Notes:
      (1) A pixaa provides a 2-level hierarchy of images.
          A common use is for segmentation masks, which are
          inexpensive to store in png format.
      (2) For example, suppose you want a mask for each textline
          in a two-column page.  The textline masks for each column
          can be represented by a pixa, of which there are 2 in the pixaa.
          The boxes for the textline mask components within a column
          can have their origin referred to the column rather than the page.
          Then the boxa field can be used to represent the two box (regions)
          for the columns, and the (x,y) components of each box can
          be used to get the absolute position of the textlines on
          the page.

=head2 pixaaCreateFromPixa

PIXAA * pixaaCreateFromPixa ( PIXA *pixa, l_int32 n, l_int32 type, l_int32 copyflag )

  pixaaCreateFromPixa()

      Input:  pixa
              n (number specifying subdivision of pixa)
              type (L_CHOOSE_CONSECUTIVE, L_CHOOSE_SKIP_BY)
              copyflag (L_CLONE, L_COPY)
      Return: paa, or null on error

  Notes:
      (1) This subdivides a pixa into a set of smaller pixa that
          are accumulated into a pixaa.
      (2) If type == L_CHOOSE_CONSECUTIVE, the first 'n' pix are
          put in a pixa and added to pixaa, then the next 'n', etc.
          If type == L_CHOOSE_SKIP_BY, the first pixa is made by
          aggregating pix[0], pix[n], pix[2*n], etc.
      (3) The copyflag specifies if each new pix is a copy or a clone.

=head2 pixaaDestroy

void pixaaDestroy ( PIXAA **ppaa )

  pixaaDestroy()

      Input:  &paa <to be nulled>
      Return: void

=head2 pixaaExtendArray

l_int32 pixaaExtendArray ( PIXAA *paa )

  pixaaExtendArray()

      Input:  paa
      Return: 0 if OK; 1 on error

=head2 pixaaGetBoxa

BOXA * pixaaGetBoxa ( PIXAA *paa, l_int32 accesstype )

  pixaaGetBoxa()

      Input:  paa
              accesstype  (L_COPY, L_CLONE)
      Return: boxa, or null on error

  Notes:
      (1) L_COPY returns a copy; L_CLONE returns a new reference to the boxa.
      (2) In both cases, invoke boxaDestroy() on the returned boxa.

=head2 pixaaGetCount

l_int32 pixaaGetCount ( PIXAA *paa, NUMA **pna )

  pixaaGetCount()

      Input:  paa
              &na (<optional return> number of pix in each pixa)
      Return: count, or 0 if no pixaa

  Notes:
      (1) If paa is empty, a returned na will also be empty.

=head2 pixaaGetPix

PIX * pixaaGetPix ( PIXAA *paa, l_int32 index, l_int32 ipix, l_int32 accessflag )

  pixaaGetPix()

      Input:  paa
              index  (index into the pixa array in the pixaa)
              ipix  (index into the pix array in the pixa)
              accessflag  (L_COPY or L_CLONE)
      Return: pix, or null on error

=head2 pixaaGetPixa

PIXA * pixaaGetPixa ( PIXAA *paa, l_int32 index, l_int32 accesstype )

  pixaaGetPixa()

      Input:  paa
              index  (to the index-th pixa)
              accesstype  (L_COPY, L_CLONE, L_COPY_CLONE)
      Return: pixa, or null on error

  Notes:
      (1) L_COPY makes a new pixa with a copy of every pix
      (2) L_CLONE just makes a new reference to the pixa,
          and bumps the counter.  You would use this, for example,
          when you need to extract some data from a pix within a
          pixa within a pixaa.
      (3) L_COPY_CLONE makes a new pixa with a clone of every pix
          and box
      (4) In all cases, you must invoke pixaDestroy() on the returned pixa

=head2 pixaaInitFull

l_int32 pixaaInitFull ( PIXAA *paa, PIXA *pixa )

  pixaaInitFull()

      Input:  paa (typically empty)
              pixa (to be replicated into the entire pixa ptr array)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This initializes a pixaa by filling up the entire pixa ptr array
          with copies of @pixa.  Any existing pixa are destroyed.
      (2) Example usage.  This function is useful to prepare for a
          random insertion (or replacement) of pixa into a pixaa.
          To randomly insert pixa into a pixaa, up to some index "max":
             Pixaa *paa = pixaaCreate(max);
             Pixa *pixa = pixaCreate(1);  // if you want little memory
             pixaaInitFull(paa, pixa);  // copy it to entire array
             pixaDestroy(&pixa);  // no longer needed
          The initialization allows the pixaa to always be properly filled.

=head2 pixaaIsFull

l_int32 pixaaIsFull ( PIXAA *paa, l_int32 *pfull )

  pixaaIsFull()

      Input:  paa
              &full (<return> 1 if all pixa in the paa have full pix arrays)
      Return: return 0 if OK, 1 on error

  Notes:
      (1) Does not require boxa associated with each pixa to be full.

=head2 pixaaJoin

l_int32 pixaaJoin ( PIXAA *paad, PIXAA *paas, l_int32 istart, l_int32 iend )

  pixaaJoin()

      Input:  paad  (dest pixaa; add to this one)
              paas  (<optional> source pixaa; add from this one)
              istart  (starting index in pixaas)
              iend  (ending index in pixaas; use -1 to cat all)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This appends a clone of each indicated pixa in paas to pixaad
      (2) istart < 0 is taken to mean 'read from the start' (istart = 0)
      (3) iend < 0 means 'read to the end'

=head2 pixaaRead

PIXAA * pixaaRead ( const char *filename )

  pixaaRead()

      Input:  filename
      Return: paa, or null on error

  Notes:
      (1) The pix are stored in the file as png.
          If the png library is not linked, this will fail.

=head2 pixaaReadFromFiles

PIXAA * pixaaReadFromFiles ( const char *dirname, const char *substr, l_int32 first, l_int32 nfiles )

  pixaaReadFromFiles()

      Input:  dirname (directory)
              substr (<optional> substring filter on filenames; can be NULL)
              first (0-based)
              nfiles (use 0 for everything from @first to the end)
      Return: paa, or null on error or if no pixa files are found.

  Notes:
      (1) The files must be serialized pixa files (e.g., *.pa)
          If some files cannot be read, warnings are issued.
      (2) Use @substr to filter filenames in the directory.  If
          @substr == NULL, this takes all files.
      (3) After filtering, use @first and @nfiles to select
          a contiguous set of files, that have been lexically
          sorted in increasing order.

=head2 pixaaReadStream

PIXAA * pixaaReadStream ( FILE *fp )

  pixaaReadStream()

      Input:  stream
      Return: paa, or null on error

  Notes:
      (1) The pix are stored in the file as png.
          If the png library is not linked, this will fail.

=head2 pixaaReplacePixa

l_int32 pixaaReplacePixa ( PIXAA *paa, l_int32 index, PIXA *pixa )

  pixaaReplacePixa()

      Input:  paa
              index  (to the index-th pixa)
              pixa (insert to replace existing one)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This allows random insertion of a pixa into a pixaa, with
          destruction of any existing pixa at that location.
          The input pixa is now owned by the pixaa.
      (2) No other pixa in the array are affected.
      (3) The index must be within the allowed set.

=head2 pixaaTruncate

l_int32 pixaaTruncate ( PIXAA *paa )

  pixaaTruncate()

      Input:  paa
      Return: 0 if OK, 1 on error

  Notes:
      (1) This identifies the largest index containing a pixa that
          has any pix within it, destroys all pixa above that index,
          and resets the count.

=head2 pixaaVerifyDepth

l_int32 pixaaVerifyDepth ( PIXAA *paa, l_int32 *pmaxdepth )

  pixaaVerifyDepth()

      Input:  paa
              &maxdepth (<optional return> max depth of all pix in pixaa)
      Return: depth (return 0 if they're not all the same, or on error)

=head2 pixaaWrite

l_int32 pixaaWrite ( const char *filename, PIXAA *paa )

  pixaaWrite()

      Input:  filename
              paa
      Return: 0 if OK, 1 on error

  Notes:
      (1) The pix are stored in the file as png.
          If the png library is not linked, this will fail.

=head2 pixaaWriteStream

l_int32 pixaaWriteStream ( FILE *fp, PIXAA *paa )

  pixaaWriteStream()

      Input:  stream (opened for "wb")
              paa
      Return: 0 if OK, 1 on error

  Notes:
      (1) The pix are stored in the file as png.
          If the png library is not linked, this will fail.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
