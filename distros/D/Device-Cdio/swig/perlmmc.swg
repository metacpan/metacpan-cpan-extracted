/* -*- c -*-
  Copyright (C) 2006, 2008, 2011 Rocky Bernstein <rocky@cpan.org>
  See end for license.
*/
%define DOCSTRING 
"A Perl wrapper for The CD Input and Control library's ISO-9660 library's
MultiMedia Commands (MMC)."
%enddef
%module(docstring=DOCSTRING) perlmmc

/* See <cdio/mmc.h> for more extensive documentation. */

%{
/* Includes the header in the wrapper code */
#include <cdio/cdio.h>
#include <cdio/mmc.h>
%}

#include <cdio/cdio.h>
#include <cdio/mmc.h>

%include "types.swg"

typedef long int cdio_mmc_level_t;

%constant long int GPCMD_INQUIRY       = CDIO_MMC_GPCMD_INQUIRY;
%constant long int GPCMD_MODE_SELECT_6 = CDIO_MMC_GPCMD_MODE_SELECT_6;
%constant long int GPCMD_MODE_SENSE_6  = CDIO_MMC_GPCMD_MODE_SENSE_6;
%constant long int GPCMD_START_STOP    = CDIO_MMC_GPCMD_START_STOP;
%constant long int GPCMD_ALLOW_MEDIUM_REMOVAL = 
                                         CDIO_MMC_GPCMD_ALLOW_MEDIUM_REMOVAL;

/** Group 2 Commands (CDB's here are 10-bytes)  */

%constant long int CDIO_MMC_GPCMD_READ_10  = CDIO_MMC_GPCMD_READ_10;
%constant long int GPCMD_READ_SUBCHANNEL   = CDIO_MMC_GPCMD_READ_SUBCHANNEL;
%constant long int GPCMD_READ_HEADER       = CDIO_MMC_GPCMD_READ_HEADER;
%constant long int GPCMD_PLAY_AUDIO_10	   = CDIO_MMC_GPCMD_PLAY_AUDIO_10;
%constant long int GPCMD_GET_CONFIGURATION = CDIO_MMC_GPCMD_GET_CONFIGURATION;
%constant long int GPCMD_PLAY_AUDIO_MSF	   = CDIO_MMC_GPCMD_PLAY_AUDIO_MSF;
%constant long int GPCMD_PLAY_AUDIO_TI     = CDIO_MMC_GPCMD_PLAY_AUDIO_TI;
%constant long int GPCMD_PLAY_TRACK_REL_10 = CDIO_MMC_GPCMD_PLAY_TRACK_REL_10;
%constant long int GPCMD_GET_EVENT_STATUS  = CDIO_MMC_GPCMD_GET_EVENT_STATUS;
%constant long int GPCMD_PAUSE_RESUME      = CDIO_MMC_GPCMD_PAUSE_RESUME;
%constant long int GPCMD_READ_DISC_INFO	   = CDIO_MMC_GPCMD_READ_DISC_INFO;
%constant long int GPCMD_MODE_SELECT_10    = CDIO_MMC_GPCMD_MODE_SELECT_10;
%constant long int GPCMD_MODE_SENSE_10	   = CDIO_MMC_GPCMD_MODE_SENSE_10;
%constant long int GPCMD_PLAY_AUDIO_12	   = CDIO_MMC_GPCMD_PLAY_AUDIO_12;
%constant long int GPCMD_LOAD_UNLOAD	   = CDIO_MMC_GPCMD_LOAD_UNLOAD;
%constant long int GPCMD_READ_12	   = CDIO_MMC_GPCMD_READ_12;
%constant long int GPCMD_PLAY_TRACK_REL_12 = CDIO_MMC_GPCMD_PLAY_TRACK_REL_12;
%constant long int GPCMD_READ_DVD_STRUCTURE= CDIO_MMC_GPCMD_READ_DVD_STRUCTURE;
%constant long int GPCMD_READ_MSF	   = CDIO_MMC_GPCMD_READ_MSF;
%constant long int GPCMD_SET_SPEED         = CDIO_MMC_GPCMD_SET_SPEED;
%constant long int GPCMD_READ_CD	   = CDIO_MMC_GPCMD_READ_CD;

/** Vendor-unique Commands   */
%constant long int GPCMD_CD_PLAYBACK_STATUS= CDIO_MMC_GPCMD_CD_PLAYBACK_STATUS;
%constant long int GPCMD_PLAYBACK_CONTROL  = CDIO_MMC_GPCMD_PLAYBACK_CONTROL;
%constant long int GPCMD_READ_CDDA	   = CDIO_MMC_GPCMD_READ_CDDA;
%constant long int GPCMD_READ_CDXA	   = CDIO_MMC_GPCMD_READ_CDXA;
%constant long int GPCMD_READ_ALL_SUBCODES = CDIO_MMC_GPCMD_READ_ALL_SUBCODES;

/** Read Subchannel states */
%constant long int READ_SUB_ST_INVALID     = CDIO_MMC_READ_SUB_ST_INVALID;
%constant long int READ_SUB_ST_PLAY        = CDIO_MMC_READ_SUB_ST_PLAY;
%constant long int READ_SUB_ST_PAUSED      = CDIO_MMC_READ_SUB_ST_PAUSED;
%constant long int READ_SUB_ST_COMPLETED   = CDIO_MMC_READ_SUB_ST_COMPLETED;
%constant long int READ_SUB_ST_ERROR       = CDIO_MMC_READ_SUB_ST_ERROR;
%constant long int READ_SUB_ST_NO_STATUS   = CDIO_MMC_READ_SUB_ST_NO_STATUS;

%constant long int READ_TYPE_ANY           = CDIO_MMC_READ_TYPE_ANY;
%constant long int READ_TYPE_CDDA          = CDIO_MMC_READ_TYPE_CDDA;
%constant long int READ_TYPE_MODE1         = CDIO_MMC_READ_TYPE_MODE1;
%constant long int READ_TYPE_MODE2         = CDIO_MMC_READ_TYPE_MODE2;
%constant long int READ_TYPE_M2F1          = CDIO_MMC_READ_TYPE_M2F1;
%constant long int READ_TYPE_M2F2          = CDIO_MMC_READ_TYPE_M2F2;

/*! Format values for READ_TOC */
%constant long int READTOC_FMT_TOC         = CDIO_MMC_READTOC_FMT_TOC;
%constant long int READTOC_FMT_SESSION     = CDIO_MMC_READTOC_FMT_SESSION;
%constant long int READTOC_FMT_FULTOC      = CDIO_MMC_READTOC_FMT_FULTOC;

%constant long int CDIO_MMC_READTOC_FMT_PMA= CDIO_MMC_READTOC_FMT_PMA;
%constant long int READTOC_FMT_PMA         = CDIO_MMC_READTOC_FMT_PMA;
%constant long int READTOC_FMT_ATIP        = CDIO_MMC_READTOC_FMT_ATIP;
%constant long int READTOC_FMT_CDTEXT      = CDIO_MMC_READTOC_FMT_CDTEXT;

/* Page codes for MODE SENSE and MODE SET. */
%constant long int R_W_ERROR_PAGE          = CDIO_MMC_R_W_ERROR_PAGE;
%constant long int WRITE_PARMS_PAGE        = CDIO_MMC_WRITE_PARMS_PAGE;
%constant long int CDR_PARMS_PAGE          = CDIO_MMC_CDR_PARMS_PAGE;
%constant long int AUDIO_CTL_PAGE          = CDIO_MMC_AUDIO_CTL_PAGE;
%constant long int POWER_PAGE              = CDIO_MMC_POWER_PAGE;
%constant long int FAULT_FAIL_PAGE         = CDIO_MMC_FAULT_FAIL_PAGE;
%constant long int TO_PROTECT_PAGE         = CDIO_MMC_TO_PROTECT_PAGE;
%constant long int CAPABILITIES_PAGE       = CDIO_MMC_CAPABILITIES_PAGE;
%constant long int ALL_PAGES               = CDIO_MMC_ALL_PAGES;

/* Return type codes for GET_CONFIGURATION. */
%constant long int GET_CONF_ALL_FEATURES   = CDIO_MMC_GET_CONF_ALL_FEATURES;
%constant long int GET_CONF_CURRENT_FEATURES= CDIO_MMC_GET_CONF_CURRENT_FEATURES;
%constant long int GET_CONF_NAMED_FEATURE  = CDIO_MMC_GET_CONF_NAMED_FEATURE;

/* FEATURE codes used in GET CONFIGURATION. */
%constant long int FEATURE_PROFILE_LIST    = CDIO_MMC_FEATURE_PROFILE_LIST;
%constant long int FEATURE_CORE            = CDIO_MMC_FEATURE_CORE;
%constant long int FEATURE_MORPHING        = CDIO_MMC_FEATURE_MORPHING;
%constant long int FEATURE_REMOVABLE_MEDIUM= CDIO_MMC_FEATURE_REMOVABLE_MEDIUM;
%constant long int FEATURE_WRITE_PROTECT   = CDIO_MMC_FEATURE_WRITE_PROTECT;
%constant long int FEATURE_RANDOM_READABLE = CDIO_MMC_FEATURE_RANDOM_READABLE;
%constant long int FEATURE_MULTI_READ      = CDIO_MMC_FEATURE_MULTI_READ;
%constant long int FEATURE_CD_READ         = CDIO_MMC_FEATURE_CD_READ;
%constant long int FEATURE_DVD_READ        = CDIO_MMC_FEATURE_DVD_READ;
%constant long int FEATURE_RANDOM_WRITABLE = CDIO_MMC_FEATURE_RANDOM_WRITABLE;
%constant long int FEATURE_INCR_WRITE      = CDIO_MMC_FEATURE_INCR_WRITE;
%constant long int FEATURE_SECTOR_ERASE    = CDIO_MMC_FEATURE_SECTOR_ERASE;
%constant long int FEATURE_FORMATABLE      = CDIO_MMC_FEATURE_FORMATABLE;
%constant long int FEATURE_DEFECT_MGMT     = CDIO_MMC_FEATURE_DEFECT_MGMT;
%constant long int FEATURE_WRITE_ONCE      = CDIO_MMC_FEATURE_WRITE_ONCE;
%constant long int FEATURE_RESTRICT_OVERW  = CDIO_MMC_FEATURE_RESTRICT_OVERW;
%constant long int FEATURE_CD_RW_CAV       = CDIO_MMC_FEATURE_CD_RW_CAV;
%constant long int FEATURE_MRW             = CDIO_MMC_FEATURE_MRW;
%constant long int FEATURE_ENHANCED_DEFECT = CDIO_MMC_FEATURE_ENHANCED_DEFECT;
%constant long int FEATURE_DVD_PRW         = CDIO_MMC_FEATURE_DVD_PRW;
%constant long int FEATURE_DVD_PR          = CDIO_MMC_FEATURE_DVD_PR;
%constant long int FEATURE_RIGID_RES_OVERW = CDIO_MMC_FEATURE_RIGID_RES_OVERW;
%constant long int FEATURE_CD_TAO          = CDIO_MMC_FEATURE_CD_TAO;
%constant long int FEATURE_CD_SAO          = CDIO_MMC_FEATURE_CD_SAO;
%constant long int FEATURE_DVD_R_RW_WRITE  = CDIO_MMC_FEATURE_DVD_R_RW_WRITE;
%constant long int FEATURE_CD_RW_MEDIA_WRITE= CDIO_MMC_FEATURE_CD_RW_MEDIA_WRITE;
%constant long int FEATURE_DVD_PR_2_LAYER  = CDIO_MMC_FEATURE_DVD_PR_2_LAYER;
%constant long int FEATURE_POWER_MGMT      = CDIO_MMC_FEATURE_POWER_MGMT;
%constant long int FEATURE_CDDA_EXT_PLAY   = CDIO_MMC_FEATURE_CDDA_EXT_PLAY;
%constant long int FEATURE_MCODE_UPGRADE   = CDIO_MMC_FEATURE_MCODE_UPGRADE;
%constant long int FEATURE_TIME_OUT        = CDIO_MMC_FEATURE_TIME_OUT;
%constant long int FEATURE_DVD_CSS         = CDIO_MMC_FEATURE_DVD_CSS;
%constant long int FEATURE_RT_STREAMING    = CDIO_MMC_FEATURE_RT_STREAMING;
%constant long int FEATURE_LU_SN           = CDIO_MMC_FEATURE_LU_SN;
%constant long int FEATURE_FIRMWARE_DATE   = CDIO_MMC_FEATURE_FIRMWARE_DATE;
/* Profile profile codes used in GET_CONFIGURATION - PROFILE LIST. */

%constant long int FEATURE_PROF_NON_REMOVABLE = CDIO_MMC_FEATURE_PROF_NON_REMOVABLE;
%constant long int FEATURE_PROF_REMOVABLE  = CDIO_MMC_FEATURE_PROF_REMOVABLE;
%constant long int FEATURE_PROF_MO_ERASABLE= CDIO_MMC_FEATURE_PROF_MO_ERASABLE;
%constant long int FEATURE_PROF_MO_WRITE_ONCE= CDIO_MMC_FEATURE_PROF_MO_WRITE_ONCE;

%constant long int FEATURE_PROF_AS_MO      = CDIO_MMC_FEATURE_PROF_AS_MO;
%constant long int FEATURE_PROF_CD_ROM     = CDIO_MMC_FEATURE_PROF_CD_ROM;
%constant long int FEATURE_PROF_CD_R       = CDIO_MMC_FEATURE_PROF_CD_R;
%constant long int FEATURE_PROF_CD_RW      = CDIO_MMC_FEATURE_PROF_CD_RW;
%constant long int FEATURE_PROF_DVD_ROM    = CDIO_MMC_FEATURE_PROF_DVD_ROM;
%constant long int FEATURE_PROF_DVD_R_SEQ  = CDIO_MMC_FEATURE_PROF_DVD_R_SEQ;
%constant long int FEATURE_PROF_DVD_RAM    = CDIO_MMC_FEATURE_PROF_DVD_RAM;
%constant long int FEATURE_PROF_DVD_RW_RO  = CDIO_MMC_FEATURE_PROF_DVD_RW_RO;
%constant long int FEATURE_PROF_DVD_RW_SEQ = CDIO_MMC_FEATURE_PROF_DVD_RW_SEQ;
%constant long int FEATURE_PROF_DVD_PRW    = CDIO_MMC_FEATURE_PROF_DVD_PRW;
%constant long int FEATURE_PROF_DVD_PR     = CDIO_MMC_FEATURE_PROF_DVD_PR;
%constant long int FEATURE_PROF_DDCD_ROM   = CDIO_MMC_FEATURE_PROF_DDCD_ROM;
%constant long int FEATURE_PROF_DDCD_R     = CDIO_MMC_FEATURE_PROF_DDCD_R;
%constant long int FEATURE_PROF_DDCD_RW    = CDIO_MMC_FEATURE_PROF_DDCD_RW;
%constant long int FEATURE_PROF_DVD_PR    = CDIO_MMC_FEATURE_PROF_DVD_PR;
%constant long int FEATURE_PROF_NON_CONFORM= CDIO_MMC_FEATURE_PROF_NON_CONFORM;
%constant long int FEATURE_INTERFACE_UNSPECIFIED = CDIO_MMC_FEATURE_INTERFACE_UNSPECIFIED;
%constant long int FEATURE_INTERFACE_SCSI  = CDIO_MMC_FEATURE_INTERFACE_SCSI;
%constant long int FEATURE_INTERFACE_ATAPI = CDIO_MMC_FEATURE_INTERFACE_ATAPI;
%constant long int FEATURE_INTERFACE_IEEE_1394= CDIO_MMC_FEATURE_INTERFACE_IEEE_1394;
%constant long int FEATURE_INTERFACE_IEEE_1394A= CDIO_MMC_FEATURE_INTERFACE_IEEE_1394A;
%constant long int FEATURE_INTERFACE_FIBRE_CH= CDIO_MMC_FEATURE_INTERFACE_FIBRE_CH;


%feature("autodoc",
"Read Audio Subchannel information
  
 param p_cdio the CD object to be acted upon.
 param p_subchannel place for returned subchannel information
.");
%rename mmc_audio_read_subchannel audio_read_subchannel;

%feature("autodoc",
"Return a string containing the name of the audio state as returned from
 the Q_SUBCHANNEL.
");
%rename mmc_audio_state2str audio_state2str;

/*!
  Eject using MMC commands. If CD-ROM is "locked" we'll unlock it.
  Command is not "immediate" -- we'll wait for the command to complete.
  For a more general (and lower-level) routine, @see mmc_start_stop_media.
*/
//%rename mmc_eject_media eject_media;
int mmc_eject_media(const CdIo_t *p_cdio);
/*!
  Return a string containing the name of the given feature
*/
%rename mmc_feature2str feature2str;

/*!
  Return a string containing the name of the given feature
*/
%rename mmc_feature_profile2str feature_profile2str;

/*!  
  Return the length in bytes of the Command Descriptor
  Buffer (CDB) for a given MMC command. The length will be 
  either 6, 10, or 12. 
*/
%rename mmc_get_cmd_len get_cmd_len;

/*!
  Get the block size used in read requests, via MMC.
  @return the blocksize if > 0; error if <= 0
*/
%rename mmc_get_blocksize get_blocksize;

/*!  
  Get the lsn of the end of the CD
  
  @return the lsn. On error return CDIO_INVALID_LSN.
*/
%rename mmc_get_disc_last_lsn get_lsn;

/*! 
  Return the discmode as reported by the MMC Read (FULL) TOC
  command.
  
  Information was obtained from Section 5.1.13 (Read TOC/PMA/ATIP)
  pages 56-62 from the MMC draft specification, revision 10a
  at http://www.t10.org/ftp/t10/drafts/mmc/mmc-r10a.pdf See
  especially tables 72, 73 and 75.
*/
%rename mmc_get_discmode get_discmode;

/*!
  Get drive capabilities for a device.
  @return the drive capabilities.
*/
%rename mmc_get_drive_cap get_drive_cap;

/*!
  Get the MMC level supported by the device.
*/
%rename mmc_get_drive_mmc_cap get_drive_mmc_cap;

/*! 
  Get the DVD type associated with cd object.
  
  @return the DVD discmode.
*/
%rename mmc_get_dvd_struct_physical get_dvd_struct_physical;

/*! 
  Get the CD-ROM hardware info via an MMC INQUIRY command.
  
  @return true if we were able to get hardware info, false if we had
  an error.
*/
%rename mmc_get_hwinfo get_hwinfo;

/*! 
  Find out if media has changed since the last call.
  @param p_cdio the CD object to be acted upon.
  @return 1 if media has changed since last call, 0 if not. Error
  return codes are the same as driver_return_code_t
*/
%rename mmc_get_media_changed get_media_changed;

/*!
  Get the media catalog number (MCN) from the CD via MMC.
  
  @return the media catalog number r NULL if there is none or we
  don't have the ability to get it.
  
  Note: string is malloc'd so caller has to free() the returned
  string when done with it.
  
*/
%rename mmc_get_mcn get_mcn;

/** Get the output port volumes and port selections used on AUDIO PLAY
    commands via a MMC MODE SENSE command using the CD Audio Control
    Page.
*/
%rename mmc_audio_get_volume audio_get_volume;

/*!
  Report if CD-ROM has a praticular kind of interface (ATAPI, SCSCI, ...)
  Is it possible for an interface to have serveral? If not this 
  routine could probably return the single mmc_feature_interface_t.
  @return true if we have the interface and false if not.
*/
%rename mmc_have_interface have_interface;

/*! Run a MODE_SENSE command (6- or 10-byte version) 
  and put the results in p_buf 
  @return DRIVER_OP_SUCCESS if we ran the command ok.
*/
%rename mmc_mode_sense mode_sense;

/*! Run a MODE_SENSE command (10-byte version) 
  and put the results in p_buf 
  @return DRIVER_OP_SUCCESS if we ran the command ok.
*/
%rename mmc_mode_sense_10 mode_sense_10;

/*! Run a MODE_SENSE command (6-byte version) 
  and put the results in p_buf 
  @return DRIVER_OP_SUCCESS if we ran the command ok.
*/
%rename mmc_mode_sense_6 mode_sense_6;

/*! Issue a MMC READ_CD command.
    
  @param p_cdio  object to read from 
  
  @param p_buf   Place to store data. The caller should ensure that 
  p_buf can hold at least i_blocksize * i_blocks  bytes.
  
  @param i_lsn   sector to read 
  
  @param expected_sector_type restricts reading to a specific CD
  sector type.  Only 3 bits with values 1-5 are used:
    0 all sector types
    1 CD-DA sectors only 
    2 Mode 1 sectors only
    3 Mode 2 formless sectors only. Note in contrast to all other
      values an MMC CD-ROM is not required to support this mode.
    4 Mode 2 Form 1 sectors only
    5 Mode 2 Form 2 sectors only

  @param b_digital_audio_play Control error concealment when the
  data being read is CD-DA.  If the data being read is not CD-DA,
  this parameter is ignored.  If the data being read is CD-DA and
  DAP is false zero, then the user data returned should not be
  modified by flaw obscuring mechanisms such as audio data mute and
  interpolate.  If the data being read is CD-DA and DAP is true,
  then the user data returned should be modified by flaw obscuring
  mechanisms such as audio data mute and interpolate.  
  
  b_sync_header return the sync header (which will probably have
  the same value as CDIO_SECTOR_SYNC_HEADER of size
  CDIO_CD_SYNC_SIZE).
  
  @param header_codes Header Codes refer to the sector header and
  the sub-header that is present in mode 2 formed sectors: 
  
   0 No header information is returned.  
   1 The 4-byte sector header of data sectors is be returned, 
   2 The 8-byte sector sub-header of mode 2 formed sectors is
     returned.  
   3 Both sector header and sub-header (12 bytes) is returned.  
   The Header preceeds the rest of the bytes (e.g. user-data bytes) 
   that might get returned.
   
   @param b_user_data  Return user data if true. 
   
   For CD-DA, the User Data is CDIO_CD_FRAMESIZE_RAW bytes.

   For Mode 1, The User Data is ISO_BLOCKSIZE bytes beginning at
   offset CDIO_CD_HEADER_SIZE+CDIO_CD_SUBHEADER_SIZE.
   
   For Mode 2 formless, The User Data is M2RAW_SECTOR_SIZE bytes
   beginning at offset CDIO_CD_HEADER_SIZE+CDIO_CD_SUBHEADER_SIZE.
   
   For data Mode 2, form 1, User Data is ISO_BLOCKSIZE bytes beginning at
   offset CDIO_CD_XA_SYNC_HEADER.
   
   For data Mode 2, form 2, User Data is 2 324 bytes beginning at
   offset CDIO_CD_XA_SYNC_HEADER.
   
   @param b_sync 

   @param b_edc_ecc true if we return EDC/ECC error detection/correction bits.
   
   The presence and size of EDC redundancy or ECC parity is defined
   according to sector type: 
   
   CD-DA sectors have neither EDC redundancy nor ECC parity.  
   
   Data Mode 1 sectors have 288 bytes of EDC redundancy, Pad, and
   ECC parity beginning at offset 2064.
   
   Data Mode 2 formless sectors have neither EDC redundancy nor ECC
   parity
   
   Data Mode 2 form 1 sectors have 280 bytes of EDC redundancy and
   ECC parity beginning at offset 2072
   
   Data Mode 2 form 2 sectors optionally have 4 bytes of EDC
   redundancy beginning at offset 2348.
   
   
   @param c2_error_information If true associate a bit with each
   sector for C2 error The resulting bit field is ordered exactly as
   the main channel bytes.  Each 8-bit boundary defines a byte of
   flag bits.
   
   @param subchannel_selection subchannel-selection bits
   
     0  No Sub-channel data shall be returned.  (0 bytes)
     1  RAW P-W Sub-channel data shall be returned.  (96 byte)
     2  Formatted Q sub-channel data shall be transferred (16 bytes)
     3  Reserved     
     4  Corrected and de-interleaved R-W sub-channel (96 bytes)
     5-7  Reserved

   @param i_blocksize size of the a block expected to be returned
     
   @param i_blocks number of blocks expected to be returned.
     
*/
%rename mmc_read_cd read_cd;

/*! Read just the user data part of some sort of data sector (via 
    mmc_read_cd). 
    
    @param p_cdio object to read from

    @param p_buf place to read data into.  The caller should make sure
                 this location can store at least CDIO_CD_FRAMESIZE,
                 M2RAW_SECTOR_SIZE, or M2F2_SECTOR_SIZE depending on
                 the kind of sector getting read. If you don't know
                 whether you have a Mode 1/2, Form 1/ Form 2/Formless
                 sector best to reserve space for the maximum,
                 M2RAW_SECTOR_SIZE.

    @param i_lsn sector to read
    @param i_blocksize size of each block
    @param i_blocks number of blocks to read

*/
%rename mmc_read_data_sectors read_data_sectors;

/*! Read sectors using SCSI-MMC GPCMD_READ_CD. 
  Can read only up to 25 blocks.
*/
%rename mmc_read_sectors read_sectors;

/*!
    Run a Multimedia command (MMC). 
  
    @param p_cdio	 CD structure set by cdio_open().
    @param i_timeout_ms  time in milliseconds we will wait for the command
                         to complete. 
    @param p_cdb	 CDB bytes. All values that are needed should be set 
                         on input. We'll figure out what the right CDB length 
                         should be.
    @param e_direction   direction the transfer is to go.
    @param i_buf	 Size of buffer
    @param p_buf	 Buffer for data, both sending and receiving.

    @return 0 if command completed successfully.
 */
%rename mmc_run_cmd run_cmd;

/*!
  Set the block size for subsequest read requests, via MMC.
*/
%rename mmc_set_blocksize set_blocksize;

/*!
  Set the drive speed. 
*/
%rename mmc_set_speed set_speed;

/*!
    Load or Unload media using a MMC START STOP command. 
    
    @param p_cdio  the CD object to be acted upon.
    @param b_eject eject if true and close tray if false
    @param b_immediate wait or don't wait for operation to complete
    @param power_condition Set CD-ROM to idle/standby/sleep. If nonzero
    eject/load is ignored, so set to 0 if you want to eject or load.
    
    @see mmc_eject_media or mmc_close_tray
 */
%rename mmc_start_stop_unit stop_media;
int mmc_start_stop_unit (const CdIo_t *p_cdio);
%feature("autodoc",
"mmc_start_stop_unit cmd, a more general (and lower-level) routine
to eject media / open tray. mmc_eject_media sometimes does not work.");
int mmc_close_tray(CdIo_t *p_cdio);


char * mmc_get_isrc(CdIo_t *p_cdio, track_t track);
%inline %{
char * mmc_get_isrc(CdIo_t *p_cdio, track_t track) {
    static cdio_isrc_t isrc;
    bzero(isrc, sizeof(isrc));
    int status;

    status = mmc_isrc_track_read_subchannel (p_cdio, track, isrc);
    if(status != DRIVER_OP_SUCCESS)
        *isrc = '\0';
    return isrc;
}
%}

%perlcode %{

import Device::Cdio::VERSION;
$VERSION = $Device::Cdio::VERSION;
use strict;

=pod

=head1 NAME

perlmmc - lower-level wrapper to MMC from libcdio, the ISO 9660 library of the CD Input and Control package

=head1 SYNOPSIS

This is fairly straight-forward wrapper around the MultiMedia commands from
the C library libcdio. Although this is perfectly usable on its own, it is expected that the interfaces L<Device::Cdio::MMC> or L<Device::Cdio::Device::MMC> 
is what most people will want to use. 

There are various constants that are defined here.

=head1 METHODS

=head2 this

This seems to be an artifact of SWIG. 

=head1 SEE ALSO

L<http://www.gnu.org/software/libcdio> has documentation on
libcdio including the a manual and the API via doxygen.

=head1 AUTHORS

Rocky Bernstein C<< <rocky at cpan.org> >>.

=head1 COPYRIGHT

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

=cut

%}
