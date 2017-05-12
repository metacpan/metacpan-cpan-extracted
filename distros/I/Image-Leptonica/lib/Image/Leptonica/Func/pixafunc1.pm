package Image::Leptonica::Func::pixafunc1;
$Image::Leptonica::Func::pixafunc1::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::pixafunc1

=head1 VERSION

version 0.04

=head1 C<pixafunc1.c>

   pixafunc1.c

      Filters
           PIX      *pixSelectBySize()
           PIXA     *pixaSelectBySize()
           NUMA     *pixaMakeSizeIndicator()

           PIX      *pixSelectByPerimToAreaRatio()
           PIXA     *pixaSelectByPerimToAreaRatio()
           PIX      *pixSelectByPerimSizeRatio()
           PIXA     *pixaSelectByPerimSizeRatio()
           PIX      *pixSelectByAreaFraction()
           PIXA     *pixaSelectByAreaFraction()
           PIX      *pixSelectByWidthHeightRatio()
           PIXA     *pixaSelectByWidthHeightRatio()

           PIXA     *pixaSelectWithIndicator()
           l_int32   pixRemoveWithIndicator()
           l_int32   pixAddWithIndicator()
           PIX      *pixaRenderComponent()

      Sort functions
           PIXA     *pixaSort()
           PIXA     *pixaBinSort()
           PIXA     *pixaSortByIndex()
           PIXAA    *pixaSort2dByIndex()

      Pixa and Pixaa range selection
           PIXA     *pixaSelectRange()
           PIXAA    *pixaaSelectRange()

      Pixa and Pixaa scaling
           PIXAA    *pixaaScaleToSize()
           PIXAA    *pixaaScaleToSizeVar()
           PIXA     *pixaScaleToSize()

      Miscellaneous
           PIXA     *pixaAddBorderGeneral()
           PIXA     *pixaaFlattenToPixa()
           l_int32   pixaaSizeRange()
           l_int32   pixaSizeRange()
           PIXA     *pixaClipToPix()
           l_int32   pixaAnyColormaps()
           l_int32   pixaGetDepthInfo()
           PIXA     *pixaConvertToSameDepth()
           l_int32   pixaEqual()

=head1 FUNCTIONS

=head2 pixAddWithIndicator

l_int32 pixAddWithIndicator ( PIX *pixs, PIXA *pixa, NUMA *na )

  pixAddWithIndicator()

      Input:  pixs (1 bpp pix from which components are added; in-place)
              pixa (of connected components, some of which will be put
                    into pixs)
              na (numa indicator: add components corresponding to 1s)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This complements pixRemoveWithIndicator().   Here, the selected
          components are added to pixs.

=head2 pixRemoveWithIndicator

l_int32 pixRemoveWithIndicator ( PIX *pixs, PIXA *pixa, NUMA *na )

  pixRemoveWithIndicator()

      Input:  pixs (1 bpp pix from which components are removed; in-place)
              pixa (of connected components in pixs)
              na (numa indicator: remove components corresponding to 1s)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This complements pixAddWithIndicator().   Here, the selected
          components are set subtracted from pixs.

=head2 pixSelectByAreaFraction

PIX * pixSelectByAreaFraction ( PIX *pixs, l_float32 thresh, l_int32 connectivity, l_int32 type, l_int32 *pchanged )

  pixSelectByAreaFraction()

      Input:  pixs (1 bpp)
              thresh (threshold ratio of fg pixels to (w * h))
              connectivity (4 or 8)
              type (L_SELECT_IF_LT, L_SELECT_IF_GT,
                    L_SELECT_IF_LTE, L_SELECT_IF_GTE)
              &changed (<optional return> 1 if changed; 0 if clone returned)
      Return: pixd, or null on error

  Notes:
      (1) The args specify constraints on the amount of foreground
          coverage of the components that are kept.
      (2) If unchanged, returns a copy of pixs.  Otherwise,
          returns a new pix with the filtered components.
      (3) This filters components based on the fraction of fg pixels
          of the component in its bounding box.
      (4) Use L_SELECT_IF_LT or L_SELECT_IF_LTE to save components
          with less than the threshold fraction of foreground, and
          L_SELECT_IF_GT or L_SELECT_IF_GTE to remove them.

=head2 pixSelectByPerimSizeRatio

PIX * pixSelectByPerimSizeRatio ( PIX *pixs, l_float32 thresh, l_int32 connectivity, l_int32 type, l_int32 *pchanged )

  pixSelectByPerimSizeRatio()

      Input:  pixs (1 bpp)
              thresh (threshold ratio of fg boundary to fg pixels)
              connectivity (4 or 8)
              type (L_SELECT_IF_LT, L_SELECT_IF_GT,
                    L_SELECT_IF_LTE, L_SELECT_IF_GTE)
              &changed (<optional return> 1 if changed; 0 if clone returned)
      Return: pixd, or null on error

  Notes:
      (1) The args specify constraints on the size of the
          components that are kept.
      (2) If unchanged, returns a copy of pixs.  Otherwise,
          returns a new pix with the filtered components.
      (3) This filters components with smooth vs. dendritic shape, using
          the ratio of the fg boundary pixels to the circumference of
          the bounding box, and comparing it to a threshold value.
      (4) Use L_SELECT_IF_LT or L_SELECT_IF_LTE to save the smooth
          boundary components, and L_SELECT_IF_GT or L_SELECT_IF_GTE
          to remove them.

=head2 pixSelectByPerimToAreaRatio

PIX * pixSelectByPerimToAreaRatio ( PIX *pixs, l_float32 thresh, l_int32 connectivity, l_int32 type, l_int32 *pchanged )

  pixSelectByPerimToAreaRatio()

      Input:  pixs (1 bpp)
              thresh (threshold ratio of fg boundary to fg pixels)
              connectivity (4 or 8)
              type (L_SELECT_IF_LT, L_SELECT_IF_GT,
                    L_SELECT_IF_LTE, L_SELECT_IF_GTE)
              &changed (<optional return> 1 if changed; 0 if clone returned)
      Return: pixd, or null on error

  Notes:
      (1) The args specify constraints on the size of the
          components that are kept.
      (2) If unchanged, returns a copy of pixs.  Otherwise,
          returns a new pix with the filtered components.
      (3) This filters "thick" components, where a thick component
          is defined to have a ratio of boundary to interior pixels
          that is smaller than a given threshold value.
      (4) Use L_SELECT_IF_LT or L_SELECT_IF_LTE to save the thicker
          components, and L_SELECT_IF_GT or L_SELECT_IF_GTE to remove them.

=head2 pixSelectBySize

PIX * pixSelectBySize ( PIX *pixs, l_int32 width, l_int32 height, l_int32 connectivity, l_int32 type, l_int32 relation, l_int32 *pchanged )

  pixSelectBySize()

      Input:  pixs (1 bpp)
              width, height (threshold dimensions)
              connectivity (4 or 8)
              type (L_SELECT_WIDTH, L_SELECT_HEIGHT,
                    L_SELECT_IF_EITHER, L_SELECT_IF_BOTH)
              relation (L_SELECT_IF_LT, L_SELECT_IF_GT,
                        L_SELECT_IF_LTE, L_SELECT_IF_GTE)
              &changed (<optional return> 1 if changed; 0 otherwise)
      Return: filtered pixd, or null on error

  Notes:
      (1) The args specify constraints on the size of the
          components that are kept.
      (2) If unchanged, returns a copy of pixs.  Otherwise,
          returns a new pix with the filtered components.
      (3) If the selection type is L_SELECT_WIDTH, the input
          height is ignored, and v.v.
      (4) To keep small components, use relation = L_SELECT_IF_LT or
          L_SELECT_IF_LTE.
          To keep large components, use relation = L_SELECT_IF_GT or
          L_SELECT_IF_GTE.

=head2 pixSelectByWidthHeightRatio

PIX * pixSelectByWidthHeightRatio ( PIX *pixs, l_float32 thresh, l_int32 connectivity, l_int32 type, l_int32 *pchanged )

  pixSelectByWidthHeightRatio()

      Input:  pixs (1 bpp)
              thresh (threshold ratio of width/height)
              connectivity (4 or 8)
              type (L_SELECT_IF_LT, L_SELECT_IF_GT,
                    L_SELECT_IF_LTE, L_SELECT_IF_GTE)
              &changed (<optional return> 1 if changed; 0 if clone returned)
      Return: pixd, or null on error

  Notes:
      (1) The args specify constraints on the width-to-height ratio
          for components that are kept.
      (2) If unchanged, returns a copy of pixs.  Otherwise,
          returns a new pix with the filtered components.
      (3) This filters components based on the width-to-height ratios.
      (4) Use L_SELECT_IF_LT or L_SELECT_IF_LTE to save components
          with less than the threshold ratio, and
          L_SELECT_IF_GT or L_SELECT_IF_GTE to remove them.

=head2 pixaAddBorderGeneral

PIXA * pixaAddBorderGeneral ( PIXA *pixad, PIXA *pixas, l_int32 left, l_int32 right, l_int32 top, l_int32 bot, l_uint32 val )

  pixaAddBorderGeneral()

      Input:  pixad (can be null or equal to pixas)
              pixas (containing pix of all depths; colormap ok)
              left, right, top, bot  (number of pixels added)
              val   (value of added border pixels)
      Return: pixad (with border added to each pix), including on error

  Notes:
      (1) For binary images:
             white:  val = 0
             black:  val = 1
          For grayscale images:
             white:  val = 2 ** d - 1
             black:  val = 0
          For rgb color images:
             white:  val = 0xffffff00
             black:  val = 0
          For colormapped images, use 'index' found this way:
             white: pixcmapGetRankIntensity(cmap, 1.0, &index);
             black: pixcmapGetRankIntensity(cmap, 0.0, &index);
      (2) For in-place replacement of each pix with a bordered version,
          use @pixad = @pixas.  To make a new pixa, use @pixad = NULL.
      (3) In both cases, the boxa has sides adjusted as if it were
          expanded by the border.

=head2 pixaAnyColormaps

l_int32 pixaAnyColormaps ( PIXA *pixa, l_int32 *phascmap )

  pixaAnyColormaps()

      Input:  pixa
              &hascmap (<return> 1 if any pix has a colormap; 0 otherwise)
      Return: 0 if OK; 1 on error

=head2 pixaBinSort

PIXA * pixaBinSort ( PIXA *pixas, l_int32 sorttype, l_int32 sortorder, NUMA **pnaindex, l_int32 copyflag )

  pixaBinSort()

      Input:  pixas
              sorttype (L_SORT_BY_X, L_SORT_BY_Y, L_SORT_BY_WIDTH,
                        L_SORT_BY_HEIGHT, L_SORT_BY_PERIMETER)
              sortorder  (L_SORT_INCREASING, L_SORT_DECREASING)
              &naindex (<optional return> index of sorted order into
                        original array)
              copyflag (L_COPY, L_CLONE)
      Return: pixad (sorted version of pixas), or null on error

  Notes:
      (1) This sorts based on the data in the boxa.  If the boxa
          count is not the same as the pixa count, this returns an error.
      (2) The copyflag refers to the pix and box copies that are
          inserted into the sorted pixa.  These are either L_COPY
          or L_CLONE.
      (3) For a large number of boxes (say, greater than 1000), this
          O(n) binsort is much faster than the O(nlogn) shellsort.
          For 5000 components, this is over 20x faster than boxaSort().
      (4) Consequently, pixaSort() calls this function if it will
          likely go much faster.

=head2 pixaClipToPix

PIXA * pixaClipToPix ( PIXA *pixas, PIX *pixs )

  pixaClipToPix()

      Input:  pixas
              pixs
      Return: pixad, or null on error

  Notes:
      (1) This is intended for use in situations where pixas
          was originally generated from the input pixs.
      (2) Returns a pixad where each pix in pixas is ANDed
          with its associated region of the input pixs.  This
          region is specified by the the box that is associated
          with the pix.
      (3) In a typical application of this function, pixas has
          a set of region masks, so this generates a pixa of
          the parts of pixs that correspond to each region
          mask component, along with the bounding box for
          the region.

=head2 pixaConvertToSameDepth

PIXA * pixaConvertToSameDepth ( PIXA *pixas )

  pixaConvertToSameDepth()

      Input:  pixas
      Return: pixad, or null on error

  Notes:
      (1) If any pix has a colormap, they are all converted to rgb.
          Otherwise, they are all converted to the maximum depth of
          all the pix.
      (2) This can be used to allow lossless rendering onto a single pix.

=head2 pixaEqual

l_int32 pixaEqual ( PIXA *pixa1, PIXA *pixa2, l_int32 maxdist, NUMA **pnaindex, l_int32 *psame )

  pixaEqual()

      Input:  pixa1
              pixa2
              maxdist
              &naindex (<optional return> index array of correspondences
              &same (<return> 1 if equal; 0 otherwise)
      Return  0 if OK, 1 on error

  Notes:
      (1) The two pixa are the "same" if they contain the same
          boxa and the same ordered set of pix.  However, if they
          have boxa, the pix in each pixa can differ in ordering
          by an amount given by the parameter @maxdist.  If they
          don't have a boxa, the @maxdist parameter is ignored,
          and the ordering must be identical.
      (2) This applies only to boxa geometry, pixels and ordering;
          other fields in the pix are ignored.
      (3) naindex[i] gives the position of the box in pixa2 that
          corresponds to box i in pixa1.  It is only returned if the
          pixa have boxa and the boxa are equal.
      (4) In situations where the ordering is very different, so that
          a large @maxdist is required for "equality", this should be
          implemented with a hash function for efficiency.

=head2 pixaGetDepthInfo

l_int32 pixaGetDepthInfo ( PIXA *pixa, l_int32 *pmaxdepth, l_int32 *psame )

  pixaGetDepthInfo()

      Input:  pixa
              &maxdepth (<optional return> max pixel depth of pix in pixa)
              &same (<optional return> true if all depths are equal)
      Return: 0 if OK; 1 on error

=head2 pixaMakeSizeIndicator

NUMA * pixaMakeSizeIndicator ( PIXA *pixa, l_int32 width, l_int32 height, l_int32 type, l_int32 relation )

  pixaMakeSizeIndicator()

      Input:  pixa
              width, height (threshold dimensions)
              type (L_SELECT_WIDTH, L_SELECT_HEIGHT,
                    L_SELECT_IF_EITHER, L_SELECT_IF_BOTH)
              relation (L_SELECT_IF_LT, L_SELECT_IF_GT,
                        L_SELECT_IF_LTE, L_SELECT_IF_GTE)
      Return: na (indicator array), or null on error

  Notes:
      (1) The args specify constraints on the size of the
          components that are kept.
      (2) If the selection type is L_SELECT_WIDTH, the input
          height is ignored, and v.v.
      (3) To keep small components, use relation = L_SELECT_IF_LT or
          L_SELECT_IF_LTE.
          To keep large components, use relation = L_SELECT_IF_GT or
          L_SELECT_IF_GTE.

=head2 pixaRenderComponent

PIX * pixaRenderComponent ( PIX *pixs, PIXA *pixa, l_int32 index )

  pixaRenderComponent()

      Input:  pixs (<optional> 1 bpp pix)
              pixa (of 1 bpp connected components, one of which will
                    be rendered in pixs, with its origin determined
                    by the associated box.)
              index (of component to be rendered)
      Return: pixd, or null on error

  Notes:
      (1) If pixs is null, this generates an empty pix of a size determined
          by union of the component bounding boxes, and including the origin.
      (2) The selected component is blitted into pixs.

=head2 pixaScaleToSize

PIXA * pixaScaleToSize ( PIXA *pixas, l_int32 wd, l_int32 hd )

  pixaScaleToSize()

      Input:  pixas
              wd  (target width; use 0 if using height as target)
              hd  (target height; use 0 if using width as target)
      Return: pixad, or null on error

  Notes:
      (1) See pixaaScaleToSize()

=head2 pixaSelectByAreaFraction

PIXA * pixaSelectByAreaFraction ( PIXA *pixas, l_float32 thresh, l_int32 type, l_int32 *pchanged )

  pixaSelectByAreaFraction()

      Input:  pixas
              thresh (threshold ratio of fg pixels to (w * h))
              type (L_SELECT_IF_LT, L_SELECT_IF_GT,
                    L_SELECT_IF_LTE, L_SELECT_IF_GTE)
              &changed (<optional return> 1 if changed; 0 if clone returned)
      Return: pixad, or null on error

  Notes:
      (1) Returns a pixa clone if no components are removed.
      (2) Uses pix and box clones in the new pixa.
      (3) This filters components based on the fraction of fg pixels
          of the component in its bounding box.
      (4) Use L_SELECT_IF_LT or L_SELECT_IF_LTE to save components
          with less than the threshold fraction of foreground, and
          L_SELECT_IF_GT or L_SELECT_IF_GTE to remove them.

=head2 pixaSelectByPerimSizeRatio

PIXA * pixaSelectByPerimSizeRatio ( PIXA *pixas, l_float32 thresh, l_int32 type, l_int32 *pchanged )

  pixaSelectByPerimSizeRatio()

      Input:  pixas
              thresh (threshold ratio of fg boundary to b.b. circumference)
              type (L_SELECT_IF_LT, L_SELECT_IF_GT,
                    L_SELECT_IF_LTE, L_SELECT_IF_GTE)
              &changed (<optional return> 1 if changed; 0 if clone returned)
      Return: pixad, or null on error

  Notes:
      (1) Returns a pixa clone if no components are removed.
      (2) Uses pix and box clones in the new pixa.
      (3) See pixSelectByPerimSizeRatio().

=head2 pixaSelectByPerimToAreaRatio

PIXA * pixaSelectByPerimToAreaRatio ( PIXA *pixas, l_float32 thresh, l_int32 type, l_int32 *pchanged )

  pixaSelectByPerimToAreaRatio()

      Input:  pixas
              thresh (threshold ratio of fg boundary to fg pixels)
              type (L_SELECT_IF_LT, L_SELECT_IF_GT,
                    L_SELECT_IF_LTE, L_SELECT_IF_GTE)
              &changed (<optional return> 1 if changed; 0 if clone returned)
      Return: pixad, or null on error

  Notes:
      (1) Returns a pixa clone if no components are removed.
      (2) Uses pix and box clones in the new pixa.
      (3) See pixSelectByPerimToAreaRatio().

=head2 pixaSelectBySize

PIXA * pixaSelectBySize ( PIXA *pixas, l_int32 width, l_int32 height, l_int32 type, l_int32 relation, l_int32 *pchanged )

  pixaSelectBySize()

      Input:  pixas
              width, height (threshold dimensions)
              type (L_SELECT_WIDTH, L_SELECT_HEIGHT,
                    L_SELECT_IF_EITHER, L_SELECT_IF_BOTH)
              relation (L_SELECT_IF_LT, L_SELECT_IF_GT,
                        L_SELECT_IF_LTE, L_SELECT_IF_GTE)
              &changed (<optional return> 1 if changed; 0 otherwise)
      Return: pixad, or null on error

  Notes:
      (1) The args specify constraints on the size of the
          components that are kept.
      (2) Uses pix and box clones in the new pixa.
      (3) If the selection type is L_SELECT_WIDTH, the input
          height is ignored, and v.v.
      (4) To keep small components, use relation = L_SELECT_IF_LT or
          L_SELECT_IF_LTE.
          To keep large components, use relation = L_SELECT_IF_GT or
          L_SELECT_IF_GTE.

=head2 pixaSelectByWidthHeightRatio

PIXA * pixaSelectByWidthHeightRatio ( PIXA *pixas, l_float32 thresh, l_int32 type, l_int32 *pchanged )

  pixaSelectByWidthHeightRatio()

      Input:  pixas
              thresh (threshold ratio of width/height)
              type (L_SELECT_IF_LT, L_SELECT_IF_GT,
                    L_SELECT_IF_LTE, L_SELECT_IF_GTE)
              &changed (<optional return> 1 if changed; 0 if clone returned)
      Return: pixad, or null on error

  Notes:
      (1) Returns a pixa clone if no components are removed.
      (2) Uses pix and box clones in the new pixa.
      (3) This filters components based on the width-to-height ratio
          of each pix.
      (4) Use L_SELECT_IF_LT or L_SELECT_IF_LTE to save components
          with less than the threshold ratio, and
          L_SELECT_IF_GT or L_SELECT_IF_GTE to remove them.

=head2 pixaSelectRange

PIXA * pixaSelectRange ( PIXA *pixas, l_int32 first, l_int32 last, l_int32 copyflag )

  pixaSelectRange()

      Input:  pixas
              first (use 0 to select from the beginning)
              last (use 0 to select to the end)
              copyflag (L_COPY, L_CLONE)
      Return: pixad, or null on error

  Notes:
      (1) The copyflag specifies what we do with each pix from pixas.
          Specifically, L_CLONE inserts a clone into pixad of each
          selected pix from pixas.

=head2 pixaSelectWithIndicator

PIXA * pixaSelectWithIndicator ( PIXA *pixas, NUMA *na, l_int32 *pchanged )

  pixaSelectWithIndicator()

      Input:  pixas
              na (indicator numa)
              &changed (<optional return> 1 if changed; 0 if clone returned)
      Return: pixad, or null on error

  Notes:
      (1) Returns a pixa clone if no components are removed.
      (2) Uses pix and box clones in the new pixa.
      (3) The indicator numa has values 0 (ignore) and 1 (accept).
      (4) If the source boxa is not fully populated, it is left
          empty in the dest pixa.

=head2 pixaSizeRange

l_int32 pixaSizeRange ( PIXA *pixa, l_int32 *pminw, l_int32 *pminh, l_int32 *pmaxw, l_int32 *pmaxh )

  pixaSizeRange()

      Input:  pixa
              &minw, &minh, &maxw, &maxh (<optional return> range of
                                          dimensions of pix in the array)
      Return: 0 if OK, 1 on error

=head2 pixaSort

PIXA * pixaSort ( PIXA *pixas, l_int32 sorttype, l_int32 sortorder, NUMA **pnaindex, l_int32 copyflag )

  pixaSort()

      Input:  pixas
              sorttype (L_SORT_BY_X, L_SORT_BY_Y, L_SORT_BY_WIDTH,
                        L_SORT_BY_HEIGHT, L_SORT_BY_MIN_DIMENSION,
                        L_SORT_BY_MAX_DIMENSION, L_SORT_BY_PERIMETER,
                        L_SORT_BY_AREA, L_SORT_BY_ASPECT_RATIO)
              sortorder  (L_SORT_INCREASING, L_SORT_DECREASING)
              &naindex (<optional return> index of sorted order into
                        original array)
              copyflag (L_COPY, L_CLONE)
      Return: pixad (sorted version of pixas), or null on error

  Notes:
      (1) This sorts based on the data in the boxa.  If the boxa
          count is not the same as the pixa count, this returns an error.
      (2) The copyflag refers to the pix and box copies that are
          inserted into the sorted pixa.  These are either L_COPY
          or L_CLONE.

=head2 pixaSort2dByIndex

PIXAA * pixaSort2dByIndex ( PIXA *pixas, NUMAA *naa, l_int32 copyflag )

  pixaSort2dByIndex()

      Input:  pixas
              naa (numaa that maps from the new pixaa to the input pixas)
              copyflag (L_CLONE or L_COPY)
      Return: paa (sorted), or null on error

=head2 pixaSortByIndex

PIXA * pixaSortByIndex ( PIXA *pixas, NUMA *naindex, l_int32 copyflag )

  pixaSortByIndex()

      Input:  pixas
              naindex (na that maps from the new pixa to the input pixa)
              copyflag (L_COPY, L_CLONE)
      Return: pixad (sorted), or null on error

=head2 pixaaFlattenToPixa

PIXA * pixaaFlattenToPixa ( PIXAA *paa, NUMA **pnaindex, l_int32 copyflag )

  pixaaFlattenToPixa()

      Input:  paa
              &naindex  (<optional return> the pixa index in the pixaa)
              copyflag  (L_COPY or L_CLONE)
      Return: pixa, or null on error

  Notes:
      (1) This 'flattens' the pixaa to a pixa, taking the pix in
          order in the first pixa, then the second, etc.
      (2) If &naindex is defined, we generate a Numa that gives, for
          each pix in the pixaa, the index of the pixa to which it belongs.

=head2 pixaaScaleToSize

PIXAA * pixaaScaleToSize ( PIXAA *paas, l_int32 wd, l_int32 hd )

  pixaaScaleToSize()

      Input:  paas
              wd  (target width; use 0 if using height as target)
              hd  (target height; use 0 if using width as target)
      Return: paad, or null on error

  Notes:
      (1) This guarantees that each output scaled image has the
          dimension(s) you specify.
           - To specify the width with isotropic scaling, set @hd = 0.
           - To specify the height with isotropic scaling, set @wd = 0.
           - If both @wd and @hd are specified, the image is scaled
             (in general, anisotropically) to that size.
           - It is an error to set both @wd and @hd to 0.

=head2 pixaaScaleToSizeVar

PIXAA * pixaaScaleToSizeVar ( PIXAA *paas, NUMA *nawd, NUMA *nahd )

  pixaaScaleToSizeVar()

      Input:  paas
              nawd  (<optional> target widths; use NULL if using height)
              nahd  (<optional> target height; use NULL if using width)
      Return: paad, or null on error

  Notes:
      (1) This guarantees that the scaled images in each pixa have the
          dimension(s) you specify in the numas.
           - To specify the width with isotropic scaling, set @nahd = NULL.
           - To specify the height with isotropic scaling, set @nawd = NULL.
           - If both @nawd and @nahd are specified, the image is scaled
             (in general, anisotropically) to that size.
           - It is an error to set both @nawd and @nahd to NULL.
      (2) If either nawd and/or nahd is defined, it must have the same
          count as the number of pixa in paas.

=head2 pixaaSelectRange

PIXAA * pixaaSelectRange ( PIXAA *paas, l_int32 first, l_int32 last, l_int32 copyflag )

  pixaaSelectRange()

      Input:  paas
              first (use 0 to select from the beginning)
              last (use 0 to select to the end)
              copyflag (L_COPY, L_CLONE)
      Return: paad, or null on error

  Notes:
      (1) The copyflag specifies what we do with each pixa from paas.
          Specifically, L_CLONE inserts a clone into paad of each
          selected pixa from paas.

=head2 pixaaSizeRange

l_int32 pixaaSizeRange ( PIXAA *paa, l_int32 *pminw, l_int32 *pminh, l_int32 *pmaxw, l_int32 *pmaxh )

  pixaaSizeRange()

      Input:  paa
              &minw, &minh, &maxw, &maxh (<optional return> range of
                                          dimensions of all boxes)
      Return: 0 if OK, 1 on error

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
