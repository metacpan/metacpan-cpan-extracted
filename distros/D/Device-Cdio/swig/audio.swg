/* -*- c -*-
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
*/

/** NOTE: This is most of the easily-converted subset of libcdio's <cdio/audio.h>.
    For more, feel free to dig in and add.
**/

/* See <cdio/audio.h> for more extensive documentation. */

%rename cdio_audio_pause audio_pause;
%feature("autodoc",
"audio_pause(cdio)->status

Pause playing CD through analog output.");
driver_return_code_t cdio_audio_pause (CdIo_t *p_cdio);


%feature("autodoc",
"audio_play_track_index(cdio, start_track, start_index, end_track, end_index)->status

Playing CD through analog output at the desired start track and index,
to the end track and index. Tracks should be in the valid CD track range 0..99.

Just as a track number is burned into the CD, so is a an index for a track.
It gives a position within the track. Use 0 for the beginning.
");
driver_return_code_t audio_play_track_index (CdIo_t *p_cdio,
					     int start_track, int start_index,
					     int end_track, int end_index);
%inline %{

#ifndef CLAMP
# define CLAMP(val, min_value, max_value)	\
  ( (val < min_value ? min_value :		\
    ((val > max_value) ? max_value : val)) )
#endif

driver_return_code_t audio_play_track_index(CdIo_t *p_cdio,
					    int start_track, int start_index,
					    int end_track,   int end_index)
{
    cdio_track_index_t track_index;

    track_index.i_start_track = (uint8_t) (CLAMP(start_track, 0, 99));
    track_index.i_start_index = (uint8_t) (CLAMP(start_index, 0, 255));
    track_index.i_start_track = (uint8_t) (CLAMP(end_track,   0, 99));
    track_index.i_end_track   = (uint8_t) (CLAMP(end_index,   0, 99));
    return cdio_audio_play_track_index(p_cdio, &track_index);
}
%}


%feature("autodoc",
"auto_play_lsn(cdio, start_lsn, end_lsn)->status

Playing CD through analog output at the given lsn to the ending lsn");
driver_return_code_t audio_play_lsn (CdIo_t *p_cdio, lsn_t start_lsn,
				     lsn_t end_lsn);
%inline %{
driver_return_code_t audio_play_lsn (CdIo_t *p_cdio, lsn_t start_lsn,
				     lsn_t end_lsn)
{
  msf_t start_msf;
  msf_t end_msf;
  cdio_lsn_to_msf (start_lsn, &start_msf);
  cdio_lsn_to_msf (end_lsn, &end_msf);
  return cdio_audio_play_msf(p_cdio, &start_msf, &end_msf);
}
%}

%rename cdio_audio_resume audio_resume;
%feature("autodoc",
"audio_resume(cdio)->status
Resume playing an audio CD.");
driver_return_code_t cdio_audio_resume (CdIo_t *p_cdio);


%rename cdio_audio_stop audio_stop;
%feature("autodoc",
"audio_stop(cdio)->status
Stop playing an audio CD.");
driver_return_code_t cdio_audio_stop (CdIo_t *p_cdio);

%feature("autodoc",
"return audio volume levels array");


%typemap(out) uint8_t,int {
    $result = sv_newmortal();
    sv_setiv($result,(IV) $1);
    argvi++;
}
%typemap(out) uint8_t*,int* {
    AV *myav;
    SV **svs;
    if ($1) {
        svs = (SV **) malloc(4*sizeof(SV *));
        svs[0] = sv_newmortal();
        sv_setiv((SV*) svs[0],$1[0]);
        svs[1] = sv_newmortal();
        sv_setiv((SV*) svs[1],$1[1]);
        svs[2] = sv_newmortal();
        sv_setiv((SV*) svs[2],$1[2]);
        svs[3] = sv_newmortal();
        sv_setiv((SV*) svs[3],$1[3]);
        myav = av_make(4,svs);
        free(svs);
        $result = newRV_noinc((SV*)myav);
        sv_2mortal($result);
        argvi++;
    }

}

%apply int *OUTPUT { int *rc };
uint8_t *audio_get_volume_levels (CdIo_t *p_cdio, int *rc);

%inline %{
uint8_t *audio_get_volume_levels (CdIo_t *p_cdio, int *rc)
{
    static  uint8_t _volume[4];

    driver_return_code_t drc;
    drc = cdio_audio_get_volume (p_cdio, (cdio_audio_volume_t*)&_volume);
    *rc = drc;
    return _volume;
}
%}

%feature("autodoc",
"audio_set_volume_levels(cdio, channel0, channel1, channel2, channel3)->status

Set volume levels for playing CD through analog output. For strereo
CDROM devices's (which is most of them) only channel0 and channel1 are
used. 0 is the smallest volume and 255 is the largest valume. Values
above 255 will be pegged at 255 and values below 0 will be pegged at
0.
");
int audio_set_volume_levels(CdIo_t *p_cdio,
			    int channel_vol1, int channel_vol2,
			    int channel_vol3, int channel_vol4);

%inline %{

#ifndef CLAMP
# define CLAMP(val, min_value, max_value)	\
  ( (val < min_value ? min_value :		\
    ((val > max_value) ? max_value : val)) )
#endif

int audio_set_volume_levels(CdIo_t *p_cdio,
			    int channel_vol1, int channel_vol2,
			    int channel_vol3, int channel_vol4)
{
    static cdio_audio_volume_t audio_volume;

    audio_volume.level[0] = CLAMP(channel_vol1, 0, 255);
    audio_volume.level[1] = CLAMP(channel_vol2, 0, 255);
    audio_volume.level[2] = CLAMP(channel_vol3, 0, 255);
    audio_volume.level[3] = CLAMP(channel_vol4, 0, 255);
    return cdio_audio_set_volume(p_cdio, &audio_volume);
}
%}


%apply int *OUTPUT { int *drc };
SV * audio_get_status ( CdIo_t *p_cdio, int *drc);
%inline %{
extern uint8_t cdio_from_bcd8(uint8_t p);
//static cdio_subchannel_t cdio_subchannel;
SV * audio_get_status ( CdIo_t *p_cdio, int *drc)
{
    static cdio_subchannel_t sub;
    driver_return_code_t rc;
    HV * audio_st;
    char *a_s_t;
    rc = cdio_audio_read_subchannel(p_cdio, &sub);
    *drc = rc;
    audio_st = newHV();
    /* unsigned int msf_seconds(msf_t *msf) or
     *
     */
    switch(sub.audio_status) {
        case 0x00:
            a_s_t = "INVALID";
            break;
        case 0x11:
            a_s_t = "playing";
            break;
        case 0x12:
            a_s_t = "paused";
            break;
        case 0x13:
            a_s_t = "completed";
            break;
        case 0x14:
            a_s_t = "ERROR";
            break;
        case 0x15:
            a_s_t = "NO_STATUS";
            break;
        default:
            a_s_t = "UNKNOWN";
    }
    hv_store(audio_st, "format", 6,
            newSVuv(sub.format), 0);
    hv_store(audio_st, "audio_status", 12,
            newSVuv(sub.audio_status), 0);
    hv_store(audio_st, "status_text", 11,
            newSVpv(a_s_t, 0), 0);
    hv_store(audio_st, "address", 7,
            newSVuv(sub.address), 0);
    hv_store(audio_st, "control", 7,
            newSVuv(sub.control), 0);
    hv_store(audio_st, "track", 5,
            newSVuv(sub.track), 0);
    hv_store(audio_st, "index", 5,
            newSVuv(sub.index), 0);
    hv_store(audio_st, "abs_m", 5,
            newSVuv(cdio_from_bcd8(sub.abs_addr.m)), 0);
    hv_store(audio_st, "abs_s", 5,
            newSVuv(cdio_from_bcd8(sub.abs_addr.s)), 0);
    hv_store(audio_st, "abs_f", 5,
            newSVuv(cdio_from_bcd8(sub.abs_addr.f)), 0);
    hv_store(audio_st, "disk_s", 6,
            newSVuv(cdio_audio_get_msf_seconds(&sub.abs_addr)),0);
    hv_store(audio_st, "rel_m", 5,
            newSVuv(cdio_from_bcd8(sub.rel_addr.m)), 0);
    hv_store(audio_st, "rel_s", 5,
            newSVuv(cdio_from_bcd8(sub.rel_addr.s)), 0);
    hv_store(audio_st, "rel_f", 5,
            newSVuv(cdio_from_bcd8(sub.rel_addr.f)), 0);
    hv_store(audio_st, "track_s", 7,
            newSVuv(cdio_audio_get_msf_seconds(&sub.rel_addr)),0);

    return newRV_noinc(sv_2mortal((SV*)audio_st));
}
%}
