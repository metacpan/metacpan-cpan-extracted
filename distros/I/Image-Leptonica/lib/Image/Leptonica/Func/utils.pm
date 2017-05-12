package Image::Leptonica::Func::utils;
$Image::Leptonica::Func::utils::VERSION = '0.04';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Image::Leptonica::Func::utils

=head1 VERSION

version 0.04

=head1 C<utils.c>

  utils.c

       Control of error, warning and info messages
           l_int32    setMsgSeverity()

       Error return functions, invoked by macros
           l_int32    returnErrorInt()
           l_float32  returnErrorFloat()
           void      *returnErrorPtr()

       Safe string procs
           char      *stringNew()
           l_int32    stringCopy()
           l_int32    stringReplace()
           l_int32    stringLength()
           l_int32    stringCat()
           char      *stringJoin()
           char      *stringReverse()
           char      *strtokSafe()
           l_int32    stringSplitOnToken()

       Find and replace string and array procs
           char      *stringRemoveChars()
           l_int32    stringFindSubstr()
           char      *stringReplaceSubstr()
           char      *stringReplaceEachSubstr()
           L_DNA     *arrayFindEachSequence()
           l_int32    arrayFindSequence()

       Safe realloc
           void      *reallocNew()

       Read and write between file and memory
           l_uint8   *l_binaryRead()
           l_uint8   *l_binaryReadStream()
           l_int32    l_binaryWrite()
           l_int32    nbytesInFile()
           l_int32    fnbytesInFile()

       Copy in memory
           l_uint8   *l_binaryCopy()

       File copy operations
           l_int32    fileCopy()
           l_int32    fileConcatenate()
           l_int32    fileAppendString()

       Test files for equivalence
           l_int32    filesAreIdentical()

       Byte-swapping data conversion
           l_uint16   convertOnBigEnd16()
           l_uint32   convertOnBigEnd32()
           l_uint16   convertOnLittleEnd16()
           l_uint32   convertOnLittleEnd32()

       Cross-platform functions for opening file streams
           FILE      *fopenReadStream()
           FILE      *fopenWriteStream()

       Cross-platform functions that avoid C-runtime boundary crossing
       with Windows DLLs
           FILE      *lept_fopen()
           l_int32    lept_fclose()
           void       lept_calloc()
           void       lept_free()

       Cross-platform file system operations in temp directories
           l_int32    lept_mkdir()
           l_int32    lept_rmdir()
           l_int32    lept_direxists()
           l_int32    lept_mv()
           l_int32    lept_rm()
           l_int32    lept_cp()

       File name operations
           l_int32    splitPathAtDirectory()
           l_int32    splitPathAtExtension()
           char      *pathJoin()
           char      *genPathname()
           char      *genTempFilename()
           l_int32    extractNumberFromFilename()

       File corruption operation
           l_int32    fileCorruptByDeletion()

       Generate random integer in given range
           l_int32    genRandomIntegerInRange()

       Simple math function
           l_int32    lept_roundftoi()

       Gray code conversion
           l_uint32   convertBinaryToGrayCode()
           l_uint32   convertGrayToBinaryCode()

       Leptonica version number
           char      *getLeptonicaVersion()

       Timing
           void       startTimer()
           l_float32  stopTimer()
           L_TIMER    startTimerNested()
           l_float32  stopTimerNested()
           void       l_getCurrentTime()
           void       l_getFormattedDate()

  Notes on cross-platform development
  -----------------------------------
  This is important if your applications must work on Windows.
  (1) With the exception of splitPathAtDirectory() and
      splitPathAtExtension(), all input pathnames must have unix separators.
  (2) The conversion from unix to windows pathnames happens in genPathname().
  (3) Use fopenReadStream() and fopenWriteStream() to open files,
      because these use genPathname() to find the platform-dependent
      filenames.  Likewise for l_binaryRead() and l_binaryWrite().
  (4) For moving, copying and removing files and directories that are in
      /tmp or subdirectories of /tmp, use the lept_*() file system
      shell wrappers:
         lept_mkdir(), lept_rmdir(), lept_mv(), lept_rm() and lept_cp().
  (5) Use the lept_*() C library wrappers.  These work properly on
      Windows, where the same DLL must perform complementary operations
      on file streams (open/close) and heap memory (malloc/free):
         lept_fopen(), lept_fclose(), lept_calloc() and lept_free().

=head1 FUNCTIONS

=head2 arrayFindEachSequence

L_DNA * arrayFindEachSequence ( const l_uint8 *data, l_int32 datalen, const l_uint8 *sequence, l_int32 seqlen )

  arrayFindEachSequence()

      Input:  data (byte array)
              datalen (length of data, in bytes)
              sequence (subarray of bytes to find in data)
              seqlen (length of sequence, in bytes)
      Return: dna of offsets where the sequence is found, or null if
              none are found or on error

  Notes:
      (1) The byte arrays @data and @sequence are not C strings,
          as they can contain null bytes.  Therefore, for each
          we must give the length of the array.
      (2) This finds every occurrence in @data of @sequence.

=head2 arrayFindSequence

l_int32 arrayFindSequence ( const l_uint8 *data, l_int32 datalen, const l_uint8 *sequence, l_int32 seqlen, l_int32 *poffset, l_int32 *pfound )

  arrayFindSequence()

      Input:  data (byte array)
              datalen (length of data, in bytes)
              sequence (subarray of bytes to find in data)
              seqlen (length of sequence, in bytes)
              &offset (return> offset from beginning of
                       data where the sequence begins)
              &found (<optional return> 1 if sequence is found; 0 otherwise)
      Return: 0 if OK, 1 on error

  Notes:
      (1) The byte arrays 'data' and 'sequence' are not C strings,
          as they can contain null bytes.  Therefore, for each
          we must give the length of the array.
      (2) This searches for the first occurrence in @data of @sequence,
          which consists of @seqlen bytes.  The parameter @seqlen
          must not exceed the actual length of the @sequence byte array.
      (3) If the sequence is not found, the offset will be set to -1.

=head2 convertBinaryToGrayCode

l_uint32 convertBinaryToGrayCode ( l_uint32 val )

  convertBinaryToGrayCode()

      Input:  val
      Return: gray code value

  Notes:
      (1) Gray code values corresponding to integers differ by
          only one bit transition between successive integers.

=head2 convertGrayCodeToBinary

l_uint32 convertGrayCodeToBinary ( l_uint32 val )

  convertGrayCodeToBinary()

      Input:  gray code value
      Return: binary value

=head2 extractNumberFromFilename

l_int32 extractNumberFromFilename ( const char *fname, l_int32 numpre, l_int32 numpost )

  extractNumberFromFilename()

      Input:  fname
              numpre (number of characters before the digits to be found)
              numpost (number of characters after the digits to be found)
      Return: num (number embedded in the filename); -1 on error or if
                   not found

  Notes:
      (1) The number is to be found in the basename, which is the
          filename without either the directory or the last extension.
      (2) When a number is found, it is non-negative.  If no number
          is found, this returns -1, without an error message.  The
          caller needs to check.

=head2 fileAppendString

l_int32 fileAppendString ( const char *filename, const char *str )

  fileAppendString()

      Input:  filename
              str (string to append to file)
      Return: 0 if OK, 1 on error

=head2 fileConcatenate

l_int32 fileConcatenate ( const char *srcfile, const char *destfile )

  fileConcatenate()

      Input:  srcfile (file to append)
              destfile (file to add to)
      Return: 0 if OK, 1 on error

=head2 fileCopy

l_int32 fileCopy ( const char *srcfile, const char *newfile )

  fileCopy()

      Input:  srcfile (copy this file)
              newfile (to this file)
      Return: 0 if OK, 1 on error

=head2 fileCorruptByDeletion

l_int32 fileCorruptByDeletion ( const char *filein, l_float32 loc, l_float32 size, const char *fileout )

  fileCorruptByDeletion()

      Input:  filein
              loc (fractional location of start of deletion)
              size (fractional size of deletion)
              fileout (corrupted file)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This is useful for testing robustness of I/O wrappers with image
          file corruption.
      (2) Deletion size adjusts automatically to avoid array transgressions.

=head2 filesAreIdentical

l_int32 filesAreIdentical ( const char *fname1, const char *fname2, l_int32 *psame )

  filesAreIdentical()

      Input:  fname1
              fname2
              &same (<return> 1 if identical; 0 if different)
      Return: 0 if OK, 1 on error

=head2 fnbytesInFile

size_t fnbytesInFile ( FILE *fp )

  fnbytesInFile()

      Input:  file stream
      Return: nbytes in file; 0 on error

=head2 fopenReadStream

FILE * fopenReadStream ( const char *filename )

  fopenReadStream()

      Input:  filename
      Return: stream, or null on error

  Notes:
      (1) This wrapper also handles pathname conversions for Windows.
          It should be used whenever you want to run fopen() to
          read from a stream.

=head2 fopenWriteStream

FILE * fopenWriteStream ( const char *filename, const char *modestring )

  fopenWriteStream()

      Input:  filename
              modestring
      Return: stream, or null on error

  Notes:
      (1) This wrapper also handles pathname conversions for Windows.
          It should be used whenever you want to run fopen() to
          write or append to a stream.

=head2 genPathname

char * genPathname ( const char *dir, const char *fname )

  genPathname()

      Input:  dir (directory name, with or without trailing '/')
              fname (<optional> file name within the directory)
      Return: pathname (either a directory or full path), or null on error

  Notes:
      (1) Use unix-style pathname separators ('/').
      (2) This function can be used in several ways:
            * to generate a full path from a directory and a file name
            * to convert a unix pathname to a windows pathname
            * to convert from the unix '/tmp' directory to the
              equivalent windows temp directory.
          The windows name translation is:
                   /tmp  -->   <Temp>/leptonica
      (3) There are three cases for the input:
          (a) @dir is a directory and @fname is null: result is a directory
          (b) @dir is a full path and @fname is null: result is a full path
          (c) @dir is a directory and @fname is defined: result is a full path
      (4) In all cases, the resulting pathname is not terminated with a slash
      (5) The caller is responsible for freeing the pathname.

=head2 genRandomIntegerInRange

l_int32 genRandomIntegerInRange ( l_int32 range, l_int32 seed, l_int32 *pval )

  genRandomIntegerInRange()

      Input:  range (size of range; must be >= 2)
              seed (use 0 to skip; otherwise call srand)
              val (<return> random integer in range {0 ... range-1}
      Return: 0 if OK, 1 on error

  Notes:
      (1) For example, to choose a rand integer between 0 and 99,
          use @range = 100.

=head2 genTempFilename

char * genTempFilename ( const char *dir, const char *tail, l_int32 usetime, l_int32 usepid )

  genTempFilename()

      Input:  dir (directory name; use '.' for local dir;
                   no trailing '/' and @dir == "/" is invalid)
              tail (<optional>  tailname, including extension if any;
                    can be null or empty but can't contain '/')
              usetime (1 to include current time in microseconds in
                       the filename; 0 to omit.
              usepid (1 to include pid in filename; 0 to omit.
      Return: temp filename, or null on error

  Notes:
      (1) Use unix-style pathname separators ('/').
      (2) Specifying the root directory (@dir == "/") is invalid.
      (3) Specifying a @tail containing '/' is invalid.
      (4) The most general form (@usetime = @usepid = 1) is:
              <dir>/<usec>_<pid>_<tail>
          When @usetime = 1, @usepid = 0, the output filename is:
              <dir>/<usec>_<tail>
          When @usepid = 0, @usepid = 1, the output filename is:
              <dir>/<pid>_<tail>
          When @usetime = @usepid = 0, the output filename is:
              <dir>/<tail>
          Note: It is not valid to have @tail = null or empty and have
          both @usetime = @usepid = 0.  That is, there must be
          some non-empty tail name.
      (5) N.B. The caller is responsible for freeing the returned filename.
          For windows, to avoid C-runtime boundary crossing problems
          when using DLLs, you must use lept_free() to free the name.
      (6) For windows, if the caller requests the directory '/tmp',
          this uses GetTempPath() to select the actual directory,
          avoiding platform-conditional code in use.  The directory
          selected is <Temp>/leptonica, where <Temp> is the Windows
          temp directory.
      (7) Set @usetime = @usepid = 1 when
          (a) more than one process is writing and reading temp files, or
          (b) multiple threads from a single process call this function, or
          (c) there is the possiblity of an attack where the intruder
              is logged onto the server and might try to guess filenames.

=head2 getLeptonicaVersion

char * getLeptonicaVersion (  )

  getLeptonicaVersion()

      Return: string of version number (e.g., 'leptonica-1.68')

  Notes:
      (1) The caller has responsibility to free the memory.

=head2 l_binaryCopy

l_uint8 * l_binaryCopy ( l_uint8 *datas, size_t size )

  l_binaryCopy()

      Input:  datas
              size (of data array)
      Return: datad (on heap), or null on error

  Notes:
      (1) We add 4 bytes to the zeroed output because in some cases
          (e.g., string handling) it is important to have the data
          be null terminated.  This guarantees that after the memcpy,
          the result is automatically null terminated.

=head2 l_binaryRead

l_uint8 * l_binaryRead ( const char *filename, size_t *pnbytes )

  l_binaryRead()

      Input:  filename
              &nbytes (<return> number of bytes read)
      Return: data, or null on error

=head2 l_binaryReadStream

l_uint8 * l_binaryReadStream ( FILE *fp, size_t *pnbytes )

  l_binaryReadStream()

      Input:  stream
              &nbytes (<return> number of bytes read)
      Return: null-terminated array, or null on error
              (reading 0 bytes is not an error)

  Notes:
      (1) The returned array is terminated with a null byte so that
          it can be used to read ascii data into a proper C string.
      (2) Side effect: this re-positions the stream ptr to the
          beginning of the file.

=head2 l_binaryWrite

l_int32 l_binaryWrite ( const char *filename, const char *operation, void *data, size_t nbytes )

  l_binaryWrite()

      Input:  filename (output)
              operation  ("w" for write; "a" for append)
              data  (binary data to be written)
              nbytes  (size of data array)
      Return: 0 if OK; 1 on error

=head2 l_getCurrentTime

void l_getCurrentTime ( l_int32 *sec, l_int32 *usec )

  l_getCurrentTime()

      Input:  &sec (<optional return> in seconds since birth of Unix)
              &usec (<optional return> in microseconds since birth of Unix)
      Return: void

=head2 l_getFormattedDate

char * l_getFormattedDate (  )

  l_getFormattedDate()

      Input:  (none)
      Return: formatted date string, or null on error

=head2 lept_calloc

void * lept_calloc ( size_t nmemb, size_t size )

  lept_calloc()

      Input:  nmemb (number of members)
              size (of each member)
      Return: void ptr, or null on error

  Notes:
      (1) For safety with windows DLLs, this can be used in conjunction
          with lept_free() to avoid C-runtime boundary problems.
          Just use these two functions throughout your application.

=head2 lept_cp

l_int32 lept_cp ( const char *srcfile, const char *newfile )

  lept_cp()

      Input:  srcfile
              newfile
      Return: 0 on success, non-zero on failure

  Notes:
      (1) This copies a file to /tmp or a subdirectory of /tmp.
      (2) The input srcfile name is the complete pathname.
          The input newfile is either in /tmp or a subdirectory
          of /tmp, and newfile can be specified either as the
          full path or without the leading '/tmp'.
      (3) Use unix pathname separators.
      (4) On Windows, the source and target filename are altered
          internally if necessary to conform to the Windows temp file.
      (5) Alternatively, you can use fileCopy().  This avoids
          forking a new process and has no restrictions on the
          destination directory.

=head2 lept_direxists

void lept_direxists ( const char *dirname, l_int32 *pexists )

  lept_direxists()

      Input:  dirname
              &exists (<return> 1 on success, 0 on failure)
      Return: void

  Notes:
      (1) For Windows, use windows pathname separators.

=head2 lept_fclose

l_int32 lept_fclose ( FILE *fp )

  lept_fclose()

      Input:  fp (stream handle)
      Return: 0 if OK, 1 on error

  Notes:
      (1) This should be used by any application that accepts
          a file handle generated by a leptonica Windows DLL.

=head2 lept_fopen

FILE * lept_fopen ( const char *filename, const char *mode )

  lept_fopen()

      Input:  filename
              mode (same as for fopen(); e.g., "rb")
      Return: stream or null on error

  Notes:
      (1) This must be used by any application that passes
          a file handle to a leptonica Windows DLL.

=head2 lept_free

void lept_free ( void *ptr )

  lept_free()

      Input:  void ptr
      Return: 0 if OK, 1 on error

  Notes:
      (1) This should be used by any application that accepts
          heap data allocated by a leptonica Windows DLL.

=head2 lept_mkdir

l_int32 lept_mkdir ( const char *subdir )

  lept_mkdir()

      Input:  subdir (of /tmp or its equivalent on Windows)
      Return: 0 on success, non-zero on failure

  Notes:
      (1) This makes a subdirectory of /tmp/.
      (2) Use unix pathname separators.
      (3) On Windows, it makes a subdirectory of <Temp>/leptonica,
          where <Temp> is the Windows temp dir.  The name translation is:
                 /tmp  -->   <Temp>/leptonica

=head2 lept_mv

l_int32 lept_mv ( const char *srcfile, const char *newfile )

  lept_mv()

      Input:  srcfile, newfile
      Return: 0 on success, non-zero on failure

  Notes:
      (1) This moves a srcfile to /tmp or to a subdirectory of /tmp.
      (2) The input srcfile name is the complete pathname.
          The input newfile is either in /tmp or a subdirectory
          of /tmp, and newfile can be specified either as the
          full path or without the leading '/tmp'.
      (3) Use unix pathname separators.
      (4) On Windows, the source and target filename are altered
          internally if necessary to conform to the Windows temp file.
          The name translation is: /tmp  -->   <Temp>/leptonica

=head2 lept_rm

l_int32 lept_rm ( const char *subdir, const char *filename )

  lept_rm()

      Input:  subdir (can be NULL, in which case the removed file is
                      in /tmp)
              filename (with or without the directory)
      Return: 0 on success, non-zero on failure

  Notes:
      (1) This removes the named file in /tmp or a subdirectory of /tmp.
          If the file is in /tmp, use NULL for the subdir.
      (2) @filename can include directories in the path, but they are ignored.
      (3) Use unix pathname separators.
      (4) On Windows, the file is in either <Temp>/leptonica, or
          a subdirectory of this, where <Temp> is the Windows temp dir.
          The name translation is: /tmp  -->   <Temp>/leptonica

=head2 lept_rmdir

l_int32 lept_rmdir ( const char *subdir )

  lept_rmdir()

      Input:  subdir (of /tmp or its equivalent on Windows)
      Return: 0 on success, non-zero on failure

  Notes:
      (1) On unix, this removes all the files in the named
          subdirectory of /tmp.  It then removes the subdirectory.
      (2) Use unix pathname separators.
      (3) On Windows, the affected directory is a subdirectory
          of <Temp>/leptonica, where <Temp> is the Windows temp dir.

=head2 lept_roundftoi

l_int32 lept_roundftoi ( l_float32 fval )

  lept_roundftoi()

      Input:  fval
      Return: value rounded to int

  Notes:
      (1) For fval >= 0, fval --> round(fval) == floor(fval + 0.5)
          For fval < 0, fval --> -round(-fval))
          This is symmetric around 0.
          e.g., for fval in (-0.5 ... 0.5), fval --> 0

=head2 nbytesInFile

size_t nbytesInFile ( const char *filename )

  nbytesInFile()

      Input:  filename
      Return: nbytes in file; 0 on error

=head2 pathJoin

char * pathJoin ( const char *dir, const char *fname )

  pathJoin()

      Input:  dir (<optional> can be null)
              fname (<optional> can be null)
      Return: specially concatenated path, or null on error

  Notes:
      (1) Use unix-style pathname separators ('/').
      (2) @fname can be the entire path, or part of the path containing
          at least one directory, or a tail without a directory, or null.
      (3) It produces a path that strips multiple slashes to a single
          slash, joins @dir and @fname by a slash, and has no trailing
          slashes (except in the cases where @dir == "/" and
          @fname == NULL, or v.v.).
      (4) If both @dir and @fname are null, produces an empty string.
      (5) Neither @dir nor @fname can begin with '.'.
      (6) The result is not canonicalized or tested for correctness:
          garbage in (e.g., /&%), garbage out.
      (7) Examples:
             //tmp// + //abc/  -->  /tmp/abc
             tmp/ + /abc/      -->  tmp/abc
             tmp/ + abc/       -->  tmp/abc
             /tmp/ + ///       -->  /tmp
             /tmp/ + NULL      -->  /tmp
             // + /abc//       -->  /abc
             // + NULL         -->  /
             NULL + /abc/def/  -->  /abc/def
             NULL + abc//      -->  abc
             NULL + //         -->  /
             NULL + NULL       -->  (empty string)
             "" + ""           -->  (empty string)
             "" + /            -->  /
             ".." + /etc/foo   -->  NULL
             /tmp + ".."       -->  NULL

=head2 reallocNew

void * reallocNew ( void **pindata, l_int32 oldsize, l_int32 newsize )

  reallocNew()

      Input:  &indata (<optional>; nulls indata)
              oldsize (size of input data to be copied, in bytes)
              newsize (size of data to be reallocated in bytes)
      Return: ptr to new data, or null on error

  Action: !N.B. (3) and (4)!
      (1) Allocates memory, initialized to 0
      (2) Copies as much of the input data as possible
          to the new block, truncating the copy if necessary
      (3) Frees the input data
      (4) Zeroes the input data ptr

  Notes:
      (1) If newsize <=0, just frees input data and nulls ptr
      (2) If input ptr is null, just callocs new memory
      (3) This differs from realloc in that it always allocates
          new memory (if newsize > 0) and initializes it to 0,
          it requires the amount of old data to be copied,
          and it takes the address of the input ptr and
          nulls the handle.

=head2 returnErrorFloat

l_float32 returnErrorFloat ( const char *msg, const char *procname, l_float32 fval )

  returnErrorFloat()

      Input:  msg (error message)
              procname
              fval (return val)
      Return: fval

=head2 returnErrorInt

l_int32 returnErrorInt ( const char *msg, const char *procname, l_int32 ival )

  returnErrorInt()

      Input:  msg (error message)
              procname
              ival (return val)
      Return: ival (typically 1 for an error return)

=head2 returnErrorPtr

void * returnErrorPtr ( const char *msg, const char *procname, void *pval )

  returnErrorPtr()

      Input:  msg (error message)
              procname
              pval  (return val)
      Return: pval (typically null)

=head2 setMsgSeverity

l_int32 setMsgSeverity ( l_int32 newsev )

  setMsgSeverity()

      Input:  newsev
      Return: oldsev

  Notes:
      (1) setMsgSeverity() allows the user to specify the desired
          message severity threshold.  Messages of equal or greater
          severity will be output.  The previous message severity is
          returned when the new severity is set.
      (2) If L_SEVERITY_EXTERNAL is passed, then the severity will be
          obtained from the LEPT_MSG_SEVERITY environment variable.
          If the environmental variable is not set, a warning is issued.

=head2 stringCat

l_int32 stringCat ( char *dest, size_t size, const char *src )

  stringCat()

      Input:  dest (null-terminated byte buffer)
              size (size of dest)
              src string (can be null or null-terminated string)
      Return: number of bytes added to dest; -1 on error

  Notes:
      (1) Alternative implementation of strncat, that checks the input,
          is easier to use (since the size of the dest buffer is specified
          rather than the number of bytes to copy), and does not complain
          if @src is null.
      (2) Never writes past end of dest.
      (3) If it can't append src (an error), it does nothing.
      (4) N.B. The order of 2nd and 3rd args is reversed from that in
          strncat, as in the Windows function strcat_s().

=head2 stringCopy

l_int32 stringCopy ( char *dest, const char *src, l_int32 n )

  stringCopy()

      Input:  dest (existing byte buffer)
              src string (can be null)
              n (max number of characters to copy)
      Return: 0 if OK, 1 on error

  Notes:
      (1) Relatively safe wrapper for strncpy, that checks the input,
          and does not complain if @src is null or @n < 1.
          If @n < 1, this is a no-op.
      (2) @dest needs to be at least @n bytes in size.
      (3) We don't call strncpy() because valgrind complains about
          use of uninitialized values.

=head2 stringFindSubstr

l_int32 stringFindSubstr ( const char *src, const char *sub, l_int32 *ploc )

  stringFindSubstr()

      Input:  src (input string; can be of zero length)
              sub (substring to be searched for)
              &loc (<return optional> location of substring in src)
      Return: 1 if found; 0 if not found or on error

  Notes:
      (1) This is a wrapper around strstr().
      (2) Both @src and @sub must be defined, and @sub must have
          length of at least 1.
      (3) If the substring is not found and loc is returned, it has
          the value -1.

=head2 stringJoin

char * stringJoin ( const char *src1, const char *src2 )

  stringJoin()

      Input:  src1 string (<optional> can be null)
              src2 string (<optional> can be null)
      Return: concatenated string, or null on error

  Notes:
      (1) This is a safe version of strcat; it makes a new string.
      (2) It is not an error if either or both of the strings
          are empty, or if either or both of the pointers are null.

=head2 stringLength

l_int32 stringLength ( const char *src, size_t size )

  stringLength()

      Input:  src string (can be null or null-terminated string)
              size (size of src buffer)
      Return: length of src in bytes.

  Notes:
      (1) Safe implementation of strlen that only checks size bytes
          for trailing NUL.
      (2) Valid returned string lengths are between 0 and size - 1.
          If size bytes are checked without finding a NUL byte, then
          an error is indicated by returning size.

=head2 stringNew

char * stringNew ( const char *src )

  stringNew()

      Input:  src string
      Return: dest copy of src string, or null on error

=head2 stringRemoveChars

char * stringRemoveChars ( const char *src, const char *remchars )

  stringRemoveChars()

      Input:  src (input string; can be of zero length)
              remchars  (string of chars to be removed from src)
      Return: dest (string with specified chars removed), or null on error

=head2 stringReplaceEachSubstr

char * stringReplaceEachSubstr ( const char *src, const char *sub1, const char *sub2, l_int32 *pcount )

  stringReplaceEachSubstr()

      Input:  src (input string; can be of zero length)
              sub1 (substring to be replaced)
              sub2 (substring to put in; can be "")
              &count (<optional return > the number of times that sub1
                      is found in src; 0 if not found)
      Return: dest (string with substring replaced), or null if the
              substring not found or on error.

  Notes:
      (1) Replaces every instance.
      (2) To only remove each instance of sub1, use "" for sub2
      (3) Returns NULL if sub1 and sub2 are the same.

=head2 stringReplaceSubstr

char * stringReplaceSubstr ( const char *src, const char *sub1, const char *sub2, l_int32 *pfound, l_int32 *ploc )

  stringReplaceSubstr()

      Input:  src (input string; can be of zero length)
              sub1 (substring to be replaced)
              sub2 (substring to put in; can be "")
              &found (<return optional> 1 if sub1 is found; 0 otherwise)
              &loc (<return optional> location of ptr after replacement)
      Return: dest (string with substring replaced), or null if the
              substring not found or on error.

  Notes:
      (1) Replaces the first instance.
      (2) To only remove sub1, use "" for sub2
      (3) Returns a new string if sub1 and sub2 are the same.
      (4) The optional loc is input as the byte offset within the src
          from which the search starts, and after the search it is the
          char position in the string of the next character after
          the substituted string.
      (5) N.B. If ploc is not null, loc must always be initialized.
          To search the string from the beginning, set loc = 0.

=head2 stringReverse

char * stringReverse ( const char *src )

  stringReverse()

      Input:  src (string)
      Return: dest (newly-allocated reversed string)

=head1 AUTHOR

Zakariyya Mughal <zmughal@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Zakariyya Mughal.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
