package Image::Leptonica::Func::sarray;
$Image::Leptonica::Func::sarray::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::sarray

=head1 VERSION

version 0.04

=head1 C<sarray.c>

   sarray.c

      Create/Destroy/Copy
          SARRAY    *sarrayCreate()
          SARRAY    *sarrayCreateInitialized()
          SARRAY    *sarrayCreateWordsFromString()
          SARRAY    *sarrayCreateLinesFromString()
          void      *sarrayDestroy()
          SARRAY    *sarrayCopy()
          SARRAY    *sarrayClone()

      Add/Remove string
          l_int32    sarrayAddString()
          static l_int32  sarrayExtendArray()
          char      *sarrayRemoveString()
          l_int32    sarrayReplaceString()
          l_int32    sarrayClear()

      Accessors
          l_int32    sarrayGetCount()
          char     **sarrayGetArray()
          char      *sarrayGetString()
          l_int32    sarrayGetRefcount()
          l_int32    sarrayChangeRefcount()

      Conversion back to string
          char      *sarrayToString()
          char      *sarrayToStringRange()

      Concatenate 2 sarrays
          l_int32    sarrayConcatenate()
          l_int32    sarrayAppendRange()

      Pad an sarray to be the same size as another sarray
          l_int32    sarrayPadToSameSize()

      Convert word sarray to (formatted) line sarray
          SARRAY    *sarrayConvertWordsToLines()

      Split string on separator list
          SARRAY    *sarraySplitString()

      Filter sarray
          SARRAY    *sarraySelectBySubstring()
          SARRAY    *sarraySelectByRange()
          l_int32    sarrayParseRange()

      Sort
          SARRAY    *sarraySort()
          SARRAY    *sarraySortByIndex()
          l_int32    stringCompareLexical()

      Serialize for I/O
          SARRAY    *sarrayRead()
          SARRAY    *sarrayReadStream()
          l_int32    sarrayWrite()
          l_int32    sarrayWriteStream()
          l_int32    sarrayAppend()

      Directory filenames
          SARRAY    *getNumberedPathnamesInDirectory()
          SARRAY    *getSortedPathnamesInDirectory()
          SARRAY    *convertSortedToNumberedPathnames()
          SARRAY    *getFilenamesInDirectory()

      These functions are important for efficient manipulation
      of string data, and they have found widespread use in
      leptonica.  For example:
         (1) to generate text files: e.g., PostScript and PDF
             wrappers around sets of images
         (2) to parse text files: e.g., extracting prototypes
             from the source to generate allheaders.h
         (3) to generate code for compilation: e.g., the fast
             dwa code for arbitrary structuring elements.

      Comments on usage:

          The user is responsible for correctly disposing of strings
          that have been extracted from sarrays:
            - When you want a string from an Sarray to inspect it, or
              plan to make a copy of it later, use sarrayGetString()
              with copyflag = 0.  In this case, you must neither free
              the string nor put it directly in another array.
              We provide the copyflag constant L_NOCOPY, which is 0,
              for this purpose:
                 str-not-owned = sarrayGetString(sa, index, L_NOCOPY);
              To extract a copy of a string, use:
                 str-owned = sarrayGetString(sa, index, L_COPY);

            - When you want to insert a string that is in one
              array into another array (always leaving the first
              array intact), you have two options:
                 (1) use copyflag = L_COPY to make an immediate copy,
                     which you must then add to the second array
                     by insertion; namely,
                       str-owned = sarrayGetString(sa, index, L_COPY);
                       sarrayAddString(sa, str-owned, L_INSERT);
                 (2) use copyflag = L_NOCOPY to get another handle to
                     the string, in which case you must add
                     a copy of it to the second string array:
                       str-not-owned = sarrayGetString(sa, index, L_NOCOPY);
                       sarrayAddString(sa, str-not-owned, L_COPY).

              In all cases, when you use copyflag = L_COPY to extract
              a string from an array, you must either free it
              or insert it in an array that will be freed later.

=head1 FUNCTIONS

=head2 convertSortedToNumberedPathnames

SARRAY * convertSortedToNumberedPathnames ( SARRAY *sa, l_int32 numpre, l_int32 numpost, l_int32 maxnum )

  convertSortedToNumberedPathnames()

      Input:  sorted pathnames (including zero-padded integers)
              numpre (number of characters in name before number)
              numpost (number of characters in name after the number,
                       up to a dot before an extension)
              maxnum (only consider page numbers up to this value)
      Return: sarray of numbered pathnames, or NULL on error

  Notes:
      (1) Typically, numpre = numpost = 0; e.g., when the filename
          just has a number followed by an optional extension.

=head2 getFilenamesInDirectory

SARRAY * getFilenamesInDirectory ( const char *dirname )

  getFilenamesInDirectory()

      Input:  directory name
      Return: sarray of file names, or NULL on error

  Notes:
      (1) The versions compiled under unix and cygwin use the POSIX C
          library commands for handling directories.  For windows,
          there is a separate implementation.
      (2) It returns an array of filename tails; i.e., only the part of
          the path after the last slash.
      (3) Use of the d_type field of dirent is not portable:
          "According to POSIX, the dirent structure contains a field
          char d_name[] of unspecified size, with at most NAME_MAX
          characters preceding the terminating null character.  Use
          of other fields will harm the portability of your programs."
      (4) As a consequence of (3), we note several things:
           - MINGW doesn't have a d_type member.
           - Older versions of gcc (e.g., 2.95.3) return DT_UNKNOWN
             for d_type from all files.
          On these systems, this function will return directories
          (except for '.' and '..', which are eliminated using
          the d_name field).

=head2 getNumberedPathnamesInDirectory

SARRAY * getNumberedPathnamesInDirectory ( const char *dirname, const char *substr, l_int32 numpre, l_int32 numpost, l_int32 maxnum )

  getNumberedPathnamesInDirectory()

      Input:  directory name
              substr (<optional> substring filter on filenames; can be NULL)
              numpre (number of characters in name before number)
              numpost (number of characters in name after the number,
                       up to a dot before an extension)
              maxnum (only consider page numbers up to this value)
      Return: sarray of numbered pathnames, or NULL on error

  Notes:
      (1) Returns the full pathnames of the numbered filenames in
          the directory.  The number in the filename is the index
          into the sarray.  For indices for which there are no filenames,
          an empty string ("") is placed into the sarray.
          This makes reading numbered files very simple.  For example,
          the image whose filename includes number N can be retrieved using
               pixReadIndexed(sa, N);
      (2) If @substr is not NULL, only filenames that contain
          the substring can be included.  If @substr is NULL,
          all matching filenames are used.
      (3) If no numbered files are found, it returns an empty sarray,
          with no initialized strings.
      (4) It is assumed that the page number is contained within
          the basename (the filename without directory or extension).
          @numpre is the number of characters in the basename
          preceeding the actual page number; @numpost is the number
          following the page number, up to either the end of the
          basename or a ".", whichever comes first.
      (5) This is useful when all filenames contain numbers that are
          not necessarily consecutive.  0-padding is not required.
      (6) To use a O(n) matching algorithm, the largest page number
          is found and two internal arrays of this size are created.
          This maximum is constrained not to exceed @maxsum,
          to make sure that an unrealistically large number is not
          accidentally used to determine the array sizes.

=head2 getSortedPathnamesInDirectory

SARRAY * getSortedPathnamesInDirectory ( const char *dirname, const char *substr, l_int32 first, l_int32 nfiles )

  getSortedPathnamesInDirectory()

      Input:  directory name
              substr (<optional> substring filter on filenames; can be NULL)
              first (0-based)
              nfiles (use 0 for all to the end)
      Return: sarray of sorted pathnames, or NULL on error

  Notes:
      (1) Use @substr to filter filenames in the directory.  If
          @substr == NULL, this takes all files.
      (2) The files in the directory, after optional filtering by
          the substring, are lexically sorted in increasing order.
          Use @first and @nfiles to select a contiguous set of files.
      (3) The full pathnames are returned for the requested sequence.
          If no files are found after filtering, returns an empty sarray.

=head2 sarrayAddString

l_int32 sarrayAddString ( SARRAY *sa, char *string, l_int32 copyflag )

  sarrayAddString()

      Input:  sarray
              string  (string to be added)
              copyflag (L_INSERT, L_COPY)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Legacy usage decrees that we always use 0 to insert a string
          directly and 1 to insert a copy of the string.  The
          enums for L_INSERT and L_COPY agree with this convention,
          and will not change in the future.
      (2) See usage comments at the top of this file.

=head2 sarrayAppend

l_int32 sarrayAppend ( const char *filename, SARRAY *sa )

  sarrayAppend()

      Input:  filename
              sarray
      Return: 0 if OK; 1 on error

=head2 sarrayAppendRange

l_int32 sarrayAppendRange ( SARRAY *sa1, SARRAY *sa2, l_int32 start, l_int32 end )

  sarrayAppendRange()

      Input:  sa1  (to be added to)
              sa2  (append specified range of strings in sa2 to sa1)
              start (index of first string of sa2 to append)
              end (index of last string of sa2 to append; -1 to end of array)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Copies of the strings in sarray2 are added to sarray1.
      (2) The [start ... end] range is truncated if necessary.
      (3) Use end == -1 to append to the end of sa2.

=head2 sarrayChangeRefcount

l_int32 sarrayChangeRefcount ( SARRAY *sa, l_int32 delta )

  sarrayChangeRefcount()

      Input:  sarray
              delta (change to be applied)
      Return: 0 if OK, 1 on error

=head2 sarrayClear

l_int32 sarrayClear ( SARRAY *sa )

  sarrayClear()

      Input:  sarray
      Return: 0 if OK; 1 on error

=head2 sarrayClone

SARRAY * sarrayClone ( SARRAY *sa )

  sarrayClone()

      Input:  sarray
      Return: ptr to same sarray, or null on error

=head2 sarrayConcatenate

l_int32 sarrayConcatenate ( SARRAY *sa1, SARRAY *sa2 )

  sarrayConcatenate()

      Input:  sa1  (to be added to)
              sa2  (append to sa1)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Copies of the strings in sarray2 are added to sarray1.

=head2 sarrayConvertWordsToLines

SARRAY * sarrayConvertWordsToLines ( SARRAY *sa, l_int32 linesize )

  sarrayConvertWordsToLines()

      Input:  sa  (sa of individual words)
              linesize  (max num of chars in each line)
      Return: saout (sa of formatted lines), or null on error

  This is useful for re-typesetting text to a specific maximum
  line length.  The individual words in the input sarray
  are concatenated into textlines.  An input word string of zero
  length is taken to be a paragraph separator.  Each time
  such a string is found, the current line is ended and
  a new line is also produced that contains just the
  string of zero length ("").  When the output sarray
  of lines is eventually converted to a string with newlines
  (typically) appended to each line string, the empty
  strings are just converted to newlines, producing the visible
  paragraph separation.

  What happens when a word is larger than linesize?
  We write it out as a single line anyway!  Words preceding
  or following this long word are placed on lines preceding
  or following the line with the long word.  Why this choice?
  Long "words" found in text documents are typically URLs, and
  it's often desirable not to put newlines in the middle of a URL.
  The text display program (e.g., text editor) will typically
  wrap the long "word" to fit in the window.

=head2 sarrayCopy

SARRAY * sarrayCopy ( SARRAY *sa )

  sarrayCopy()

      Input:  sarray
      Return: copy of sarray, or null on error

=head2 sarrayCreate

SARRAY * sarrayCreate ( l_int32 n )

  sarrayCreate()

      Input:  size of string ptr array to be alloc'd
              (use 0 for default)
      Return: sarray, or null on error

=head2 sarrayCreateInitialized

SARRAY * sarrayCreateInitialized ( l_int32 n, char *initstr )

  sarrayCreateInitialized()

      Input:  n (size of string ptr array to be alloc'd)
              initstr (string to be initialized on the full array)
      Return: sarray, or null on error

=head2 sarrayCreateLinesFromString

SARRAY * sarrayCreateLinesFromString ( char *string, l_int32 blankflag )

  sarrayCreateLinesFromString()

      Input:  string
              blankflag  (0 to exclude blank lines; 1 to include)
      Return: sarray, or null on error

  Notes:
      (1) This finds the number of line substrings, each of which
          ends with a newline, and puts a copy of each substring
          in a new sarray.
      (2) The newline characters are removed from each substring.

=head2 sarrayCreateWordsFromString

SARRAY * sarrayCreateWordsFromString ( const char *string )

  sarrayCreateWordsFromString()

      Input:  string
      Return: sarray, or null on error

  Notes:
      (1) This finds the number of word substrings, creates an sarray
          of this size, and puts copies of each substring into the sarray.

=head2 sarrayDestroy

void sarrayDestroy ( SARRAY **psa )

  sarrayDestroy()

      Input:  &sarray <to be nulled>
      Return: void

  Notes:
      (1) Decrements the ref count and, if 0, destroys the sarray.
      (2) Always nulls the input ptr.

=head2 sarrayGetCount

l_int32 sarrayGetCount ( SARRAY *sa )

  sarrayGetCount()

      Input:  sarray
      Return: count, or 0 if no strings or on error

=head2 sarrayGetRefcount

l_int32 sarrayGetRefcount ( SARRAY *sa )

  sarrayGetRefcount()

      Input:  sarray
      Return: refcount, or UNDEF on error

=head2 sarrayGetString

char * sarrayGetString ( SARRAY *sa, l_int32 index, l_int32 copyflag )

  sarrayGetString()

      Input:  sarray
              index   (to the index-th string)
              copyflag  (L_NOCOPY or L_COPY)
      Return: string, or null on error

  Notes:
      (1) Legacy usage decrees that we always use 0 to get the
          pointer to the string itself, and 1 to get a copy of
          the string.
      (2) See usage comments at the top of this file.
      (3) To get a pointer to the string itself, use for copyflag:
             L_NOCOPY or 0 or FALSE
          To get a copy of the string, use for copyflag:
             L_COPY or 1 or TRUE
          The const values of L_NOCOPY and L_COPY are guaranteed not
          to change.

=head2 sarrayPadToSameSize

l_int32 sarrayPadToSameSize ( SARRAY *sa1, SARRAY *sa2, char *padstring )

  sarrayPadToSameSize()

      Input:  sa1, sa2
              padstring
      Return: 0 if OK, 1 on error

  Notes:
      (1) If two sarrays have different size, this adds enough
          instances of @padstring to the smaller so that they are
          the same size.  It is useful when two or more sarrays
          are being sequenced in parallel, and it is necessary to
          find a valid string at each index.

=head2 sarrayParseRange

l_int32 sarrayParseRange ( SARRAY *sa, l_int32 start, l_int32 *pactualstart, l_int32 *pend, l_int32 *pnewstart, const char *substr, l_int32 loc )

  sarrayParseRange()

      Input:  sa (input sarray)
              start (index to start range search)
             &actualstart (<return> index of actual start; may be > 'start')
             &end (<return> index of end)
             &newstart (<return> index of start of next range)
              substr (substring for matching at beginning of string)
              loc (byte offset within the string for the pattern; use
                   -1 if the location does not matter);
      Return: 0 if valid range found; 1 otherwise

  Notes:
      (1) This finds the range of the next set of strings in SA,
          beginning the search at 'start', that does NOT have
          the substring 'substr' either at the indicated location
          in the string or anywhere in the string.  The input
          variable 'loc' is the specified offset within the string;
          use -1 to indicate 'anywhere in the string'.
      (2) Always check the return value to verify that a valid range
          was found.
      (3) If a valid range is not found, the values of actstart,
          end and newstart are all set to the size of sa.
      (4) If this is the last valid range, newstart returns the value n.
          In use, this should be tested before calling the function.
      (5) Usage example.  To find all the valid ranges in a file
          where the invalid lines begin with two dashes, copy each
          line in the file to a string in an sarray, and do:
             start = 0;
             while (!sarrayParseRange(sa, start, &actstart, &end, &start,
                    "--", 0))
                 fprintf(stderr, "start = %d, end = %d\n", actstart, end);

=head2 sarrayRead

SARRAY * sarrayRead ( const char *filename )

  sarrayRead()

      Input:  filename
      Return: sarray, or null on error

=head2 sarrayReadStream

SARRAY * sarrayReadStream ( FILE *fp )

  sarrayReadStream()

      Input:  stream
      Return: sarray, or null on error

  Notes:
      (1) We store the size of each string along with the string.
      (2) This allows a string to have embedded newlines.  By reading
          the entire string, as determined by its size, we are
          not affected by any number of embedded newlines.

=head2 sarrayRemoveString

char * sarrayRemoveString ( SARRAY *sa, l_int32 index )

  sarrayRemoveString()

      Input:  sarray
              index (of string within sarray)
      Return: removed string, or null on error

=head2 sarrayReplaceString

l_int32 sarrayReplaceString ( SARRAY *sa, l_int32 index, char *newstr, l_int32 copyflag )

  sarrayReplaceString()

      Input:  sarray
              index (of string within sarray to be replaced)
              newstr (string to replace existing one)
              copyflag (L_INSERT, L_COPY)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This destroys an existing string and replaces it with
          the new string or a copy of it.
      (2) By design, an sarray is always compacted, so there are
          never any holes (null ptrs) in the ptr array up to the
          current count.

=head2 sarraySelectByRange

SARRAY * sarraySelectByRange ( SARRAY *sain, l_int32 first, l_int32 last )

  sarraySelectByRange()

      Input:  sain (input sarray)
              first (index of first string to be selected)
              last (index of last string to be selected; use 0 to go to the
                    end of the sarray)
      Return: saout (output sarray), or null on error

  Notes:
      (1) This makes @saout consisting of copies of all strings in @sain
          in the index set [first ... last].  Use @last == 0 to get all
          strings from @first to the last string in the sarray.

=head2 sarraySelectBySubstring

SARRAY * sarraySelectBySubstring ( SARRAY *sain, const char *substr )

  sarraySelectBySubstring()

      Input:  sain (input sarray)
              substr (<optional> substring for matching; can be NULL)
      Return: saout (output sarray, filtered with substring) or null on error

  Notes:
      (1) This selects all strings in sain that have substr as a substring.
          Note that we can't use strncmp() because we're looking for
          a match to the substring anywhere within each filename.
      (2) If substr == NULL, returns a copy of the sarray.

=head2 sarraySort

SARRAY * sarraySort ( SARRAY *saout, SARRAY *sain, l_int32 sortorder )

  sarraySort()

      Input:  saout (output sarray; can be NULL or equal to sain)
              sain (input sarray)
              sortorder (L_SORT_INCREASING or L_SORT_DECREASING)
      Return: saout (output sarray, sorted by ascii value), or null on error

  Notes:
      (1) Set saout = sain for in-place; otherwise, set naout = NULL.
      (2) Shell sort, modified from K&R, 2nd edition, p.62.
          Slow but simple O(n logn) sort.

=head2 sarraySortByIndex

SARRAY * sarraySortByIndex ( SARRAY *sain, NUMA *naindex )

  sarraySortByIndex()

      Input:  sain
              naindex (na that maps from the new sarray to the input sarray)
      Return: saout (sorted), or null on error

=head2 sarraySplitString

l_int32 sarraySplitString ( SARRAY *sa, const char *str, const char *separators )

  sarraySplitString()

      Input:  sa (to append to; typically empty initially)
              str (string to split; not changed)
              separators (characters that split input string)
      Return: 0 if OK, 1 on error.

  Notes:
      (1) This uses strtokSafe().  See the notes there in utils.c.

=head2 sarrayToString

char * sarrayToString ( SARRAY *sa, l_int32 addnlflag )

  sarrayToString()

      Input:  sarray
              addnlflag (flag: 0 adds nothing to each substring
                               1 adds '\n' to each substring
                               2 adds ' ' to each substring)
      Return: dest string, or null on error

  Notes:
      (1) Concatenates all the strings in the sarray, preserving
          all white space.
      (2) If addnlflag != 0, adds either a '\n' or a ' ' after
          each substring.
      (3) This function was NOT implemented as:
            for (i = 0; i < n; i++)
                     strcat(dest, sarrayGetString(sa, i, L_NOCOPY));
          Do you see why?

=head2 sarrayToStringRange

char * sarrayToStringRange ( SARRAY *sa, l_int32 first, l_int32 nstrings, l_int32 addnlflag )

  sarrayToStringRange()

      Input: sarray
             first  (index of first string to use; starts with 0)
             nstrings (number of strings to append into the result; use
                       0 to append to the end of the sarray)
             addnlflag (flag: 0 adds nothing to each substring
                              1 adds '\n' to each substring
                              2 adds ' ' to each substring)
      Return: dest string, or null on error

  Notes:
      (1) Concatenates the specified strings inthe sarray, preserving
          all white space.
      (2) If addnlflag != 0, adds either a '\n' or a ' ' after
          each substring.
      (3) If the sarray is empty, this returns a string with just
          the character corresponding to @addnlflag.

=head2 sarrayWrite

l_int32 sarrayWrite ( const char *filename, SARRAY *sa )

  sarrayWrite()

      Input:  filename
              sarray
      Return: 0 if OK; 1 on error

=head2 sarrayWriteStream

l_int32 sarrayWriteStream ( FILE *fp, SARRAY *sa )

  sarrayWriteStream()

      Input:  stream
              sarray
      Returns 0 if OK; 1 on error

  Notes:
      (1) This appends a '\n' to each string, which is stripped
          off by sarrayReadStream().

=head2 stringCompareLexical

l_int32 stringCompareLexical ( const char *str1, const char *str2 )

  stringCompareLexical()

      Input:  str1
              str2
      Return: 1 if str1 > str2 (lexically); 0 otherwise

  Notes:
      (1) If the lexical values are identical, return a 0, to
          indicate that no swapping is required to sort the strings.

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
