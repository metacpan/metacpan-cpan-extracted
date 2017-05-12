/*********************************************************************
 * MSDOS/Attrib.xs
 *
 * Copyright 1996,1997 Christopher J. Madsen
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
 * GNU General Public License or the Artistic License for more details.
 *
 * XSUBs to get and set MS-DOS file attributes under OS/2 or Win32
 *********************************************************************/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef __EMX__ /* OS/2 */
  #define INCL_DOSERRORS    /* API error codes */
  #define INCL_DOSFILEMGR   /* File Manager values */
  #include <os2.h>
#else /* WIN32 */
  #define WIN32_LEAN_AND_MEAN
  #include <windows.h>
  #define FILE_READONLY   FILE_ATTRIBUTE_READONLY
  #define FILE_HIDDEN     FILE_ATTRIBUTE_HIDDEN
  #define FILE_SYSTEM     FILE_ATTRIBUTE_SYSTEM
  #define FILE_DIRECTORY  FILE_ATTRIBUTE_DIRECTORY
  #define FILE_ARCHIVED   FILE_ATTRIBUTE_ARCHIVE
  typedef DWORD ULONG;
#endif /* WIN32 */

/*********************************************************************
 * Tell Perl about the FILE_ constants:
 *
 * Input:
 *   name:  The constant to return
 *
 * Returns:
 *   The value of the constant
 *   Sets errno and returns 0 if invalid name
 *********************************************************************/

static unsigned int
constant(const char *name)
{
  errno = 0;

  if (strncmp(name,"FILE_",5)) goto not_here;
  name += 5;                    /* Skip over FILE_ */

  if (strEQ(name, "READONLY"))
    return FILE_READONLY;
  if (strEQ(name, "HIDDEN"))
    return FILE_HIDDEN;
  if (strEQ(name, "SYSTEM"))
    return FILE_SYSTEM;
  if (strEQ(name, "DIRECTORY"))
    return FILE_DIRECTORY;
  if (strEQ(name, "ARCHIVED"))
    return FILE_ARCHIVED;
  if (strEQ(name, "CHANGEABLE")) /* All changeable attributes */
    return FILE_READONLY|FILE_HIDDEN|FILE_SYSTEM|FILE_ARCHIVED;

 not_here:
  errno = EINVAL;
  return 0;
} /* end constant */

/*********************************************************************
 * Get the attributes of a file or directory:
 *
 * Input:
 *   attribs:  A six byte buffer to store the attributes in
 *   path:     The pathname to get attributes for
 *
 * Output:
 *   attribs:
 *     A five character string "RHSAD"
 *       Each letter is replaced by an underscore ('_') if the file
 *       does not have the corresponding attribute.
 *     The empty string if an error occured
 *********************************************************************/

static void
get_attribs(char* attribs, const char* path)
{
#ifdef __EMX__
  FILESTATUS3  buf;             /* File info buffer */
  APIRET       rc;              /* Return code */

  rc = DosQueryPathInfo(path, 1 /* get file info */, &buf, sizeof(buf));

  if (rc != 0) {
    if (rc == ERROR_PATH_NOT_FOUND)
      errno = ENOENT;
    else
      errno = EINVAL;
    attribs[0] = '\0';
    return;
  }

  attribs[0] = ((buf.attrFile & FILE_READONLY)  ? 'R' : '_');
  attribs[1] = ((buf.attrFile & FILE_HIDDEN)    ? 'H' : '_');
  attribs[2] = ((buf.attrFile & FILE_SYSTEM)    ? 'S' : '_');
  attribs[3] = ((buf.attrFile & FILE_ARCHIVED)  ? 'A' : '_');
  attribs[4] = ((buf.attrFile & FILE_DIRECTORY) ? 'D' : '_');
  attribs[5] = '\0';

#else /* WIN32 */
  DWORD  rc;                    /* Return code */

  rc = GetFileAttributes(path);

  if (rc == 0xFFFFFFFF) {
    rc = GetLastError();
    if ((rc == ERROR_PATH_NOT_FOUND) || (rc == ERROR_FILE_NOT_FOUND))
      errno = ENOENT;
    else
      errno = EINVAL;
    attribs[0] = '\0';
    return;
  }
  attribs[0] = ((rc & FILE_ATTRIBUTE_READONLY)  ? 'R' : '_');
  attribs[1] = ((rc & FILE_ATTRIBUTE_HIDDEN)    ? 'H' : '_');
  attribs[2] = ((rc & FILE_ATTRIBUTE_SYSTEM)    ? 'S' : '_');
  attribs[3] = ((rc & FILE_ATTRIBUTE_ARCHIVE)   ? 'A' : '_');
  attribs[4] = ((rc & FILE_ATTRIBUTE_DIRECTORY) ? 'D' : '_');
  attribs[5] = '\0';
#endif /* WIN32 */
} /* end get_attribs */

/*********************************************************************
 * Set the attributes of a file or directory:
 *
 * This is intended for internal use only; the .pm file defines a
 * set_attribs function with a more flexible interface.
 *
 * Input:
 *   path:   The pathname to set the attributes for
 *   clear:  Bitmask of attributes to be removed
 *   set:    Bitmask of attributes to be added
 *
 * Note:
 *   CLEAR is applied before SET; therefore, an attribute in both SET
 *   and CLEAR will be set, not cleared.
 *
 * Returns:
 *   True if success
 *   False if error
 *********************************************************************/

static bool
_set_attribs(const char* path, ULONG clear, ULONG set)
{
#ifdef __EMX__
  FILESTATUS3  buf;             /* File info buffer */
  APIRET       rc;              /* Return code */

  rc = DosQueryPathInfo(path, 1 /* get file info */, &buf, sizeof(buf));

  if (rc == 0) {
    buf.attrFile &= ~clear;
    buf.attrFile |= set;
    rc = DosSetPathInfo(path, 1 /* set file info */, &buf, sizeof(buf),
                        0 /* can return immediately */);
  }

  if (rc != 0) {
    if (rc == ERROR_PATH_NOT_FOUND)
      errno = ENOENT;
    else if (rc == ERROR_SHARING_VIOLATION)
      errno = EACCES;
    else
      errno = EINVAL;
    return 0;                   /* Failure */
  } /* end if error */

  return 1;                     /* Success */

#else /* WIN32 */
  DWORD rc;                     /* Return code */

  rc = GetFileAttributes(path);

  if (rc == 0xFFFFFFFF)
    rc = 0;                     /* signal error */
  else {
    rc &= ~clear;
    rc |= set;
    rc = SetFileAttributes(path, rc);
  }

  if (rc == 0) {
    rc = GetLastError();
    if ((rc == ERROR_PATH_NOT_FOUND) || (rc == ERROR_FILE_NOT_FOUND))
      errno = ENOENT;
    else if ((rc == ERROR_ACCESS_DENIED) || (rc == ERROR_SHARING_VIOLATION))
      errno = EACCES;
    else
      errno = EINVAL;
    return 0;                   /* Failure */
  } /* end if error */

  return 1;                     /* Success */
#endif /* WIN32 */
} /* end _set_attribs */

MODULE = MSDOS::Attrib		PACKAGE = MSDOS::Attrib

PROTOTYPES: ENABLE

unsigned int
constant(name)
	char *	name

char *
get_attribs(path)
	char *	path
  PREINIT:
    char attribs[6];
  CODE:
    get_attribs(attribs, path);
    RETVAL = attribs;
  OUTPUT:
    RETVAL

bool
_set_attribs(path, clear, set)
	char *		path
	unsigned long	clear
	unsigned long	set

# Local Variables:
# tmtrack-file-task: "MSDOS::Attrib.xs"
# End:
