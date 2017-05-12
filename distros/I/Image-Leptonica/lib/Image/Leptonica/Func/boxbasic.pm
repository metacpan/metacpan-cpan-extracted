package Image::Leptonica::Func::boxbasic;
$Image::Leptonica::Func::boxbasic::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::boxbasic

=head1 VERSION

version 0.04

=head1 C<boxbasic.c>

   boxbasic.c

   Basic 'class' functions for box, boxa and boxaa,
   including accessors and serialization.

      Box creation, copy, clone, destruction
           BOX      *boxCreate()
           BOX      *boxCreateValid()
           BOX      *boxCopy()
           BOX      *boxClone()
           void      boxDestroy()

      Box accessors
           l_int32   boxGetGeometry()
           l_int32   boxSetGeometry()
           l_int32   boxGetSideLocation()
           l_int32   boxGetRefcount()
           l_int32   boxChangeRefcount()
           l_int32   boxIsValid()

      Boxa creation, copy, destruction
           BOXA     *boxaCreate()
           BOXA     *boxaCopy()
           void      boxaDestroy()

      Boxa array extension
           l_int32   boxaAddBox()
           l_int32   boxaExtendArray()
           l_int32   boxaExtendArrayToSize()

      Boxa accessors
           l_int32   boxaGetCount()
           l_int32   boxaGetValidCount()
           BOX      *boxaGetBox()
           BOX      *boxaGetValidBox()
           l_int32   boxaGetBoxGeometry()
           l_int32   boxaIsFull()

      Boxa array modifiers
           l_int32   boxaReplaceBox()
           l_int32   boxaInsertBox()
           l_int32   boxaRemoveBox()
           l_int32   boxaRemoveBoxAndSave()
           l_int32   boxaInitFull()
           l_int32   boxaClear()

      Boxaa creation, copy, destruction
           BOXAA    *boxaaCreate()
           BOXAA    *boxaaCopy()
           void      boxaaDestroy()

      Boxaa array extension
           l_int32   boxaaAddBoxa()
           l_int32   boxaaExtendArray()
           l_int32   boxaaExtendArrayToSize()

      Boxaa accessors
           l_int32   boxaaGetCount()
           l_int32   boxaaGetBoxCount()
           BOXA     *boxaaGetBoxa()
           BOX      *boxaaGetBox()

      Boxaa array modifiers
           l_int32   boxaaInitFull()
           l_int32   boxaaExtendWithInit()
           l_int32   boxaaReplaceBoxa()
           l_int32   boxaaInsertBoxa()
           l_int32   boxaaRemoveBoxa()
           l_int32   boxaaAddBox()

      Boxaa serialized I/O
           BOXAA    *boxaaReadFromFiles()
           BOXAA    *boxaaRead()
           BOXAA    *boxaaReadStream()
           l_int32   boxaaWrite()
           l_int32   boxaaWriteStream()

      Boxa serialized I/O
           BOXA     *boxaRead()
           BOXA     *boxaReadStream()
           BOXA     *boxaReadMem()
           l_int32   boxaWrite()
           l_int32   boxaWriteStream()
           l_int32   boxaWriteMem()

      Box print (for debug)
           l_int32   boxPrintStreamInfo()

   Most functions use only valid boxes, which are boxes that have both
   width and height > 0.  However, a few functions, such as
   boxaGetMedian() do not assume that all boxes are valid.  For any
   function that can use a boxa with invalid boxes, it is convenient
   to use these accessors:
       boxaGetValidCount()   :  count of valid boxes
       boxaGetValidBox()     :  returns NULL for invalid boxes

=head1 FUNCTIONS

=head2 boxClone

BOX * boxClone ( BOX *box )

  boxClone()

      Input:  box
      Return: ptr to same box, or null on error

=head2 boxCopy

BOX * boxCopy ( BOX *box )

  boxCopy()

      Input:  box
      Return: copy of box, or null on error

=head2 boxCreate

BOX * boxCreate ( l_int32 x, l_int32 y, l_int32 w, l_int32 h )

  boxCreate()

      Input:  x, y, w, h
      Return: box, or null on error

  Notes:
      (1) This clips the box to the +quad.  If no part of the
          box is in the +quad, this returns NULL.
      (2) We allow you to make a box with w = 0 and/or h = 0.
          This does not represent a valid region, but it is useful
          as a placeholder in a boxa for which the index of the
          box in the boxa is important.  This is an atypical
          situation; usually you want to put only valid boxes with
          nonzero width and height in a boxa.  If you have a boxa
          with invalid boxes, the accessor boxaGetValidBox()
          will return NULL on each invalid box.
      (3) If you want to create only valid boxes, use boxCreateValid(),
          which returns NULL if either w or h is 0.

=head2 boxCreateValid

BOX * boxCreateValid ( l_int32 x, l_int32 y, l_int32 w, l_int32 h )

  boxCreateValid()

      Input:  x, y, w, h
      Return: box, or null on error

  Notes:
      (1) This returns NULL if either w = 0 or h = 0.

=head2 boxDestroy

void boxDestroy ( BOX **pbox )

  boxDestroy()

      Input:  &box (<will be set to null before returning>)
      Return: void

  Notes:
      (1) Decrements the ref count and, if 0, destroys the box.
      (2) Always nulls the input ptr.

=head2 boxGetGeometry

l_int32 boxGetGeometry ( BOX *box, l_int32 *px, l_int32 *py, l_int32 *pw, l_int32 *ph )

  boxGetGeometry()

      Input:  box
              &x, &y, &w, &h (<optional return>; each can be null)
      Return: 0 if OK, 1 on error

=head2 boxGetSideLocation

l_int32 boxGetSideLocation ( BOX *box, l_int32 side, l_int32 *ploc )

  boxGetSideLocation()

      Input:  box
              side (L_GET_LEFT, L_GET_RIGHT, L_GET_TOP, L_GET_BOT)
              &loc (<return> location)
      Return: 0 if OK, 1 on error

  Notes:
      (1) All returned values are within the box.  In particular:
            right = left + width - 1
            bottom = top + height - 1

=head2 boxIsValid

l_int32 boxIsValid ( BOX *box, l_int32 *pvalid )

  boxIsValid()

      Input:  box
              &valid (<return> 1 if valid; 0 otherwise)
      Return: 0 if OK, 1 on error

=head2 boxPrintStreamInfo

l_int32 boxPrintStreamInfo ( FILE *fp, BOX *box )

  boxPrintStreamInfo()

      Input:  stream
              box
      Return: 0 if OK, 1 on error

  Notes:
      (1) This outputs debug info.  Use serialization functions to
          write to file if you want to read the data back.

=head2 boxSetGeometry

l_int32 boxSetGeometry ( BOX *box, l_int32 x, l_int32 y, l_int32 w, l_int32 h )

  boxSetGeometry()

      Input:  box
              x, y, w, h (use -1 to leave unchanged)
      Return: 0 if OK, 1 on error

=head2 boxaAddBox

l_int32 boxaAddBox ( BOXA *boxa, BOX *box, l_int32 copyflag )

  boxaAddBox()

      Input:  boxa
              box  (to be added)
              copyflag (L_INSERT, L_COPY, L_CLONE)
      Return: 0 if OK, 1 on error

=head2 boxaClear

l_int32 boxaClear ( BOXA *boxa )

  boxaClear()

      Input:  boxa
      Return: 0 if OK, 1 on error

  Notes:
      (1) This destroys all boxes in the boxa, setting the ptrs
          to null.  The number of allocated boxes, n, is set to 0.

=head2 boxaCopy

BOXA * boxaCopy ( BOXA *boxa, l_int32 copyflag )

  boxaCopy()

      Input:  boxa
              copyflag (L_COPY, L_CLONE, L_COPY_CLONE)
      Return: new boxa, or null on error

  Notes:
      (1) See pix.h for description of the copyflag.
      (2) The copy-clone makes a new boxa that holds clones of each box.

=head2 boxaCreate

BOXA * boxaCreate ( l_int32 n )

  boxaCreate()

      Input:  n  (initial number of ptrs)
      Return: boxa, or null on error

=head2 boxaDestroy

void boxaDestroy ( BOXA **pboxa )

  boxaDestroy()

      Input:  &boxa (<will be set to null before returning>)
      Return: void

  Note:
      - Decrements the ref count and, if 0, destroys the boxa.
      - Always nulls the input ptr.

=head2 boxaExtendArray

l_int32 boxaExtendArray ( BOXA *boxa )

  boxaExtendArray()

      Input:  boxa
      Return: 0 if OK; 1 on error

  Notes:
      (1) Reallocs with doubled size of ptr array.

=head2 boxaExtendArrayToSize

l_int32 boxaExtendArrayToSize ( BOXA *boxa, l_int32 size )

  boxaExtendArrayToSize()

      Input:  boxa
              size (new size of boxa array)
      Return: 0 if OK; 1 on error

  Notes:
      (1) If necessary, reallocs new boxa ptr array to @size.

=head2 boxaGetBox

BOX * boxaGetBox ( BOXA *boxa, l_int32 index, l_int32 accessflag )

  boxaGetBox()

      Input:  boxa
              index  (to the index-th box)
              accessflag  (L_COPY or L_CLONE)
      Return: box, or null on error

=head2 boxaGetBoxGeometry

l_int32 boxaGetBoxGeometry ( BOXA *boxa, l_int32 index, l_int32 *px, l_int32 *py, l_int32 *pw, l_int32 *ph )

  boxaGetBoxGeometry()

      Input:  boxa
              index  (to the index-th box)
              &x, &y, &w, &h (<optional return>; each can be null)
      Return: 0 if OK, 1 on error

=head2 boxaGetCount

l_int32 boxaGetCount ( BOXA *boxa )

  boxaGetCount()

      Input:  boxa
      Return: count (of all boxes); 0 if no boxes or on error

=head2 boxaGetValidBox

BOX * boxaGetValidBox ( BOXA *boxa, l_int32 index, l_int32 accessflag )

  boxaGetValidBox()

      Input:  boxa
              index  (to the index-th box)
              accessflag  (L_COPY or L_CLONE)
      Return: box, or null if box is not valid or on error

  Notes:
      (1) This returns NULL for an invalid box in a boxa.
          For a box to be valid, both the width and height must be > 0.
      (2) We allow invalid boxes, with w = 0 or h = 0, as placeholders
          in boxa for which the index of the box in the boxa is important.
          This is an atypical situation; usually you want to put only
          valid boxes in a boxa.

=head2 boxaGetValidCount

l_int32 boxaGetValidCount ( BOXA *boxa )

  boxaGetValidCount()

      Input:  boxa
      Return: count (of valid boxes); 0 if no valid boxes or on error

=head2 boxaInitFull

l_int32 boxaInitFull ( BOXA *boxa, BOX *box )

  boxaInitFull()

      Input:  boxa (typically empty)
              box (<optional> to be replicated into the entire ptr array)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This initializes a boxa by filling up the entire box ptr array
          with copies of @box.  If @box == NULL, use a placeholder box
          of zero size.  Any existing boxes are destroyed.
          After this opepration, the number of boxes is equal to
          the number of allocated ptrs.
      (2) Note that we use boxaReplaceBox() instead of boxaInsertBox().
          They both have the same effect when inserting into a NULL ptr
          in the boxa ptr array:
      (3) Example usage.  This function is useful to prepare for a
          random insertion (or replacement) of boxes into a boxa.
          To randomly insert boxes into a boxa, up to some index "max":
             Boxa *boxa = boxaCreate(max);
             boxaInitFull(boxa, NULL);
          If you want placeholder boxes of non-zero size:
             Boxa *boxa = boxaCreate(max);
             Box *box = boxCreate(...);
             boxaInitFull(boxa, box);
             boxDestroy(&box);
          If we have an existing boxa with a smaller ptr array, it can
          be reused for up to max boxes:
             boxaExtendArrayToSize(boxa, max);
             boxaInitFull(boxa, NULL);
          The initialization allows the boxa to always be properly
          filled, even if all the boxes are not later replaced.
          If you want to know which boxes have been replaced,
          and you initialized with invalid zero-sized boxes,
          use boxaGetValidBox() to return NULL for the invalid boxes.

=head2 boxaInsertBox

l_int32 boxaInsertBox ( BOXA *boxa, l_int32 index, BOX *box )

  boxaInsertBox()

      Input:  boxa
              index (location in boxa to insert new value)
              box (new box to be inserted)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This shifts box[i] --> box[i + 1] for all i >= index,
          and then inserts box as box[index].
      (2) To insert at the beginning of the array, set index = 0.
      (3) To append to the array, it's easier to use boxaAddBox().
      (4) This should not be used repeatedly to insert into large arrays,
          because the function is O(n).

=head2 boxaIsFull

l_int32 boxaIsFull ( BOXA *boxa, l_int32 *pfull )

  boxaIsFull()

      Input:  boxa
              &full (return> 1 if boxa is full)
      Return: 0 if OK, 1 on error

=head2 boxaRead

BOXA * boxaRead ( const char *filename )

  boxaRead()

      Input:  filename
      Return: boxa, or null on error

=head2 boxaReadMem

BOXA * boxaReadMem ( const l_uint8 *data, size_t size )

  boxaReadMem()

      Input:  data (ascii)
              size (of data; can use strlen to get it)
      Return: boxa, or null on error

=head2 boxaReadStream

BOXA * boxaReadStream ( FILE *fp )

  boxaReadStream()

      Input:  stream
      Return: boxa, or null on error

=head2 boxaRemoveBox

l_int32 boxaRemoveBox ( BOXA *boxa, l_int32 index )

  boxaRemoveBox()

      Input:  boxa
              index (of box to be removed)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This removes box[index] and then shifts
          box[i] --> box[i - 1] for all i > index.
      (2) It should not be used repeatedly to remove boxes from
          large arrays, because the function is O(n).

=head2 boxaRemoveBoxAndSave

l_int32 boxaRemoveBoxAndSave ( BOXA *boxa, l_int32 index, BOX **pbox )

  boxaRemoveBoxAndSave()

      Input:  boxa
              index (of box to be removed)
              &box (<optional return> removed box)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This removes box[index] and then shifts
          box[i] --> box[i - 1] for all i > index.
      (2) It should not be used repeatedly to remove boxes from
          large arrays, because the function is O(n).

=head2 boxaReplaceBox

l_int32 boxaReplaceBox ( BOXA *boxa, l_int32 index, BOX *box )

  boxaReplaceBox()

      Input:  boxa
              index  (to the index-th box)
              box (insert to replace existing one)
      Return: 0 if OK, 1 on error

  Notes:
      (1) In-place replacement of one box.
      (2) The previous box at that location, if any, is destroyed.

=head2 boxaWrite

l_int32 boxaWrite ( const char *filename, BOXA *boxa )

  boxaWrite()

      Input:  filename
              boxa
      Return: 0 if OK, 1 on error

=head2 boxaWriteMem

l_int32 boxaWriteMem ( l_uint8 **pdata, size_t *psize, BOXA *boxa )

  boxaWriteMem()

      Input:  &data (<return> data of serialized boxa; ascii)
              &size (<return> size of returned data)
              boxa
      Return: 0 if OK, 1 on error

=head2 boxaWriteStream

l_int32 boxaWriteStream ( FILE *fp, BOXA *boxa )

  boxaWriteStream()

      Input: stream
             boxa
      Return: 0 if OK, 1 on error

=head2 boxaaAddBox

l_int32 boxaaAddBox ( BOXAA *baa, l_int32 index, BOX *box, l_int32 accessflag )

  boxaaAddBox()

      Input:  boxaa
              index (of boxa with boxaa)
              box (to be added)
              accessflag (L_INSERT, L_COPY or L_CLONE)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Adds to an existing boxa only.

=head2 boxaaAddBoxa

l_int32 boxaaAddBoxa ( BOXAA *baa, BOXA *ba, l_int32 copyflag )

  boxaaAddBoxa()

      Input:  boxaa
              boxa     (to be added)
              copyflag  (L_INSERT, L_COPY, L_CLONE)
      Return: 0 if OK, 1 on error

=head2 boxaaCopy

BOXAA * boxaaCopy ( BOXAA *baas, l_int32 copyflag )

  boxaaCopy()

      Input:  baas (input boxaa to be copied)
              copyflag (L_COPY, L_CLONE)
      Return: baad (new boxaa, composed of copies or clones of the boxa
                    in baas), or null on error

  Notes:
      (1) L_COPY makes a copy of each boxa in baas.
          L_CLONE makes a clone of each boxa in baas.

=head2 boxaaCreate

BOXAA * boxaaCreate ( l_int32 n )

  boxaaCreate()

      Input:  size of boxa ptr array to be alloc'd (0 for default)
      Return: baa, or null on error

=head2 boxaaDestroy

void boxaaDestroy ( BOXAA **pbaa )

  boxaaDestroy()

      Input:  &boxaa (<will be set to null before returning>)
      Return: void

=head2 boxaaExtendArray

l_int32 boxaaExtendArray ( BOXAA *baa )

  boxaaExtendArray()

      Input:  boxaa
      Return: 0 if OK, 1 on error

=head2 boxaaExtendArrayToSize

l_int32 boxaaExtendArrayToSize ( BOXAA *baa, l_int32 size )

  boxaaExtendArrayToSize()

      Input:  boxaa
              size (new size of boxa array)
      Return: 0 if OK; 1 on error

  Notes:
      (1) If necessary, reallocs the boxa ptr array to @size.

=head2 boxaaExtendWithInit

l_int32 boxaaExtendWithInit ( BOXAA *baa, l_int32 maxindex, BOXA *boxa )

  boxaaExtendWithInit()

      Input:  boxaa
              maxindex
              boxa (to be replicated into the extended ptr array)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This should be used on an existing boxaa that has been
          fully loaded with boxa.  It then extends the boxaa,
          loading all the additional ptrs with copies of boxa.
          Typically, boxa will be empty.

=head2 boxaaGetBox

BOX * boxaaGetBox ( BOXAA *baa, l_int32 iboxa, l_int32 ibox, l_int32 accessflag )

  boxaaGetBox()

      Input:  baa
              iboxa  (index into the boxa array in the boxaa)
              ibox  (index into the box array in the boxa)
              accessflag   (L_COPY or L_CLONE)
      Return: box, or null on error

=head2 boxaaGetBoxCount

l_int32 boxaaGetBoxCount ( BOXAA *baa )

  boxaaGetBoxCount()

      Input:  boxaa
      Return: count (number of boxes), or 0 if no boxes or on error

=head2 boxaaGetBoxa

BOXA * boxaaGetBoxa ( BOXAA *baa, l_int32 index, l_int32 accessflag )

  boxaaGetBoxa()

      Input:  boxaa
              index  (to the index-th boxa)
              accessflag   (L_COPY or L_CLONE)
      Return: boxa, or null on error

=head2 boxaaGetCount

l_int32 boxaaGetCount ( BOXAA *baa )

  boxaaGetCount()

      Input:  boxaa
      Return: count (number of boxa), or 0 if no boxa or on error

=head2 boxaaInitFull

l_int32 boxaaInitFull ( BOXAA *baa, BOXA *boxa )

  boxaaInitFull()

      Input:  boxaa (typically empty)
              boxa (to be replicated into the entire ptr array)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This initializes a boxaa by filling up the entire boxa ptr array
          with copies of @boxa.  Any existing boxa are destroyed.
          After this operation, the number of boxa is equal to
          the number of allocated ptrs.
      (2) Note that we use boxaaReplaceBox() instead of boxaInsertBox().
          They both have the same effect when inserting into a NULL ptr
          in the boxa ptr array
      (3) Example usage.  This function is useful to prepare for a
          random insertion (or replacement) of boxa into a boxaa.
          To randomly insert boxa into a boxaa, up to some index "max":
             Boxaa *baa = boxaaCreate(max);
               // initialize the boxa
             Boxa *boxa = boxaCreate(...);
             ...  [optionally fix with boxes]
             boxaaInitFull(baa, boxa);
          A typical use is to initialize the array with empty boxa,
          and to replace only a subset that must be aligned with
          something else, such as a pixa.

=head2 boxaaInsertBoxa

l_int32 boxaaInsertBoxa ( BOXAA *baa, l_int32 index, BOXA *boxa )

  boxaaInsertBoxa()

      Input:  boxaa
              index (location in boxaa to insert new boxa)
              boxa (new boxa to be inserted)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This shifts boxa[i] --> boxa[i + 1] for all i >= index,
          and then inserts boxa as boxa[index].
      (2) To insert at the beginning of the array, set index = 0.
      (3) To append to the array, it's easier to use boxaaAddBoxa().
      (4) This should not be used repeatedly to insert into large arrays,
          because the function is O(n).

=head2 boxaaRead

BOXAA * boxaaRead ( const char *filename )

  boxaaRead()

      Input:  filename
      Return: boxaa, or null on error

=head2 boxaaReadFromFiles

BOXAA * boxaaReadFromFiles ( const char *dirname, const char *substr, l_int32 first, l_int32 nfiles )

  boxaaReadFromFiles()

      Input:  dirname (directory)
              substr (<optional> substring filter on filenames; can be NULL)
              first (0-based)
              nfiles (use 0 for everything from @first to the end)
      Return: baa, or null on error or if no boxa files are found.

  Notes:
      (1) The files must be serialized boxa files (e.g., *.ba).
          If some files cannot be read, warnings are issued.
      (2) Use @substr to filter filenames in the directory.  If
          @substr == NULL, this takes all files.
      (3) After filtering, use @first and @nfiles to select
          a contiguous set of files, that have been lexically
          sorted in increasing order.

=head2 boxaaReadStream

BOXAA * boxaaReadStream ( FILE *fp )

  boxaaReadStream()

      Input:  stream
      Return: boxaa, or null on error

=head2 boxaaRemoveBoxa

l_int32 boxaaRemoveBoxa ( BOXAA *baa, l_int32 index )

  boxaaRemoveBoxa()

      Input:  boxaa
              index  (of the boxa to be removed)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This removes boxa[index] and then shifts
          boxa[i] --> boxa[i - 1] for all i > index.
      (2) The removed boxaa is destroyed.
      (2) This should not be used repeatedly on large arrays,
          because the function is O(n).

=head2 boxaaReplaceBoxa

l_int32 boxaaReplaceBoxa ( BOXAA *baa, l_int32 index, BOXA *boxa )

  boxaaReplaceBoxa()

      Input:  boxaa
              index  (to the index-th boxa)
              boxa (insert and replace any existing one)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Any existing boxa is destroyed, and the input one
          is inserted in its place.
      (2) If the index is invalid, return 1 (error)

=head2 boxaaWrite

l_int32 boxaaWrite ( const char *filename, BOXAA *baa )

  boxaaWrite()

      Input:  filename
              boxaa
      Return: 0 if OK, 1 on error

=head2 boxaaWriteStream

l_int32 boxaaWriteStream ( FILE *fp, BOXAA *baa )

  boxaaWriteStream()

      Input: stream
             boxaa
      Return: 0 if OK, 1 on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
