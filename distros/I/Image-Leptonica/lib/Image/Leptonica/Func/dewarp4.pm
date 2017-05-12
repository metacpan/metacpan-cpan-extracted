package Image::Leptonica::Func::dewarp4;
$Image::Leptonica::Func::dewarp4::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::dewarp4

=head1 VERSION

version 0.04

=head1 C<dewarp4.c>

  dewarp4.c

    Single page dewarper

    Reference model (book-level, dewarpa) operations and debugging output

      Top-level single page dewarper
          l_int32            dewarpSinglePage()

      Operations on dewarpa
          l_int32            dewarpaListPages()
          l_int32            dewarpaSetValidModels()
          l_int32            dewarpaInsertRefModels()
          l_int32            dewarpaStripRefModels()
          l_int32            dewarpaRestoreModels()

      Dewarp debugging output
          l_int32            dewarpaInfo()
          l_int32            dewarpaModelStats()
          static l_int32     dewarpaTestForValidModel()
          l_int32            dewarpaShowArrays()
          l_int32            dewarpDebug()
          l_int32            dewarpShowResults()

=head1 FUNCTIONS

=head2 dewarpDebug

l_int32 dewarpDebug ( L_DEWARP *dew, const char *subdir, l_int32 index )

  dewarpDebug()

      Input:  dew
              subdir (a subdirectory of /tmp; e.g., "dew1")
              index (to help label output images; e.g., the page number)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Prints dewarp fields and generates disparity array contour images.
          The contour images are written to file:
                /tmp/[subdir]/pixv_[index].png

=head2 dewarpShowResults

l_int32 dewarpShowResults ( L_DEWARPA *dewa, SARRAY *sa, BOXA *boxa, l_int32 firstpage, l_int32 lastpage, const char *pdfout )

  dewarpShowResults()

      Input:  dewa
              sarray (of indexed input images)
              boxa (crop boxes for input images; can be null)
              firstpage, lastpage
              pdfout (filename)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This generates a pdf of image pairs (before, after) for
          the designated set of input pages.
      (2) If the boxa exists, its elements are aligned with numbers
          in the filenames in @sa.  It is used to crop the input images.
          It is assumed that the dewa was generated from the cropped
          images.  No undercropping is applied before rendering.

=head2 dewarpSinglePage

l_int32 dewarpSinglePage ( PIX *pixs, l_int32 thresh, l_int32 adaptive, l_int32 both, PIX **ppixd, L_DEWARPA **pdewa, l_int32 debug )

  dewarpSinglePage()

      Input:  pixs (with text, any depth)
              thresh (for binarization)
              adaptive (1 for adaptive thresholding; 0 for global threshold)
              both (1 for horizontal and vertical; 0 for vertical only)
              &pixd (<return> dewarped result)
              &dewa (<optional return> dewa with single page; NULL to skip)
              debug (1 for debugging output, 0 otherwise)
      Return: 0 if OK, 1 on error (list of page numbers), or null on error

  Notes:
      (1) Dewarps pixs and returns the result in &pixd.
      (2) This uses default values for all model parameters.
      (3) If pixs is 1 bpp, the parameters @adaptive and @thresh are ignored.
      (4) If it can't build a model, returns a copy of pixs in &pixd.

=head2 dewarpaInfo

l_int32 dewarpaInfo ( FILE *fp, L_DEWARPA *dewa )

  dewarpaInfo()

      Input:  fp
              dewa
      Return: 0 if OK, 1 on error

=head2 dewarpaInsertRefModels

l_int32 dewarpaInsertRefModels ( L_DEWARPA *dewa, l_int32 notests, l_int32 debug )

  dewarpaInsertRefModels()

      Input:  dewa
              notests (if 1, ignore curvature constraints on model)
              debug (1 to output information on invalid page models)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This destroys all dewarp models that are invalid, and then
          inserts reference models where possible.
      (2) If @notests == 1, this ignores the curvature constraints
          and assumes that all successfully built models are valid.
      (3) If useboth == 0, it uses the closest valid model within the
          distance and parity constraints.  If useboth == 1, it tries
          to use the closest allowed hvalid model; if it doesn't find
          an hvalid model, it uses the closest valid model.
      (4) For all pages without a model, this clears out any existing
          invalid and reference dewarps, finds the nearest valid model
          with the same parity, and inserts an empty dewarp with the
          reference page.
      (5) Then if it is requested to use both vertical and horizontal
          disparity arrays (useboth == 1), it tries to replace any
          hvalid == 0 model or reference with an hvalid == 1 reference.
      (6) The distance constraint is that any reference model must
          be within maxdist.  Note that with the parity constraint,
          no reference models will be used if maxdist < 2.
      (7) This function must be called, even if reference models will
          not be used.  It should be called after building models on all
          available pages, and after setting the rendering parameters.
      (8) If the dewa has been serialized, this function is called by
          dewarpaRead() when it is read back.  It is also called
          any time the rendering parameters are changed.
      (9) Note: if this has been called with useboth == 1, and useboth
          is reset to 0, you should first call dewarpRestoreModels()
          to bring real models from the cache back to the primary array.

=head2 dewarpaListPages

l_int32 dewarpaListPages ( L_DEWARPA *dewa )

  dewarpaListPages()

      Input:  dewa (populated with dewarp structs for pages)
      Return: 0 if OK, 1 on error (list of page numbers), or null on error

  Notes:
      (1) This generates two numas, stored in the dewarpa, that give:
          (a) the page number for each dew that has a page model.
          (b) the page number for each dew that has either a page
              model or a reference model.
          It can be called at any time.
      (2) It is called by the dewarpa serializer before writing.

=head2 dewarpaModelStats

l_int32 dewarpaModelStats ( L_DEWARPA *dewa, l_int32 *pnnone, l_int32 *pnvsuccess, l_int32 *pnvvalid, l_int32 *pnhsuccess, l_int32 *pnhvalid, l_int32 *pnref )

  dewarpaModelStats()

      Input:  dewa
              &nnone (<optional return> number without any model)
              &nvsuccess (<optional return> number with a vert model)
              &nvvalid (<optional return> number with a valid vert model)
              &nhsuccess (<optional return> number with both models)
              &nhvalid (<optional return> number with both models valid)
              &nref (<optional return> number with a reference model)
      Return: 0 if OK, 1 on error

  Notes:
      (1) A page without a model has no dew.  It most likely failed to
          generate a vertical model, and has not been assigned a ref
          model from a neighboring page with a valid vertical model.
      (2) A page has vsuccess == 1 if there is at least a model of the
          vertical disparity.  The model may be invalid, in which case
          dewarpaInsertRefModels() will stash it in the cache and
          attempt to replace it by a valid ref model.
      (3) A vvvalid model is a vertical disparity model whose parameters
          satisfy the constraints given in dewarpaSetValidModels().
      (4) A page has hsuccess == 1 if both the vertical and horizontal
          disparity arrays have been constructed.
      (5) An  hvalid model has vertical and horizontal disparity
          models whose parameters satisfy the constraints given
          in dewarpaSetValidModels().
      (6) A page has a ref model if it failed to generate a valid
          model but was assigned a vvalid or hvalid model on another
          page (within maxdist) by dewarpaInsertRefModel().
      (7) This calls dewarpaTestForValidModel(); it ignores the vvalid
          and hvalid fields.

=head2 dewarpaRestoreModels

l_int32 dewarpaRestoreModels ( L_DEWARPA *dewa )

  dewarpaRestoreModels()

      Input:  dewa (populated with dewarp structs for pages)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This puts all real models (and only real models) in the
          primary dewarp array.  First remove all dewarps that are
          only references to other page models.  Then move all models
          that had been cached back into the primary dewarp array.
      (2) After this is done, we still need to recompute and insert
          the reference models before dewa->modelsready is true.

=head2 dewarpaSetValidModels

l_int32 dewarpaSetValidModels ( L_DEWARPA *dewa, l_int32 notests, l_int32 debug )

  dewarpaSetValidModels()

      Input:  dewa
              notests
              debug (1 to output information on invalid page models)
      Return: 0 if OK, 1 on error

  Notes:
      (1) A valid model must meet the rendering requirements, which
          include whether or not a vertical disparity model exists
          and conditions on curvatures for vertical and horizontal
          disparity models.
      (2) If @notests == 1, this ignores the curvature constraints
          and assumes that all successfully built models are valid.
      (3) This function does not need to be called by the application.
          It is called by dewarpaInsertRefModels(), which
          will destroy all invalid dewarps.  Consequently, to inspect
          an invalid dewarp model, it must be done before calling
          dewarpaInsertRefModels().

=head2 dewarpaShowArrays

l_int32 dewarpaShowArrays ( L_DEWARPA *dewa, l_float32 scalefact, l_int32 first, l_int32 last )

  dewarpaShowArrays()

      Input:  dewa
              scalefact (on contour images; typ. 0.5)
              first (first page model to render)
              last (last page model to render; use 0 to go to end)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Generates a pdf of contour plots of the disparity arrays.
      (2) This only shows actual models; not ref models

=head2 dewarpaStripRefModels

l_int32 dewarpaStripRefModels ( L_DEWARPA *dewa )

  dewarpaStripRefModels()

      Input:  dewa (populated with dewarp structs for pages)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This examines each dew in a dewarpa, and removes
          all that don't have their own page model (i.e., all
          that have "references" to nearby pages with valid models).
          These references were generated by dewarpaInsertRefModels(dewa).

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
