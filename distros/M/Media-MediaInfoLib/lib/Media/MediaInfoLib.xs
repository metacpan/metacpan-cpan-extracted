#ifdef __cplusplus
extern "C" {
#endif
#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#define NEED_newCONSTSUB
#include "ppport.h"
#include <MediaInfo/MediaInfo.h>
#include <ZenLib/Ztring.h>

namespace Media {
    typedef MediaInfoLib::MediaInfo MediaInfoLib;
}

#define DEFINE_CONST(stash, export, name, sv) \
do { \
    newCONSTSUB(stash, name, sv); \
    av_push(export, newSVpvs(name)); \
} while (0)

MODULE = Media::MediaInfoLib PACKAGE = Media::MediaInfoLib

BOOT:
{
    HV* stash = gv_stashpv("Media::MediaInfoLib", 1);
    AV* export_ok = get_av("Media::MediaInfoLib::EXPORT_OK", GV_ADD);
    /* MediaInfoLib::stream_t */
    DEFINE_CONST(stash, export_ok, "STREAM_GENERAL", newSViv(MediaInfoLib::Stream_General));
    DEFINE_CONST(stash, export_ok, "STREAM_VIDEO",   newSViv(MediaInfoLib::Stream_Video));
    DEFINE_CONST(stash, export_ok, "STREAM_AUDIO",   newSViv(MediaInfoLib::Stream_Audio));
    DEFINE_CONST(stash, export_ok, "STREAM_TEXT",    newSViv(MediaInfoLib::Stream_Text));
    DEFINE_CONST(stash, export_ok, "STREAM_OTHER",   newSViv(MediaInfoLib::Stream_Other));
    DEFINE_CONST(stash, export_ok, "STREAM_IMAGE",   newSViv(MediaInfoLib::Stream_Image));
    DEFINE_CONST(stash, export_ok, "STREAM_MENU",    newSViv(MediaInfoLib::Stream_Menu));
    /* MediaInfoLib::info_t */
    DEFINE_CONST(stash, export_ok, "INFO_NAME",         newSViv(MediaInfoLib::Info_Name));
    DEFINE_CONST(stash, export_ok, "INFO_TEXT",         newSViv(MediaInfoLib::Info_Text));
    DEFINE_CONST(stash, export_ok, "INFO_MEASURE",      newSViv(MediaInfoLib::Info_Measure));
    DEFINE_CONST(stash, export_ok, "INFO_OPTIONS",      newSViv(MediaInfoLib::Info_Options));
    DEFINE_CONST(stash, export_ok, "INFO_NAME_TEXT",    newSViv(MediaInfoLib::Info_Name_Text));
    DEFINE_CONST(stash, export_ok, "INFO_MEASURE_TEXT", newSViv(MediaInfoLib::Info_Measure_Text));
    DEFINE_CONST(stash, export_ok, "INFO_INFO",         newSViv(MediaInfoLib::Info_Info));
    DEFINE_CONST(stash, export_ok, "INFO_HOWTO",        newSViv(MediaInfoLib::Info_HowTo));
    DEFINE_CONST(stash, export_ok, "INFO_DOMAIN",       newSViv(MediaInfoLib::Info_Domain));
};

PROTOTYPES: DISABLE

Media::MediaInfoLib*
Media::MediaInfoLib::new(stuff)
    SV* stuff;
ALIAS:
    Media::MediaInfoLib::open = 1
PREINIT:
    char* s;
    STRLEN len;
    size_t ret;
CODE:
    MediaInfoLib::MediaInfo* mi = new MediaInfoLib::MediaInfo;
    if (SvROK(stuff)) {
        s = SvPV(SvRV(stuff), len);
        ret = mi->Open((ZenLib::int8u*) s, len);
        if (ret != 1) {
            delete mi;
            croak("Can't open the given bytes");
        }
    } else {
        s = SvPV(stuff, len);
        ret = mi->Open(ZenLib::Ztring(s, len));
        if (ret != 1) {
            delete mi;
            croak("Can't open file: %s", s);
        }
    }
    RETVAL = mi;
OUTPUT:
    RETVAL

ZenLib::Ztring
Media::MediaInfoLib::inform()
CODE:
    RETVAL = THIS->Inform();
OUTPUT:
    RETVAL

ZenLib::Ztring
Media::MediaInfoLib::get(stream_kind, stream_number, parameter, info_kind = MediaInfoLib::Info_Text, search_kind = MediaInfoLib::Info_Name)
    MediaInfoLib::stream_t stream_kind;
    size_t stream_number;
    ZenLib::Ztring parameter;
    MediaInfoLib::info_t info_kind;
    MediaInfoLib::info_t search_kind;
CODE:
    RETVAL = THIS->Get(stream_kind, stream_number, parameter, info_kind, search_kind);
OUTPUT:
    RETVAL

ZenLib::Ztring
Media::MediaInfoLib::option(option, value = ZenLib::Ztring())
    ZenLib::Ztring option;
    ZenLib::Ztring value;
CODE:
    RETVAL = THIS->Option(option, value);
OUTPUT:
    RETVAL

ZenLib::Ztring
Media::MediaInfoLib::option_static(option, value = ZenLib::Ztring())
    ZenLib::Ztring option;
    ZenLib::Ztring value;
CODE:
    RETVAL = THIS->Option_Static(option, value);
OUTPUT:
    RETVAL

size_t
Media::MediaInfoLib::count_get(stream_kind, stream_number = -1)
    MediaInfoLib::stream_t stream_kind;
    size_t stream_number;
CODE:
    RETVAL = THIS->Count_Get(stream_kind, stream_number);
OUTPUT:
    RETVAL

void
Media::MediaInfoLib::DESTROY()
CODE:
    THIS->Close();
    delete THIS;
