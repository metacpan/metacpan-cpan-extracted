/*******************************************************************************
*
*  $Revision: 5 $
*  $Author: mhx $
*  $Date: 2009/10/02 22:34:53 +0200 $
*
********************************************************************************
*
* Copyright (c) 2008 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#if defined INCLUDE_MP4_H
# include <mp4.h>
#elif defined INCLUDE_MP4V2_MP4V2_H
# include <mp4v2/mp4v2.h>
#else
# error "invalid configuration"
#endif

#if defined MP4V2_PROJECT_version_hex && MP4V2_PROJECT_version_hex >= 0x00010900
# define LIBMP4V2_VERSION MP4V2_PROJECT_version_hex
# define _v19ARG(arg)  , arg
#else
# define LIBMP4V2_VERSION 0x00010000
# define _v19ARG(arg)
#endif

#define MP4FILE_CHARCONST(name) \
          (void) newCONSTSUB(ourstash, #name, newSVpvs(name))

struct mp4file
{
  MP4FileHandle fh;
};

typedef struct mp4file MP4FILE;


MODULE=MP4::File     PACKAGE=MP4::File

PROTOTYPES: DISABLE

MP4FILE *
MP4FILE::new()
  CODE:
    Newxz(RETVAL, 1, MP4FILE);
    RETVAL->fh = MP4_INVALID_FILE_HANDLE;

  OUTPUT:
    RETVAL

void
MP4FILE::DESTROY()
  PPCODE:
    if (MP4_IS_VALID_FILE_HANDLE(THIS->fh))
    {
      MP4Close(THIS->fh);
    }

    Safefree(THIS);

bool
MP4FILE::Close()
  PPCODE:
    if (MP4_IS_VALID_FILE_HANDLE(THIS->fh))
    {
      MP4Close(THIS->fh);
      THIS->fh = MP4_INVALID_FILE_HANDLE;
    }
    XSRETURN_YES;

bool
MP4FILE::Read(fileName, verbosity = 0)
    const char *fileName;
    u_int32_t verbosity;

  CODE:
    if (MP4_IS_VALID_FILE_HANDLE(THIS->fh))
    {
      MP4Close(THIS->fh);
    }

    THIS->fh = MP4Read(fileName, verbosity);

    RETVAL = (bool) MP4_IS_VALID_FILE_HANDLE(THIS->fh);

  OUTPUT:
    RETVAL

bool
MP4FILE::Modify(fileName, verbosity = 0, flags = 0)
    const char *fileName;
    u_int32_t verbosity;
    u_int32_t flags;

  CODE:
    if (MP4_IS_VALID_FILE_HANDLE(THIS->fh))
    {
      MP4Close(THIS->fh);
    }

    THIS->fh = MP4Modify(fileName, verbosity, flags);

    RETVAL = (bool) MP4_IS_VALID_FILE_HANDLE(THIS->fh);

  OUTPUT:
    RETVAL

const char *
MP4FILE::Info(trackId = MP4_INVALID_TRACK_ID)
    MP4TrackId trackId;

  CODE:
    RETVAL = MP4Info(THIS->fh, trackId);

    if (RETVAL == NULL)
    {
      XSRETURN_UNDEF;
    }

  OUTPUT:
    RETVAL

const char *
FileInfo(classname, fileName, trackId = MP4_INVALID_TRACK_ID)
    const char *fileName;
    MP4TrackId trackId;

  CODE:
    RETVAL = MP4FileInfo(fileName, trackId);

    if (RETVAL == NULL)
    {
      XSRETURN_UNDEF;
    }

  OUTPUT:
    RETVAL

bool
Optimize(classname, fileName, newFileName = NULL, verbosity = 0)
    const char *fileName;
    const char *newFileName;
    u_int32_t verbosity;

  CODE:
    RETVAL = MP4Optimize(fileName, newFileName, verbosity);

  OUTPUT:
    RETVAL

u_int32_t
MP4FILE::GetVerbosity()
  CODE:
    RETVAL = MP4GetVerbosity(THIS->fh);

  OUTPUT:
    RETVAL

void
MP4FILE::SetVerbosity(verbosity)
    u_int32_t verbosity;

  PPCODE:
    MP4SetVerbosity(THIS->fh, verbosity);

MP4TrackId
MP4FILE::FindTrackId(index, type = NULL, subType = 0)
    u_int16_t index;
    const char *type;
    u_int8_t subType;

  CODE:
    RETVAL = MP4FindTrackId(THIS->fh, index, type, subType);

  OUTPUT:
    RETVAL

const char *
MP4FILE::GetTrackType(trackId)
    MP4TrackId trackId;

  CODE:
    RETVAL = MP4GetTrackType(THIS->fh, trackId);

  OUTPUT:
    RETVAL

double
MP4FILE::GetTrackDuration(trackId)
    MP4TrackId trackId;

  CODE:
    RETVAL = 1e-9*MP4ConvertFromTrackDuration(THIS->fh, trackId,
                    MP4GetTrackDuration(THIS->fh, trackId), MP4_NSECS_TIME_SCALE);

  OUTPUT:
    RETVAL

UV
MP4FILE::GetTrackBitRate(trackId)
    MP4TrackId trackId;

  CODE:
    RETVAL = MP4GetTrackBitRate(THIS->fh, trackId);

  OUTPUT:
    RETVAL

UV
MP4FILE::GetTrackTimeScale(trackId)
    MP4TrackId trackId;

  CODE:
    RETVAL = MP4GetTrackTimeScale(THIS->fh, trackId);

  OUTPUT:
    RETVAL

bool
MP4FILE::MetadataDelete()
  CODE:
    RETVAL = MP4MetadataDelete(THIS->fh);

  OUTPUT:
    RETVAL

bool
MP4FILE::DeleteMetadataName()
  ALIAS:
    DeleteMetadataArtist = 1
    DeleteMetadataWriter = 2
    DeleteMetadataComment = 3
    DeleteMetadataTool = 4
    DeleteMetadataYear = 5
    DeleteMetadataAlbum = 6
    DeleteMetadataGenre = 7
    DeleteMetadataGrouping = 8
    DeleteMetadataCoverArt = 9
    DeleteMetadataTrack = 10
    DeleteMetadataDisk = 11
    DeleteMetadataTempo = 12
    DeleteMetadataCompilation = 13

  PREINIT:
    static bool (*fp[])(MP4FileHandle) = {
      MP4DeleteMetadataName,
      MP4DeleteMetadataArtist,
      MP4DeleteMetadataWriter,
      MP4DeleteMetadataComment,
      MP4DeleteMetadataTool,
      MP4DeleteMetadataYear,
      MP4DeleteMetadataAlbum,
      MP4DeleteMetadataGenre,
      MP4DeleteMetadataGrouping,
      MP4DeleteMetadataCoverArt,
      MP4DeleteMetadataTrack,
      MP4DeleteMetadataDisk,
      MP4DeleteMetadataTempo,
      MP4DeleteMetadataCompilation
    };

  CODE:
    RETVAL = fp[ix](THIS->fh);

  OUTPUT:
    RETVAL

void
MP4FILE::GetMetadataName()
  ALIAS:
    GetMetadataArtist = 1
    GetMetadataWriter = 2
    GetMetadataComment = 3
    GetMetadataTool = 4
    GetMetadataYear = 5
    GetMetadataAlbum = 6
    GetMetadataGenre = 7
    GetMetadataGrouping = 8

  PREINIT:
    static bool (*fp[])(MP4FileHandle, char **) = {
      MP4GetMetadataName,
      MP4GetMetadataArtist,
      MP4GetMetadataWriter,
      MP4GetMetadataComment,
      MP4GetMetadataTool,
      MP4GetMetadataYear,
      MP4GetMetadataAlbum,
      MP4GetMetadataGenre,
      MP4GetMetadataGrouping
    };
    char *value;

  PPCODE:
    if (fp[ix](THIS->fh, &value) && value != NULL)
    {
      ST(0) = newSVpv(value, 0);
      SvUTF8_on(ST(0));
      free(value);
      XSRETURN(1);
    }

    XSRETURN_UNDEF;

bool
MP4FILE::SetMetadataName(value)
    SV *value

  ALIAS:
    SetMetadataArtist = 1
    SetMetadataWriter = 2
    SetMetadataComment = 3
    SetMetadataTool = 4
    SetMetadataYear = 5
    SetMetadataAlbum = 6
    SetMetadataGenre = 7
    SetMetadataGrouping = 8

  PREINIT:
    static bool (*fp[])(MP4FileHandle, const char *) = {
      MP4SetMetadataName,
      MP4SetMetadataArtist,
      MP4SetMetadataWriter,
      MP4SetMetadataComment,
      MP4SetMetadataTool,
      MP4SetMetadataYear,
      MP4SetMetadataAlbum,
      MP4SetMetadataGenre,
      MP4SetMetadataGrouping
    };

  CODE:
    RETVAL = fp[ix](THIS->fh, SvPVutf8_nolen(value));

  OUTPUT:
    RETVAL

UV
MP4FILE::GetMetadataCoverArtCount()
  CODE:
    RETVAL = MP4GetMetadataCoverArtCount(THIS->fh);

  OUTPUT:
    RETVAL

void
MP4FILE::GetMetadataCoverArt(index = 0)
    u_int32_t index

  PREINIT:
    u_int8_t *data;
    u_int32_t length;

  PPCODE:
    if (MP4GetMetadataCoverArt(THIS->fh, &data, &length _v19ARG(index)))
    {
      if (data != NULL)
      {
        ST(0) = newSVpvn((const char *) data, length);
        free(data);
      }
      else
      {
        ST(0) = newSVpvn("", 0);
      }

      XSRETURN(1);
    }

    XSRETURN_UNDEF;

bool
MP4FILE::SetMetadataCoverArt(cover)
    SV *cover

  PREINIT:
    STRLEN length;
    u_int8_t *data = (u_int8_t *) SvPV(cover, length);

  CODE:
    RETVAL = MP4SetMetadataCoverArt(THIS->fh, data, length);

  OUTPUT:
    RETVAL

void
MP4FILE::GetMetadataTrack()
  ALIAS:
    GetMetadataDisk = 1

  PREINIT:
    static bool (*fp[])(MP4FileHandle, u_int16_t *, u_int16_t *) = {
      MP4GetMetadataTrack,
      MP4GetMetadataDisk
    };
    u_int16_t curr, total;

  PPCODE:
    if (fp[ix](THIS->fh, &curr, &total))
    {
      EXTEND(SP, 2);
      ST(0) = newSVuv(curr);
      ST(1) = newSVuv(total);
      XSRETURN(2);
    }

    XSRETURN_EMPTY;

bool
MP4FILE::SetMetadataTrack(curr, total)
    u_int16_t curr
    u_int16_t total

  ALIAS:
    SetMetadataDisk = 1

  PREINIT:
    static bool (*fp[])(MP4FileHandle, u_int16_t, u_int16_t) = {
      MP4SetMetadataTrack,
      MP4SetMetadataDisk
    };

  CODE:
    RETVAL = fp[ix](THIS->fh, curr, total);

  OUTPUT:
    RETVAL

void
MP4FILE::GetMetadataTempo()
  PREINIT:
    u_int16_t tempo;

  PPCODE:
    if (MP4GetMetadataTempo(THIS->fh, &tempo))
    {
      XSRETURN_UV(tempo);
    }

    XSRETURN_UNDEF;

bool
MP4FILE::SetMetadataTempo(tempo)
    u_int16_t tempo

  CODE:
    RETVAL = MP4SetMetadataTempo(THIS->fh, tempo);

  OUTPUT:
    RETVAL

void
MP4FILE::GetMetadataCompilation()
  PREINIT:
    u_int8_t cpl;

  PPCODE:
    if (MP4GetMetadataCompilation(THIS->fh, &cpl))
    {
      if (cpl)
        XSRETURN_YES;
      else
        XSRETURN_NO;
    }

    XSRETURN_UNDEF;

bool
MP4FILE::SetMetadataCompilation(cpl)
    bool cpl

  CODE:
    RETVAL = MP4SetMetadataCompilation(THIS->fh, cpl);

  OUTPUT:
    RETVAL


BOOT:
  {
    HV *ourstash = gv_stashpv("MP4::File", TRUE);

    MP4FILE_CHARCONST(MP4_OD_TRACK_TYPE);
    MP4FILE_CHARCONST(MP4_SCENE_TRACK_TYPE);
    MP4FILE_CHARCONST(MP4_AUDIO_TRACK_TYPE);
    MP4FILE_CHARCONST(MP4_VIDEO_TRACK_TYPE);
    MP4FILE_CHARCONST(MP4_HINT_TRACK_TYPE);
    MP4FILE_CHARCONST(MP4_CNTL_TRACK_TYPE);
    MP4FILE_CHARCONST(MP4_CLOCK_TRACK_TYPE);
    MP4FILE_CHARCONST(MP4_MPEG7_TRACK_TYPE);
    MP4FILE_CHARCONST(MP4_OCI_TRACK_TYPE);
    MP4FILE_CHARCONST(MP4_IPMP_TRACK_TYPE);
    MP4FILE_CHARCONST(MP4_MPEGJ_TRACK_TYPE);
  }
