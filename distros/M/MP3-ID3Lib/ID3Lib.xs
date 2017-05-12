#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "id3.h"
 
MODULE = MP3::ID3Lib	PACKAGE = MP3::ID3LibXS  PREFIX= id3_

ID3Tag*
id3_create(package, filename)
     char * package;
     char * filename;

     CODE:
     ID3Tag *tag;
     SV* rv;

     tag = ID3Tag_New();
     (void) ID3Tag_Link(tag, filename);

     RETVAL = tag;

     OUTPUT:
     RETVAL

MODULE = MP3::ID3Lib	PACKAGE = ID3TagPtr  PREFIX= id3_

AV*
id3_frames(tag)
     ID3Tag* tag;

     CODE:
     ID3Frame* frame;
     ID3TagIterator* iterator;
     int i = 0;
     ID3_FrameID id;
     ID3Field* field;
     iterator = ID3Tag_CreateIterator(tag);

     AV* ret = newAV();

     while ((frame = ID3TagIterator_GetNext(iterator)) != NULL) {
       id = ID3Frame_GetID(frame);
       if ((field = ID3Frame_GetField(frame, ID3FN_TEXT)) != NULL) {
         char title[1024];
         (void) ID3Field_GetASCII(field, title, 1024);

         HV* h = newHV();

         SV* si = newSV(0);
         sv_setiv(si, i);
         SvPV_nolen(si);
         hv_store(h, "index", 5, si, 0);

         si = newSV(0);
         sv_setiv(si, id);
         hv_store(h, "type", 4, si, 0);

         si = newSV(0);
         sv_setpv(si, title);
         hv_store(h, "value", 5, si, 0);

         SV* hr = newRV_inc((SV*)h);
         av_push(ret, hr);

         i++;
       }


     }
     ID3TagIterator_Delete(iterator);

     RETVAL = ret;

     OUTPUT:
     RETVAL


void
id3_commit(tag, ins)
     ID3Tag* tag;
     SV* ins;

     CODE:
     I32 in_len, i;
     SV* hr;
     AV* in;
     SV* offset;
     SV* value;
     SV* type;
     SV* is_changed;
     SV** svp;
     HV* h;
     ID3Frame* frame;
     ID3TagIterator* iterator;

     int id;
     ID3Field* field;

     if (SvTYPE(ins) != SVt_RV) {
       Perl_die(aTHX_ "Expected type SV for ins");
     }
     in = (AV*)SvRV(ins);
     if (SvTYPE(in) != SVt_PVAV) {
       Perl_die(aTHX_ "Expected type AV for in");
     }
     in_len = av_len(in);

     iterator = ID3Tag_CreateIterator(tag);

     for (i = 0; i < in_len; i++) {

       frame = ID3TagIterator_GetNext(iterator);
       id = ID3Frame_GetID(frame);

       hr = *av_fetch(in, i, 0);
       if (!SvROK(hr)) {
         Perl_die(aTHX_ "Expected RV for hr");
       }
       h = (HV*)SvRV(hr);
       if (SvTYPE(h) != SVt_PVHV) {
         Perl_die(aTHX_ "Expected type HV for h");
       }

       offset = *hv_fetch(h, "index", 5, 0);
       if (!SvIOK(offset)) {
         Perl_die(aTHX_ "Expected IV for offset");
       }
       if (i != SvIV(offset)) {
         Perl_die(aTHX_ "offset != i\n");
       }

       is_changed = *hv_fetch(h, "is_changed", 10, 0);
       if (!SvIOK(is_changed)) {
         Perl_die(aTHX_ "Expected IV for is_changed");
       }

       if (SvIV(is_changed)) {
         value = *hv_fetch(h, "value", 5, 0);
         if (!SvPOK(value)) {
           Perl_die(aTHX_ "Expected PV for value"); 
         }

	 field = ID3Frame_GetField(frame, ID3FN_TEXT);
         ID3Field_SetASCII(field, SvPV_nolen(value));
       }
     }
     ID3Tag_Update(tag);


void
id3_add_frame(tag, id, value)
     ID3Tag* tag;
     int id;
     char* value;

     CODE:
     ID3Frame* frame;
     ID3_FrameID fid;
     ID3Field* field;

     fid = (ID3_FrameID) id;
     frame = ID3Frame_NewID(fid);
     field = ID3Frame_GetField(frame, ID3FN_TEXT);
     ID3Field_SetASCII(field, value);
     ID3Tag_AttachFrame(tag, frame);

void
id3_DESTROY(tag)
     ID3Tag* tag;

     CODE:
     ID3Tag_Delete(tag);


