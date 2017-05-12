/* -*- c -*-
  Copyright (C) 2006, 2008, 2011 Rocky Bernstein <rocky@cpan.org>

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
*/
/* See <cdio/device.h> for more extensive documentation. */

%constant long int DISC_MODE_CD_DA    = CDIO_DISC_MODE_CD_DA;
%constant long int DISC_MODE_CD_DATA  = CDIO_DISC_MODE_CD_DATA;
%constant long int DISC_MODE_CD_XA  = CDIO_DISC_MODE_CD_XA;
%constant long int DISC_MODE_CD_MIXED  = CDIO_DISC_MODE_CD_MIXED;
%constant long int DISC_MODE_DVD_ROM  = CDIO_DISC_MODE_DVD_ROM;
%constant long int DISC_MODE_DVD_RAM  = CDIO_DISC_MODE_DVD_RAM;
%constant long int DISC_MODE_DVD_R  = CDIO_DISC_MODE_DVD_R;
%constant long int DISC_MODE_DVD_RW  = CDIO_DISC_MODE_DVD_RW;
%constant long int DISC_MODE_DVD_PR  = CDIO_DISC_MODE_DVD_PR;
%constant long int DISC_MODE_DVD_PRW  = CDIO_DISC_MODE_DVD_PRW;
%constant long int DISC_MODE_DVD_OTHER  = CDIO_DISC_MODE_DVD_OTHER;
%constant long int DISC_MODE_NO_INFO  = CDIO_DISC_MODE_NO_INFO;
%constant long int DISC_MODE_ERROR  = CDIO_DISC_MODE_ERROR;
%constant long int DISC_MODE_CD_I = CDIO_DISC_MODE_CD_I;

%rename cdio_get_disc_last_lsn get_disc_last_lsn;
%feature("autodoc",
"get_disc_last_lsn(cdio)->lsn
Get the LSN of the end of the CD.

perlcdio.INVALID_LSN is returned on error.");
lsn_t cdio_get_disc_last_lsn(const CdIo_t *p_cdio);
  

%feature("autodoc",
"get_disc_mode(p_cdio) -> str

Get disc mode - the kind of CD (CD-DA, CD-ROM mode 1, CD-MIXED, etc.
that we've got. The notion of 'CD' is extended a little to include
DVD's.");
const char *get_disc_mode (CdIo_t *p_cdio);

%rename cdio_get_joliet_level get_joliet_level;
%feature("autodoc",
"get_joliet_level(cdio)->int

Return the Joliet level recognized for cdio.
This only makes sense for something that has an ISO-9660
filesystem.");
int cdio_get_joliet_level(const CdIo_t *p_cdio);

/*!
  Get the media catalog number (MCN) from the CD.
  
  @return the media catalog number or NULL if there is none or we
  don't have the ability to get it.
  
  Note: string is malloc'd so caller has to free() the returned
  string when done with it.
  
*/
%rename cdio_get_mcn get_mcn;
%newobject cdio_get_mcn; // free malloc'd return value
char * cdio_get_mcn (const CdIo_t *p_cdio);

%rename cdio_get_num_tracks get_num_tracks;
%feature("autodoc",
"get_num_tracks(p_cdio)->int

Return the number of tracks on the CD. 
On error $perlcdio::INVALID_TRACK is returned.");
track_t cdio_get_num_tracks (const CdIo_t *p_cdio);

/*========================INLINE======================================*/

%inline %{
const char *
get_disc_mode (CdIo_t *p_cdio) 
{
  discmode_t discmode = cdio_get_discmode(p_cdio);
  if (CDIO_DISC_MODE_ERROR == discmode)
    return (const char *)newSV(0);
  return discmode2str[discmode];
}
%}


SV * get_cdtext (CdIo_t *p_cdio, int track);
%inline %{
SV * get_cdtext (CdIo_t *p_cdio, int track)
{
    HV * cdtext_hash;
    char **cdtext; const char *str; int num; unsigned int l=0;
    cdtext = ( char **)cdio_get_cdtext (p_cdio, (track_t) track);
    if(!cdtext)
        return newSV(0); //we return undef if there is no cdtext on the disk
    cdtext_hash = newHV();
    for (num=0; num<MAX_CDTEXT_FIELDS; num++) {
        if(cdtext[num]) {
            l++;
            str = cdtext_field2str(num);
            hv_store(cdtext_hash, str, strlen(str),
                newSVpv(cdtext[num], 0), 0);
        }
    }
    if(!l) {
        SvREFCNT_dec((SV*)cdtext_hash);
        return newSV(0);
    } // we could easily return the number of strings, too.
    return newRV_noinc(sv_2mortal((SV*)cdtext_hash));
}
%}

uint32_t get_cddb_discid(CdIo_t *p_cdio);
%inline %{
static int
cddb_dec_digit_sum(int n)
{
  int ret=0;
  
  for (;;) {
    ret += n%10;
    n    = n/10;
    if (!n) return ret;
  }
}

uint32_t get_cddb_discid(CdIo_t *p_cdio)
{
    int i,t,n=0;
    msf_t start_msf;
    msf_t msf;
    track_t i_tracks = cdio_get_num_tracks (p_cdio);
    if(i_tracks == CDIO_INVALID_TRACK)
        return 0;

    for (i = 1; i <= i_tracks; i++) {
        cdio_get_track_msf(p_cdio, i, &msf);
        n += cddb_dec_digit_sum(cdio_audio_get_msf_seconds(&msf));
    }

    cdio_get_track_msf(p_cdio, 1, &start_msf);
    cdio_get_track_msf(p_cdio, CDIO_CDROM_LEADOUT_TRACK, &msf);
  
    t = cdio_audio_get_msf_seconds(&msf)-cdio_audio_get_msf_seconds(&start_msf);
  
    return ((n % 0xff) << 24 | t << 8 | i_tracks);
}
%}

SV * guess_cd_type(const CdIo_t *cdio, int start_session, track_t track_num);
%inline %{
SV * guess_cd_type(const CdIo_t *cdio, int start_session, track_t track_num) {
    cdio_iso_analysis_t t;
    int r;
    HV * iso_analysis;
    r = cdio_guess_cd_type (cdio,  start_session, track_num, &t);
    iso_analysis = newHV();
    hv_store(iso_analysis, "cdio_fs_t",9, newSViv(r&CDIO_FS_MASK),0);
    hv_store(iso_analysis, "cdio_fs_cap_t",13, newSViv(r&~CDIO_FS_MASK),0);
    hv_store(iso_analysis, "joliet_level",12, newSVuv(t.joliet_level),0);
    hv_store(iso_analysis, "iso_label",9,newSVpv(t.iso_label,0),0);
    hv_store(iso_analysis, "isofs_size",10, newSVuv(t.isofs_size),0);
    hv_store(iso_analysis, "UDFVerMinor",11,
            newSVuv((unsigned int)t.UDFVerMinor),0);
    hv_store(iso_analysis, "UDFVerMajor",11, 
        newSVuv((unsigned int)t.UDFVerMajor),0);

    return  newRV_noinc(sv_2mortal((SV*)iso_analysis));
}
%}
