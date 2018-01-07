/* -*- c -*-
  See end for copyright and license.
*/
%define DOCSTRING
"A Perl wrapper for The CD Input and Control library's ISO-9660 library
See also the ISO-9660 specification. The freely available European
equivalant standard is called ECMA-119."
%enddef
%module(docstring=DOCSTRING) perliso9660

%{
/* Includes the header in the wrapper code */
#include <time.h>
#include <cdio/types.h>
#include <cdio/iso9660.h>
#include <cdio/version.h>
%}

#include <time.h>
#include <cdio/iso9660.h>
#include <cdio/version.h>

/* Various libcdio constants and typedefs */
%include "types.swg"

%include "typemaps.i"

typedef uint8_t iso_extension_mask_t;

%constant long int ISO_BLOCKSIZE        = CDIO_CD_FRAMESIZE;
%constant long int PVD_SECTOR 	        = ISO_PVD_SECTOR ;
%constant long int EVD_SECTOR 	        = ISO_EVD_SECTOR ;
%constant long int LEN_ISONAME 	        = LEN_ISONAME;
%constant long int MAX_SYSTEM_ID 	= ISO_MAX_SYSTEM_ID ;
%constant long int MAX_ISONAME 	        = MAX_ISONAME;
%constant long int MAX_PREPARER_ID 	= ISO_MAX_PREPARER_ID ;
%constant long int MAX_ISOPATHNAME 	= MAX_ISOPATHNAME;

%constant long int FILE                 = ISO_FILE;
%constant long int EXISTENCE            = ISO_EXISTENCE;
%constant long int DIRECTORY            = ISO_DIRECTORY;
%constant long int ASSOCIATED           = ISO_ASSOCIATED;
%constant long int RECORD               = ISO_RECORD;
%constant long int PROTECTION           = ISO_PROTECTION;
%constant long int DRESERVED1           = ISO_DRESERVED1;
%constant long int DRESERVED2           = ISO_DRESERVED2;
%constant long int MULTIEXTENT          = ISO_MULTIEXTENT;

%constant long int VD_BOOT_RECORD       = ISO_VD_BOOT_RECORD;
%constant long int VD_PRIMARY           = ISO_VD_PRIMARY;
%constant long int VD_SUPPLEMENTARY     = ISO_VD_SUPPLEMENTARY;
%constant long int VD_PARITION          = ISO_VD_PARITION;
%constant long int VD_END               = ISO_VD_END;

%constant long int MAX_PUBLISHER_ID     = ISO_MAX_PUBLISHER_ID;
%constant long int MAX_APPLICATION_ID   = ISO_MAX_APPLICATION_ID;
%constant long int MAX_VOLUME_ID        = ISO_MAX_VOLUME_ID;
%constant long int MAX_VOLUMESET_ID     = ISO_MAX_VOLUMESET_ID;
%constant long int STANDARD_ID          = ISO_STANDARD_ID;

%constant long int NOCHECK              = ISO9660_NOCHECK;
%constant long int SEVEN_BIT            = ISO9660_7BIT;
%constant long int ACHARS               = ISO9660_ACHARS;
%constant long int DCHARS               = ISO9660_DCHARS;

%constant long int EXTENSION_JOLIET_LEVEL1 = ISO_EXTENSION_JOLIET_LEVEL1;
%constant long int EXTENSION_JOLIET_LEVEL2 = ISO_EXTENSION_JOLIET_LEVEL2;
%constant long int EXTENSION_JOLIET_LEVEL3 = ISO_EXTENSION_JOLIET_LEVEL3;
%constant long int EXTENSION_ROCK_RIDGE    = ISO_EXTENSION_ROCK_RIDGE;
%constant long int EXTENSION_HIGH_SIERRA   = ISO_EXTENSION_HIGH_SIERRA;

%constant long int EXTENSION_ALL           = ISO_EXTENSION_ALL;
%constant long int EXTENSION_NONE          = ISO_EXTENSION_NONE;
%constant long int EXTENSION_JOLIET        = ISO_EXTENSION_JOLIET;

/* Set up to allow functions to return stat lists of type "stat
   *". We'll use a typedef so we can make sure to isolate this.
*/
%inline %{
typedef CdioList_t IsoStatList_t;
typedef iso9660_stat_t IsoStat_t;
%}
typedef CdioList_t IsoStatList_t;
typedef iso9660_stat_t IsoStat_t;

%typemap(out) IsoStat_t *{
    // $1 is of type IsoStatList_t
    iso9660_stat_t *p_statbuf = result;

    if (!result) goto out;

 PPCODE:
    /* Have Perl compute the length of the string using strlen() */
    XPUSHs(sv_2mortal(newSVpv(p_statbuf->filename, 0)));
    XPUSHs(sv_2mortal(newSViv(p_statbuf->lsn)));
    XPUSHs(sv_2mortal(newSViv(p_statbuf->size)));
    XPUSHs(sv_2mortal(newSViv(p_statbuf->secsize)));
    XPUSHs(sv_2mortal(newSViv(p_statbuf->type)));
    XPUSHs(sv_2mortal(newSViv(p_statbuf->tm.tm_sec)));
    XPUSHs(sv_2mortal(newSViv(p_statbuf->tm.tm_min)));
    XPUSHs(sv_2mortal(newSViv(p_statbuf->tm.tm_hour)));
    XPUSHs(sv_2mortal(newSViv(p_statbuf->tm.tm_mday)));
    XPUSHs(sv_2mortal(newSViv(p_statbuf->tm.tm_mon)));
    XPUSHs(sv_2mortal(newSViv(p_statbuf->tm.tm_year)));
    XPUSHs(sv_2mortal(newSViv(p_statbuf->tm.tm_wday)));
    XPUSHs(sv_2mortal(newSViv(p_statbuf->tm.tm_yday)));
    XPUSHs(sv_2mortal(newSViv(p_statbuf->tm.tm_isdst)));
    argvi += 16;
    free (p_statbuf);
 out: ;
}

%typemap(out) IsoStatList_t *{
    // $1 is of type IsoStatList_t
    CdioISO9660FileList_t *p_entlist   = result;
    CdioListNode_t *p_entnode;
    unsigned int num = 0;

    if (!result) goto out;

 PPCODE:
    /* For each element in the array of strings, create a new
     * mortalscalar, and stuff it into the above array. */
    _CDIO_LIST_FOREACH (p_entnode, p_entlist) {
      iso9660_stat_t *p_statbuf =
	(iso9660_stat_t *) _cdio_list_node_data (p_entnode);
      /* Have perl compute the length of the string using strlen() */
      XPUSHs(sv_2mortal(newSVpv(p_statbuf->filename, 0)));
      XPUSHs(sv_2mortal(newSViv(p_statbuf->lsn)));
      XPUSHs(sv_2mortal(newSViv(p_statbuf->size)));
      XPUSHs(sv_2mortal(newSViv(p_statbuf->secsize)));
      XPUSHs(sv_2mortal(newSViv(p_statbuf->type)));
      XPUSHs(sv_2mortal(newSViv(p_statbuf->tm.tm_sec)));
      XPUSHs(sv_2mortal(newSViv(p_statbuf->tm.tm_min)));
      XPUSHs(sv_2mortal(newSViv(p_statbuf->tm.tm_hour)));
      XPUSHs(sv_2mortal(newSViv(p_statbuf->tm.tm_mday)));
      XPUSHs(sv_2mortal(newSViv(p_statbuf->tm.tm_mon)));
      XPUSHs(sv_2mortal(newSViv(p_statbuf->tm.tm_year)));
      XPUSHs(sv_2mortal(newSViv(p_statbuf->tm.tm_wday)));
      XPUSHs(sv_2mortal(newSViv(p_statbuf->tm.tm_yday)));
      XPUSHs(sv_2mortal(newSViv(p_statbuf->tm.tm_isdst)));
      num += 14;
    }
    iso9660_filelist_free(p_entlist);
    argvi += num + 2;
 out: ;
}

/*!
  Open an ISO 9660 image for reading. Maybe in the future we will have
  a mode. NULL is returned on error.
*/
%rename iso9660_open open_iso;
iso9660_t *iso9660_open (const char *psz_path /*flags, mode */);

/*!
  Open an ISO 9660 image for reading allowing various ISO 9660
  extensions.  Maybe in the future we will have a mode. NULL is
  returned on error.
*/
%rename iso9660_open_ext open_ext;
iso9660_t *iso9660_open_ext (const char *psz_path,
			     iso_extension_mask_t iso_extension_mask);

/*!
  Open an ISO 9660 image for reading with some tolerence for positioning
  of the ISO9660 image. We scan for ISO_STANDARD_ID and use that to set
  the eventual offset to adjust by (as long as that is <= i_fuzz).

  Maybe in the future we will have a mode. NULL is returned on error.

  @see iso9660_open
*/
%rename iso9660_open_fuzzy open_fuzzy;
iso9660_t *iso9660_open_fuzzy (const char *psz_path /*flags, mode */,
			       uint16_t i_fuzz);

/*!
  Open an ISO 9660 image for reading with some tolerence for positioning
  of the ISO9660 image. We scan for ISO_STANDARD_ID and use that to set
  the eventual offset to adjust by (as long as that is <= i_fuzz).

  Maybe in the future we will have a mode. NULL is returned on error.

  @see iso9660_open
*/
%rename iso9660_open_fuzzy open_fuzzy_ext;
iso9660_t *iso9660_open_fuzzy_ext (const char *psz_path,
				   iso_extension_mask_t iso_extension_mask,
				   uint16_t i_fuzz
				   /*flags, mode */);
/*!
  Read the Super block of an ISO 9660 image but determine framesize
  and datastart and a possible additional offset. Generally here we are
  not reading an ISO 9660 image but a CD-Image which contains an ISO 9660
  filesystem.
*/
%rename iso9660_ifs_fuzzy_read_superblock ifs_fuzzy_read_superblock;
bool iso9660_ifs_fuzzy_read_superblock (iso9660_t *p_iso,
					iso_extension_mask_t iso_extension_mask,
					uint16_t i_fuzz);
/*!
  Close previously opened ISO 9660 image.
  True is unconditionally returned. If there was an error false would
  be returned.
*/
%rename iso9660_close close;
bool iso9660_close (iso9660_t * p_iso);

%typemap(out) buf_t {
  /* $1 is of type buf_t */
  ST(argvi) = sv_newmortal();
  if (result) {
    /* I don't yet know how to pick up arg4 another way.
       THIS MEANS ARG3 MUST ALWAYS BE THE SIZE.  */
    sv_setpvn((SV*)ST(argvi++), (char *) result, *arg4);
    /* Don't leak memory. return value was malloc'd by libcdio. */
    /* free(result);   */
  } else {
    sv_setsv((SV*)ST(argvi++), &PL_sv_undef);
  }
}
%inline %{
  typedef long int my_ssize_t;
%}
%apply my_ssize_t *OUTPUT { my_ssize_t *pi_size };

/*!  Seek to a position and then read n bytes. (buffer, size) are
  returned.
*/
%newobject seek_read; // free malloc'd return value
typedef char *buf_t;
buf_t seek_read (const iso9660_t *p_iso,
		 lsn_t start, long int i_size,
		 /*out*/ my_ssize_t *pi_size);
%inline %{
typedef char *buf_t;
buf_t seek_read (const iso9660_t *p_iso,
		 lsn_t start, long int i_size,
		 /*out*/ my_ssize_t *pi_size) {

  char *p_buf = calloc(ISO_BLOCKSIZE, i_size);
  *pi_size = iso9660_iso_seek_read(p_iso, p_buf, start, i_size);
  return p_buf;
 }
%}


/*!
  Read the Primary Volume Descriptor for a CD.
  True is returned if read, and false if there was an error.
*/
iso9660_pvd_t *fs_read_pvd ( const CdIo_t *p_cdio );
%inline %{
iso9660_pvd_t *fs_read_pvd ( const CdIo_t *p_cdio ) {
  static iso9660_pvd_t pvd;
  bool b_ok = iso9660_fs_read_pvd ( p_cdio, &pvd );
  if (!b_ok) return NULL;
  return &pvd;
 }
%}

/*!
  Read the Primary Volume Descriptor for an ISO 9660 image.
  True is returned if read, and false if there was an error.
*/
iso9660_pvd_t *ifs_read_pvd ( const iso9660_t *p_iso );
%inline %{
iso9660_pvd_t *ifs_read_pvd ( const iso9660_t *p_iso ) {
  static iso9660_pvd_t pvd;
  bool b_ok = iso9660_ifs_read_pvd ( p_iso, &pvd );
  if (!b_ok) return NULL;
  return &pvd;
 }
%}

/*!
  Read the Super block of an ISO 9660 image. This is the
  Primary Volume Descriptor (PVD) and perhaps a Supplemental Volume
  Descriptor if (Joliet) extensions are acceptable.
*/
%rename iso9660_fs_read_superblock fs_read_superblock;
bool iso9660_fs_read_superblock (CdIo_t *p_cdio,
				 iso_extension_mask_t iso_extension_mask);

/*!
  Read the Super block of an ISO 9660 image. This is the
  Primary Volume Descriptor (PVD) and perhaps a Supplemental Volume
  Descriptor if (Joliet) extensions are acceptable.
*/
%rename iso9660_ifs_read_superblock ifs_read_superblock;
bool iso9660_ifs_read_superblock (iso9660_t *p_iso,
				  iso_extension_mask_t iso_extension_mask);


/*====================================================
  Time conversion
 ====================================================*/
/*!
  Set time in format used in ISO 9660 directory index record
  from a Unix time structure. */
iso9660_dtime_t *
set_dtime ( int tm_sec, int tm_min, int tm_hour, int tm_mday, int tm_mon,
	    int tm_year);
%inline %{
iso9660_dtime_t *
set_dtime ( int tm_sec, int tm_min, int tm_hour, int tm_mday, int tm_mon,
	    int tm_year)
{
  struct tm tm = { tm_sec, tm_min, tm_hour, tm_mday, tm_mon, tm_year, 0, 0, 0 };
  static iso9660_dtime_t dtime;
  iso9660_set_dtime (&tm, &dtime);
  return &dtime;
}
%}

/*!
  Set "long" time in format used in ISO 9660 primary volume descriptor
  from a Unix time structure. */
iso9660_ltime_t *
set_ltime ( int tm_sec, int tm_min, int tm_hour, int tm_mday, int tm_mon,
	    int tm_year);

%inline %{
iso9660_ltime_t *
set_ltime ( int tm_sec, int tm_min, int tm_hour, int tm_mday, int tm_mon,
	    int tm_year)

{
  struct tm tm = { tm_sec, tm_min, tm_hour, tm_mday, tm_mon, tm_year, 0, 0, 0 };
  static iso9660_ltime_t ldate;
  iso9660_set_ltime (&tm, &ldate);
  return &ldate;
}
%}

/*!
  Get Unix time structure from format use in an ISO 9660 directory index
  record. Even though tm_wday and tm_yday fields are not explicitly in
  dtime, they are calculated from the other fields.

  If tm is to reflect the localtime, set "use_localtime" true, otherwise
  tm will reported in GMT.
*/
%apply int *OUTPUT { int *tm_sec, int *tm_min,  int *tm_hour, int *tm_mday,
                     int *tm_mon, int *tm_year, int *tm_wday, int *tm_yday,
                     int *tm_isdst };

bool get_dtime (const iso9660_dtime_t *dtime, bool use_localtime,
		int *tm_sec, int *tm_min,  int *tm_hour, int *tm_mday,
		int *tm_mon, int *tm_year, int *tm_wday, int *tm_yday,
		int *tm_isdst);

%inline %{
bool get_dtime (const iso9660_dtime_t *dtime, bool use_localtime,
		int *tm_sec, int *tm_min,  int *tm_hour, int *tm_mday,
		int *tm_mon, int *tm_year, int *tm_wday, int *tm_yday,
		int *tm_isdst)
{
  struct tm tm;
  bool b_okay = iso9660_get_dtime (dtime, use_localtime, &tm);
  if (b_okay) {
    *tm_sec   = tm.tm_sec;
    *tm_min   = tm.tm_min;
    *tm_hour  = tm.tm_hour;
    *tm_mon   = tm.tm_mon;
    *tm_mday  = tm.tm_mday;
    *tm_year  = tm.tm_year;
    *tm_wday  = tm.tm_wday;
    *tm_yday  = tm.tm_yday;
    *tm_isdst = tm.tm_isdst;
  }
  return b_okay;
}
%}

/*!
  Get "long" time in format used in ISO 9660 primary volume descriptor
  from a Unix time structure.
*/
bool get_ltime (const iso9660_ltime_t *dtime,
		int *tm_sec, int *tm_min,  int *tm_hour, int *tm_mday,
		int *tm_mon, int *tm_year, int *tm_wday, int *tm_yday,
		int *tm_isdst);

%inline %{
bool get_ltime (const iso9660_ltime_t *p_ldate,
		int *tm_sec, int *tm_min,  int *tm_hour, int *tm_mday,
		int *tm_mon, int *tm_year, int *tm_wday, int *tm_yday,
		int *tm_isdst)
{
  struct tm tm;
  bool b_okay = iso9660_get_ltime (p_ldate, &tm);
  if (b_okay) {
    *tm_sec   = tm.tm_sec;
    *tm_min   = tm.tm_min;
    *tm_hour  = tm.tm_hour;
    *tm_mon   = tm.tm_mon;
    *tm_mday  = tm.tm_mday;
    *tm_year  = tm.tm_year;
    *tm_wday  = tm.tm_wday;
    *tm_yday  = tm.tm_yday;
    *tm_isdst = tm.tm_isdst;
  }
  return b_okay;
}
%}


/*========================================================
  Characters used in file and directory and manipulation
 =======================================================*/
/*!
   Return true if c is a DCHAR - a character that can appear in an an
   ISO-9600 level 1 directory name. These are the ASCII capital
   letters A-Z, the digits 0-9 and an underscore.
*/
%rename iso9660_isdchar is_dchar;
bool iso9660_isdchar (int c);

/*!
   Return true if c is an ACHAR -
   These are the DCHAR's plus some ASCII symbols including the space
   symbol.
*/
%rename iso9660_isachar is_achar;
bool iso9660_isachar (int c);

/*!
   Convert an ISO-9660 file name that stored in a directory entry into
   what's usually listed as the file name in a listing.
   Lowercase name, and remove trailing ;1's or .;1's and
   turn the other ;'s into version numbers.

   @param psz_oldname the ISO-9660 filename to be translated.
   @param psz_newname returned string. The caller allocates this and
   it should be at least the size of psz_oldname.
   @return length of the translated string is returned.
*/
%newobject name_translate;
char * name_translate(const char *psz_oldname);
%inline %{
char *
name_translate(const char *psz_oldname) {
  char *psz_newname=calloc(sizeof(char), strlen(psz_oldname)+1);
  iso9660_name_translate(psz_oldname, psz_newname);
  return psz_newname;
}
%}

/*!
   Convert an ISO-9660 file name that stored in a directory entry into
   what's usually listed as the file name in a listing.  Lowercase
   name if no Joliet Extension interpretation. Remove trailing ;1's or
   .;1's and turn the other ;'s into version numbers.

   @param psz_oldname the ISO-9660 filename to be translated.
   @param psz_newname returned string. The caller allocates this and
   it should be at least the size of psz_oldname.
   @param i_joliet_level 0 if not using Joliet Extension. Otherwise the
   Joliet level.
   @return length of the translated string is returned. It will be no greater
   than the length of psz_oldname.
*/
%newobject name_translate_ext;
char * name_translate_ext(const char *psz_oldname, uint8_t i_joliet_level);
%inline %{
char *
name_translate_ext(const char *psz_oldname, uint8_t i_joliet_level) {
  char *psz_newname=calloc(sizeof(char), strlen(psz_oldname)+1);
  iso9660_name_translate_ext(psz_oldname, psz_newname, i_joliet_level);
  return psz_newname;
}
%}

/*!
  Pad string src with spaces to size len and copy this to dst. If
  len is less than the length of src, dst will be truncated to the
  first len characters of src.

  src can also be scanned to see if it contains only ACHARs, DCHARs,
  7-bit ASCII chars depending on the enumeration _check.

  In addition to getting changed, dst is the return value.
  Note: this string might not be NULL terminated.
 */
%newobject strncpy_pad; // free malloc'd return value
char *strncpy_pad(const char src[], size_t len, enum strncpy_pad_check _check);
%inline %{
char *
strncpy_pad(const char src[], size_t len, enum strncpy_pad_check _check) {
  char *dst = calloc(sizeof(char), len+1);
  return iso9660_strncpy_pad(dst, src, len, _check);
}
%}

/*=====================================================================
  Files and Directory Names
======================================================================*/

/*!
  Check that psz_path is a valid ISO-9660 directory name.

  A valid directory name should not start out with a slash (/),
  dot (.) or null byte, should be less than 37 characters long,
  have no more than 8 characters in a directory component
  which is separated by a /, and consist of only DCHARs.

  True is returned if psz_path is valid.
 */
%rename iso9660_dirname_valid_p dirname_valid_p;
bool iso9660_dirname_valid_p (const char psz_path[]);

/*!
  Take psz_path and a version number and turn that into a ISO-9660
  pathname.  (That's just the pathname followed by ";" and the version
  number. For example, mydir/file.ext -> MYDIR/FILE.EXT;1 for version
  1. The resulting ISO-9660 pathname is returned.
*/
%rename iso9660_pathname_isofy pathname_isofy;
%newobject iso9660_pathname_isofy; // free malloc'd return value
char *iso9660_pathname_isofy (const char psz_path[], uint16_t i_version);

/*!
  Check that psz_path is a valid ISO-9660 pathname.

  A valid pathname contains a valid directory name, if one appears and
  the filename portion should be no more than 8 characters for the
  file prefix and 3 characters in the extension (or portion after a
  dot). There should be exactly one dot somewhere in the filename
  portion and the filename should be composed of only DCHARs.

  True is returned if psz_path is valid.
 */
%rename iso9660_pathname_valid_p pathname_valid_p;
bool iso9660_pathname_valid_p (const char psz_path[]);

/* ... */

/*!
   Given a directory pointer, find the filesystem entry that contains
   lsn and return information about it.

   Returns stat_t of entry if we found lsn, or NULL otherwise.
 */
%rename iso9660_fs_find_lsn fs_find_lsn;
IsoStat_t *iso9660_fs_find_lsn(CdIo_t *p_cdio, lsn_t i_lsn);


/*!
   Given a directory pointer, find the filesystem entry that contains
   lsn and return information about it.

   Returns stat_t of entry if we found lsn, or NULL otherwise.
 */
%rename iso9660_ifs_find_lsn ifs_find_lsn;
IsoStat_t *iso9660_ifs_find_lsn(iso9660_t *p_iso, lsn_t i_lsn);


/*!
  Return file status for psz_path. NULL is returned on error.
 */
%rename iso9660_fs_stat fs_stat;
IsoStat_t *iso9660_fs_stat (CdIo_t *p_cdio, const char psz_path[]);


/*!
  Return file status for path name psz_path. NULL is returned on error.
  pathname version numbers in the ISO 9660 name are dropped, i.e. ;1
  is removed and if level 1 ISO-9660 names are lowercased.

  The b_mode2 parameter is not used.
 */
%rename iso9660_fs_stat_translate fs_stat_translate;
IsoStat_t *iso9660_fs_stat_translate (CdIo_t *p_cdio,
				      const char psz_path[]);

/*!
  Return file status for pathname. NULL is returned on error.
 */
%rename iso9660_ifs_stat ifs_stat;
IsoStat_t *iso9660_ifs_stat (iso9660_t *p_iso, const char psz_path[]);


/*!  Return file status for path name psz_path. NULL is returned on
  error.  pathname version numbers in the ISO 9660 name are dropped,
  i.e. ;1 is removed and if level 1 ISO-9660 names are lowercased.
 */
%rename iso9660_ifs_stat_translate ifs_stat_translate;
IsoStat_t *iso9660_ifs_stat_translate (iso9660_t *p_iso,
				       const char psz_path[]);

/*!  Read psz_path (a directory) and return a list of iso9660_stat_t
  pointers for the files inside that directory. The caller must free the
  returned result.
*/
%newobject fs_readdir; // free malloc'd return value
IsoStatList_t *fs_readdir (CdIo_t *p_cdio, const char psz_path[]);

%inline %{
IsoStatList_t *fs_readdir (CdIo_t *p_cdio, const char psz_path[])
{
  CdioList_t *p_statlist = iso9660_fs_readdir (p_cdio, psz_path);
  return p_statlist;
}
%}

/*!  Read psz_path (a directory) and return a list of iso9660_stat_t
  pointers for the files inside that directory. The caller must free
  the returned result.
*/
%newobject ifs_readdir; // free malloc'd return value
IsoStatList_t *ifs_readdir (iso9660_t *p_iso, const char psz_path[]);

%inline %{
IsoStatList_t *ifs_readdir (iso9660_t *p_iso, const char psz_path[])
{
  CdioList_t *p_statlist = iso9660_ifs_readdir (p_iso, psz_path);
  return p_statlist;
}
%}

/*!
  Return the PVD's application ID.
  NULL is returned if there is some problem in getting this.
*/
%rename iso9660_get_application_id get_application_id;
char * iso9660_get_application_id(iso9660_pvd_t *p_pvd);

/*!
  Get the application ID.  Return NULL if there
  is some problem in getting this.
*/
%newobject get_application_id; // free malloc'd return value
char *ifs_get_application_id(iso9660_t *p_iso);
%inline %{
char *
ifs_get_application_id(iso9660_t *p_iso) {
  char *psz;
  bool ok = iso9660_ifs_get_application_id(p_iso, &psz);
  if (!ok) return NULL;
  return psz;
}
%}


/*!
  Return the Joliet level recognized for p_iso.
*/
%rename iso9660_ifs_get_joliet_level get_joliet_level;
uint8_t iso9660_ifs_get_joliet_level(iso9660_t *p_iso);

%rename iso9660_get_dir_len get_dir_len;
uint8_t iso9660_get_dir_len(const iso9660_dir_t *p_idr);

/*!
  Return the directory name stored in the iso9660_dir_t
*/
%rename iso9660_get_to_name get_to_name;
%newobject iso9660_dir_to_name; // free malloc'd return value
char * iso9660_dir_to_name (const iso9660_dir_t *p_iso9660_dir);

/*!
  Returns a POSIX mode for a given p_iso_dirent.
*/
%rename iso9660_get_posix_filemode get_posix_filemode;
mode_t iso9660_get_posix_filemode(const iso9660_stat_t *p_iso_dirent);

/*!
  Return a string containing the preparer id with trailing
  blanks removed.
*/
%rename iso9660_get_preparer_id get_preparer_id;
char *iso9660_get_preparer_id(const iso9660_pvd_t *p_pvd);

/*!  Get the preparer ID.  Return NULL if there is some problem in
  getting this.
*/
%newobject ifs_get_preparer_id; // free malloc'd return value
char *ifs_get_preparer_id(iso9660_t *p_iso);
%inline %{
char *
ifs_get_preparer_id(iso9660_t *p_iso) {
  char *psz;
  bool ok = iso9660_ifs_get_preparer_id(p_iso, &psz);
  if (!ok) return NULL;
  return psz;
}
%}

/*!
  Return a string containing the PVD's publisher id with trailing
  blanks removed.
*/
%rename iso9660_get_publisher_id get_publisher_id;
char *iso9660_get_publisher_id(const iso9660_pvd_t *p_pvd);

/*!
  Get the publisher ID.  return NULL if there
  is some problem in getting this.
*/
%newobject ifs_get_publisher_id; // free malloc'd return value
char *ifs_get_publisher_id(iso9660_t *p_iso);
%inline %{
char *
ifs_get_publisher_id(iso9660_t *p_iso) {
  char *psz;
  bool ok = iso9660_ifs_get_publisher_id(p_iso, &psz);
  if (!ok) return NULL;
  return psz;
}
%}

%rename iso9660_get_pvd_type get_pvd_type;
uint8_t iso9660_get_pvd_type(const iso9660_pvd_t *p_pvd);

%rename iso9660_get_pvd_id get_pvd_id;
const char * iso9660_get_pvd_id(const iso9660_pvd_t *p_pvd);

%rename iso9660_get_pvd_space_size get_pvd_space_size;
int iso9660_get_pvd_space_size(const iso9660_pvd_t *p_pvd);

%rename iso9660_get_pvd_block_size get_pvd_block_size;
int iso9660_get_pvd_block_size(const iso9660_pvd_t *p_pvd) ;

/*! Return the primary volume id version number (of pvd).
  If there is an error 0 is returned.
*/
%rename iso9660_get_pvd_version get_pvd_version;
int iso9660_get_pvd_version(const iso9660_pvd_t *pvd) ;

/*!
  Return a string containing the PVD's system id with trailing
  blanks removed.
*/
%rename iso9660_get_system_id get_system_id;
char *iso9660_get_system_id(const iso9660_pvd_t *p_pvd);

/*!
  Get the system ID.  return NULL if there
  is some problem in getting this.
*/
%newobject ifs_get_system_id; // free malloc'd return value
char *ifs_get_system_id(iso9660_t *p_iso);
%inline %{
char *
ifs_get_system_id(iso9660_t *p_iso) {
  char *psz;
  bool ok = iso9660_ifs_get_system_id(p_iso, &psz);
  if (!ok) return NULL;
  return psz;
}
%}

/*! Return the LSN of the root directory for pvd.
  If there is an error CDIO_INVALID_LSN is returned.
*/
%rename iso9660_get_root_lsn get_root_lsn;
lsn_t iso9660_get_root_lsn(const iso9660_pvd_t *p_pvd);

/*!
  Return the PVD's volume ID.
*/
%rename iso9660_get_volume_id get_volume_id;
char *iso9660_get_volume_id(const iso9660_pvd_t *p_pvd);

/*!
  Get the system ID.  return NULL if there
  is some problem in getting this.
*/
%newobject ifs_get_volume_id; // free malloc'd return value
char *ifs_get_volume_id(iso9660_t *p_iso);
%inline %{
char *
ifs_get_volume_id(iso9660_t *p_iso) {
  char *psz;
  bool ok = iso9660_ifs_get_volume_id(p_iso, &psz);
  if (!ok) return NULL;
  return psz;
}
%}

/*!
  Return the PVD's volumeset ID.
  NULL is returned if there is some problem in getting this.
*/
%rename iso9660_get_volumeset_id get_volumeset_id;
char *iso9660_get_volumeset_id(const iso9660_pvd_t *p_pvd);

/*!
  Get the volumeset ID.  return NULL if there
  is some problem in getting this.
*/
%newobject ifs_get_volumeset_id; // free malloc'd return value
char *ifs_get_volumeset_id(iso9660_t *p_iso);
%inline %{
char *
ifs_get_volumeset_id(iso9660_t *p_iso) {
  char *psz;
  bool ok = iso9660_ifs_get_volumeset_id(p_iso, &psz);
  if (!ok) return NULL;
  return psz;
}
%}

/* ================= pathtable  ================== */

/*! Zero's out pathable. Do this first. */
%rename iso9660_pathtable_init pathtable_init;
void iso9660_pathtable_init (void *pt);

%rename iso9660_pathtable_get_size pathtable_get_size;
unsigned int iso9660_pathtable_get_size (const void *pt);

%rename iso9660_pathtable_l_add_entry pathtable_l_add_entry;
uint16_t iso9660_pathtable_l_add_entry (void *pt, const char name[],
					uint32_t extent, uint16_t parent);

%rename iso9660_pathtable_m_add_entry pathtable_m_add_entry;
uint16_t iso9660_pathtable_m_add_entry (void *pt, const char name[],
					uint32_t extent, uint16_t parent);

/*======================================================================
   Volume Descriptors
========================================================================*/

#ifdef FINSHED
void iso9660_set_pvd (void *pd, const char volume_id[],
		      const char application_id[],
		      const char publisher_id[], const char preparer_id[],
		      uint32_t iso_size, const void *root_dir,
		      uint32_t path_table_l_extent,
		      uint32_t path_table_m_extent,
		      uint32_t path_table_size, const time_t *pvd_time);
#endif /*FINISHED*/

%rename iso9660_set_evd set_evd;
void iso9660_set_evd (void *pd);

/*!
  Return true if ISO 9660 image has extended attrributes (XA).
*/
%rename iso9660_ifs_is_xa is_xa;
bool iso9660_ifs_is_xa (const iso9660_t * p_iso);

%perlcode %{

import Device::Cdio::VERSION;
$VERSION = $Device::Cdio::VERSION;
use strict;
=pod

=head1 NAME

perliso9660 - lower-level wrapper to libiso9660, the ISO 9660 library of the CD Input and Control package

=head1 SYNOPSIS

This is fairly straight-forward wrapper around the C library libiso9660
Although this is perfectly usable on its own, it is expected that the
Object-Oriented interface L<Device::Cdio::ISO9660> is what most people will
want to use.

There are various constants that are defined here.

=head1 DESCRIPTION

Encapsulation is done in two parts. The lower-level Perl
interface is called perliso9660 (this file) and is generated via SWIG.

=head1 CONSTANTS

=over 4

=item ISO_BLOCKSIZE

Number of bytes in an ISO 9660 block (2048)

=item PVD_SECTOR

"Primary Volume Descriptor" sector (16)

=item EVD_SECTOR

"End Volume Descriptor" sector (17)

=item LEN_ISONAME

Size in bytes of the filename  portion + null byte (31)

=item MAX_SYSTEM_ID

Maximum number of characters in a system id (32)

=item MAX_ISONAME

Size in bytes of the filename portion + null byte. (37)

=item MAX_PREPARER_ID

Maximum number of characters in a preparer id. (128)

=item MAX_ISOPATHNAME

Maximum number of characters in the entire ISO 9660 filename. (255)

=item MAX_PUBLISHER_ID

Maximum number of characters in a publisher id.

=item MAX_APPLICATION_ID

Maximum number of characters in an application id.

=item MAX_VOLUME_ID

Maximum number of characters in a volume id.

=item MAX_VOLUMESET_ID

Maximum number of characters in a volume-set id.

=item STANDARD_ID

String inside frame which identifies an ISO 9660 filesystem. This
string is the "id" field of an iso9660_pvd_t or an iso9660_svd_t.

=item EXTENSION_JOLIET_LEVEL1

Use Joliet Level 1.

=item EXTENSION_JOLIET_LEVEL2

Use Joliet Level 2.

=item EXTENSION_JOLIET_LEVEL3

Use Joliet Level 3

=item EXTENSION_ROCK_RIDGE

Use Rock-Ridge Extensions.

=item EXTENSION_HIGH_SIERRA

Use High-Sierra Extensions.

=item EXTENSION_ALL

Use any of the above extensions.

=item EXTENSION_NONE

Use none of the above extensions.

=item EXTENSION_JOLIET

Use any Joliet Extension available.

=back

=head2 Directory Flags

=over 4

=item FILE

Not really a flag but the lack of one.

=item EXISTENCE

Do not make existence known (hidden).

=item DIRECTORY

This file is a directory.

=item ASSOCIATED

This file is an associated file

=item RECORD

Record format is in extended attribute if not set.

=item PROTECTION

No read/execute permission in extended attribute.

=item DRESERVED1

Reserved bit 5.

=item DRESERVED2

Reserved bit 6

=item MULTIEXTENT

Not the final entry of a multi-extent file.

=back

=head2 Volume Descriptor Types

=over 4

=item VD_BOOT_RECORD

CD is bootable

=item VD_PRIMARY

Primary Volume descriptor which must be in any ISO-9660

=item VD_SUPPLEMENTARY

(optional) Supplimentary Volume Descriptor. But used by Joliet, for
example.

=item VD_PARITION

Indicates a partition of a CD.

=item VD_END

=back

=head2 Flags for strncpy

=over 4

=item NOCHECK

Enumeration meaning don not check in strncpy_pad.

=item SEVEN_BIT

Enumeration in strncpy_pad for checking entry has only 7-bit characters.


=item ACHARS

Enumeration in strncpy_pad for checking entry has only ACHARs.

=item DCHARS

Enumeration in strncpy_pad for checking entry has only DCHARs.

=back

=head1 SUBROUTINES

=head2 Input Output

=head3 open_iso

Open an ISO 9660 image for reading. Maybe in the future we will have
mode. undef is returned on error.

=head3 open_ext

Open an ISO 9660 image for reading allowing various ISO 9660
extensions.  Maybe in the future we will have a mode. undef is
eturned on error.

=head3 open_fuzzy

Open an ISO 9660 image for reading with some tolerence for positioning
of the ISO9660 image. We scan for $perliso9660::ISO_STANDARD_ID and
use that to set he eventual offset to adjust by (as long as that is <=
i_fuzz).

Maybe in the future we will have a mode. undef is returned on error.

See also open_iso

=head3 open_fuzzy_ext

Open an ISO 9660 image for reading with some tolerence for positioning
of the ISO9660 image. We scan for ISO_STANDARD_ID and use that to set
the eventual offset to adjust by (as long as that is <= i_fuzz).

Maybe in the future we will have a mode. undef is returned on error.

=head3 ifs_fuzzy_read_superblock

Read the Super block of an ISO 9660 image but determine framesize
and datastart and a possible additional offset. Generally here we are
not reading an ISO 9660 image but a CD-Image which contains an ISO 9660
filesystem.

=head3 close

Close previously opened ISO 9660 image.
1 is unconditionally returned. If there was an error 0 would
be returned.

=head3 seek_read

Seek to a position and then read n bytes. (buffer, size) are is returned.

=head3 fs_read_pvd

Read the Primary Volume Descriptor for a CD.
1 is returned if read, and 0 if there was an error.

=head3 ifs_read_pvd

Read the Primary Volume Descriptor for an ISO 9660 image.
1 is returned if read, and 0 if there was an error.

=head3 _fs_read_superblock

Read the Super block of an ISO 9660 image. This is the
Primary Volume Descriptor (PVD) and perhaps a Supplemental Volume
Descriptor if (Joliet) extensions are acceptable.

=head3 ifs_read_superblock

Read the Super block of an ISO 9660 image. This is the
Primary Volume Descriptor (PVD) and perhaps a Supplemental Volume
Descriptor if (Joliet) extensions are acceptable.

=head2 Time Conversion

=head3 set_dtime

Set time in format used in ISO 9660 directory index record
from a Unix time structure.


=head3 set_ltime

Set "long" time in format used in ISO 9660 primary volume descriptor
from a Unix time structure.

=head3 get_dtime

Get Unix time structure from format use in an ISO 9660 directory index
record. Even though tm_wday and tm_yday fields are not explicitly in
dtime, they are calculated from the other fields.

If tm is to reflect the localtime, set "use_localtime" 1, otherwise
tm will reported in GMT.

=head3 get_ltime

Get "long" time in format used in ISO 9660 primary volume descriptor
from a Unix time structure.

=head2 Character Classification and String Manipulation

=head3 is_dchar

Return 1 if c (an int) is a DCHAR - a character that can appear in an an
ISO-9600 level 1 directory name. These are the ASCII capital
letters A-Z, the digits 0-9 and an underscore.

=head3 is_achar

=head3 name_translate

Convert an ISO-9660 file name that stored in a directory entry into
what is usually listed as the file name in a listing.
wercase name, and remove trailing ;1's or .;1's and
turn the others into version numbers.

=head3 name_translate_ext

Convert an ISO-9660 file name that stored in a directory entry into
what is usually listed as the file name in a listing.  Lowercase
name if no Joliet Extension interpretation. Remove trailing ;1's or
.;1's and turn the others into version numbers.

=head3 strncpy_pad

Pad string src with spaces to size len and copy this to dst. If len is
less than the length of src, dst will be truncated to the first len
characters of src.

src can also be scanned to see if it contains only ACHARs, DCHARs,
7-bit ASCII chars depending on the enumeration _check.

In addition to getting changed, dst is the return value.  Note: this
string might not be undef terminated.

=head2 File and Directory Names

=head3 dirname_valid_p

Check that psz_path is a valid ISO-9660 directory name.

A valid directory name should not start out with a slash (/),
dot (.) or null byte, should be less than 37 characters long,
have no more than 8 characters in a directory component
which is separated by a /, and consist of only DCHARs.

1 is returned if psz_path is valid.

=head3 pathname_isofy

Take psz_path and a version number and turn that into a ISO-9660
pathname.  (That is just the pathname followed by ";" and the version
number. For example, mydir/file.ext -> MYDIR/FILE.EXT;1 for version
1. The resulting ISO-9660 pathname is returned.

=head3 pathname_valid_p

Check that psz_path is a valid ISO-9660 pathname.

A valid pathname contains a valid directory name, if one appears and
the filename portion should be no more than 8 characters for the
file prefix and 3 characters in the extension (or portion after a
dot). There should be exactly one dot somewhere in the filename
portion and the filename should be composed of only DCHARs.

1 is returned if psz_path is valid.

=head3 fs_find_lsn

Given a directory pointer, find the filesystem entry that contains
lsn and return information about it.

Returns stat_t of entry if we found lsn, or undef otherwise.

=head3 ifs_find_lsn

Given a directory pointer, find the filesystem entry that contains
lsn and return information about it.

Returns stat_t of entry if we found lsn, or undef otherwise.

=head3 fs_stat

Return file status for psz_path. undef is returned on error.

=head3 fs_stat_translate

Return file status for path name psz_path. undef is returned on error.
pathname version numbers in the ISO 9660 name are dropped, i.e. ;1
is removed and if level 1 ISO-9660 names are lowercased.

=head3 ifs_stat

Return file status for pathname. undef is returned on error.

=head3 ifs_stat_translate

Return file status for path name psz_path. undef is returned on
error.  pathname version numbers in the ISO 9660 name are dropped,
i.e. ;1 is removed and if level 1 ISO-9660 names are lowercased.


=head3 fs_readdir

Read psz_path (a directory) and return a list of iso9660_stat_t
pointers for the files inside that directory. The caller must free the
returned result.

=head3 ifs_readdir

Read psz_path (a directory) and return a list of iso9660_stat_t
pointers for the files inside that directory. The caller must free
the returned result.

=head3 get_dir_len

Return the directory name stored in the iso9660_dir_t

A string is allocated: the caller must deallocate.

=head3 dir_to_name

=head3 get_posix_filemode

Returns a POSIX mode for a given p_iso_dirent.

=head2 Primary Volume Descriptor Routines

=head3 get_application_id

Return the PVD's application ID.

undef is returned if there is some problem in getting this.

=head3 ifs_get_application_id

Get the application ID.  psz_app_id is set to undef if there
is some problem in getting this and 0 is returned.

=head3 get_preparer_id

Return a string containing the preparer id with trailing
blanks removed.

=head3 ifs_get_preparer_id

Get the preparer ID.  psz_preparer_id is set to undef if there
is some problem in getting this and 0 is returned.

=head3 get_publisher_id

Return a string containing the PVD's publisher id with trailing
blanks removed.

=head3 ifs_get_publisher_id

Get the publisher ID.  psz_publisher_id is set to undef if there
is some problem in getting this and 0 is returned.

=head3 get_pvd_type

=head3 get_pvd_id

=head3 get_pvd_space_size

=head3 get_pvd_block_size

=head3 get_pvd_version

Return the primary volume id version number (of pvd).
If there is an error 0 is returned.

=head3 get_system_id

Return a string containing the PVD's system id with trailing
blanks removed.

=head3 ifs_get_system_id

Get the system ID.  psz_system_id is set to undef if there
is some problem in getting this and 0 is returned.

=head3 get_root_lsn

Return the LSN of the root directory for pvd.
If there is an error CDIO_INVALID_LSN is returned.

=head3 get_volume_id

Return the PVD's volume ID.

=head3 ifs_get_volume_id

Get the system ID.  psz_system_id is set to undef if there
s some problem in getting this and 0 is returned.

=head3 get_volumeset_id

Return the PVD's volumeset ID.
undef is returned if there is some problem in getting this.

=head3 ifs_get_volumeset_id

Get the systemset ID.  psz_systemset_id is set to undef if there
is some problem in getting this and 0 is returned.

=head2 Path Table Routines

=head3 iso9660_pathtable_init

Zero out pathable. Do this first.

=head3 pathtable_get_size

=head3 pathtable_l_add_entry

=head3 pathtable_m_add_entry

=head3 set_evd

=head2 Miscellaneous

=head3 get_joliet_level

Return the Joliet level recognized for p_iso.

=head3 ifs_is_xa

Return 1 if ISO 9660 image has extended attrributes (XA).

=head1 METHODS

=head2 this

This seems to be an artifact of SWIG.

=head1 SEE ALSO

L<http://www.gnu.org/software/libcdio> has documentation on
libcdio including the a manual and the API via doxygen.

=head1 AUTHORS

Rocky Bernstein C<< <rocky at cpan.org> >>.

=head1 COPYRIGHT

Copyright (C) 2006, 2008, 2011, 2017 Rocky Bernstein <rocky@cpan.org>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
%}
